// Haptics for the web build.
//
// Android browsers have navigator.vibrate.
//
// iOS Safari (and the home screen PWA) has no web API for haptics, but plays
// the system tick when the finger flips an <input type="checkbox" switch>.
// Flipping one from script stays silent since iOS 26.5 (tested on an iPhone
// with iOS 27: the finger has to do it). So one invisible switch lies over
// the whole app, inside <flutter-view>: every touch lands on it, bubbles on
// to Flutter as usual, and Flutter decides whether that tap buzzes. A tap
// handler that calls kaloratHaptic() while the finger is down arms it; when
// the finger lifts without that, the switch lets the click through to the
// app below, so it does not flip and nothing buzzes.
//
// On iOS that means haptics only for taps, on release: Haptics.selection()
// while dragging a wheel, or a tick after something finishes, stays silent.
(function () {
  'use strict';

  // kinds: 0 tick, 1 selection, 2 confirm
  var PATTERNS = [10, 6, [12, 50, 12]];
  var MIN_GAP_MS = 28;
  var last = 0;

  if (typeof navigator.vibrate === 'function') {
    window.kaloratHaptic = function (kind) {
      var now = performance.now();
      if (now - last < MIN_GAP_MS) return;
      last = now;
      try {
        navigator.vibrate(PATTERNS[kind] || PATTERNS[0]);
      } catch (_) {}
    };
    window.kaloratHapticsInit = function () {};
    return;
  }

  var coarse =
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(pointer: coarse)').matches;
  var ios =
    /iPhone|iPad|iPod/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (!coarse || !ios) {
    window.kaloratHaptic = function () {};
    window.kaloratHapticsInit = function () {};
    return;
  }

  var layer = null;
  var sw = null;
  var down = false;
  var armed = false;
  var downX = 0;
  var downY = 0;
  var restoreTimer = 0;
  var disarmTimer = 0;

  function passThrough(on) {
    if (layer) layer.style.pointerEvents = on ? 'none' : 'auto';
  }

  function disarm() {
    armed = false;
    clearTimeout(disarmTimer);
    if (layer) layer.removeAttribute('for');
  }

  // A text field has the keyboard: the overlay stays out of its way, so
  // taps place the cursor and the field keeps its focus.
  function editing() {
    var el = document.activeElement;
    return !!el && el !== layer && el !== sw && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.isContentEditable);
  }

  window.kaloratHaptic = function () {
    if (!down) return;
    armed = true;
    // Dynamically associate the label only for explicitly armed taps so
    // unarmed touches/scrolls on iOS never activate the underlying switch.
    if (layer && sw) layer.htmlFor = sw.id;
    clearTimeout(disarmTimer);
    disarmTimer = setTimeout(disarm, 250);
  };

  // Called once the app runs. Flutter has its pointer listeners on window
  // by then, so the pointerup listener here runs after the app's tap
  // handlers.
  window.kaloratHapticsInit = function () {
    var view = document.querySelector('flutter-view');
    if (layer || !view) return;

    sw = document.createElement('input');
    sw.id = 'kalorat-haptic-switch';
    sw.type = 'checkbox';
    sw.setAttribute('switch', '');
    sw.tabIndex = -1;
    sw.setAttribute('aria-hidden', 'true');
    sw.style.cssText =
      'position:fixed;left:0;top:0;width:1px;height:1px;margin:0;padding:0;' +
      'appearance:auto;-webkit-appearance:auto;opacity:0;pointer-events:none;' +
      'z-index:-1';

    // Keep the hit overlay as a neutral <label> without a `for` attribute at
    // rest so iOS UIKit switch gestures/haptics never trigger on blank taps.
    layer = document.createElement('label');
    layer.tabIndex = -1;
    layer.setAttribute('aria-hidden', 'true');
    layer.style.cssText =
      'position:fixed;left:0;top:0;width:100vw;height:100vh;margin:0;padding:0;' +
      'opacity:0;z-index:2147483000;' +
      'touch-action:none;-webkit-tap-highlight-color:transparent;' +
      '-webkit-touch-callout:none;-webkit-user-select:none;user-select:none';
    if (editing()) passThrough(true);
    view.appendChild(sw);
    view.appendChild(layer);

    // Never takes focus: a focused control would pull it from the app and
    // its text fields. Flipping via label does not need focus.
    layer.addEventListener('mousedown', function (e) {
      e.preventDefault();
    });
    sw.addEventListener('focus', function () {
      sw.blur();
    });
    sw.addEventListener('change', function () {
      setTimeout(disarm, 0);
    });
    layer.addEventListener('click', function (e) {
      if (!armed) {
        e.preventDefault();
        disarm();
        return;
      }
      setTimeout(disarm, 0);
    });
    layer.addEventListener('pointerdown', function (e) {
      if (!e.isPrimary) return;
      down = true;
      downX = e.clientX;
      downY = e.clientY;
      disarm();
    });
    window.addEventListener('pointermove', function (e) {
      if (!e.isPrimary || !down) return;
      if (Math.abs(e.clientX - downX) > 10 || Math.abs(e.clientY - downY) > 10) {
        down = false;
        disarm();
      }
    });
    window.addEventListener('pointerup', function (e) {
      if (!e.isPrimary || !down) return;
      down = false;
      if (armed) return;
      // Not a tap that buzzes: strip association and let the click that
      // follows go to the app below without flipping the switch.
      disarm();
      passThrough(true);
      clearTimeout(restoreTimer);
      restoreTimer = setTimeout(function () {
        if (!editing()) passThrough(false);
      }, 250);
    });
    window.addEventListener('pointercancel', function () {
      down = false;
      disarm();
    });
    window.addEventListener(
      'click',
      function (e) {
        if (e.target === layer || e.target === sw || editing()) return;
        clearTimeout(restoreTimer);
        setTimeout(function () {
          if (!editing()) passThrough(false);
        }, 0);
      },
      true
    );
    document.addEventListener('focusin', function () {
      if (editing()) passThrough(true);
    });
    document.addEventListener('focusout', function () {
      setTimeout(function () {
        if (!editing()) passThrough(false);
      }, 0);
    });
  };
})();
