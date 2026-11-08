// JPEG encoding for photos, in a worker (jpeg_worker.js) where the browser
// has one. kaloratEncodeJpeg resolves to the JPEG bytes, or to null when the
// worker cannot do it (no OffscreenCanvas, an image it cannot decode); the
// callers then encode on the main thread as before.
(function () {
  'use strict';
  var worker = null;
  var ready = null; // Promise<boolean>: whether the worker can encode
  var jobs = {};
  var nextId = 0;

  function start() {
    if (ready) return ready;
    ready = new Promise(function (resolve) {
      if (typeof Worker !== 'function' || typeof OffscreenCanvas !== 'function') {
        resolve(false);
        return;
      }
      try {
        worker = new Worker(new URL('jpeg_worker.js', document.baseURI));
      } catch (_) {
        resolve(false);
        return;
      }
      var timer = setTimeout(function () {
        resolve(false);
      }, 5000);
      worker.onmessage = function (e) {
        var msg = e.data;
        if (msg.type === 'ready') {
          clearTimeout(timer);
          resolve(!!msg.ok);
          return;
        }
        var done = jobs[msg.id];
        if (!done) return;
        delete jobs[msg.id];
        done(msg.bytes || null);
      };
      worker.onerror = function () {
        clearTimeout(timer);
        resolve(false);
        for (var id in jobs) jobs[id](null);
        jobs = {};
        ready = Promise.resolve(false);
      };
    });
    return ready;
  }

  // source: an ImageBitmap (transferred, so closed for the caller) or the
  // bytes of an encoded photo (copied). The photo is shrunk to at most
  // maxDimension on its longest side; mirrored flips it left to right.
  window.kaloratEncodeJpeg = function (source, maxDimension, quality, mirrored) {
    return start().then(function (ok) {
      if (!ok) {
        if (source && source.close) source.close();
        return null;
      }
      return new Promise(function (resolve) {
        var id = ++nextId;
        // A worker that stops answering must not hold the photo forever.
        var timer = setTimeout(function () {
          if (jobs[id]) {
            delete jobs[id];
            resolve(null);
          }
        }, 8000);
        jobs[id] = function (bytes) {
          clearTimeout(timer);
          resolve(bytes);
        };
        var job = { id: id, max: maxDimension, quality: quality, mirrored: !!mirrored };
        if (source instanceof Uint8Array) {
          job.bytes = source;
          worker.postMessage(job);
        } else {
          job.bitmap = source;
          worker.postMessage(job, [source]);
        }
      });
    });
  };

  // Started early, so the first photo does not wait for it.
  var warm = function () {
    start();
  };
  if (typeof requestIdleCallback === 'function') {
    requestIdleCallback(warm, { timeout: 3000 });
  } else {
    setTimeout(warm, 1500);
  }
})();
