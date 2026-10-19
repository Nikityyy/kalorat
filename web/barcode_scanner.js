// Background barcode scanning of the camera preview for the PWA.
//
// While Dart has scanning switched on, a frame of the camera <video> is sent
// to barcode_worker.js about ten times a second, but only after the previous
// frame is done, so decoding never queues up and the UI thread only copies
// the frame. Frames are downscaled to MAX_EDGE: enough for a barcode held at
// arm's length, and quick to decode.
//
// window.kaloratBarcode.start(onCode) / .stop() / .prewarm();
// onCode(text, format, left, top, right, bottom, aspect) is called for every
// frame that contains a code: where it is as fractions of the frame (-1 when
// unknown) and the frame's width / height.
// .decodeImage(bytes) reads a photo instead and resolves to
// { text, format, box, aspect } or null.
// .takeFrame() resolves to a JPEG (Uint8Array) of the camera picture in which
// the last code was read, or null.
(function () {
  'use strict';
  var MAX_EDGE = 960;
  // About six grabs a second: still finds a barcode within a moment, and
  // leaves the main thread to the preview.
  var INTERVAL_MS = 160;
  // The picture kept on a hit: the size meal photos are stored at.
  var PHOTO_EDGE = 1600;

  var worker = null;
  var ready = false;
  var workerHasCanvas = false;
  var useBitmaps = typeof createImageBitmap === 'function';
  var busy = false;
  var busySince = 0;
  var running = false;
  var onCode = null;
  var timer = null;
  var nextId = 0;
  var fallbackCanvas = null;
  var fallbackCtx = null;
  var stills = {};
  var readyWaiters = [];
  var hitCanvas = null;
  var hitText = null;
  var hitAt = 0;
  var stats = { frames: 0, found: 0, lastMs: 0, maxMs: 0, mode: '' };

  function ensureWorker() {
    if (worker) return;
    try {
      worker = new Worker(new URL('barcode_worker.js', document.baseURI));
    } catch (error) {
      console.warn('Barcode worker unavailable:', error);
      return;
    }
    worker.onmessage = function (event) {
      var msg = event.data;
      if (msg.type === 'ready') {
        ready = true;
        workerHasCanvas = msg.canvas;
        stats.mode = workerHasCanvas && useBitmaps ? 'bitmap' : 'pixels';
        readyWaiters.splice(0).forEach(function (resolve) {
          resolve(true);
        });
      } else if (msg.type === 'result' && stills[msg.id]) {
        var resolve = stills[msg.id];
        delete stills[msg.id];
        resolve(msg.text ? { text: msg.text, format: String(msg.format || ''), box: msg.box, aspect: msg.aspect } : null);
      } else if (msg.type === 'result') {
        busy = false;
        stats.frames++;
        stats.lastMs = msg.ms;
        if (msg.ms > stats.maxMs) stats.maxMs = msg.ms;
        if (msg.text && running && onCode) {
          stats.found++;
          keepHitFrame(msg.text);
          var b = msg.box || [-1, -1, -1, -1];
          try {
            onCode(msg.text, String(msg.format || ''), b[0], b[1], b[2], b[3], msg.aspect || 0);
          } catch (_) {}
        }
      } else if (msg.type === 'error') {
        busy = false;
        console.warn('Barcode worker:', msg.message);
      }
    };
    worker.onerror = function () {
      busy = false;
    };
  }

  function findVideo() {
    var videos = document.querySelectorAll('flt-platform-view video');
    for (var i = 0; i < videos.length; i++) {
      var v = videos[i];
      if (v.isConnected && v.videoWidth && v.readyState >= 2) return v;
    }
    return null;
  }

  function targetSize(video) {
    var vw = video.videoWidth;
    var vh = video.videoHeight;
    var scale = Math.min(1, MAX_EDGE / Math.max(vw, vh));
    return { w: Math.round(vw * scale), h: Math.round(vh * scale) };
  }

  function sendPixels(video, size, id) {
    if (!fallbackCanvas) {
      fallbackCanvas = document.createElement('canvas');
      fallbackCtx = fallbackCanvas.getContext('2d', { willReadFrequently: true });
    }
    if (fallbackCanvas.width !== size.w || fallbackCanvas.height !== size.h) {
      fallbackCanvas.width = size.w;
      fallbackCanvas.height = size.h;
    }
    fallbackCtx.drawImage(video, 0, 0, size.w, size.h);
    var image = fallbackCtx.getImageData(0, 0, size.w, size.h);
    worker.postMessage(
      { id: id, image: { data: image.data.buffer, width: size.w, height: size.h } },
      [image.data.buffer]
    );
  }

  // Copies the preview as it is right now, a frame or two after the one the
  // worker read, before Dart hears of the code. A code held in view is
  // copied again only every second.
  function keepHitFrame(text) {
    var now = Date.now();
    if (text === hitText && hitCanvas && now - hitAt < 1000) return;
    var video = findVideo();
    if (!video) return;
    try {
      var scale = Math.min(1, PHOTO_EDGE / Math.max(video.videoWidth, video.videoHeight));
      var w = Math.round(video.videoWidth * scale);
      var h = Math.round(video.videoHeight * scale);
      if (!hitCanvas) hitCanvas = document.createElement('canvas');
      if (hitCanvas.width !== w || hitCanvas.height !== h) {
        hitCanvas.width = w;
        hitCanvas.height = h;
      }
      hitCanvas.getContext('2d').drawImage(video, 0, 0, w, h);
      hitText = text;
      hitAt = now;
    } catch (_) {
      hitText = null;
    }
  }

  function takeFrame() {
    if (!hitCanvas || !hitText) return Promise.resolve(null);
    var canvas = hitCanvas;
    return new Promise(function (resolve) {
      canvas.toBlob(
        function (blob) {
          if (!blob) return resolve(null);
          blob.arrayBuffer().then(
            function (buffer) {
              resolve(new Uint8Array(buffer));
            },
            function () {
              resolve(null);
            }
          );
        },
        'image/jpeg',
        0.85
      );
    });
  }

  function whenReady() {
    ensureWorker();
    if (!worker) return Promise.resolve(false);
    if (ready) return Promise.resolve(true);
    return new Promise(function (resolve) {
      readyWaiters.push(resolve);
      setTimeout(function () {
        resolve(false);
      }, 10000);
    });
  }

  // Photos are read at up to STILL_EDGE: a barcode is often only a small
  // part of a photo.
  var STILL_EDGE = 2048;

  function decodeImage(bytes) {
    return whenReady().then(function (ok) {
      if (!ok || !workerHasCanvas || typeof createImageBitmap !== 'function') return null;
      return createImageBitmap(new Blob([bytes]), { imageOrientation: 'from-image' })
        .then(function (full) {
          var scale = Math.min(1, STILL_EDGE / Math.max(full.width, full.height));
          if (scale === 1) return full;
          var w = Math.round(full.width * scale);
          var h = Math.round(full.height * scale);
          return createImageBitmap(full, { resizeWidth: w, resizeHeight: h, resizeQuality: 'high' }).then(function (small) {
            full.close();
            return small;
          });
        })
        .then(function (bitmap) {
          var id = ++nextId;
          return new Promise(function (resolve) {
            stills[id] = resolve;
            worker.postMessage({ id: id, bitmap: bitmap, still: true }, [bitmap]);
            setTimeout(function () {
              if (stills[id]) {
                delete stills[id];
                resolve(null);
              }
            }, 8000);
          });
        })
        .catch(function () {
          return null;
        });
    });
  }

  function grab() {
    var video = findVideo();
    if (!video) return;
    var size = targetSize(video);
    var id = ++nextId;
    busy = true;
    busySince = Date.now();
    if (useBitmaps && workerHasCanvas) {
      createImageBitmap(video, {
        resizeWidth: size.w,
        resizeHeight: size.h,
        resizeQuality: 'medium',
      }).then(
        function (bitmap) {
          if (!running) {
            bitmap.close();
            busy = false;
            return;
          }
          worker.postMessage({ id: id, bitmap: bitmap }, [bitmap]);
        },
        function () {
          // Some browsers cannot make a bitmap from a video: copy pixels instead.
          useBitmaps = false;
          stats.mode = 'pixels';
          busy = false;
        }
      );
    } else {
      try {
        sendPixels(video, size, id);
      } catch (_) {
        busy = false;
      }
    }
  }

  function tick() {
    timer = null;
    if (!running) return;
    timer = setTimeout(tick, INTERVAL_MS);
    // A frame the worker never answered must not stop scanning for good.
    if (busy && Date.now() - busySince > 2000) busy = false;
    if (!ready || busy || document.hidden) return;
    grab();
  }

  window.kaloratBarcode = {
    prewarm: function () {
      ensureWorker();
    },
    start: function (callback) {
      onCode = callback;
      ensureWorker();
      if (!worker || running) return;
      running = true;
      tick();
    },
    takeFrame: takeFrame,
    decodeImage: decodeImage,
    stop: function () {
      running = false;
      onCode = null;
      hitText = null;
      if (timer) clearTimeout(timer);
      timer = null;
    },
    stats: function () {
      return Object.assign({ running: running, ready: ready }, stats);
    },
  };
})();
