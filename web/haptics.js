// Haptics for the web build.
//
// Android browsers have navigator.vibrate. iOS Safari (and the home screen
// PWA) has no web API for haptics. Toggling a hidden
// <input type="checkbox" switch> from script (the ios-haptics trick) was
// tested on an iPhone with iOS 27: only a switch the finger itself flips
// plays the haptic, so there is nothing to call on iOS.
//
// Browsers only allow vibration during a user gesture, so callers trigger it
// from tap handlers. Anywhere else it silently does nothing.
(function () {
  'use strict';

  // kinds: 0 tick, 1 selection, 2 confirm
  var PATTERNS = [10, 6, [12, 50, 12]];
  var MIN_GAP_MS = 28;
  var last = 0;

  window.kaloratHaptic = function (kind) {
    if (typeof navigator.vibrate !== 'function') return;
    var now = performance.now();
    if (now - last < MIN_GAP_MS) return;
    last = now;
    try {
      navigator.vibrate(PATTERNS[kind] || PATTERNS[0]);
    } catch (_) {}
  };
})();
