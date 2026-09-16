# Optional Kalorat analysis relay

This service is optional. The Flutter app stays BYOK: configure a backend URL with
`--dart-define=KALORAT_ANALYSIS_BACKEND_URL=http://localhost:8787`. For a
non-local deployment, also set a shared relay token and pass it with
`--dart-define=KALORAT_ANALYSIS_BACKEND_TOKEN=change-me`. The app
forwards the user-provided Gemini key for the duration of each request. The relay
never logs or persists that key or the request body. It uses Node 18+ native
`fetch`, which pools upstream connections, and emits metadata-only latency logs. Without a relay token, keep the relay private/local.

Run locally:

```bash
node backend/server.js
```

The app can also continue direct-to-Gemini when no backend URL is supplied.
