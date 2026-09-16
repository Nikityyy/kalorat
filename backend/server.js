const http = require('node:http');
const { randomUUID } = require('node:crypto');

const port = Number(process.env.PORT || process.env.KALORAT_BACKEND_PORT || 8787);
const maxBodyBytes = 12 * 1024 * 1024;
const upstreamTimeoutMs = Number(process.env.KALORAT_UPSTREAM_TIMEOUT_MS || 45000);

function corsHeaders() {
  return {
    'access-control-allow-origin': process.env.KALORAT_CORS_ORIGIN || '*',
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type,x-kalorat-request-id,x-kalorat-relay-token',
    'access-control-expose-headers': 'x-kalorat-request-id,x-kalorat-backend-latency-ms',
  };
}

function isAuthorized(request) {
  const expected = process.env.KALORAT_RELAY_TOKEN;
  return !expected || request.headers['x-kalorat-relay-token'] === expected;
}

function rejectUnauthorized(request, response) {
  if (isAuthorized(request)) return false;
  sendJson(response, 401, { error: 'relay_unauthorized' });
  return true;
}

function sendJson(response, status, payload, extra = {}) {
  response.writeHead(status, {
    ...corsHeaders(),
    'content-type': 'application/json; charset=utf-8',
    ...extra,
  });
  response.end(JSON.stringify(payload));
}

function readJson(request) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    request.on('data', (chunk) => {
      size += chunk.length;
      if (size > maxBodyBytes) {
        reject(new Error('request_too_large'));
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });
    request.on('end', () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString('utf8')));
      } catch (_) {
        reject(new Error('invalid_json'));
      }
    });
    request.on('error', reject);
  });
}

async function proxyAnalysis(request, response) {
  if (rejectUnauthorized(request, response)) return;
  const startedAt = performance.now();
  const requestId = request.headers['x-kalorat-request-id'] || randomUUID();
  let body;
  try {
    body = await readJson(request);
  } catch (error) {
    sendJson(response, error.message === 'request_too_large' ? 413 : 400, {
      error: error.message,
    });
    return;
  }

  const apiKey = body.apiKey;
  const model = typeof body.model === 'string' ? body.model : '';
  const geminiRequest = body.request;
  if (!apiKey || !model || !geminiRequest) {
    sendJson(response, 400, {
      error: 'apiKey, model, and request are required',
    });
    return;
  }

  // The key is used only for this upstream request and is never logged or
  // persisted. Node's native fetch/undici keeps connections pooled.
  const upstreamMethod = body.stream === false ? 'generateContent' : 'streamGenerateContent?alt=sse';
  const upstreamUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:${upstreamMethod}`;
  let upstream;
  const abortController = new AbortController();
  const timeoutHandle = setTimeout(() => abortController.abort(), upstreamTimeoutMs);
  const abortOnClientClose = () => {
    if (!response.writableFinished) abortController.abort();
  };
  response.once('close', abortOnClientClose);
  try {
    upstream = await fetch(upstreamUrl, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-goog-api-key': apiKey,
        'x-kalorat-request-id': requestId,
      },
      body: JSON.stringify(geminiRequest),
      signal: abortController.signal,
    });
  } catch (error) {
    clearTimeout(timeoutHandle);
    response.off('close', abortOnClientClose);
    if (response.writableEnded) return;
    sendJson(response, 502, { error: 'upstream_network_error' });
    console.log(JSON.stringify({
      event: 'analysis_request', requestId, model,
      status: 502, totalMs: Math.round(performance.now() - startedAt),
    }));
    return;
  }

  const headers = {
    ...corsHeaders(),
    'content-type': upstream.headers.get('content-type') || 'text/event-stream',
    'cache-control': 'no-cache, no-transform',
    'x-kalorat-request-id': requestId,
    'x-kalorat-backend-latency-ms': String(Math.round(performance.now() - startedAt)),
  };
  response.writeHead(upstream.status, headers);

  let firstByteMs = null;
  let bytes = 0;
  try {
    if (upstream.body) {
      const reader = upstream.body.getReader();
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        if (firstByteMs === null) firstByteMs = Math.round(performance.now() - startedAt);
        const chunk = Buffer.from(value);
        bytes += chunk.length;
        response.write(chunk);
      }
    } else {
      const text = await upstream.text();
      bytes = Buffer.byteLength(text);
      if (bytes) response.write(text);
    }
  } finally {
    clearTimeout(timeoutHandle);
    response.off('close', abortOnClientClose);
    if (!response.writableEnded) response.end();
  }

  console.log(JSON.stringify({
    event: 'analysis_request', requestId, model,
    status: upstream.status,
    firstByteMs,
    totalMs: Math.round(performance.now() - startedAt),
    responseBytes: bytes,
  }));
}

async function validateApiKey(request, response) {
  if (rejectUnauthorized(request, response)) return;
  let body;
  try {
    body = await readJson(request);
  } catch (_) {
    sendJson(response, 400, { valid: false, error: 'invalid_json' });
    return;
  }
  const apiKey = body.apiKey;
  if (typeof apiKey !== 'string' || apiKey.length === 0) {
    sendJson(response, 200, { valid: false });
    return;
  }
  try {
    const upstream = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models',
      { headers: { 'x-goog-api-key': apiKey } },
    );
    sendJson(response, 200, { valid: upstream.ok });
  } catch (_) {
    sendJson(response, 200, { valid: false });
  }
}

const server = http.createServer(async (request, response) => {
  if (request.method === 'OPTIONS') {
    response.writeHead(204, corsHeaders());
    response.end();
    return;
  }

  if (request.method === 'GET' && request.url === '/health') {
    sendJson(response, 200, { ok: true, service: 'kalorat-analysis' });
    return;
  }

  if (request.method === 'POST' && request.url === '/v1/validate-key') {
    await validateApiKey(request, response);
    return;
  }

  if (request.method === 'POST' && request.url === '/v1/analyze') {
    await proxyAnalysis(request, response);
    return;
  }

  sendJson(response, 404, { error: 'not_found' });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Kalorat analysis relay listening on http://0.0.0.0:${port}`);
});
