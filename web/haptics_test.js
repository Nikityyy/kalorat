// Haptics test for the iPhone home screen app. No browser API reports whether
// the Taptic Engine fired, so this panel runs each known way of triggering it
// from a plain HTML button (outside Flutter's event handling) and records
// what the browser saw: whether the tap still counted as a user gesture and
// whether the switch really toggled. The person marks what they felt.
// Opened from the camera diagnostics (five taps on the logo).
(function () {
  'use strict';

  function hiddenSwitch(style) {
    var label = document.createElement('label');
    label.setAttribute('aria-hidden', 'true');
    label.style.cssText = style;
    var input = document.createElement('input');
    input.type = 'checkbox';
    input.setAttribute('switch', '');
    label.appendChild(input);
    return { label: label, input: input };
  }

  // Each variant: [id, event, how]. how(done) toggles a switch and returns it.
  var VARIANTS = [
    ['click-label', 'click', function () {
      var s = hiddenSwitch('display:none');
      document.head.appendChild(s.label); s.label.click(); document.head.removeChild(s.label);
      return s.input;
    }],
    ['touchend-label', 'touchend', function () {
      var s = hiddenSwitch('display:none');
      document.head.appendChild(s.label); s.label.click(); document.head.removeChild(s.label);
      return s.input;
    }],
    ['pointerup-label', 'pointerup', function () {
      var s = hiddenSwitch('display:none');
      document.head.appendChild(s.label); s.label.click(); document.head.removeChild(s.label);
      return s.input;
    }],
    ['click-rendered', 'click', function () {
      // Rendered but invisible, in <body>: some iOS versions may only play
      // the haptic for a switch that is laid out.
      var s = hiddenSwitch('position:fixed;left:0;top:0;width:1px;height:1px;opacity:0.01;overflow:hidden;pointer-events:none');
      document.body.appendChild(s.label); s.label.click();
      setTimeout(function () { s.label.remove(); }, 500);
      return s.input;
    }],
    ['click-input', 'click', function () {
      var s = hiddenSwitch('position:fixed;left:0;top:0;opacity:0.01;pointer-events:none');
      document.body.appendChild(s.label); s.input.click();
      setTimeout(function () { s.label.remove(); }, 500);
      return s.input;
    }],
    ['vibrate', 'click', function () {
      if (typeof navigator.vibrate !== 'function') throw new Error('no navigator.vibrate');
      navigator.vibrate(30);
      return null;
    }],
  ];

  function el(tag, css, text) {
    var e = document.createElement(tag);
    if (css) e.style.cssText = css;
    if (text != null) e.textContent = text;
    return e;
  }

  window.kaloratHapticsTest = function (labelsJson) {
    var t = {};
    try { t = JSON.parse(labelsJson || '{}'); } catch (_) {}
    var old = document.getElementById('kalorat-haptics-test');
    if (old) old.remove();

    var panel = el('div', 'position:fixed;inset:0;z-index:100000;overflow:auto;background:#0A0A0A;color:#fff;' +
      'font:14px -apple-system,system-ui,sans-serif;padding:calc(env(safe-area-inset-top) + 16px) 16px calc(env(safe-area-inset-bottom) + 16px);');
    panel.id = 'kalorat-haptics-test';
    panel.appendChild(el('h2', 'margin:0 0 8px;font-size:20px', t.title || 'Haptics'));
    panel.appendChild(el('p', 'margin:0 0 16px;color:#aaa', t.intro || ''));

    var results = {};
    var info = el('pre', 'white-space:pre-wrap;font:11px ui-monospace,monospace;color:#9f9;margin:16px 0');
    function render() {
      var lines = [
        navigator.userAgent,
        'standalone ' + (navigator.standalone === true || matchMedia('(display-mode: standalone)').matches) +
          ' coarse ' + matchMedia('(pointer: coarse)').matches +
          ' vibrate ' + (typeof navigator.vibrate === 'function') +
          ' userActivation ' + ('userActivation' in navigator),
      ];
      Object.keys(results).forEach(function (k) { lines.push(k + ': ' + results[k]); });
      if (window.kaloratHapticLog) {
        lines.push('app haptics (last calls):');
        lines.push.apply(lines, window.kaloratHapticLog);
      }
      info.textContent = lines.join('\n');
    }

    // 1. The native switch, toggled by hand: if this does not buzz, the
    // phone plays no switch haptic at all (system setting or iOS version).
    var row = el('label', 'display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid #333');
    var native = document.createElement('input');
    native.type = 'checkbox';
    native.setAttribute('switch', '');
    native.style.cssText = 'transform:scale(1.4)';
    row.appendChild(native);
    row.appendChild(el('span', '', '0 · ' + (t.native || 'native switch')));
    var felt0 = el('input'); felt0.type = 'checkbox';
    row.appendChild(el('span', 'margin-left:auto;color:#aaa', t.felt || 'felt'));
    row.appendChild(felt0);
    felt0.addEventListener('change', function () { results['0 native felt'] = felt0.checked; render(); });
    panel.appendChild(row);

    VARIANTS.forEach(function (v, i) {
      var id = v[0], type = v[1], how = v[2];
      var r = el('div', 'display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid #333');
      var b = el('button', 'flex:1;padding:14px;border-radius:12px;border:0;background:#1EB070;color:#000;font:600 15px -apple-system,system-ui',
        (i + 1) + ' · ' + id);
      b.addEventListener(type, function (e) {
        var active = navigator.userActivation ? navigator.userActivation.isActive : 'n/a';
        var out;
        try {
          var input = how();
          out = 'event ' + e.type + ' trusted ' + e.isTrusted + ' activation ' + active +
            (input ? ' toggled ' + input.checked : ' called');
        } catch (err) {
          out = 'error ' + err.message;
        }
        results[(i + 1) + ' ' + id] = out;
        render();
      });
      r.appendChild(b);
      var felt = el('input'); felt.type = 'checkbox';
      r.appendChild(el('span', 'color:#aaa', t.felt || 'felt'));
      r.appendChild(felt);
      felt.addEventListener('change', function () { results[(i + 1) + ' ' + id + ' felt'] = felt.checked; render(); });
      panel.appendChild(r);
    });

    // The app's own path, as a Flutter button would use it.
    var app = el('button', 'padding:14px;border-radius:12px;border:1px solid #1EB070;background:none;color:#1EB070;font:600 15px -apple-system,system-ui',
      '7 · kaloratHaptic');
    app.addEventListener('click', function () {
      try { window.kaloratHaptic(0); results['7 kaloratHaptic'] = 'called'; } catch (err) { results['7 kaloratHaptic'] = 'error ' + err.message; }
      render();
    });
    var appRow = el('div', 'display:flex;align-items:center;gap:12px;padding:12px 0');
    app.style.marginTop = '0';
    app.style.flex = '1';
    appRow.appendChild(app);
    var felt7 = el('input'); felt7.type = 'checkbox';
    appRow.appendChild(el('span', 'color:#aaa', t.felt || 'felt'));
    appRow.appendChild(felt7);
    felt7.addEventListener('change', function () { results['7 kaloratHaptic felt'] = felt7.checked; render(); });
    panel.appendChild(appRow);

    panel.appendChild(info);
    var close = el('button', 'width:100%;padding:14px;border-radius:12px;border:0;background:#333;color:#fff;font:600 15px -apple-system,system-ui', t.close || 'Close');
    close.addEventListener('click', function () { panel.remove(); });
    panel.appendChild(close);
    render();
    document.body.appendChild(panel);
  };
})();
