// Finds the back and front camera for the PWA with as few camera opens as
// possible.
//
// The camera plugin's availableCameras() opens every camera once to read
// which way it faces. An iPhone lists up to six (wide, ultra wide, tele,
// dual, triple, front), and each open takes a moment, so the first picture
// came late. Here the browser picks the back and front camera by facing
// mode (two opens), and their ids are kept, so later starts open nothing
// before the preview itself. Browsers may hand out new ids (Chrome does
// between sessions), so kept ids are only used while the device list, which
// opens no camera, still has them.
//
// window.kaloratCameraDevices(fresh) resolves to JSON
// [{ id, facing }, ...] (back first) or null; fresh ignores the kept ids.
// window.kaloratForgetCameraDevices() drops them, e.g. when one no longer
// opens. window.kaloratPreviewSnapshot() resolves to a soft PNG of the
// preview; window.kaloratPreviewNextFrame() resolves once the playing
// preview shows a new frame.
(function () {
  'use strict';
  var KEY = 'kalorat.cameraDevices.v1';

  function kept() {
    try {
      var list = JSON.parse(localStorage.getItem(KEY));
      return Array.isArray(list) && list.length && list[0].id ? list : null;
    } catch (_) {
      return null;
    }
  }

  function probe(video) {
    return navigator.mediaDevices.getUserMedia({ audio: false, video: video }).then(
      function (stream) {
        var track = stream.getVideoTracks()[0];
        var settings = track && track.getSettings ? track.getSettings() : {};
        stream.getTracks().forEach(function (t) {
          t.stop();
        });
        return settings.deviceId ? { id: settings.deviceId, facing: settings.facingMode || null } : null;
      },
      function (error) {
        // Without permission there is nothing to find; the caller falls
        // back to the plugin, which reports the error.
        if (error && (error.name === 'NotAllowedError' || error.name === 'SecurityError')) throw error;
        return null;
      }
    );
  }

  // The kept ids, if the browser still lists every one of them.
  function stillListed(list) {
    if (!list || typeof navigator.mediaDevices.enumerateDevices !== 'function') return Promise.resolve(null);
    return navigator.mediaDevices.enumerateDevices().then(
      function (devices) {
        var ids = devices
          .filter(function (d) {
            return d.kind === 'videoinput';
          })
          .map(function (d) {
            return d.deviceId;
          });
        return list.every(function (c) {
          return ids.indexOf(c.id) >= 0;
        })
          ? list
          : null;
      },
      function () {
        return null;
      }
    );
  }

  window.kaloratCameraDevices = function (fresh) {
    var md = navigator.mediaDevices;
    if (!md || typeof md.getUserMedia !== 'function') return Promise.resolve(null);
    return stillListed(fresh ? null : kept()).then(function (list) {
      return list ? JSON.stringify(list) : find();
    });
  };

  function find() {
    var found = [];
    return probe({ facingMode: { exact: 'environment' } })
      .then(function (back) {
        if (back) found.push(back);
        return probe({ facingMode: { exact: 'user' } });
      })
      .then(function (front) {
        if (front && !found.some(function (c) { return c.id === front.id; })) found.push(front);
        // A computer's webcam reports no facing mode: take the default one.
        return found.length ? null : probe(true);
      })
      .then(function (any) {
        if (any) found.push(any);
        if (!found.length) return null;
        try {
          localStorage.setItem(KEY, JSON.stringify(found));
        } catch (_) {}
        return JSON.stringify(found);
      })
      .catch(function () {
        return null;
      });
  }

  window.kaloratForgetCameraDevices = function () {
    try {
      localStorage.removeItem(KEY);
    } catch (_) {}
  };
})();

// The preview video that plays (or last played) the camera.
function kaloratPreviewVideo(playing) {
  var videos = document.querySelectorAll('flt-platform-view video');
  var video = null;
  for (var i = 0; i < videos.length; i++) {
    var v = videos[i];
    if (v.readyState >= 2 && v.videoWidth && v.srcObject && (!playing || !v.paused)) video = v;
  }
  return video;
}

