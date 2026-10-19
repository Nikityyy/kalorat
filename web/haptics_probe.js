// Haptics test for iPhones. Since iOS 26.5 a switch toggled from script no
// longer buzzes; only a finger toggling a real <input type=checkbox switch>
// does. So each variant here puts something real under the finger, over a
// Flutter button, and counts what happened: how often the switch toggled
// (here) and how often Flutter saw the tap (in the app). The person says
// which ones they felt. Opened from the camera diagnostics.
//
// A switch placed inside <flutter-view> lets the touch reach Flutter too:
// Flutter listens for pointerdown on <flutter-view>, so the event bubbles to
// it, and it only cancels the browser's default (the switch toggle) for
// events aimed at <flutter-view> itself.
(function () {
  'use strict';

  var targets = {};

  function makeSwitch() {
    var input = document.createElement('input');
    input.type = 'checkbox';
    input.setAttribute('switch', '');
    input.tabIndex = -1;
    input.setAttribute('aria-hidden', 'true');
    return input;
  }

  function host(inside) {
    return (inside && document.querySelector('flutter-view')) || document.body;
  }

  // Modes:
  //  visible     the switch as it looks, over the button
  //  clear       invisible switch (opacity 0) over the button
  //  faint       the same at opacity 0.01
  //  still       opacity 0 and touch-action: none
  //  label       an invisible <label> over the button, its switch elsewhere
  //  outside     invisible switch outside <flutter-view>: Flutter misses the tap
  var BASE =
    'position:fixed;margin:0;padding:0;z-index:2147483000;' +
    '-webkit-tap-highlight-color:transparent;';

  function build(id, mode) {
    var t = { mode: mode, toggles: 0, nodes: [] };
    var input = makeSwitch();
    var count = function () {
      t.toggles++;
    };
    input.addEventListener('change', count);
    if (mode === 'label') {
      input.id = 'kalorat-probe-' + id;
      // Rendered (not display:none) but out of the way.
      input.style.cssText = BASE + 'left:0;top:0;width:1px;height:1px;opacity:0;pointer-events:none';
      var label = document.createElement('label');
      label.htmlFor = input.id;
      label.setAttribute('aria-hidden', 'true');
      label.style.cssText = BASE + 'display:block;opacity:0;touch-action:manipulation';
      host(true).appendChild(input);
      host(true).appendChild(label);
      t.nodes = [label, input];
      t.box = label;
    } else {
      var css = BASE + 'appearance:auto;-webkit-appearance:auto;border-radius:12px;';
      if (mode === 'visible') css += 'opacity:1;';
      else if (mode === 'faint') css += 'opacity:0.01;';
      else css += 'opacity:0;';
      css += mode === 'still' ? 'touch-action:none;' : 'touch-action:manipulation;';
      input.style.cssText = css;
      host(mode !== 'outside').appendChild(input);
      t.nodes = [input];
      t.box = input;
    }
    return t;
  }

  window.kaloratHapticProbe = {
    // Puts variant [mode] over the rect (CSS pixels of the viewport).
    place: function (id, mode, left, top, width, height) {
      var t = targets[id];
      if (!t || t.mode !== mode) {
        if (t) this.remove(id);
        t = targets[id] = build(id, mode);
      }
      var s = t.box.style;
      s.left = left + 'px';
      s.top = top + 'px';
      s.width = width + 'px';
      s.height = height + 'px';
    },
    toggles: function (id) {
      return targets[id] ? targets[id].toggles : 0;
    },
    remove: function (id) {
      var t = targets[id];
      if (!t) return;
      t.nodes.forEach(function (n) {
        n.remove();
      });
      delete targets[id];
    },
    // The old way, from script; expected to stay silent on iOS 26.5+.
    scripted: function () {
      var label = document.createElement('label');
      label.style.display = 'none';
      var input = makeSwitch();
      label.appendChild(input);
      document.head.appendChild(label);
      label.click();
      document.head.removeChild(label);
      return input.checked;
    },
    vibrate: function () {
      return typeof navigator.vibrate === 'function' ? navigator.vibrate(30) : false;
    },
    info: function () {
      return (
        navigator.userAgent +
        '\nstandalone ' +
        (navigator.standalone === true || matchMedia('(display-mode: standalone)').matches) +
        ', vibrate ' +
        (typeof navigator.vibrate === 'function')
      );
    },
  };
})();
