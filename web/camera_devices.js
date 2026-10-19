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
// opens. window.kaloratPreviewSnapshot() resolves to a JPEG of the preview.
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

// A small, soft JPEG of what the camera preview shows right now, or null:
// shown while the camera switches, instead of a black screen. The frame is
// shrunk to a few pixels and drawn back up with smoothing (and blurred where
// the canvas can), once; no blur filter then has to run over the whole
// screen on every frame of the fade. The picture is taken at once; only the
// JPEG is made after the call returns, so the camera can be released.
window.kaloratPreviewSnapshot = function () {
  var videos = document.querySelectorAll('flt-platform-view video');
  var video = null;
  for (var i = 0; i < videos.length; i++) {
    if (videos[i].readyState >= 2 && videos[i].videoWidth) video = videos[i];
  }
  if (!video) return Promise.resolve(null);
  try {
    var aspect = video.videoWidth / video.videoHeight;
    var tiny = document.createElement('canvas');
    tiny.width = Math.max(1, Math.round(aspect >= 1 ? 32 : 32 * aspect));
    tiny.height = Math.max(1, Math.round(aspect >= 1 ? 32 / aspect : 32));
    var tctx = tiny.getContext('2d');
    tctx.imageSmoothingQuality = 'high';
    tctx.drawImage(video, 0, 0, tiny.width, tiny.height);
    var soft = document.createElement('canvas');
    soft.width = tiny.width * 6;
    soft.height = tiny.height * 6;
    var sctx = soft.getContext('2d');
    sctx.imageSmoothingEnabled = true;
    sctx.imageSmoothingQuality = 'high';
    if ('filter' in sctx) sctx.filter = 'blur(6px)';
    // Drawn a little larger so the blur does not darken the edges.
    sctx.drawImage(tiny, -8, -8, soft.width + 16, soft.height + 16);
    // A little darker, so it reads as a paused picture; done here so the
    // app draws the image without a color filter.
    sctx.filter = 'none';
    sctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
    sctx.fillRect(0, 0, soft.width, soft.height);
    // Encoded right away: toBlob runs when the browser is idle, which in
    // the middle of a camera switch can be too late to show anything.
    var url = soft.toDataURL('image/jpeg', 0.85);
    var data = atob(url.slice(url.indexOf(',') + 1));
    var bytes = new Uint8Array(data.length);
    for (var j = 0; j < data.length; j++) bytes[j] = data.charCodeAt(j);
    return Promise.resolve(bytes);
  } catch (_) {
    return Promise.resolve(null);
  }
};