// Blurs the RGBA pixels of a small image in place: three box blurs in a
// row come close to a Gaussian. Edges repeat their last pixel, so the
// picture does not darken towards them.
function kaloratBoxBlur(data, w, h, r) {
  var tmp = new Float32Array(w * h * 4);
  function pass(src, dst, len, count, stride, step) {
    for (var line = 0; line < count; line++) {
      var base = line * stride;
      for (var c = 0; c < 4; c++) {
        var sum = 0;
        for (var k = -r; k <= r; k++) sum += src[base + Math.min(len - 1, Math.max(0, k)) * step + c];
        for (var i = 0; i < len; i++) {
          dst[base + i * step + c] = sum / (2 * r + 1);
          sum += src[base + Math.min(len - 1, i + r + 1) * step + c] - src[base + Math.max(0, i - r) * step + c];
        }
      }
    }
  }
  var buf = Float32Array.from(data);
  for (var n = 0; n < 3; n++) {
    pass(buf, tmp, w, h, w * 4, 4); // rows
    pass(tmp, buf, h, w, 4, w * 4); // columns
  }
  for (var j = 0; j < data.length; j++) data[j] = buf[j];
}

// A soft PNG of what the camera preview shows right now, or null: it lies
// over the preview while the camera starts again (after a switch, or when
// the camera tab comes back) instead of a black or frozen picture. The
// frame is shrunk, blurred here (Safari's canvas has no blur filter), drawn
// back up in steps of two so it stays smooth, and darkened a little. PNG,
// because a JPEG's 8 pixel blocks show once the app stretches the picture.
// Takes a few milliseconds, so it is done when the call returns.
window.kaloratPreviewSnapshot = function () {
  var video = kaloratPreviewVideo(false);
  if (!video) return Promise.resolve(null);
  try {
    var aspect = video.videoWidth / video.videoHeight;
    var small = document.createElement('canvas');
    small.width = Math.max(1, Math.round(aspect >= 1 ? 64 : 64 * aspect));
    small.height = Math.max(1, Math.round(aspect >= 1 ? 64 / aspect : 64));
    var ctx = small.getContext('2d', { willReadFrequently: true });
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(video, 0, 0, small.width, small.height);
    var pixels = ctx.getImageData(0, 0, small.width, small.height);
    kaloratBoxBlur(pixels.data, small.width, small.height, 2);
    ctx.putImageData(pixels, 0, 0);
    var canvas = small;
    for (var step = 0; step < 2; step++) {
      var next = document.createElement('canvas');
      next.width = canvas.width * 2;
      next.height = canvas.height * 2;
      var nctx = next.getContext('2d');
      nctx.imageSmoothingEnabled = true;
      nctx.imageSmoothingQuality = 'high';
      nctx.drawImage(canvas, 0, 0, next.width, next.height);
      canvas = next;
    }
    var cctx = canvas.getContext('2d');
    cctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
    cctx.fillRect(0, 0, canvas.width, canvas.height);
    // Encoded right away: toBlob runs when the browser is idle, which in
    // the middle of a camera switch can be too late to show anything.
    var url = canvas.toDataURL('image/png');
    var data = atob(url.slice(url.indexOf(',') + 1));
    var bytes = new Uint8Array(data.length);
    for (var j = 0; j < data.length; j++) bytes[j] = data.charCodeAt(j);
    return Promise.resolve(bytes);
  } catch (_) {
    return Promise.resolve(null);
  }
};

// Resolves once a playing preview has shown a new frame (and the frame
// after it was drawn, for the canvas preview), or after [timeoutMs].
window.kaloratPreviewNextFrame = function (timeoutMs) {
  return new Promise(function (resolve) {
    var done = false;
    function finish() {
      if (done) return;
      done = true;
      requestAnimationFrame(function () {
        resolve();
      });
    }
    setTimeout(finish, timeoutMs || 1500);
    (function wait() {
      if (done) return;
      var video = kaloratPreviewVideo(true);
      if (!video) return requestAnimationFrame(wait);
      if (typeof video.requestVideoFrameCallback === 'function') {
        video.requestVideoFrameCallback(finish);
      } else {
        var t = video.currentTime;
        (function changed() {
          if (done) return;
          if (video.currentTime !== t) finish();
          else requestAnimationFrame(changed);
        })();
      }
    })();
  });
};
