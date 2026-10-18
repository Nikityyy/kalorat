// Camera preview that draws the <video> into a <canvas> with our own "cover"
// geometry instead of relying on the video element's own layout.
// Some iPhones paint the video small inside its box (about 56% of it, centred);
// a canvas does not depend on how Safari lays out the video element, and it
// fixed that on a real iPhone.
//
// On by default on iPhone and iPad, off elsewhere. The camera diagnostics panel
// can switch it either way; the choice is kept in localStorage ('1' / '0') and
// takes effect immediately.
(function () {
  'use strict';
  var KEY = 'kalorat.cameraCanvas';

  function isAppleTouch() {
    var ua = navigator.userAgent || '';
    if (/iPhone|iPad|iPod/.test(ua)) return true;
    // iPadOS reports itself as a Mac.
    return navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
  }

  function enabled() {
    try {
      var stored = localStorage.getItem(KEY);
      if (stored === '1') return true;
      if (stored === '0') return false;
    } catch (_) {}
    return isAppleTouch();
  }

  window.kaloratCameraCanvasEnabled = enabled;
  window.kaloratSetCameraCanvas = function (on) {
    try {
      localStorage.setItem(KEY, on ? '1' : '0');
    } catch (_) {}
  };

  function attach(video) {
    var host = video.parentElement;
    if (!host) return;
    video.__kaloratCanvas = true;
    var canvas = document.createElement('canvas');
    canvas.setAttribute('aria-hidden', 'true');
    canvas.style.cssText =
      'position:absolute;left:0;top:0;width:100%;height:100%;pointer-events:none;display:none';
    if (getComputedStyle(host).position === 'static') host.style.position = 'relative';
    host.appendChild(canvas);
    var ctx = canvas.getContext('2d', { alpha: false });
    var shown = false;

    function frame() {
      if (!video.isConnected) return; // camera was torn down
      requestAnimationFrame(frame);
      var on = enabled();
      if (on !== shown) {
        shown = on;
        canvas.style.display = on ? 'block' : 'none';
        // Keep the video playing but invisible while the canvas shows it.
        video.style.opacity = on ? '0' : '';
      }
      if (!on || document.hidden) return;
      var vw = video.videoWidth;
      var vh = video.videoHeight;
      if (!vw || !vh || video.readyState < 2) return;
      var dpr = Math.min(window.devicePixelRatio || 1, 2);
      var cw = Math.round(host.clientWidth * dpr);
      var ch = Math.round(host.clientHeight * dpr);
      if (!cw || !ch) return;
      if (canvas.width !== cw || canvas.height !== ch) {
        canvas.width = cw;
        canvas.height = ch;
      }
      var s = Math.max(cw / vw, ch / vh);
      var dw = vw * s;
      var dh = vh * s;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      // The plugin mirrors the front camera with scaleX(-1) on the video.
      if (video.style.transform.indexOf('scaleX(-1)') !== -1) {
        ctx.translate(cw, 0);
        ctx.scale(-1, 1);
      }
      ctx.drawImage(video, (cw - dw) / 2, (ch - dh) / 2, dw, dh);
    }
    requestAnimationFrame(frame);
  }

  function scan() {
    var videos = document.querySelectorAll('flt-platform-view video');
    for (var i = 0; i < videos.length; i++) {
      if (!videos[i].__kaloratCanvas) attach(videos[i]);
    }
  }

  function start() {
    scan();
    new MutationObserver(scan).observe(document.body, { childList: true, subtree: true });
  }
  if (document.body) start();
  else document.addEventListener('DOMContentLoaded', start);
})();
