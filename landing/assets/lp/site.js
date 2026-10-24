// Kalorat landing. Every number comes from meals.js (Kalorat's own results for
// the three photos) or the demo day below; every word from strings.js.
(function () {
  'use strict';
  var MEALS = window.KALORAT_MEALS;
  var reduce = matchMedia('(prefers-reduced-motion: reduce)');
  var narrow = matchMedia('(max-width: 860px)');
  var hover = matchMedia('(hover: hover)');
  var weak = (navigator.hardwareConcurrency || 4) <= 2 || (navigator.deviceMemory || 4) <= 2;
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var T = function (k) { return window.kaloratT(k); };
  var lang = function () { return window.KALORAT_LANG || 'en'; };
  var fill = function (s, o) { return String(s).replace(/\{(\w+)\}/g, function (_, k) { return o[k]; }); };
  var clamp = function (v, a, b) { return Math.max(a, Math.min(b, v)); };
  var ease = function (t) { return 1 - Math.pow(1 - t, 3); };
  var NS = 'http://www.w3.org/2000/svg';
  var svgEl = function (tag, attrs, parent) {
    var n = document.createElementNS(NS, tag);
    for (var k in attrs) n.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(n);
    return n;
  };
  var el = function (tag, cls, parent, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    if (parent) parent.appendChild(n);
    return n;
  };
  var fmt = function (n) { return String(Math.round(n)); };
  // A heading never cuts a word: when the longest word (German compounds) is
  // wider than the column, the heading's size steps down to fit it.
  function fit(node) {
    node.style.fontSize = '';
    // Measure each word unbroken: a long German compound must shrink the line, never split.
    var widest = 0;
    node.classList.add('is-measuring');
    $$('.w', node).forEach(function (w) { widest = Math.max(widest, w.offsetWidth); });
    node.classList.remove('is-measuring');
    var room = node.clientWidth;
    if (widest > room && room) node.style.fontSize = (parseFloat(getComputedStyle(node).fontSize) * room / widest * .97).toFixed(1) + 'px';
  }
  // Words into masks; --l is the line each word sits on, for the stagger.
  function split(node) {
    var words = node.textContent.trim().split(/\s+/);
    node.textContent = '';
    words.forEach(function (w, i) {
      var o = el('span', 'w', node), s = el('span', null, o, w);
      if (i < words.length - 1) node.appendChild(document.createTextNode(' '));
      return s;
    });
    fit(node);
    var tops = [];
    $$('.w', node).forEach(function (w) { var t = w.offsetTop; if (tops.indexOf(t) < 0) tops.push(t); w.firstChild.style.setProperty('--l', tops.indexOf(t)); });
  }
  var frame = function (fn) { var on = false; return function () { if (on) return; on = true; requestAnimationFrame(function () { on = false; fn(); }); }; };

  // ---------- smooth scroll ----------
  var lenis = null;
  if (window.Lenis && !reduce.matches && !weak) {
    lenis = new window.Lenis({ lerp: 0.11, wheelMultiplier: 0.9, syncTouch: false });
    (function raf(t) { lenis.raf(t); requestAnimationFrame(raf); })(performance.now());
  }
  document.addEventListener('click', function (e) {
    var a = e.target.closest('a[href^="#"]');
    if (!a) return;
    var id = a.getAttribute('href');
    var target = id === '#top' ? document.body : $(id);
    if (!target) return;
    e.preventDefault();
    if (lenis) lenis.scrollTo(id === '#top' ? 0 : target, { offset: -84, duration: 1.4 });
    else (id === '#top' ? window : target).scrollIntoView ? (id === '#top' ? window.scrollTo({ top: 0, behavior: reduce.matches ? 'auto' : 'smooth' }) : target.scrollIntoView({ behavior: reduce.matches ? 'auto' : 'smooth' })) : 0;
    if (target.id) history.replaceState(null, '', id);
  });

  // ---------- the bar steps aside while you read, and comes back ----------
  var bar = $('#bar'), lastY = scrollY, darks = $$('.how, .foot');
  var tone = function () { bar.classList.toggle('on-night', darks.some(function (d) { var r = d.getBoundingClientRect(); return r.top < 44 && r.bottom > 44; })); };
  addEventListener('scroll', frame(tone), { passive: true });
  addEventListener('scroll', frame(function () {
    var y = scrollY, down = y > lastY;
    bar.classList.toggle('is-hidden', down && y > 700 && !bar.contains(document.activeElement));
    lastY = y;
  }), { passive: true });

  // ---------- the map ----------
  var map = $('#map'), plate = $('#plate'), img = $('#plate-img'), source = $('#plate picture source'), topo = $('#topo'), spots = $('#spots');
  var current = 'lunch', drawnKcal = null, hot = -1, hotLock = -1, box = null;
  // The camera over the map: plate offset and zoom (origin: the plate's corner).
  var cam = { z: 1, x: 0, y: 0 }, camAnim = 0, camAim = -1;
  var pos = function (p) { return { x: box.left + cam.x + cam.z * p.x * box.iw, y: box.top + cam.y + cam.z * p.y * box.ih }; };
  function meal() { return MEALS[current]; }
  function data() { return meal()[lang()] || meal().en; }
  var SIZES = [960, 1600, 2400];
  var srcset = function (m, ext) { return SIZES.map(function (w) { return 'assets/lp/img/' + m + '-' + w + '.' + ext + ' ' + w + 'w'; }).join(', '); };

  // Where the photo sits: like object-fit: cover with an object-position,
  // zoomed in on the plate where the photo has a lot of table.
  function place() {
    var r = map.getBoundingClientRect(), m = meal();
    // A tablet's map is wide and short: closer in, so the plate fills it.
    var f = narrow.matches ? [m.mobile[0], m.mobile[1], m.mobile[2] * (r.width > 560 ? 1.2 : 1)] : [m.focus[0], m.focus[1], m.zoom];
    var s = Math.max(r.width / m.w, r.height / m.h) * f[2];
    var iw = m.w * s, ih = m.h * s;
    box = { w: r.width, h: r.height, iw: iw, ih: ih, left: (r.width - iw) * f[0], top: (r.height - ih) * f[1] };
    plate.style.cssText = 'left:' + box.left + 'px;top:' + box.top + 'px;width:' + iw + 'px;height:' + ih + 'px;right:auto;bottom:auto';
    plate.classList.add('is-placed');
    cancelAnimationFrame(camAnim); cam = { z: 1, x: 0, y: 0 }; camAim = -1;
    layoutSpots();
  }

  function applyCam() {
    plate.style.transform = cam.z === 1 && !cam.x && !cam.y ? '' : 'translate3d(' + cam.x.toFixed(2) + 'px,' + cam.y.toFixed(2) + 'px,0) scale(' + cam.z.toFixed(4) + ')';
    var d = data();
    $$('.spot', spots).forEach(function (li) { var q = pos(d.parts[li.dataset.p]); li.style.left = q.x + 'px'; li.style.top = q.y + 'px'; });
  }
  function camTarget(i) {
    var p = i < 0 ? null : data().parts[i];
    if (!p || p.x == null || !box) return { z: 1, x: 0, y: 0 };
    // On the phone the legend covers the lower third: aim above it.
    var z = narrow.matches ? 1.35 : 1.6, n = narrow.matches;
    var x = box.w * (n ? .5 : .56) - box.left - z * p.x * box.iw, y = box.h * (n ? .34 : .4) - box.top - z * p.y * box.ih;
    // The phone may pull a low summit up past the plate's edge, into the ground colour.
    var slack = box.h * (n ? .4 : .25);
    return { z: z, x: clamp(x, box.w - box.left - z * box.iw, -box.left), y: clamp(y, box.h - box.top - z * box.ih - slack, -box.top) };
  }
  // Fly to a part, as a map flies to a summit; -1 flies home.
  function fly(i) {
    if (!box || i === camAim) return;
    camAim = i;
    var to = camTarget(i), from = { z: cam.z, x: cam.x, y: cam.y }, t0 = performance.now(), dur = reduce.matches ? 0 : 1250;
    cancelAnimationFrame(camAnim);
    spots.classList.add('is-flying');
    (function step(now) {
      var t = dur ? clamp((now - t0) / dur, 0, 1) : 1, e = t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
      cam = { z: from.z + (to.z - from.z) * e, x: from.x + (to.x - from.x) * e, y: from.y + (to.y - from.y) * e };
      applyCam();
      if (t < 1) camAnim = requestAnimationFrame(step);
      else { spots.classList.remove('is-flying'); layoutSpots(); }
    })(t0);
  }

  var drawT;
  function drawTopo(animate) {
    var d = data(), mp = d.map, m = meal();
    topo.setAttribute('viewBox', '0 0 1000 ' + m.vh);
    topo.textContent = '';
    mp.paths.forEach(function (p) {
      // Every fourth ring is an index contour, drawn heavier, as on a survey map.
      svgEl('path', { class: p[0] % 4 === 3 ? 'ring ix' : 'ring', d: p[2], pathLength: '1', 'data-p': p[1], 'data-l': p[0], style: '--i:' + (mp.levels - 1 - p[0]) }, topo);
    });
    ringOrder = $$('.ring', topo).sort(function (a, b) { return b.dataset.l - a.dataset.l; });
    // The trail: red-white-red, from the lowest summit to the highest, over the
    // summits you can see (not the ones under the legend or off the map).
    var leg = $('#legend').getBoundingClientRect(), mr = map.getBoundingClientRect();
    var seen = function (p) { if (!box) return true; var q = pos(p); return q.x > 12 && q.x < box.w - 12 && q.y > 12 && q.y < box.h - 12 && !(q.x > leg.left - mr.left - 16 && q.x < leg.right - mr.left + 16 && q.y > leg.top - mr.top - 16 && q.y < leg.bottom - mr.top + 16); };
    var pts = d.parts.filter(function (p) { return p.x != null && seen(p); }).sort(function (a, b) { return a.k - b.k; }).map(function (p) { return [p.x * 1000, p.y * m.vh]; });
    // Uncross it (2-opt with both ends fixed): a trail never runs over itself.
    var cross = function (a, b, c, d) { var o = function (p, q, r) { return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0]); }; return o(a, b, c) * o(a, b, d) < 0 && o(c, d, a) * o(c, d, b) < 0; };
    for (var pass = 0, again = true; again && pass < 20; pass++) {
      again = false;
      for (var a = 0; a < pts.length - 3; a++) for (var c = a + 2; c < pts.length - 1; c++) {
        if (cross(pts[a], pts[a + 1], pts[c], pts[c + 1])) { pts = pts.slice(0, a + 1).concat(pts.slice(a + 1, c + 1).reverse(), pts.slice(c + 1)); again = true; }
      }
    }
    if (pts.length > 1) {
      var td = 'M' + pts[0][0].toFixed(1) + ' ' + pts[0][1].toFixed(1);
      for (var i = 0; i < pts.length - 1; i++) {
        var p0 = pts[i - 1] || pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] || p2;
        td += 'C' + [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6, p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1]].map(function (v) { return v.toFixed(1); }).join(' ');
      }
      var mask = svgEl('mask', { id: 'trail-m', maskUnits: 'userSpaceOnUse', x: -100, y: -100, width: 1200, height: m.vh + 200 }, topo);
      svgEl('path', { class: 'tr-mask', d: td, pathLength: '1' }, mask);
      var tg = svgEl('g', { class: 'trail', mask: 'url(#trail-m)' }, topo);
      svgEl('path', { class: 'tr-base', d: td }, tg);
      svgEl('path', { class: 'tr-dash', d: td }, tg);
    }
    topo.classList.toggle('is-drawing', !!animate);
    spots.classList.toggle('is-drawing', !!animate);
    // Once drawn, drop the entrance: a spot that comes back later must not wait for it again.
    clearTimeout(drawT);
    if (animate) drawT = setTimeout(function () { topo.classList.remove('is-drawing'); spots.classList.remove('is-drawing'); }, 6000);
  }

  function buildSpots() {
    spots.textContent = '';
    data().parts.forEach(function (p, i) {
      if (p.x == null) return;
      var li = el('li', 'spot', spots);
      li.dataset.p = i;
      li.style.setProperty('--i', i);
      el('i', 'spot-tri', li);
      // A spot height: the part's kcal as the summit's height, its name under it.
      var lab = el('span', 'spot-lab', li);
      var h = el('span', 'spot-h', lab, p.k);
      el('small', null, h, ' kcal');
      el('span', 'spot-n', lab, p.n);
      li.addEventListener('pointerenter', function () { setHot(i); });
      li.addEventListener('pointerleave', function () { setHot(-1); });
      li.addEventListener('click', function () { hotLock = hotLock === i ? -1 : i; setHot(hotLock); });
    });
  }

  // Labels go right of their summit, or left when there is no room; one that
  // would cover another label or the legend shows only its summit.
  function layoutSpots() {
    if (!box) return;
    var d = data(), placed = [];
    var leg = $('#legend').getBoundingClientRect(), mr = map.getBoundingClientRect();
    var legBox = { l: leg.left - mr.left - 8, t: leg.top - mr.top - 8, r: leg.right - mr.left + 8, b: leg.bottom - mr.top + 8 };
    var barBox = { l: 0, t: 0, r: box.w, b: narrow.matches ? 70 : 84 };
    var hit = function (a, b) { return a.l < b.r && a.r > b.l && a.t < b.b && a.b > b.t; };
    $$('.spot', spots).sort(function (a, b) { return (+b.dataset.p === hot) - (+a.dataset.p === hot); }).forEach(function (li) {
      var p = d.parts[li.dataset.p], q = pos(p), x = q.x, y = q.y, isHot = +li.dataset.p === hot;
      li.style.left = x + 'px'; li.style.top = y + 'px';
      li.classList.remove('is-left'); li.hidden = false; li.querySelector('.spot-lab').hidden = false;
      var w = li.querySelector('.spot-lab').offsetWidth + 22, h = 40;
      var right = { l: x - 7, t: y - 20, r: x - 7 + w, b: y - 20 + h }, left = { l: x + 7 - w, t: y - 20, r: x + 7, b: y - 20 + h };
      var ok = function (q) { return q.l > 6 && q.r < box.w - 6 && q.t > 6 && q.b < box.h - 6 && !hit(q, legBox) && !hit(q, barBox) && !placed.some(function (o) { return hit(q, o); }); };
      var tri = { l: x - 8, t: y - 8, r: x + 8, b: y + 8 };
      if (x < 0 || x > box.w || y < 0 || y > box.h || hit(tri, legBox) || hit(tri, barBox)) { li.hidden = true; return; }
      if (ok(right)) placed.push(right);
      else if (ok(left)) { li.classList.add('is-left'); placed.push(left); }
      else if (isHot) placed.push(right);
      else li.querySelector('.spot-lab').hidden = true;
    });
  }

  function setHot(i) {
    if (i === -1 && hotLock !== -1) i = hotLock;
    hot = i;
    topo.classList.toggle('is-focus', i !== -1);
    $$('.ring', topo).forEach(function (p) { p.classList.toggle('is-hot', +p.dataset.p === i); });
    $$('.spot', spots).forEach(function (s) { s.classList.toggle('is-hot', +s.dataset.p === i); });
    $$('.row').forEach(function (r) { r.classList.toggle('is-hot', +r.dataset.p === i); });
  }

  // The reticle reads the terrain under the pointer: the innermost ring wins.
  var ret = $('#reticle'), rt = $('#rt'), retPart = -2, ringOrder = [];
  function partAt(cx, cy) {
    var r = topo.getBoundingClientRect(), vb = topo.viewBox.baseVal, pt = topo.createSVGPoint();
    pt.x = (cx - r.left) / r.width * vb.width; pt.y = (cy - r.top) / r.height * vb.height;
    for (var k = 0; k < ringOrder.length; k++) if (ringOrder[k].isPointInFill(pt)) return +ringOrder[k].dataset.p;
    return -1;
  }
  if (matchMedia('(hover: hover) and (pointer: fine)').matches) {
    var readAt = frame(function () {
      var e = readAt.e, r = map.getBoundingClientRect(), x = e.clientX - r.left, y = e.clientY - r.top;
      ret.firstChild.style.transform = 'translateY(' + y + 'px)';
      ret.children[1].style.transform = 'translateX(' + x + 'px)';
      ret.children[2].style.transform = ret.children[3].style.transform = 'translate(' + x + 'px,' + y + 'px)';
      ret.classList.toggle('is-flip', x > r.width - 220);
      var i = partAt(e.clientX, e.clientY);
      if (i === retPart) return;
      retPart = i;
      ret.classList.toggle('is-on', i !== -1);
      if (i !== -1) { var p = data().parts[i]; rt.textContent = p.n; el('small', null, rt, p.g + ' g · ' + p.k + ' kcal'); }
      if (hotLock === -1) setHot(i);
    });
    map.addEventListener('pointermove', function (e) { if (e.pointerType !== 'mouse') return; readAt.e = e; map.classList.add('is-reading'); readAt(); });
    map.addEventListener('pointerleave', function () { map.classList.remove('is-reading'); ret.classList.remove('is-on'); retPart = -2; if (hotLock === -1) setHot(-1); });
  }

  function readout(animate) {
    var d = data(), from = drawnKcal == null ? d.kcal : drawnKcal, to = d.kcal, k = $('#r-kcal');
    $('#r-name').textContent = d.name;
    $('#r-range').textContent = fill(T('read.range'), { sure: d.sure, lo: d.lo, hi: d.hi });
    drawnKcal = to;
    if (!animate || reduce.matches || from === to) { k.textContent = to; return; }
    var t0 = performance.now();
    (function step(now) {
      var t = clamp((now - t0) / 900, 0, 1);
      k.textContent = fmt(from + (to - from) * ease(t));
      if (t < 1) requestAnimationFrame(step);
    })(t0);
  }

  function setPhoto(m) {
    source.srcset = srcset(m, 'avif');
    img.srcset = srcset(m, 'webp');
    img.src = 'assets/lp/img/' + m + '-1600.webp';
    img.alt = T('meal.' + m + '.alt');
    img.width = MEALS[m].w; img.height = MEALS[m].h;
  }

  var switching = false;
  function choose(m) {
    if (m === current || switching) return;
    switching = true;
    $$('.meal').forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.meal === m)); });
    plate.classList.add('is-leaving'); map.classList.add('is-switching'); $('#legend').classList.add('is-switching');
    hotLock = -1; setHot(-1);
    setTimeout(function () {
      current = m;
      map.style.setProperty('--ground', MEALS[m].ground);
      setPhoto(m);
      var done = function () {
        buildSpots(); place(); drawTopo(true); rows(); scale(); readout(true);
        requestAnimationFrame(function () { plate.classList.remove('is-leaving'); map.classList.remove('is-switching'); $('#legend').classList.remove('is-switching'); switching = false; });
      };
      (img.decode ? img.decode() : Promise.resolve()).then(done, done);
    }, reduce.matches ? 0 : 320);
  }
  $$('.meal').forEach(function (b) { b.addEventListener('click', function () { choose(b.dataset.meal); }); });

  // ---------- every part ----------
  function rows() {
    var d = data(), m = meal(), list = $('#rows'), total = d.parts.reduce(function (a, p) { return a + p.k; }, 0);
    list.textContent = '';
    d.parts.forEach(function (p, i) {
      var li = el('li', 'row', list);
      li.dataset.p = i;
      var chip = el('span', 'row-chip', li);
      if (p.x != null) {
        // A close-up of the part, cut from the photo itself.
        var bw = 44 / 0.11, bh = bw * m.h / m.w;
        chip.style.backgroundImage = 'url(assets/lp/img/' + current + '-960.webp)';
        chip.style.backgroundSize = bw + 'px ' + bh + 'px';
        chip.style.backgroundPosition = (22 - p.x * bw) + 'px ' + (22 - p.y * bh) + 'px';
      } else chip.classList.add('is-hidden');
      var n = el('span', 'row-n', li, p.n);
      if (p.x == null) el('small', null, n, T('parts.unseen'));
      el('span', 'row-g', li, p.g + ' g');
      var k = el('span', 'row-k', li, p.k + ' ');
      el('small', null, k, 'kcal');
      li.title = fill(T('parts.share'), { pct: Math.round(p.k / total * 100) });
      li.addEventListener('pointerenter', function () { if (hover.matches) setHot(i); });
      li.addEventListener('pointerleave', function () { if (hover.matches) setHot(-1); });
      li.addEventListener('click', function () { hotLock = hotLock === i ? -1 : i; setHot(hotLock); fly(hotLock === -1 ? i : hotLock); });
    });
    $('#rows-kcal').textContent = d.kcal;
    var hid = d.parts.filter(function (p) { return p.x == null; });
    $('#rows-hid').textContent = (total !== d.kcal ? fill(T('parts.median'), { sum: total, kcal: d.kcal }) + ' ' : '') + (hid.length ? fill(T('parts.hidden'), { names: hid.map(function (p) { return p.n; }).join(', ') }) : '');
  }

  // While the list scrolls past, the map follows it.
  addEventListener('scroll', frame(function () {
    // On the phone the plate lets go once the list is done: the estimates push it up.
    if (narrow.matches) { var rm = $('.read-map'), e = $('#rows-hid').getBoundingClientRect().bottom; rm.style.transform = 'translateY(' + Math.min(0, e - rm.offsetHeight - 16) + 'px)'; }
    else $('.read-map').style.transform = '';
    if (hotLock !== -1) return;
    // On the phone the plate stays on top; the list is read in the space below it.
    var top = narrow.matches ? $('.read-map').getBoundingClientRect().bottom : 0, view = innerHeight - top;
    var rows0 = $('#rows').getBoundingClientRect();
    if (rows0.top > top + view * .62 || rows0.bottom < top + view * .3) { if (hot !== -1 && !$('.row:hover') && !$('.spot:hover')) setHot(-1); fly(-1); return; }
    var mid = top + view * .5, best = -1, bd = 1e9;
    $$('.row').forEach(function (row) { var q = row.getBoundingClientRect(), dd = Math.abs(q.top + q.height / 2 - mid); if (dd < bd) { bd = dd; best = +row.dataset.p; } });
    if (bd < 90 && best !== hot) { setHot(best); fly(best); }
  }), { passive: true });

  // The three estimates on the range the plate could be in.
  function scale() {
    var d = data(), s = $('#scale');
    s.textContent = '';
    var lo = d.lo, hi = d.hi, pad = (hi - lo) * .08, a = lo - pad, b = hi + pad, x = function (v) { return ((v - a) / (b - a) * 100) + '%'; };
    el('i', 'sc-line', s);
    var rg = el('i', 'sc-range', s); rg.style.left = x(lo); rg.style.width = ((hi - lo) / (b - a) * 100) + '%';
    var e1 = el('span', 'sc-end', s, lo); e1.style.left = x(lo);
    var e2 = el('span', 'sc-end', s, hi); e2.style.left = x(hi);
    var est = d.est.slice().sort(function (p, q) { return p - q; });
    var midI = est.indexOf(d.kcal);
    if (midI < 0) midI = Math.floor(est.length / 2);
    est.forEach(function (v, i) {
      var t = el('i', 'sc-tick' + (i === midI ? ' is-mid' : ''), s);
      t.style.left = x(v); t.style.setProperty('--i', i);
    });
    var kept = el('span', 'sc-kept', s, d.kcal + ' kcal'); kept.style.left = x(d.kcal);
    var list = $('#sc-list');
    if (!list) { list = el('p', 'sc-list', $('#est')); list.id = 'sc-list'; }
    list.innerHTML = fill(T('est.list'), { list: est.map(function (v, i) { return i === midI ? '<b>' + v + '</b>' : v; }).join(' · ') });
    s.setAttribute('aria-label', fill(T('est.alt'), { list: est.join(', '), kcal: d.kcal, lo: lo, hi: hi }));
    var note = $('#est-note');
    if (!note) { note = el('p', 'rows-hid', $('#est')); note.id = 'est-note'; }
    note.textContent = est.length < 3 ? fill(T('est.partial'), { n: est.length }) : '';
  }

  // ---------- the day ----------
  var DAY = { goal: 2482, from: 6, to: 22, ascent: 0.4,
    week: [2264, 2160, 2237, 1184, 1356, 2532, 1866], weekStart: '2026-10-14',
    weights: [['2026-08-26', 81.5], ['2026-08-29', 81.4], ['2026-09-01', 81.3], ['2026-09-03', 81.0], ['2026-09-05', 81.1], ['2026-09-07', 80.8], ['2026-09-10', 80.5], ['2026-09-13', 80.5], ['2026-09-15', 80.3], ['2026-09-17', 80.1], ['2026-09-19', 80.2], ['2026-09-22', 79.8], ['2026-09-24', 79.9], ['2026-09-27', 79.7], ['2026-09-30', 79.6], ['2026-10-02', 79.5], ['2026-10-05', 79.3], ['2026-10-07', 79.4], ['2026-10-09', 78.9], ['2026-10-12', 79.0], ['2026-10-15', 79.0], ['2026-10-17', 78.8], ['2026-10-20', 78.6]] };
  var hours = function (t) { var p = t.split(':'); return +p[0] + p[1] / 60; };
  var clock = function (h) { var m = Math.round(h * 60); return String(Math.floor(m / 60)).padStart(2, '0') + ':' + String(m % 60).padStart(2, '0'); };
  function dayMeals() { return ['breakfast', 'lunch', 'dinner'].map(function (k) { var d = MEALS[k][lang()] || MEALS[k].en; return { key: k, t: hours(MEALS[k].t), kcal: d.kcal }; }); }
  function eaten(h) { return dayMeals().reduce(function (a, m) { return a + m.kcal * ease(clamp((h - m.t) / DAY.ascent, 0, 1)); }, 0); }

  var climbSvg = $('#climb-svg'), cl = null;
  function drawClimb() {
    var W = climbSvg.clientWidth, H = climbSvg.clientHeight;
    if (!W || !H) return;
    climbSvg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
    climbSvg.textContent = '';
    var top = 64, bottom = H - 30, max = DAY.goal * 1.08;
    var X = function (h) { return (h - DAY.from) / (DAY.to - DAY.from) * W; }, Y = function (k) { return bottom - k / max * (bottom - top); };
    var grid = svgEl('g', { class: 'cl-grid' }, climbSvg);
    [6, 9, 12, 15, 18, 21].forEach(function (h) {
      var t = svgEl('text', { x: X(h) + (h === 6 ? 0 : -18), y: H - 6 }, grid); t.textContent = clock(h);
    });
    // The goal is the summit: a trail marker on a pole, its height as a spot height.
    var px = W * (W < 600 ? .9 : .94), gy = Y(DAY.goal);
    var cross = svgEl('g', { class: 'cl-cross' }, W < 600 ? null : climbSvg);
    svgEl('line', { x1: px, x2: px, y1: gy, y2: gy - 40 }, cross);
    svgEl('rect', { class: 'fl-r', x: px, y: gy - 40, width: 28, height: 18 }, cross);
    svgEl('rect', { class: 'fl-w', x: px, y: gy - 34, width: 28, height: 6 }, cross);
    svgEl('line', { x1: 0, x2: W, y1: bottom, y2: bottom }, grid);
    var pts = [];
    for (var i = 0; i <= 320; i++) { var h = DAY.from + (DAY.to - DAY.from) * i / 320; pts.push([X(h), Y(eaten(h))]); }
    var line = 'M' + pts.map(function (p) { return p[0].toFixed(1) + ' ' + p[1].toFixed(1); }).join('L');
    // The mountain is the day itself: its face is everything eaten, drawn in
    // contour lines; the trail walks its ridge, up to the summit at the goal.
    var face = line + 'L' + W + ' ' + bottom + 'L0 ' + bottom + 'Z';
    var mclip = svgEl('clipPath', { id: 'cl-mtn' }, climbSvg);
    svgEl('path', { d: face }, mclip);
    var mtn = svgEl('g', { class: 'cl-mtn', 'clip-path': 'url(#cl-mtn)' }, climbSvg);
    for (var cy = bottom - 9; cy > gy - 2; cy -= 9) svgEl('line', { x1: 0, x2: W, y1: cy, y2: cy }, mtn);
    svgEl('path', { class: 'cl-ghost', d: line }, climbSvg);
    var clip = svgEl('clipPath', { id: 'cl-clip' }, climbSvg), cr = svgEl('rect', { x: 0, y: 0, width: 0, height: H }, clip);
    var g = svgEl('g', { 'clip-path': 'url(#cl-clip)' }, climbSvg);
    svgEl('path', { class: 'cl-walked', d: face }, g);
    svgEl('path', { class: 'cl-line', d: line }, g);
    var goal = svgEl('g', { class: 'cl-goal' }, climbSvg);
    svgEl('line', { x1: 0, x2: px - 14, y1: gy, y2: gy }, goal);
    var gt = W < 600 ? svgEl('text', { x: 0, y: gy - 10 }, goal) : svgEl('text', { x: px - 16, y: gy - 12, 'text-anchor': 'end' }, goal); gt.textContent = '▲ ' + fill(T('day.goal'), { goal: DAY.goal });
    var wps = dayMeals().map(function (m) {
      var hx = m.t + DAY.ascent, x = X(hx), y = Y(eaten(hx)), wp = svgEl('g', { class: 'wp is-off' }, climbSvg), right = x < W - 220;
      svgEl('line', { class: 'pole', x1: x, x2: x, y1: y, y2: y - 46 }, wp);
      svgEl('rect', { class: 'fl-r', x: x, y: y - 46, width: 24, height: 15 }, wp);
      svgEl('rect', { class: 'fl-w', x: x, y: y - 41, width: 24, height: 5 }, wp);
      if (W < 600) {
        // Narrow: the kcal beside the flag, away from the goal line.
        var nr = x < W - 70, tn = svgEl('text', { class: 't2', x: nr ? x + 30 : x - 6, y: y - 34, 'text-anchor': nr ? 'start' : 'end' }, wp); tn.textContent = '+' + m.kcal;
        return { g: wp, at: hx };
      }
      var ix = right ? x + 34 : x - 34 - 36;
      svgEl('image', { href: 'assets/lp/img/' + m.key + '-thumb.webp', x: ix, y: y - 50, width: 36, height: 36 }, wp);
      var tx = right ? ix + 44 : ix - 8, anchor = right ? 'start' : 'end';
      var t1 = svgEl('text', { x: tx, y: y - 36, 'text-anchor': anchor }, wp); t1.textContent = T('meal.' + m.key) + ' · ' + clock(m.t);
      var t2 = svgEl('text', { class: 't2', x: tx, y: y - 19, 'text-anchor': anchor }, wp); t2.textContent = '+' + m.kcal + ' kcal';
      return { g: wp, at: hx };
    });
    if (cross.parentNode) climbSvg.appendChild(cross);
    // What is left, measured between the walker and the goal.
    var gap = svgEl('g', { class: 'cl-gap' }, climbSvg), gl = svgEl('line', {}, gap), gtx = svgEl('text', {}, gap);
    var now = svgEl('g', { class: 'cl-now' }, climbSvg);
    var nl = svgEl('line', { y1: bottom, y2: bottom }, now), nc = svgEl('circle', { r: 7 }, now), nt = svgEl('text', { 'text-anchor': 'middle' }, now);
    cl = { X: X, Y: Y, W: W, gy: gy, cr: cr, nl: nl, nc: nc, nt: nt, gl: gl, gtx: gtx, wps: wps };
    var total = dayMeals().reduce(function (a, m) { return a + m.kcal; }, 0);
    climbSvg.setAttribute('aria-label', fill(T('day.alt'), { a: MEALS.breakfast.t, b: MEALS.lunch.t, c: MEALS.dinner.t, left: DAY.goal - total, goal: DAY.goal }));
    scrubDay();
  }

  var daySec = $('#day-track');
  function scrubDay() {
    if (!cl) return;
    var r = daySec.getBoundingClientRect(), p;
    if (narrow.matches) { var c = $('#climb').getBoundingClientRect(); p = clamp((innerHeight * .95 - c.top) / (innerHeight * .75), 0, 1); }
    else p = clamp(-r.top / (r.height - innerHeight), 0, 1);
    if (reduce.matches) p = 1;
    var h = DAY.from + .3 + (21.5 - DAY.from - .3) * p, x = cl.X(h), y = cl.Y(eaten(h));
    cl.cr.setAttribute('width', x);
    cl.nl.setAttribute('x1', x); cl.nl.setAttribute('x2', x); cl.nl.setAttribute('y1', y + 10);
    cl.nc.setAttribute('cx', x); cl.nc.setAttribute('cy', y);
    // The time sits just under the walker, on the side the trail is still empty,
    // so it never meets the waypoint labels above the steps.
    var late = x > cl.W - 64;
    cl.nt.setAttribute('x', late ? x - 10 : x + 10); cl.nt.setAttribute('y', y + 24);
    cl.nt.setAttribute('text-anchor', late ? 'end' : 'start'); cl.nt.textContent = clock(h);
    cl.wps.forEach(function (w) { w.g.classList.toggle('is-off', h < w.at - .05); });
    var left = DAY.goal - eaten(h), gx = x + (late ? -24 : 24);
    cl.gl.setAttribute('x1', gx); cl.gl.setAttribute('x2', gx); cl.gl.setAttribute('y1', y - 8); cl.gl.setAttribute('y2', cl.gy + 6);
    cl.gtx.setAttribute('x', late ? gx - 8 : gx + 8); cl.gtx.setAttribute('y', (y + cl.gy) / 2 + 5); cl.gtx.setAttribute('text-anchor', late ? 'end' : 'start');
    cl.gtx.textContent = fill(T('day.gap'), { left: fmt(left) });
    // Late in the day the big number says it; the label would only meet the dinner flag.
    cl.gl.parentNode.classList.toggle('is-tight', y - cl.gy < 40);
    cl.gtx.style.display = late || x > cl.W - 200 ? 'none' : '';
    // Never across a flag or its label.
    if (!cl.gtx.style.display) {
      var b = cl.gtx.getBBox();
      if (cl.wps.some(function (w) { var o = w.g.getBBox(); return b.x < o.x + o.width + 6 && o.x < b.x + b.width + 6 && b.y < o.y + o.height && o.y < b.y + b.height; })) cl.gtx.style.display = 'none';
    }
    $('#d-left').textContent = fmt(left);
    $('#d-of').textContent = fill(T('day.of'), { goal: DAY.goal, now: clock(h) });
  }
  addEventListener('scroll', frame(scrubDay), { passive: true });

  function drawTrend() {
    // The week as a range: one peak a day, its height the day's kcal.
    var bars = $('#bars'); bars.textContent = '';
    var BW = bars.clientWidth || 500, BH = 172, base = BH - 26, max = Math.max.apply(null, DAY.week.concat([DAY.goal])) * 1.06;
    var Yk = function (k) { return base - k / max * (base - 24); }, slot = BW / 7;
    var rs = svgEl('svg', { viewBox: '0 0 ' + BW + ' ' + BH, class: 'range' }, bars);
    svgEl('rect', { x: 0, y: 0, width: BW, height: Yk(DAY.goal) }, svgEl('clipPath', { id: 'pk-cut' }, rs));
    var start = new Date(DAY.weekStart + 'T12:00:00'), wd = new Intl.DateTimeFormat(lang(), { weekday: 'short' });
    svgEl('line', { class: 'range-goal', x1: 0, x2: BW, y1: Yk(DAY.goal), y2: Yk(DAY.goal) }, rs);
    DAY.week.forEach(function (k, i) {
      var d = new Date(start); d.setDate(d.getDate() + i);
      // Seven summits side by side; what rises above the goal is drawn in ink.
      var half = slot * .46, cx = slot / 2 + i * slot, top = Yk(k), g = svgEl('g', { class: 'peak', style: '--i:' + i }, rs);
      var tri = 'M' + (cx - half).toFixed(1) + ' ' + base + 'L' + cx.toFixed(1) + ' ' + top.toFixed(1) + 'L' + (cx + half).toFixed(1) + ' ' + base + 'Z';
      svgEl('path', { class: 'pk', d: tri }, g);
      if (k > DAY.goal) svgEl('path', { class: 'pk-over', d: tri, 'clip-path': 'url(#pk-cut)' }, g);
      var t = svgEl('text', { x: cx, y: BH - 4, 'text-anchor': 'middle' }, rs); t.textContent = wd.format(d).replace('.', '');
      // Each summit carries its spot height; a day over the goal says by how much.
      var gyl = Yk(DAY.goal), ly = top - 7 > gyl - 4 && top - 7 < gyl + 14 ? gyl - 6 : top - 7;
      var sh = svgEl('text', { class: 'pk-h' + (k > DAY.goal ? ' is-over' : ''), x: cx, y: ly, 'text-anchor': 'middle' }, g);
      sh.textContent = k > DAY.goal ? '+' + (k - DAY.goal) : k;
      var tt = svgEl('title', {}, g); tt.textContent = fill(T('trend.bar'), { day: wd.format(d), kcal: k });
    });
    svgEl('line', { class: 'range-base', x1: 0, x2: BW, y1: base, y2: base }, rs);
    var avg = Math.round(DAY.week.reduce(function (a, b) { return a + b; }, 0) / DAY.week.length);
    $('#t-avg').textContent = avg;
    // Weight: the dots are the days you stepped on the scale, the line the trend.
    var svg = $('#wline'), W = svg.clientWidth || 500, H = 132; svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H); svg.textContent = '';
    var w = DAY.weights, t0 = Date.parse(w[0][0]), t1 = Date.parse(w[w.length - 1][0]), lo = 78.2, hi = 81.9;
    var X = function (t) { return (Date.parse(t) - t0) / (t1 - t0) * (W - 8) + 4; }, Y = function (v) { return 8 + (hi - v) / (hi - lo) * (H - 36); };
    w.forEach(function (p) { svgEl('circle', { class: 'wd', cx: X(p[0]), cy: Y(p[1]), r: 3 }, svg); });
    var sm = w.map(function (p, i) { var a = w.slice(Math.max(0, i - 3), i + 4); return [X(p[0]), Y(a.reduce(function (s, q) { return s + q[1]; }, 0) / a.length)]; });
    svgEl('path', { class: 'wl', pathLength: 1, d: 'M' + sm.map(function (p) { return p[0].toFixed(1) + ' ' + p[1].toFixed(1); }).join('L') }, svg);
    var end = sm[sm.length - 1];
    svgEl('circle', { class: 'wend', cx: end[0], cy: end[1], r: 6 }, svg);
    var mf = new Intl.DateTimeFormat(lang(), { month: 'short' });
    ['2026-09-01', '2026-10-01'].forEach(function (d) { var t = svgEl('text', { x: X(d), y: H - 2 }, svg); t.textContent = mf.format(new Date(d + 'T12:00:00')); });
  }

  // ---------- after the shutter ----------
  // One pinned stage: scroll walks the four waypoints; each screen wipes up
  // over the one before and the trail between the blazes fills.
  var steps = $$('.step'), scrs = $$('.scr'), howPin = $('#how-pin'), stepNow = -1;
  function setStep(i) {
    if (i === stepNow) return;
    stepNow = i;
    steps.forEach(function (s) { var k = +s.dataset.step; s.classList.toggle('is-on', k === i); s.classList.toggle('is-past', k < i); });
    scrs.forEach(function (s) { s.classList.toggle('is-shown', +s.dataset.step <= i); });
  }
  var howScroll = frame(function () {
    if (narrow.matches) return;
    var r = howPin.getBoundingClientRect(), p = clamp(-r.top / (r.height - innerHeight), 0, .9999), f = p * 4, i = Math.floor(f);
    setStep(i);
    steps.forEach(function (n, k) { n.style.setProperty('--f', clamp(f - k, 0, 1).toFixed(3)); });
  });
  addEventListener('scroll', howScroll, { passive: true });
  setStep(0);

  // €0 opens its width as it comes in, from narrow to the widest cut.
  var zero = $('#free-zero'), freeSec = $('#free');
  addEventListener('scroll', frame(function () {
    if (reduce.matches) return;
    var r = freeSec.getBoundingClientRect(), p = clamp((innerHeight - r.top) / (innerHeight * .8), 0, 1);
    zero.style.setProperty('--fz', (62 + 63 * ease(p)).toFixed(1) + '%');
  }), { passive: true });

  // The footer: the lunch plate's terrain, quietly, under the wordmark.
  function footTopo() {
    var svg = $('#foot-topo'), m = MEALS.lunch, mp = m.en.map;
    svg.setAttribute('viewBox', '0 0 1000 ' + m.vh);
    svg.textContent = '';
    mp.paths.forEach(function (p) { svgEl('path', { d: p[2] }, svg); });
  }

  // Buttons lean toward the pointer a little.
  if (matchMedia('(hover: hover) and (pointer: fine)').matches && !reduce.matches) {
    $$('.btn, .bar-get').forEach(function (b) {
      b.addEventListener('pointermove', function (e) { var r = b.getBoundingClientRect(); b.style.translate = ((e.clientX - r.left - r.width / 2) * .18).toFixed(1) + 'px ' + ((e.clientY - r.top - r.height / 2) * .28).toFixed(1) + 'px'; });
      b.addEventListener('pointerleave', function () { b.style.translate = ''; });
    });
  }
  function screens() { $$('[data-scr]').forEach(function (n) { n.src = 'assets/lp/screens/' + (lang() === 'de' ? 'de' : 'en') + '/' + n.dataset.scr + '.webp'; }); }

  // ---------- release ----------
  var rel = null;
  function showRel() {
    if (!rel) return;
    var df = new Intl.DateTimeFormat(lang(), { day: 'numeric', month: 'long', year: 'numeric' });
    $$('[data-rel]').forEach(function (n) { n.textContent = fill(T('get.rel'), { v: rel.v, mb: (rel.mb).toLocaleString(lang(), { maximumFractionDigits: 1 }), d: df.format(rel.d) }); n.hidden = false; });
  }
  if (window.fetch) fetch('https://api.github.com/repos/Nikityyy/kalorat/releases/latest').then(function (r) { return r.ok ? r.json() : null; }).then(function (r) {
    if (!r || !r.tag_name) return;
    var apk = (r.assets || []).find(function (a) { return /\.apk$/.test(a.name); });
    rel = { v: r.tag_name, mb: apk ? apk.size / 1048576 : 0, d: new Date(r.published_at) };
    if (!apk) return;
    showRel();
  }).catch(function () {});

  // ---------- reveals: visible without the script; only moved when it runs ----------
  $$('.split').forEach(split);
  var rv = $$('.parts-p, .est, .day-head p, .trend-col, .ways li, .free-list > div, .get-col, .ios li, .foot-row');
  if ('IntersectionObserver' in window && !reduce.matches) {
    rv.forEach(function (n) {
      var r = n.getBoundingClientRect();
      if (r.top < innerHeight) return;
      var sib = n.parentElement ? Array.prototype.indexOf.call(n.parentElement.children, n) : 0;
      n.classList.add('rv'); n.style.setProperty('--d', Math.min(sib, 4) * .06 + 's');
    });
    var ro = new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting || e.boundingClientRect.top < 0) { e.target.classList.add('is-in'); ro.unobserve(e.target); } }); }, { rootMargin: '0px 0px -8% 0px' });
    $$('.rv').forEach(function (n) { ro.observe(n); });
    // At the very bottom the footer may never cross the margin: show what is left.
    addEventListener('scroll', frame(function () {
      if (innerHeight + scrollY >= document.documentElement.scrollHeight - 4) $$('.rv:not(.is-in)').forEach(function (n) { n.classList.add('is-in'); });
    }), { passive: true });
  }
  var io2 = 'IntersectionObserver' in window ? new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('is-in'); io2.unobserve(e.target); } }); }, { threshold: .3 }) : null;
  ['#bars', '#wline', '#scale', '#foot-mark'].forEach(function (s) { if (io2) io2.observe($(s)); else $(s).classList.add('is-in'); });
  var io3 = 'IntersectionObserver' in window ? new IntersectionObserver(function (es) { es.forEach(function (e) { if (e.isIntersecting || e.boundingClientRect.top < 0) { e.target.classList.add('is-in'); io3.unobserve(e.target); } }); }, { rootMargin: '0px 0px -12% 0px' }) : null;
  $$('.split').forEach(function (n) { if (n.closest('.hero')) return; if (io3) io3.observe(n); else n.classList.add('is-in'); });

  // ---------- start, resize, language ----------
  function all(animate) {
    buildSpots(); place(); drawTopo(animate); readout(false); rows(); scale(); drawClimb(); drawTrend(); screens(); showRel(); footTopo();
  }
  var started = false;
  function start() {
    if (started) return; started = true;
    $$('.split').forEach(fit);
    var root = document.documentElement, intro = root.classList.contains('intro') && !reduce.matches;
    if (intro) { map.style.setProperty('--t0', '.85s'); drawnKcal = 0; }
    all(true);
    if (intro) {
      $('#r-kcal').textContent = '0';
      requestAnimationFrame(function () { requestAnimationFrame(function () { root.classList.add('go'); $('.hero h1').classList.add('is-in'); }); });
      setTimeout(function () { readout(true); }, 1100);
      setTimeout(function () { root.classList.remove('intro', 'go'); map.style.removeProperty('--t0'); }, 3400);
    } else $('.hero h1').classList.add('is-in');
    // The other two plates, ready before anyone asks for them.
    setTimeout(function () {
      ['breakfast', 'dinner'].forEach(function (m) { var i = new Image(); i.sizes = img.sizes; i.srcset = srcset(m, 'webp'); });
    }, 2500);
  }
  Promise.all([img.decode ? img.decode().catch(function () {}) : 0, document.fonts ? document.fonts.ready : 0]).then(start, start);
  setTimeout(start, 2500);
  var resized = frame(function () { $$('.split').forEach(fit); if (!started) return; place(); drawTopo(false); drawClimb(); drawTrend(); });
  addEventListener('resize', resized);
  narrow.addEventListener && narrow.addEventListener('change', resized);
  document.addEventListener('kalorat:lang', function () { $$('.split').forEach(split); if (!started) return; hotLock = -1; all(false); img.alt = T('meal.' + current + '.alt'); });
})();
