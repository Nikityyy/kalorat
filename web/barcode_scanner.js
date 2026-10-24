// Background barcode scanning of the camera preview for the PWA.
//
// While Dart has scanning switched on, a frame of the camera <video> is sent
// to barcode_worker.js shortly after the previous one is read, so decoding
// never queues up and the UI thread only copies the frame. Frames are
// downscaled to MAX_EDGE: enough for a barcode held at arm's length, and
// quick to decode. While it scans, the connection to Open Food Facts is kept
// open so the lookup after a hit starts at once.
//
// Only the part of the frame inside the guide (plus a margin) is read, set
// with .setRegion(); a code is only counted there anyway, and the smaller
// picture is read at a higher resolution in less time.
//
// window.kaloratBarcode.start(onCode) / .stop() / .prewarm();
// .setRegion(left, top, right, bottom, viewAspect, mirrored): the guide as
// fractions of the view the preview covers (like CSS object-fit: cover),
// whose width / height is viewAspect; no arguments reads the whole frame.
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
  // A crop of the guide is read up to this size: about the pixels of a
  // whole downscaled frame, at about twice the detail.
  var CROP_EDGE = 720;
  // Room around the guide, as a share of its size: a code half outside it
  // still reads, and Dart decides whether it counts.
  var MARGIN = 0.12;
  // The next frame is grabbed this long after the last one was read, so the
  // worker is busy most of the time and the main thread still has room for
  // the preview. (It used to be a fixed 160ms between grabs.)
  var GAP_MS = 50;
  var doneAt = 0;
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
  var region = null;
  // The crop of the frame being read, as fractions: [left, top, w, h].
  var crops = {};

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
        doneAt = Date.now();
        var crop = crops[msg.id] || [0, 0, 1, 1];
        delete crops[msg.id];
        stats.frames++;
        stats.lastMs = msg.ms;
        if (msg.ms > stats.maxMs) stats.maxMs = msg.ms;
        if (msg.text && running && onCode) {
          stats.found++;
          keepHitFrame(msg.text);
          var b = msg.box
            ? [
                crop[0] + msg.box[0] * crop[2],
                crop[1] + msg.box[1] * crop[3],
                crop[0] + msg.box[2] * crop[2],
                crop[1] + msg.box[3] * crop[3],
              ]
            : [-1, -1, -1, -1];
          var aspect = msg.aspect ? (msg.aspect * crop[3]) / crop[2] : 0;
          try {
            onCode(msg.text, String(msg.format || ''), b[0], b[1], b[2], b[3], aspect);
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

  // The guide's part of the frame, as fractions [left, top, w, h].
  function cropOf(video) {
    if (!region) return [0, 0, 1, 1];
    var fa = video.videoWidth / video.videoHeight;
    var va = region.viewAspect;
    // The frame as shown, in view units (the view is va wide, 1 high).
    var shownW = va > fa ? va : fa;
    var shownH = shownW / fa;
    var left = (va - shownW) / 2;
    var top = (1 - shownH) / 2;
    var mx = (region.right - region.left) * MARGIN;
    var my = (region.bottom - region.top) * MARGIN;
    var x0 = ((region.left - mx) * va - left) / shownW;
    var x1 = ((region.right + mx) * va - left) / shownW;
    if (region.mirrored) {
      var t = 1 - x1;
      x1 = 1 - x0;
      x0 = t;
    }
    var y0 = (region.top - my - top) / shownH;
    var y1 = (region.bottom + my - top) / shownH;
    x0 = Math.max(0, x0);
    y0 = Math.max(0, y0);
    x1 = Math.min(1, x1);
    y1 = Math.min(1, y1);
    if (x1 - x0 < 0.05 || y1 - y0 < 0.05) return [0, 0, 1, 1];
    return [x0, y0, x1 - x0, y1 - y0];
  }

  function targetSize(video, crop) {
    var vw = video.videoWidth * crop[2];
    var vh = video.videoHeight * crop[3];
    var edge = crop[2] < 1 || crop[3] < 1 ? CROP_EDGE : MAX_EDGE;
    var scale = Math.min(1, edge / Math.max(vw, vh));
    return {
      sx: Math.round(video.videoWidth * crop[0]),
      sy: Math.round(video.videoHeight * crop[1]),
      sw: Math.max(1, Math.round(vw)),
      sh: Math.max(1, Math.round(vh)),
      w: Math.max(1, Math.round(vw * scale)),
      h: Math.max(1, Math.round(vh * scale)),
    };
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
    fallbackCtx.drawImage(video, size.sx, size.sy, size.sw, size.sh, 0, 0, size.w, size.h);
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
    var crop = cropOf(video);
    var size = targetSize(video, crop);
    var id = ++nextId;
    crops[id] = crop;
    busy = true;
    busySince = Date.now();
    if (useBitmaps && workerHasCanvas) {
      createImageBitmap(video, size.sx, size.sy, size.sw, size.sh, {
        resizeWidth: size.w,
        resizeHeight: size.h,
        resizeQuality: 'medium',
      }).then(
        function (bitmap) {
          if (!running) {
            bitmap.close();
            delete crops[id];
            busy = false;
            return;
          }
          worker.postMessage({ id: id, bitmap: bitmap }, [bitmap]);
        },
        function () {
          // Some browsers cannot make a bitmap from a video: copy pixels instead.
          useBitmaps = false;
          stats.mode = 'pixels';
          delete crops[id];
          busy = false;
        }
      );
    } else {
      try {
        sendPixels(video, size, id);
      } catch (_) {
        delete crops[id];
        busy = false;
      }
    }
  }

  function tick() {
    timer = null;
    if (!running) return;
    timer = setTimeout(tick, 20);
    // A frame the worker never answered must not stop scanning for good.
    if (busy && Date.now() - busySince > 2000) busy = false;
    if (!ready || busy || document.hidden || Date.now() - doneAt < GAP_MS) return;
    preconnect();
    grab();
  }

  // Opens the connection to Open Food Facts while the camera scans, so the
  // lookup after a hit does not wait for DNS and TLS first. No request is
  // sent.
  var preconnected = 0;
  function preconnect() {
    if (Date.now() - preconnected < 8000) return;
    preconnected = Date.now();
    try {
      var link = document.createElement('link');
      link.rel = 'preconnect';
      link.href = 'https://world.openfoodfacts.org';
      link.crossOrigin = 'anonymous';
      document.head.appendChild(link);
      setTimeout(function () {
        link.remove();
      }, 9000);
    } catch (_) {}
  }

  // How bright the picture is behind a part of the view (0 to 1, -1 when there
  // is no picture): the part is given as fractions of the view, which the
  // video covers. A few dozen pixels are read from a tiny canvas.
  var lumaCanvas = null;
  function luma(left, top, right, bottom, viewAspect) {
    var video = findVideo();
    if (!video || !(viewAspect > 0)) return -1;
    var fa = video.videoWidth / video.videoHeight;
    var shownW = viewAspect > fa ? viewAspect : fa;
    var shownH = shownW / fa;
    var l = (viewAspect - shownW) / 2;
    var t = (1 - shownH) / 2;
    function clamp(v) {
      return Math.max(0, Math.min(1, v));
    }
    var x0 = clamp((left * viewAspect - l) / shownW);
    var x1 = clamp((right * viewAspect - l) / shownW);
    var y0 = clamp((top - t) / shownH);
    var y1 = clamp((bottom - t) / shownH);
    if (x1 <= x0 || y1 <= y0) return -1;
    try {
      if (!lumaCanvas) {
        lumaCanvas = document.createElement('canvas');
        lumaCanvas.width = 16;
        lumaCanvas.height = 4;
      }
      var ctx = lumaCanvas.getContext('2d', { willReadFrequently: true });
      ctx.drawImage(
        video,
        x0 * video.videoWidth,
        y0 * video.videoHeight,
        (x1 - x0) * video.videoWidth,
        (y1 - y0) * video.videoHeight,
        0,
        0,
        16,
        4
      );
      var d = ctx.getImageData(0, 0, 16, 4).data;
      var sum = 0;
      for (var i = 0; i < d.length; i += 4) sum += 0.2126 * d[i] + 0.7152 * d[i + 1] + 0.0722 * d[i + 2];
      return sum / (d.length / 4) / 255;
    } catch (_) {
      return -1;
    }
  }

  window.kaloratBarcode = {
    luma: luma,
    prewarm: function () {
      ensureWorker();
    },
    start: function (callback) {
      onCode = callback;
      ensureWorker();
      if (!worker || running) return;
      running = true;
      preconnect();
      tick();
    },
    setRegion: function (left, top, right, bottom, viewAspect, mirrored) {
      region =
        typeof viewAspect === 'number' && viewAspect > 0
          ? { left: left, top: top, right: right, bottom: bottom, viewAspect: viewAspect, mirrored: !!mirrored }
          : null;
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
