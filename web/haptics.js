// Haptics for the web build.
//
// Android browsers have navigator.vibrate. iOS Safari (and the home screen
// PWA) does not, but toggling an <input type="checkbox" switch> plays the
// system switch haptic. That is the trick behind ios-haptics and
// ios-vibrator-pro-max; the iOS part below follows ios-haptics.
//
// Browsers only allow the haptic during a user gesture, so callers trigger it
// from tap handlers. Anywhere else it silently does nothing.
(function () {
  'use strict';

  // kinds: 0 tick, 1 selection, 2 confirm
  var MIN_GAP_MS = 28;
  var last = 0;

  function throttled() {
    var now = performance.now();
    if (now - last < MIN_GAP_MS) return true;
    last = now;
    return false;
  }

  // The last calls and what became of them, for the haptics test panel
  // (web/haptics_test.js): no browser API says whether the phone buzzed.
  var log = (window.kaloratHapticLog = []);
  function note(text) {
    var active = navigator.userActivation ? navigator.userActivation.isActive : 'n/a';
    var ev = window.event ? window.event.type : '-';
    log.push(Math.round(performance.now()) + ' ' + text + ' event ' + ev + ' activation ' + active);
    if (log.length > 12) log.shift();
  }

  if (typeof navigator.vibrate === 'function') {
    var PATTERNS = [10, 6, [12, 50, 12]];
    window.kaloratHaptic = function (kind) {
      if (throttled()) return;
      try {
        note('vibrate ' + navigator.vibrate(PATTERNS[kind] || PATTERNS[0]));
      } catch (e) {
        note('error ' + e.message);
      }
    };
    return;
  }

  // iOS: the system plays its switch haptic when an <input type=checkbox
  // switch> toggles (iOS 18 and later). Done exactly as ios-haptics does it,
  // which is known to work on iPhones: a fresh hidden label in <head>,
  // clicked and removed again. Only touch screens get it. The old check,
  // CSS.supports('appearance', 'switch'), is not a reliable test for the
  // switch haptic, so it is gone; on a browser without the switch the click
  // does nothing.
  var coarse =
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(pointer: coarse)').matches;
  if (!coarse) {
    window.kaloratHaptic = function () {
      note('skipped (no touch screen)');
    };
    return;
  }

  function tick() {
    var label = document.createElement('label');
    label.setAttribute('aria-hidden', 'true');
    label.style.display = 'none';
    var input = document.createElement('input');
    input.type = 'checkbox';
    input.setAttribute('switch', '');
    label.appendChild(input);
    document.head.appendChild(label);
    label.click();
    document.head.removeChild(label);
  }

  function play(kind) {
    if (throttled()) return;
    try {
      note('play');
      tick();
      if (kind === 2) setTimeout(tick, 120);
    } catch (e) {
      note('error ' + e.message);
    }
  }

  // Safari only plays the haptic shortly after a real tap (as the library
  // found: about 850ms). A request without a recent gesture (a tap Flutter
  // reports late, e.g. after a double-tap wait) waits for the next real
  // pointerup/touchend/click (up to 300ms) and is dropped after that.
  // Listeners are passive and never touch the events.
  var GRANT_MS = 850;
  var PENDING_MAX_MS = 300;
  var lastGesture = 0;
  var pendingKind = -1;
  var pendingAt = 0;

  function onGesture(e) {
    if (!e.isTrusted) return;
    lastGesture = performance.now();
    if (pendingKind < 0) return;
    var kind = pendingKind;
    pendingKind = -1;
    if (lastGesture - pendingAt <= PENDING_MAX_MS) play(kind);
    else note('dropped (no gesture in time)');
  }

  var opts = { capture: true, passive: true };
  // pointerup comes first: Flutter reports a tap from it, so with this
  // capture listener (it runs before Flutter's) the haptic plays inside the
  // tap's own event instead of waiting for a later touchend or click, which
  // iOS may never send to the page.
  window.addEventListener('pointerup', onGesture, opts);
  window.addEventListener('touchend', onGesture, opts);
  window.addEventListener('click', onGesture, opts);
  window.addEventListener('keyup', onGesture, opts);

  window.kaloratHaptic = function (kind) {
    var now = performance.now();
    if (now - lastGesture <= GRANT_MS) {
      play(kind);
    } else {
      note('pending');
      pendingKind = kind;
      pendingAt = now;
    }
  };
})();
