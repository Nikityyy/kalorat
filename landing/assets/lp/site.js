// Kalorat landing. Every scene reads its numbers from meals.js (Kalorat's own
// results for the three photos and the demo day), its words from strings.js.
(function () {
  'use strict';
  var MEALS = window.KALORAT_MEALS, DAYS = window.KALORAT_DAY, DAY = DAYS.en;
  var reduce = matchMedia('(prefers-reduced-motion: reduce)');
  // Two cores or two gigabytes: the page keeps its content and drops the heavier motion.
  var fine = matchMedia('(hover: hover) and (pointer: fine)').matches;
  var strong = (navigator.hardwareConcurrency || 4) > 2 && !(navigator.deviceMemory && navigator.deviceMemory <= 2);
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var T = function (k) { return window.kaloratT(k); };
  var lang = function () { return window.KALORAT_LANG || 'en'; };
  // Building a formatter is slow on old machines and this runs every frame, so they are kept.
  var fmts = {};
  var fmt = function (n, d) {
    var k = lang() + (d || 0);
    return (fmts[k] || (fmts[k] = new Intl.NumberFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { minimumFractionDigits: d || 0, maximumFractionDigits: d || 0, useGrouping: false }))).format(n);
  };
  var fill = function (s, o) { return s.replace(/\{(\w+)\}/g, function (_, k) { return o[k]; }); };
  var ease = function (t) { return 1 - Math.pow(1 - t, 3); };
  var clamp = function (v, a, b) { return Math.max(a, Math.min(b, v)); };
  var SVG = 'http://www.w3.org/2000/svg';
  var el = function (tag, attrs, parent) {
    var n = document.createElementNS(SVG, tag);
    for (var k in attrs) n.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(n);
    return n;
  };

  /* ---------- Top bar: solid once scrolled, light over the day ---------- */
  var bar = $('#bar');
  var blocks = $$('#main > section, #main > .dusk, .foot');
  function barState() {
    bar.classList.toggle('is-solid', scrollY > 24);
    // The block under the bar's lower edge decides its colours.
    var dark = false;
    for (var i = 0; i < blocks.length; i++) {
      var r = blocks[i].getBoundingClientRect();
      if (r.top <= 70 && r.bottom > 70) { dark = /\b(night|foot|free)\b/.test(blocks[i].className); break; }
    }
    bar.classList.toggle('is-day', !dark);
  }

  /* ---------- The main action follows the device ---------- */
  var ua = navigator.userAgent;
  var ios = /iPhone|iPad|iPod/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (ios) {
    var main = $('#cta-main'), alt = $('#cta-alt');
    main.href = '#get-iphone';
    main.querySelector('span').setAttribute('data-i18n', 'cta.iphone');
    main.querySelector('small').remove();
    alt.href = '#get-android';
    alt.querySelector('span').setAttribute('data-i18n', 'cta.android.alt');
  }

  /* ---------- 1. The plate: Kalorat reads it ---------- */
  var hero = $('.hero'), stage = $('#stage'), photo = $('#hero-photo'), canvas = $('#dots');
  var partsEl = $('#parts'), finder = $('#finder');
  var rName = $('#r-name'), rKcal = $('#r-kcal'), rRange = $('#r-range');
  var ctx = canvas.getContext('2d');
  var plate = 'poke', run = 0, raf = 0, grid = null;

  function meal() { return MEALS[plate]; }
  function data() { return MEALS[plate][lang()] || MEALS[plate].en; }
  // The parts that can be pointed at on the photo (butter and oil cannot).
  function seen() { return data().parts.filter(function (p) { return p.x != null; }); }

  // Where a point of the photo lands on screen, under object-fit: cover.
  // Where the photo sits: it covers the stage; on narrow screens it zooms in
  // on the plate, so the parts are not crowded into a thumbnail.
  // Reading the stage's size forces a layout, and this runs every frame, so
  // the answer is kept until the window or the meal changes.
  var geomC = null, geomM = null;
  function geom() {
    if (geomC && geomM === meal()) return geomC;
    var m = meal(), bw = stage.clientWidth, bh = stage.clientHeight;
    var z = bw < 900 ? m.zoom || 1.5 : 1;
    var s = Math.max(bw / m.w, bh / m.h) * z, dw = m.w * s, dh = m.h * s;
    var ox = z > 1 ? bw / 2 - m.focus[0] * dw : (bw - dw) * m.pos[0] / 100;
    var oy = z > 1 ? bh * 0.48 - m.focus[1] * dh : (bh - dh) * m.pos[1] / 100;
    geomM = bw && bh ? m : null;
    return (geomC = { s: s, dw: dw, dh: dh, ox: clamp(ox, bw - dw, 0), oy: clamp(oy, bh - dh, 0) });
  }
  function layoutPhoto() {
    var g = geom();
    photo.style.width = g.dw + 'px'; photo.style.height = g.dh + 'px';
    photo.style.left = g.ox + 'px'; photo.style.top = g.oy + 'px';
  }
  function project(nx, ny) {
    var g = geom();
    return { x: g.ox + nx * g.dw, y: g.oy + ny * g.dh, s: g.s };
  }

  function overlap(a, b, m) { return a.left < b.right + m && a.right > b.left - m && a.top < b.bottom + m && a.bottom > b.top - m; }

  function placeParts() {
    layoutPhoto();
    var sr = stage.getBoundingClientRect();
    var avoid = [$('.hero-copy'), $('.readout'), $('.plates'), bar].map(function (n) { return n.getBoundingClientRect(); });
    var f = project(meal().focus[0], meal().focus[1]);
    finder.style.setProperty('--fx', f.x + 'px');
    finder.style.setProperty('--fy', f.y + 'px');
    finder.style.setProperty('--fw', meal().span * meal().w * f.s + 'px');
    // Each label goes to the right of its dot, or to the left if that side is
    // taken; a label that fits on neither side stays hidden.
    var shown = [], W = stage.clientWidth, H = stage.clientHeight;
    // The parts with the most calories get their place first.
    $$('.part', partsEl).sort(function (a, b) { return b.dataset.k - a.dataset.k; }).forEach(function (li) {
      var p = project(+li.dataset.x, +li.dataset.y);
      li.style.setProperty('--x', p.x + 'px');
      li.style.setProperty('--y', p.y + 'px');
      li.hidden = false;
      var w = li.offsetWidth, h = li.offsetHeight;
      var sides = p.x > W * 0.62 ? [true, false] : [false, true];
      var pick = sides.find(function (left) {
        var r = { left: left ? p.x - w : p.x, top: p.y - h / 2 };
        r.right = r.left + w; r.bottom = r.top + h;
        if (r.left < 8 || r.right > W - 8 || r.top < 76 || r.bottom > H - 12) return false;
        var abs = { left: sr.left + r.left, right: sr.left + r.right, top: sr.top + r.top, bottom: sr.top + r.bottom };
        if (avoid.some(function (q) { return overlap(abs, q, 12); })) return false;
        if (shown.some(function (q) { return overlap(r, q, 6); })) return false;
        shown.push(r);
        return true;
      });
      if (pick === undefined) li.hidden = true;
      else li.classList.toggle('is-left', pick);
    });
  }

  function buildParts() {
    partsEl.textContent = '';
    seen().forEach(function (p) {
      var li = document.createElement('li');
      li.className = 'part';
      li.dataset.x = p.x; li.dataset.y = p.y; li.dataset.k = p.k; li.dataset.n = p.n;
      var span = document.createElement('span');
      span.textContent = p.n;
      var b = document.createElement('b');
      b.className = 'num';
      b.textContent = fmt(p.g) + ' g';
      span.appendChild(b);
      li.appendChild(span);
      partsEl.appendChild(li);
    });
    placeParts();
  }

  function readout(kcal, done) {
    var d = data();
    rName.textContent = d.name;
    rKcal.textContent = fmt(kcal);
    rRange.textContent = fill(T('readout.range'), { sure: d.sure, lo: fmt(d.lo), hi: fmt(d.hi) });
    if (done) hero.classList.add('is-read');
  }

  // The dot matrix: the photo sampled into a grid of dots, as the app's
  // analysis shows it, then a ring opens from the plate's centre.
  function sample() {
    var cell = innerWidth < 900 ? 7 : 9, dpr = strong ? Math.min(devicePixelRatio || 1, 2) : 1;
    var bw = stage.clientWidth, bh = stage.clientHeight;
    canvas.width = bw * dpr; canvas.height = bh * dpr;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    var cols = Math.ceil(bw / cell), rows = Math.ceil(bh / cell);
    var off = document.createElement('canvas'); off.width = cols; off.height = rows;
    var o = off.getContext('2d');
    var g = geom();
    o.drawImage(small && small.naturalWidth ? small : photo, g.ox / cell, g.oy / cell, g.dw / cell, g.dh / cell);
    var px;
    try { px = o.getImageData(0, 0, cols, rows).data; } catch (_) { return null; }
    var lum = new Float32Array(cols * rows);
    for (var i = 0; i < cols * rows; i++) lum[i] = (0.2126 * px[i * 4] + 0.7152 * px[i * 4 + 1] + 0.0722 * px[i * 4 + 2]) / 255;
    // The dots never change while the ring opens, so they are drawn once
    // into their own canvas and each frame only copies it.
    var dots = document.createElement('canvas'); dots.width = bw * dpr; dots.height = bh * dpr;
    var d = dots.getContext('2d');
    d.setTransform(dpr, 0, 0, dpr, 0, 0);
    d.fillStyle = '#0A0D0B'; d.fillRect(0, 0, bw, bh);
    // Sixteen steps of brightness, one path each: a fill per dot is too slow
    // for an old machine, and the eye does not see finer steps at this size.
    var L = 16;
    for (var k = 0; k < L; k++) {
      var lk = (k + 0.5) / L, rad = (0.14 + lk * 0.38) * cell;
      d.fillStyle = 'rgba(168,179,173,' + (0.14 + lk * 0.6).toFixed(2) + ')';
      d.beginPath();
      for (var y = 0; y < rows; y++) for (var x = 0; x < cols; x++) {
        if (Math.min(L - 1, (lum[y * cols + x] * L) | 0) !== k) continue;
        var cx = x * cell + cell / 2, cy = y * cell + cell / 2;
        d.moveTo(cx + rad, cy); d.arc(cx, cy, rad, 0, 6.2832);
      }
      d.fill();
    }
    return { cell: cell, cols: cols, rows: rows, dots: dots, w: bw, h: bh };
  }

  // Outside the ring: the photo as dots. The ring: a 1px line and a ring of
  // ticks, like the bezel of a lens. Inside: the photo itself, hard-edged.
  function drawDots(r, t, built) {
    var g = grid, f = project(meal().focus[0], meal().focus[1]);
    ctx.clearRect(0, 0, g.w, g.h);
    ctx.save();
    // On arrival the matrix builds row by row, top to bottom.
    if (built < 1) { ctx.beginPath(); ctx.rect(0, 0, g.w, Math.ceil(g.h * built / g.cell) * g.cell); ctx.clip(); }
    if (r > 0) { ctx.beginPath(); ctx.rect(0, 0, g.w, g.h); ctx.arc(f.x, f.y, r, 0, 6.2832, true); ctx.clip('evenodd'); }
    ctx.drawImage(g.dots, 0, 0, g.w, g.h);
    ctx.restore();
    if (r <= 0) return;
    ctx.strokeStyle = '#6BCB97';
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.arc(f.x, f.y, r, 0, 6.2832); ctx.stroke();
    ctx.lineWidth = 2;
    var spin = t / 4000;
    for (var i = 0; i < 60; i++) {
      var a = i / 60 * 6.2832 + spin, long = i % 5 === 0 ? 14 : 8;
      ctx.globalAlpha = i % 5 === 0 ? 1 : .55;
      ctx.beginPath();
      ctx.moveTo(f.x + Math.cos(a) * (r + 6), f.y + Math.sin(a) * (r + 6));
      ctx.lineTo(f.x + Math.cos(a) * (r + 6 + long), f.y + Math.sin(a) * (r + 6 + long));
      ctx.stroke();
    }
    ctx.globalAlpha = 1;
  }

  function reveal(r) {
    var f = project(meal().focus[0], meal().focus[1]);
    var mask = r < 0 ? 'none' : 'radial-gradient(circle at ' + f.x + 'px ' + f.y + 'px, #000 ' + Math.max(0, r - 0.5) + 'px, transparent ' + r + 'px)';
    photo.style.webkitMaskImage = mask; photo.style.maskImage = mask;
  }

  function settle(lis, d) {
    hero.classList.add('is-open'); hello.classList.remove('is-on');
    reveal(-1); ctx.clearRect(0, 0, canvas.width, canvas.height);
    lis.forEach(function (li) { li.classList.add('is-on'); });
    readout(d.kcal, true);
  }

  // The dots need 160 by 100 pixels. Shrinking the full photo to that costs an
  // old machine a third of a second on the main thread, so they are read from
  // the smallest size, decoded aside first.
  var small = null, decoded = '', decoding = false;
  function read() {
    var want = 'assets/lp/img/' + meal().img + '-' + meal().sizes[0] + '.webp';
    if (photo.complete && !reduce.matches && decoded !== want) {
      if (decoding) return;
      decoding = true;
      small = new Image();
      var go = function () { decoding = false; decoded = want; read(); };
      small.onload = small.onerror = function () { if (!small.decode) go(); };
      small.src = want;
      if (small.decode) small.decode().then(go, go);
      return;
    }
    handOff();
    var id = ++run;
    cancelAnimationFrame(raf);
    hero.classList.remove('is-read');
    var d = data();
    buildParts();
    var lis = $$('.part', partsEl);
    if (reduce.matches || !photo.complete) return settle(lis, d);
    grid = sample();
    if (!grid) return settle(lis, d);
    var f = project(meal().focus[0], meal().focus[1]);
    var far = Math.max(Math.hypot(f.x, f.y), Math.hypot(grid.w - f.x, f.y), Math.hypot(f.x, grid.h - f.y), Math.hypot(grid.w - f.x, grid.h - f.y));
    var vis = seen();
    var dist = vis.map(function (p) { var q = project(p.x, p.y); return Math.hypot(q.x - f.x, q.y - f.y); });
    var order = dist.map(function (_, i) { return i; }).sort(function (a, b) { return dist[a] - dist[b]; });
    var plateR = Math.max(meal().span * meal().w * f.s * 0.55, Math.max.apply(null, dist) + 24);
    // The timeline: hold on the dots, open the ring to the plate's rim, find
    // the parts one by one as the ring reaches them, then open to the edges.
    // The first visit of a session greets while the matrix builds.
    var build = first ? 520 : 0;
    hero.classList.remove('is-open');
    if (first) {
      first = false;
      hello.style.setProperty('--hx', f.x + 'px'); hello.style.setProperty('--hy', f.y + 'px');
      hello.classList.add('is-on'); try { sessionStorage.setItem('kalorat_seen', '1'); } catch (_) {}
    }
    var hold = build + 380, open = 1500, gap = 240, t0 = performance.now(), found = 0, lastFound = -1e9, sum = 0, shownK = 0, rest = -1;
    readout(0, false);
    var ft = [], last = 0;
    (function frame(now) {
      if (id !== run) return;
      if (last) ft.push(now - last);
      last = now;
      var t = now - t0, r;
      if (t < hold) r = 0;
      else { r = ease(clamp((t - hold) / open, 0, 1)) * plateR; hello.classList.remove('is-on'); hero.classList.add('is-open'); }
      // A part is found once the ring has passed it and the previous one has had its moment.
      while (found < order.length && dist[order[found]] < r && t - lastFound >= gap) {
        var i = order[found++];
        lis[i].classList.add('is-on');
        sum += vis[i].k; lastFound = t;
      }
      if (found === order.length && rest < 0 && t - lastFound > 300) rest = t;
      if (rest >= 0) r = plateR + ease(clamp((t - rest) / 700, 0, 1)) * (far - plateR + 40);
      reveal(r); drawDots(r, t, build ? clamp(t / build, 0, 1) : 1);
      var target = found === order.length ? d.kcal : sum;
      shownK += (target - shownK) * 0.2;
      rKcal.textContent = fmt(Math.round(shownK));
      if (rest < 0 || t - rest < 700) raf = requestAnimationFrame(frame);
      else { settle(lis, d); placeParts(); judge(ft); }
    })(t0);
  }

  // The scan is the heaviest thing the page draws. If this machine could not
  // keep it near 30 frames a second, the extras step down: no inertial
  // scroll, no flying plate, dots at one pixel per point.
  function judge(ft) {
    if (!strong || ft.length < 30) return;
    var a = ft.slice().sort(function (x, y) { return x - y; }), p75 = a[Math.floor(a.length * .75)];
    window.__kaloratFrames = { p75: Math.round(p75), n: a.length };
    if (p75 <= 34) return;
    strong = false;
    document.documentElement.classList.add('is-weak');
    if (lenis) { lenis.destroy(); lenis = null; }
    handOff();
  }

  function setPhoto() {
    var m = meal(), base = 'assets/lp/img/' + m.img;
    stage.style.setProperty('--pos', m.pos[0] + '% ' + m.pos[1] + '%');
    photo.removeAttribute('srcset');
    photo.width = m.w; photo.height = m.h;
    photo.srcset = m.sizes.map(function (s) { return base + '-' + s + '.webp ' + s + 'w'; }).join(', ');
    photo.src = base + '-1280.webp';
    photo.setAttribute('data-i18n-attr', 'alt:plate.' + plate + '.alt');
    photo.alt = T('plate.' + plate + '.alt');
  }

  function choose(p) {
    if (p === plate && hero.classList.contains('is-read')) return;
    plate = p;
    $$('.plate').forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.plate === p)); });
    // The old plate falls back to dots and its labels go before the new one loads.
    cancelAnimationFrame(raf); run++;
    partsEl.textContent = '';
    hero.classList.remove('is-read');
    if (grid) { reveal(0); drawDots(0, 0, 1); }
    setPhoto(); apartBuild();
    (photo.decode ? photo.decode() : Promise.resolve()).catch(function () {}).then(read);
  }
  $$('.plate').forEach(function (b) { if (!MEALS[b.dataset.plate].en) b.hidden = true; });
  $$('.plate').forEach(function (b) { b.addEventListener('click', function () { choose(b.dataset.plate); }); });
  var hello = $('#hello'), first = true;
  try { first = !sessionStorage.getItem('kalorat_seen'); } catch (_) {}
  // On a first visit the headline rises once the matrix has built.
  if (first && !reduce.matches) $('#hero-title').style.setProperty('--d0', '700ms');
  function startHero() {
    Promise.all([photo.decode ? photo.decode() : 0, document.fonts ? document.fonts.ready : 0]).catch(function () {}).then(read);
  }


  /* ---------- 2. Taken apart ---------- */
  var apart = $('#apart'), aFig = $('#apart-fig'), aImg = $('#a-img'), aDots = $('#a-dots'), aLines = $('#a-lines');
  var aList = $('#a-list'), aSum = $('#a-sum'), aTop = $('#a-top'), aHid = $('#a-hid'), aOrder = [], aShown = -1, aRows = [];
  var aCv = $('#a-cv'), aCtx = aCv.getContext('2d'), aHint = $('#a-hint'), aDotsImg = null;
  function apartBuild() {
    var d = data(), m = meal();
    // Rows in the order the parts lie on the plate, top to bottom, so no two
    // lines cross; hidden parts (butter, oil) last, with no dot. They come out
    // biggest first.
    var parts = d.parts.slice().sort(function (a, b) { return (a.y == null) - (b.y == null) || a.y - b.y; });
    aOrder = parts.map(function (_, i) { return i; }).sort(function (a, b) { return parts[b].k - parts[a].k; });
    aImg.src = 'assets/lp/img/' + m.img + '-1280.webp';
    aImg.width = m.w; aImg.height = m.h;
    aList.textContent = ''; aDots.textContent = ''; aLines.textContent = '';
    aList.classList.toggle('is-long', parts.length > 7);
    aRows = parts.map(function (p, i) {
      var li = document.createElement('li');
      li.style.setProperty('--share', (p.k / d.kcal).toFixed(3));
      [['i num', String(i + 1).padStart(2, '0')], ['n', p.n], ['g num', fmt(p.g) + ' g'], ['k num', fmt(p.k)]].forEach(function (c) {
        var s = document.createElement('span'); s.className = c[0]; s.textContent = c[1]; s.setAttribute('aria-hidden', 'true'); li.appendChild(s);
      });
      var u = document.createElement('small'); u.textContent = 'kcal'; li.lastChild.appendChild(u);
      // The whole row is the switch that takes the part away and puts it back.
      var take = document.createElement('button');
      take.type = 'button'; take.className = 'a-take'; take.setAttribute('aria-pressed', 'false');
      take.setAttribute('aria-label', fill(T('apart.take'), { n: p.n, g: fmt(p.g), k: fmt(p.k) }));
      li.appendChild(take);
      aList.appendChild(li);
      var dot = null, line = null;
      if (p.x != null) {
        dot = document.createElement('li'); dot.textContent = i + 1; aDots.appendChild(dot);
        line = el('path', { pathLength: 1 }, aLines);
      }
      var row = { p: p, li: li, dot: dot, line: line, take: take, out: false, h: 0 };
      li.addEventListener('pointerenter', function () { hotRow(row, true); });
      li.addEventListener('pointerleave', function () { hotRow(row, false); });
      take.addEventListener('click', function () { takeAway(row); });
      if (dot) dragDot(row);
      return row;
    });
    var hid = parts.filter(function (p) { return p.x == null; });
    aHid.textContent = hid.length ? fill(T('apart.hidden'), { names: hid.map(function (p) { return p.n; }).join(', ') }) : '';
    aHid.hidden = !hid.length;
    var top = parts[aOrder[0]];
    aTop.textContent = fill(T('apart.top'), { name: top.n, pct: Math.round(top.k / d.kcal * 100) });
    aShown = -1; aSum.textContent = '0'; aDotsImg = null;
    aHint.textContent = T(fine ? 'apart.hint.drag' : 'apart.hint');
    aFig.classList.remove('is-taken', 'is-all');
    apartLayout(); apartHoles(); apartScroll();
  }
  function hotRow(r, on) {
    [r.li, r.dot, r.line].forEach(function (n) { if (n) n.classList.toggle('is-hot', on); });
  }
  function apartLayout() {
    var m = meal(), box = aImg.parentNode, D = box.clientWidth;
    if (!D) return;
    var s = D / (m.span * m.w) * 1.04, w = m.w * s, h = m.h * s;
    var l = D / 2 - m.focus[0] * w, t = D / 2 - m.focus[1] * h;
    aImg.style.width = w + 'px'; aImg.style.height = h + 'px'; aImg.style.left = l + 'px'; aImg.style.top = t + 'px';
    var fr = aFig.getBoundingClientRect(), br = box.getBoundingClientRect(), lines = getComputedStyle(aLines).display !== 'none';
    aLines.setAttribute('viewBox', '0 0 ' + fr.width + ' ' + fr.height);
    var px = br.right - fr.left + 18, ex = br.right - fr.left + 64;
    aRows.forEach(function (r) {
      if (!r.dot) return;
      var x = l + r.p.x * w, y = t + r.p.y * h;
      r.dot.style.setProperty('--x', x + 'px'); r.dot.style.setProperty('--y', y + 'px');
      if (!lines) return;
      var rr = r.li.getBoundingClientRect(), dx = br.left - fr.left + x, dy = br.top - fr.top + y;
      var ry = rr.top - fr.top + rr.height / 2, rx = rr.left - fr.left - 14;
      // Level out of the dot past the plate's rim, one slant, level into its
      // row. Dots and rows share one top-to-bottom order, so no two cross.
      // A level run that would pass through another dot steps 16px aside first.
      var jy = dy;
      aRows.forEach(function (o) {
        if (o === r || !o.dot) return;
        var ox = l + o.p.x * w, oy = t + o.p.y * h;
        if (ox > dx && Math.abs(oy - dy) < 14) jy = y + (oy > y ? -16 : 16);
      });
      var start = jy === dy ? 'M' + (dx + 12).toFixed(1) + ' ' + dy.toFixed(1)
        : 'M' + dx.toFixed(1) + ' ' + (dy + (jy < dy ? -12 : 12)).toFixed(1) + ' V' + (br.top - fr.top + jy).toFixed(1);
      r.line.setAttribute('d', start + ' H' + px.toFixed(1) + ' L' + ex.toFixed(1) + ' ' + ry.toFixed(1) + ' H' + rx.toFixed(1));
    });
  }
  function apartShow(k, force) {
    if (k === aShown && !force) return;
    aShown = k;
    var sum = 0, gone = 0, d = data(), out = [];
    aOrder.forEach(function (idx, j) {
      var r = aRows[idx], on = j < k;
      [r.li, r.dot, r.line].forEach(function (n) { if (n) n.classList.toggle('is-on', on); });
      if (r.out) { gone += r.p.k; out.push(r.p.n); }
      else if (on) sum += r.p.k;
    });
    // The total is the plain sum of the parts left on the plate.
    var all = k >= aOrder.length;
    roll(aSum, fmt(all ? d.kcal - gone : sum));
    aFig.classList.toggle('is-all', all);
    aFig.classList.toggle('is-taken', out.length > 0);
    // The sentence names the biggest part; it lights up with that part's row.
    // With parts taken away, it says what the plate is without them.
    if (out.length) {
      var names = window.Intl && Intl.ListFormat ? new Intl.ListFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { type: 'conjunction' }).format(out) : out.join(', ');
      aTop.textContent = fill(T('apart.without'), { names: names, kcal: fmt(d.kcal - gone), pct: Math.round(gone / d.kcal * 100) });
    } else {
      var top = aRows[aOrder[0]].p;
      aTop.textContent = fill(T('apart.top'), { name: top.n, pct: Math.round(top.k / d.kcal * 100) });
    }
    aTop.classList.toggle('is-swept', k > 0);
  }

  // Taking a part away: its patch of the plate falls back to dots, as if the
  // camera stopped seeing it; putting it back wipes the photo in again.
  function takeAway(r, out) {
    r.out = out == null ? !r.out : out;
    r.take.setAttribute('aria-pressed', String(r.out));
    [r.li, r.dot, r.line].forEach(function (n) { if (n) n.classList.toggle('is-out', r.out); });
    apartShow(aShown, true);
    apartHoles(true);
  }
  // The plate's dots, sampled once from the photo as it sits in the circle.
  function apartDots(D) {
    var cell = D > 400 ? 8 : 7, cols = Math.ceil(D / cell), off = document.createElement('canvas');
    off.width = off.height = cols;
    var o = off.getContext('2d'), sc = cols / D, src = small && small.naturalWidth && decoded.indexOf('/' + meal().img + '-') > 0 ? small : aImg;
    if (!src.complete || !src.naturalWidth) return null;
    o.drawImage(src, parseFloat(aImg.style.left) * sc, parseFloat(aImg.style.top) * sc, parseFloat(aImg.style.width) * sc, parseFloat(aImg.style.height) * sc);
    var px; try { px = o.getImageData(0, 0, cols, cols).data; } catch (_) { return null; }
    var dpr = strong ? Math.min(devicePixelRatio || 1, 2) : 1, c = document.createElement('canvas');
    c.width = c.height = Math.round(D * dpr);
    var g = c.getContext('2d'), L = 12;
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    g.fillStyle = '#0A0D0B'; g.fillRect(0, 0, D, D);
    for (var q = 0; q < L; q++) {
      var lq = (q + .5) / L, rad = (.14 + lq * .38) * cell;
      g.fillStyle = 'rgba(168,179,173,' + (.14 + lq * .6).toFixed(2) + ')';
      g.beginPath();
      for (var i = 0; i < cols * cols; i++) {
        var l = (.2126 * px[i * 4] + .7152 * px[i * 4 + 1] + .0722 * px[i * 4 + 2]) / 255;
        if (Math.min(L - 1, (l * L) | 0) !== q) continue;
        var cx = (i % cols) * cell + cell / 2, cy = ((i / cols) | 0) * cell + cell / 2;
        g.moveTo(cx + rad, cy); g.arc(cx, cy, rad, 0, 6.2832);
      }
      g.fill();
    }
    return { c: c, D: D };
  }
  var holesRaf = 0;
  function apartHoles(anim) {
    var D = aBox.clientWidth;
    if (!D) return;
    var dpr = strong ? Math.min(devicePixelRatio || 1, 2) : 1;
    if (aCv.width !== Math.round(D * dpr)) { aCv.width = aCv.height = Math.round(D * dpr); }
    var any = aRows.some(function (r) { return r.out || r.h > 0.001; });
    if (any && (!aDotsImg || aDotsImg.D !== D)) aDotsImg = apartDots(D);
    cancelAnimationFrame(holesRaf);
    var R = 72 * D / 560, last = performance.now();
    (function frame(now) {
      var dt = Math.min(50, now - last), moving = false;
      last = now;
      aCtx.setTransform(dpr, 0, 0, dpr, 0, 0);
      aCtx.clearRect(0, 0, D, D);
      aRows.forEach(function (r) {
        if (!r.dot) return;
        var to = r.out ? 1 : 0;
        // Expo-out over about 450 ms.
        r.h = !anim || reduce.matches ? to : r.h + (to - r.h) * (1 - Math.pow(0.0001, dt / 450));
        if (Math.abs(to - r.h) < 0.002) r.h = to; else moving = true;
        if (r.h <= 0 || !aDotsImg) return;
        var x = parseFloat(r.dot.style.getPropertyValue('--x')), y = parseFloat(r.dot.style.getPropertyValue('--y')), rr = R * r.h;
        aCtx.save(); aCtx.beginPath(); aCtx.arc(x, y, rr, 0, 6.2832); aCtx.clip();
        aCtx.drawImage(aDotsImg.c, 0, 0, D, D); aCtx.restore();
        aCtx.strokeStyle = 'rgba(107,203,151,.7)'; aCtx.lineWidth = 1; aCtx.setLineDash([3, 4]);
        aCtx.beginPath(); aCtx.arc(x, y, rr, 0, 6.2832); aCtx.stroke(); aCtx.setLineDash([]);
      });
      if (moving) holesRaf = requestAnimationFrame(frame);
    })(last);
  }
  // A dot can be dragged off the plate to take its part away; a dot dropped
  // on the plate goes home. A press without a drag is a click.
  function dragDot(r) {
    // While held, a copy follows the pointer, since the plate clips its own dots.
    var d = r.dot, sx = 0, sy = 0, on = false, moved = false, ghost = null, gx = 0, gy = 0;
    var drop = function () { if (ghost) { ghost.parentNode.removeChild(ghost); ghost = null; } d.style.opacity = ''; d.classList.remove('is-drag'); };
    d.addEventListener('pointerdown', function (e) {
      if (e.button) return;
      on = true; moved = false; sx = e.clientX; sy = e.clientY;
      if (d.setPointerCapture) d.setPointerCapture(e.pointerId);
      e.preventDefault();
    });
    d.addEventListener('pointermove', function (e) {
      if (!on) return;
      var dx = e.clientX - sx, dy = e.clientY - sy;
      if (!moved && Math.hypot(dx, dy) < 5) return;
      if (!moved) {
        moved = true; d.classList.add('is-drag');
        var q = d.getBoundingClientRect();
        ghost = d.cloneNode(true); ghost.className = 'a-ghost'; document.body.appendChild(ghost);
        gx = q.left; gy = q.top; d.style.opacity = '0';
      }
      ghost.style.transform = 'translate(' + (gx + dx) + 'px,' + (gy + dy) + 'px) scale(1.2)';
      var br = aBox.getBoundingClientRect();
      ghost.classList.toggle('is-off', Math.hypot(e.clientX - (br.left + br.width / 2), e.clientY - (br.top + br.height / 2)) > br.width / 2);
    });
    var up = function (e) {
      if (!on) return;
      on = false;
      drop();
      if (!moved) return takeAway(r);
      var br = aBox.getBoundingClientRect(), D = br.width;
      var off = Math.hypot(e.clientX - (br.left + D / 2), e.clientY - (br.top + D / 2)) > D / 2;
      if (off !== r.out) takeAway(r, off);
    };
    d.addEventListener('pointerup', up);
    d.addEventListener('pointercancel', function () { on = false; drop(); });
  }
  var aPinned = null;
  var apartPinned = function () { return aPinned === null ? (aPinned = getComputedStyle($('.apart-pin')).position === 'sticky') : aPinned; };
  addEventListener('resize', function () { aPinned = null; });
  var apartPlayed = false;
  function apartScroll() {
    if (reduce.matches) return apartShow(aOrder.length);
    var r = apart.getBoundingClientRect();
    // A window taller than the scene (a full-page capture) shows it complete.
    if (r.height <= innerHeight * 1.2) return apartShow(aOrder.length);
    if (apartPinned()) {
      var p = clamp((innerHeight * 0.35 - r.top) / (r.height - innerHeight * 0.9), 0, 1);
      return apartShow(Math.round(p * aOrder.length));
    }
    // Phones: the row under the plate lights its dot.
    var mid = $('.apart-plate').getBoundingClientRect().bottom + 60, near = null, nd = 1e9;
    aRows.forEach(function (row) { var q = row.li.getBoundingClientRect(), dd = Math.abs(q.top + q.height / 2 - mid); if (row.dot && dd < nd) { nd = dd; near = row; } });
    aRows.forEach(function (row) { hotRow(row, row === near && nd < 80); });
    // The parts come out one by one once the list is in view.
    if (apartPlayed || aList.getBoundingClientRect().top > innerHeight * 0.8) return;
    apartPlayed = true;
    var k = 0;
    (function next() { apartShow(++k); if (k < aOrder.length) setTimeout(next, 260); })();
  }

  /* ---------- 1→2. The plate travels from the photo into the circle ---------- */
  // One round copy of the plate leaves the hero as the page scrolls and lands
  // where the teardown's circle is, at the size the circle shows it. Behind
  // it, the hero keeps the plate's dot pattern, like the scan's first frame.
  var hand = document.createElement('div'), handImg = document.createElement('img'), handOn = false;
  hand.className = 'handoff'; hand.setAttribute('aria-hidden', 'true');
  handImg.alt = ''; hand.appendChild(handImg); document.body.appendChild(hand);
  var aBox = $('.apart-plate'), heroWords = $$('.hero-copy, .readout, .plates');
  function handOff() {
    if (handOn) {
      handOn = false; hand.style.visibility = 'hidden'; apart.classList.remove('is-handing');
      photo.style.webkitMaskImage = photo.style.maskImage = 'none'; partsEl.style.opacity = '';
      heroWords.forEach(function (n) { n.style.opacity = ''; });
      if (grid) ctx.clearRect(0, 0, grid.w, grid.h);
    }
  }
  // Focus can enter or leave the hero's words without a scroll.
  document.addEventListener('focusin', function () { handoff(); });
  document.addEventListener('focusout', function () { setTimeout(handoff, 0); });
  function handoff() {
    // Only where the teardown is pinned: on a phone the plate would hang over the hero's words while they are read.
    if (reduce.matches || !strong || !grid || !apartPinned() || !hero.classList.contains('is-read') || apart.getBoundingClientRect().height <= innerHeight * 1.2) return handOff();
    var end = apart.getBoundingClientRect().top + scrollY;
    var p = clamp(scrollY / Math.max(1, end), 0, 1);
    if (p <= 0.002 || p >= 1) return handOff();
    var m = meal(), pr = photo.getBoundingClientRect(), br = aBox.getBoundingClientRect(), D = br.width;
    if (!D || !pr.width) return handOff();
    var k = m.w * (D / (m.span * m.w) * 1.04) / pr.width, R = D / (2 * k);
    var hx = pr.left + m.focus[0] * pr.width, hy = pr.top + m.focus[1] * pr.height;
    // Scrubbed by the scroll, so an S-curve: it leaves slowly and lands softly.
    var e = p * p * (3 - 2 * p), cx = hx + (br.left + D / 2 - hx) * e, cy = hy + (br.top + D / 2 - hy) * e, sc = 1 + (k - 1) * e;
    if (handImg.getAttribute('src') !== photo.currentSrc) handImg.src = photo.currentSrc || photo.src;
    hand.style.width = hand.style.height = 2 * R + 'px';
    handImg.style.width = pr.width + 'px'; handImg.style.height = pr.height + 'px';
    handImg.style.left = R - m.focus[0] * pr.width + 'px'; handImg.style.top = R - m.focus[1] * pr.height + 'px';
    hand.style.transform = 'translate(' + (cx - R).toFixed(1) + 'px,' + (cy - R).toFixed(1) + 'px) scale(' + sc.toFixed(4) + ')';
    if (!handOn) {
      handOn = true; hand.style.visibility = 'visible'; apart.classList.add('is-handing');
      // The hole the plate leaves, in the photo's own pixels.
      var g = geom(), f = project(m.focus[0], m.focus[1]), r = R * g.dw / pr.width;
      var mask = 'radial-gradient(circle at ' + (m.focus[0] * g.dw).toFixed(1) + 'px ' + (m.focus[1] * g.dh).toFixed(1) + 'px, transparent ' + r.toFixed(1) + 'px, #000 ' + (r + 1).toFixed(1) + 'px)';
      photo.style.webkitMaskImage = photo.style.maskImage = mask;
      ctx.clearRect(0, 0, grid.w, grid.h);
      ctx.save(); ctx.beginPath(); ctx.arc(f.x, f.y, r, 0, 6.2832); ctx.clip();
      ctx.drawImage(grid.dots, 0, 0, grid.w, grid.h); ctx.restore();
    }
    partsEl.style.opacity = String(clamp(1 - p * 5, 0, 1));
    // The hero's words step back while the plate passes under them.
    var o = String(clamp(1 - p * 2.6, 0, 1));
    // Never fade the block that holds keyboard focus.
    var a = document.activeElement;
    heroWords.forEach(function (n) { n.style.opacity = n.contains(a) ? '' : o; });
  }

  /* ---------- 2→3. The plate becomes a step of the day ---------- */
  // As the teardown lets go, the plate stays where it was while the night
  // scrolls away under it, then shrinks onto its own step of the day's ridge,
  // the moment the ridge has climbed by its calories. Only for plates that
  // are part of the day, and only where both scenes are pinned.
  var hand2 = document.createElement('div'), h2Img = document.createElement('img'), h2Thumb = document.createElement('img'), h2On = false, carry = -1;
  hand2.className = 'handoff handoff-2'; hand2.setAttribute('aria-hidden', 'true');
  h2Img.alt = h2Thumb.alt = ''; h2Thumb.className = 'h2-thumb';
  hand2.appendChild(h2Img); hand2.appendChild(h2Thumb); document.body.appendChild(hand2);
  var h2From = null;
  function carryOff() {
    if (!h2On) return;
    h2On = false; hand2.style.visibility = 'hidden'; apart.classList.remove('is-leaving');
    if (carry >= 0) { carry = -1; drawnAt = -1; dayScroll(); }
  }
  function carryOn() {
    var j = -1;
    DAY.meals.forEach(function (m, i) { if (m.plate === plate) j = i; });
    if (j < 0 || reduce.matches || !strong || !apartPinned() || !dayPinned() || apart.getBoundingClientRect().height <= innerHeight * 1.2) return carryOff();
    var ar = apart.getBoundingClientRect(), dr = day.getBoundingClientRect();
    var s0 = ar.bottom + scrollY - innerHeight;
    // The scroll at which dayScroll() has drawn the ridge to this meal's climb.
    var mt = mins(DAY.meals[j].t) + 50, span = dr.height - innerHeight;
    var s1 = dr.top + scrollY + span * 0.8 * (mt - T0) / (T1 - T0);
    var q = clamp((scrollY - s0) / Math.max(1, s1 - s0), 0, 1);
    if (q <= 0) { h2From = null; return carryOff(); }
    if (q >= 1) return carryOff();
    // Where it leaves from: the circle as it sat in the pinned teardown.
    if (!h2From) { var b = aBox.getBoundingClientRect(); h2From = { x: b.left, y: b.top + (scrollY - s0), w: b.width }; }
    var img = ridge.querySelectorAll('.r-pin image')[j];
    if (!img) return carryOff();
    var sv = ridge.getBoundingClientRect();
    var to = { x: sv.left + +img.getAttribute('x'), y: sv.top + +img.getAttribute('y'), w: +img.getAttribute('width'), h: +img.getAttribute('height') };
    // It shrinks and moves aside early and drops late, so it is small and in
    // the free middle before the day's words arrive.
    var e = q * q * (3 - 2 * q), z = 1 - Math.pow(1 - q, 2.4), D = h2From.w;
    var w = D + (to.w - D) * z, h = D + (to.h - D) * z;
    var x = h2From.x + D / 2 + (to.x + to.w / 2 - h2From.x - D / 2) * (1 - Math.pow(1 - q, 4)) - w / 2, y = h2From.y + D / 2 + (to.y + to.h / 2 - h2From.y - D / 2) * e - h / 2;
    var m = meal(), iw = parseFloat(aImg.style.width) * Math.max(w, h) / D, ih = iw * m.h / m.w;
    if (h2Img.getAttribute('src') !== aImg.currentSrc) h2Img.src = aImg.currentSrc || aImg.src;
    var th = 'assets/lp/img/' + m.img + '-thumb.webp';
    if (h2Thumb.getAttribute('src') !== th) h2Thumb.src = th;
    hand2.style.width = w + 'px'; hand2.style.height = h + 'px';
    hand2.style.borderRadius = (Math.min(w, h) / 2 + (10 - Math.min(w, h) / 2) * e).toFixed(1) + 'px';
    hand2.style.transform = 'translate(' + x.toFixed(1) + 'px,' + y.toFixed(1) + 'px)';
    h2Img.style.width = iw + 'px'; h2Img.style.height = ih + 'px';
    h2Img.style.left = w / 2 - m.focus[0] * iw + 'px'; h2Img.style.top = h / 2 - m.focus[1] * ih + 'px';
    // The last stretch crossfades into the ridge's own photo of the meal.
    h2Thumb.style.opacity = String(clamp((e - .7) / .25, 0, 1));
    if (!h2On) { h2On = true; hand2.style.visibility = 'visible'; apart.classList.add('is-leaving'); }
    if (carry !== j) { carry = j; drawnAt = -1; dayScroll(); }
  }

  /* ---------- 5. How it reads: one phone, four steps ---------- */
  var steps = $$('.step'), scrs = $$('.scr');
  function setStep(i) {
    steps.forEach(function (s) { s.classList.toggle('is-on', +s.dataset.step === i); s.classList.toggle('is-past', +s.dataset.step < i); });
    scrs.forEach(function (s) { s.classList.toggle('is-on', +s.dataset.step === i); });
  }
  var scrubOn = false;
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (es) {
      if (scrubOn) return;
      es.forEach(function (e) { if (e.isIntersecting) setStep(+e.target.dataset.step); });
    }, { rootMargin: innerWidth <= 900 ? '-72% 0px -26% 0px' : '-48% 0px -48% 0px' });
    steps.forEach(function (s) { io.observe(s); });
  }

  // On a wide screen the section is pinned and its scroll runs the stages.
  // The line is where the scroll is: it forks into the three estimates, which
  // run at once and end at slightly different times; the middle one goes on.
  var how = $('#how'), hsEl = $('#how-scrub'), hsKnob = $('#hs-knob'), howPhone = $('#how-phone');
  var hsCut = $('#hs-cut');
  var hsEnds = $$('.hs-end', hsEl), hsLis = $$('.hs-stages li', hsEl), runs = $$('.how-runs i'), hsHold = $('.how-hold');
  // Where each stage starts on the line (0–1000), and where each estimate runs.
  var ST = [0, 180, 360, 860], RUNS = [[360, 740], [360, 800], [360, 770]];
  var hsStage = -1, hsX = -1, hsW = 0, scrH = 0, flashT = 0;
  function scrubMode() {
    var on = !reduce.matches && innerWidth > 900 && innerHeight >= 560;
    scrubOn = on;
    document.documentElement.classList.toggle('how-scrub-on', on);
    hsEl.hidden = !on;
    hsStage = -1; hsX = -1;
    if (!on) { scrs.forEach(function (s) { s.style.removeProperty('--zoom'); }); return; }
    hsW = hsEl.getBoundingClientRect().width;
    scrH = $('.phone-screen', howPhone).getBoundingClientRect().height;
    howScrub();
  }
  function howRange() { var r = how.getBoundingClientRect(); return { top: r.top, len: Math.max(1, r.height - innerHeight) }; }
  function howScrub() {
    if (!scrubOn) return;
    var g = howRange(), p = clamp(-g.top / g.len, 0, 1), x = Math.round(p * 1000);
    if (x === hsX) return;
    hsX = x;
    var s = x >= ST[3] ? 3 : x >= ST[2] ? 2 : x >= ST[1] ? 1 : 0;
    hsKnob.style.transform = 'translate(' + (p * hsW).toFixed(1) + 'px,0)';
    hsCut.setAttribute('width', x);
    hsEnds[0].classList.toggle('is-on', x >= 740); hsEnds[1].classList.toggle('is-on', x >= 770);
    // The number stays covered until the last estimate is in.
    hsHold.style.opacity = x < ST[2] ? '0' : (1 - clamp((x - 800) / 30, 0, 1)).toFixed(3);
    runs.forEach(function (n, i) {
      var f = (x - RUNS[i][0]) / (RUNS[i][1] - RUNS[i][0]);
      n.style.opacity = f > 0 && f < 1 ? '1' : '0';
      n.style.transform = 'translate(0,' + (clamp(f, 0, 1) * scrH).toFixed(1) + 'px)';
    });
    scrs[0].style.setProperty('--zoom', (1 + .06 * clamp(x / ST[1], 0, 1)).toFixed(4));
    if (s === hsStage) return;
    // The shutter: a white flash and a small jolt of the phone.
    if (s === 1 && hsStage === 0) {
      howPhone.classList.add('is-flash', 'is-jolt');
      clearTimeout(flashT); flashT = setTimeout(function () { howPhone.classList.remove('is-flash', 'is-jolt'); }, 90);
    }
    hsStage = s;
    setStep(s);
    hsLis.forEach(function (li, i) { li.classList.toggle('is-on', i === s); li.classList.toggle('is-done', i < s); });
    hsEl.setAttribute('aria-valuenow', s + 1);
    hsEl.setAttribute('aria-valuetext', fill(T('how.stage'), { n: s + 1, name: hsLis[s].textContent }));
  }
  function howGo(p, now) {
    var g = howRange(), y = scrollY + g.top + p * g.len;
    if (lenis) lenis.scrollTo(y, now ? { immediate: true } : {});
    else scrollTo({ top: y, behavior: now || reduce.matches ? 'auto' : 'smooth' });
  }
  var hsDrag = false;
  function hsAt(e) { var r = hsEl.getBoundingClientRect(); howGo(clamp((e.clientX - r.left) / r.width, 0, 1), true); }
  hsEl.addEventListener('pointerdown', function (e) {
    if (e.button) return;
    hsDrag = true; hsEl.classList.add('is-drag');
    if (hsEl.setPointerCapture) hsEl.setPointerCapture(e.pointerId);
    hsAt(e); e.preventDefault();
  });
  hsEl.addEventListener('pointermove', function (e) { if (hsDrag) hsAt(e); });
  var hsUp = function () { hsDrag = false; hsEl.classList.remove('is-drag'); };
  hsEl.addEventListener('pointerup', hsUp); hsEl.addEventListener('pointercancel', hsUp);
  hsEl.addEventListener('keydown', function (e) {
    var k = e.key, s = Math.max(hsStage, 0);
    if (k === 'ArrowRight' || k === 'ArrowUp') s = Math.min(3, s + 1);
    else if (k === 'ArrowLeft' || k === 'ArrowDown') s = Math.max(0, s - 1);
    else if (k === 'Home') s = 0;
    else if (k === 'End') s = 3;
    else return;
    e.preventDefault();
    howGo([.06, .26, .6, .94][s], false);
  });
  scrubMode();
  // The day's screens follow the page's scheme, as the app does.
  var darkQ = matchMedia('(prefers-color-scheme: dark)');
  function screens() {
    var theme = document.documentElement.getAttribute('data-theme');
    var dark = theme ? theme === 'dark' : darkQ.matches;
    $$('[data-scr]').forEach(function (img) {
      var n = img.dataset.scr, d = dark && (n === 'today' || n === 'progress') ? '-dark' : '';
      img.src = 'assets/lp/screens/' + lang() + '/' + n + d + '.webp';
    });
  }
  if (darkQ.addEventListener) darkQ.addEventListener('change', screens);

  /* ---------- The ridge: the horizon between the camera and the day ---------- */
  // Minutes since midnight of "HH:MM".
  var mins = function (s) { var p = s.split(':'); return +p[0] * 60 + +p[1]; };
  var T0 = 6 * 60, T1 = mins(DAY.now);
  // The day as a climb: flat until a meal, a short steep rise, flat again.
  function climb(upTo) {
    var pts = [[T0, 0]], sum = 0;
    DAY.meals.forEach(function (m) {
      var t = mins(m.t);
      if (t > upTo) return;
      pts.push([t, sum]);
      var rise = Math.min(upTo, t + 50), f = (rise - t) / 50;
      sum += m.kcal * f;
      pts.push([rise, sum]);
    });
    pts.push([upTo, sum]);
    return pts;
  }
  function horizon() {
    var W = 1440, H = 220, pts = climb(T1), top = DAY.goal * 1.05;
    var X = function (t) { return (t - T0) / (T1 - T0) * W; }, Y = function (k) { return H - 34 - k / top * (H - 50); };
    // A rise eases in and out, like the app's ridge.
    var d = 'M0 ' + H + ' L0 ' + Y(0).toFixed(1);
    for (var i = 1; i < pts.length; i++) {
      var a = pts[i - 1], b = pts[i];
      if (b[1] === a[1]) { d += ' L' + X(b[0]).toFixed(1) + ' ' + Y(b[1]).toFixed(1); continue; }
      var mx = (X(a[0]) + X(b[0])) / 2;
      d += ' C' + mx.toFixed(1) + ' ' + Y(a[1]).toFixed(1) + ' ' + mx.toFixed(1) + ' ' + Y(b[1]).toFixed(1) + ' ' + X(b[0]).toFixed(1) + ' ' + Y(b[1]).toFixed(1);
    }
    d += ' L' + W + ' ' + H + 'Z';
    $('#horizon-path').setAttribute('d', d);
    $('#horizon-line').setAttribute('d', d.replace(/^M0 [\d.]+ L/, 'M').replace(/ L1440 220Z$/, ''));
  }

  // A number whose figures change like a counter: each changed figure leaves
  // and the new one arrives, up when the number grows, down when it shrinks.
  function roll(node, text) {
    if (reduce.matches) {
      // No motion, but the decimal sign sits as tight as in the rolling one.
      node.textContent = '';
      text.split(/([.,])/).forEach(function (t) {
        if (!t) return;
        if (/^[.,]$/.test(t)) { var d = document.createElement('span'); d.className = 'roll-d dp'; d.textContent = t; node.appendChild(d); }
        else node.appendChild(document.createTextNode(t));
      });
      return;
    }
    var was = node.getAttribute('data-roll');
    if (was === text) return;
    node.setAttribute('data-roll', text);
    node.setAttribute('aria-label', text);
    var up = was == null || parseFloat(text.replace(',', '.')) >= parseFloat(was.replace(',', '.'));
    node.style.setProperty('--out', up ? '-.5em' : '.5em');
    node.style.setProperty('--pre', up ? '.5em' : '-.5em');
    var chars = text.split(''), fresh = !node.classList.contains('roll') || node.children.length !== chars.length;
    if (fresh) {
      node.classList.add('roll');
      node.textContent = '';
      chars.forEach(function (ch) { var d = document.createElement('span'); d.className = 'roll-d' + (/[.,]/.test(ch) ? ' dp' : ''); d.setAttribute('aria-hidden', 'true'); node.appendChild(d); });
    }
    var n = 0;
    chars.forEach(function (ch, i) {
      var slot = node.children[i], cur = slot.lastChild;
      if (cur && !fresh && cur.textContent === ch) return;
      if (cur) { cur.classList.add('is-out'); setTimeout(function () { if (cur.parentNode) cur.parentNode.removeChild(cur); }, 650); }
      var s = document.createElement('span'); s.textContent = ch; s.className = 'is-pre';
      s.style.transitionDelay = (n++ * 35) + 'ms';
      slot.appendChild(s);
      void s.offsetWidth; s.classList.remove('is-pre');
    });
  }

  // A key figure rolls in from zeros the first time its section is in view.
  var figIO = 'IntersectionObserver' in window && !reduce.matches ? new IntersectionObserver(function (es) {
    es.forEach(function (e) {
      if (!e.isIntersecting) return;
      figIO.unobserve(e.target); e.target.classList.add('is-seen');
      var t = e.target.getAttribute('data-want');
      if (t) roll(e.target, t);
    });
  }, { threshold: .6 }) : null;
  function figure(node, text) {
    node.setAttribute('data-want', text);
    if (!figIO || node.classList.contains('is-seen')) return roll(node, text);
    roll(node, text.replace(/\d/g, '0'));
    figIO.observe(node);
  }

  /* ---------- 3. The day ---------- */
  var ridge = $('#ridge-svg'), dLeft = $('#d-left'), dEvent = $('#d-event'), dOf = $('#d-of');
  var day = $('#day'), lastEvent = -1;
  function drawRidge(upTo) {
    var W = ridge.clientWidth, H = ridge.clientHeight;
    if (!W || !H) return;
    ridge.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
    ridge.textContent = '';
    var padB = 28, padT = 76, top = DAY.goal * 1.08;
    var X = function (t) { return (t - T0) / (T1 - T0) * (W - 8); };
    var Y = function (k) { return H - padB - k / top * (H - padB - padT); };
    // Hours.
    for (var h = 6; h <= 18; h += 3) {
      var x = X(h * 60);
      el('line', { class: 'r-grid', x1: x, x2: x, y1: padT - 20, y2: H - padB }, ridge);
      // On a narrow ridge every other hour keeps its label.
      if (W < 560 && h % 6) continue;
      el('text', { class: 'r-lab', x: h === 18 ? x - 4 : x + 4, y: H - 8, 'text-anchor': h === 18 ? 'end' : 'start' }, ridge).textContent = (h < 10 ? '0' : '') + h + ':00';
    }
    var gy = Y(DAY.goal);
    el('line', { class: 'r-goal', x1: 0, x2: W, y1: gy, y2: gy }, ridge);
    el('text', { class: 'r-lab', x: W - 4, y: gy - 8, 'text-anchor': 'end' }, ridge).textContent = fmt(DAY.goal) + ' kcal';
    var pts = climb(upTo), line = '', i;
    for (i = 0; i < pts.length; i++) line += (i ? ' L' : 'M') + X(pts[i][0]).toFixed(1) + ' ' + Y(pts[i][1]).toFixed(1);
    var last = pts[pts.length - 1];
    el('path', { class: 'r-area', d: line + ' L' + X(last[0]).toFixed(1) + ' ' + (H - padB) + ' L0 ' + (H - padB) + 'Z' }, ridge);
    el('path', { class: 'r-line', d: line }, ridge);
    el('line', { class: 'r-cursor', x1: X(last[0]), x2: X(last[0]), y1: padT - 20, y2: H - padB }, ridge);
    var kx = X(last[0]), ky = Y(last[1]), knob = el('g', { class: 'r-knob' }, ridge);
    el('circle', { cx: kx, cy: ky, r: 14 }, knob);
    el('path', { d: 'M' + (kx - 3) + ' ' + (ky - 5) + ' V' + (ky + 5) + ' M' + (kx + 3) + ' ' + (ky - 5) + ' V' + (ky + 5) }, knob);
    // The meals' photos on the ridge.
    var sum = 0, eaten = 0, done = 0;
    DAY.meals.forEach(function (m, j) {
      var t = mins(m.t), on = t <= upTo;
      sum += m.kcal;
      if (on) eaten = j + 1;
      if (upTo >= t + 50) done += m.kcal;
      var px = X(t + 50), py = Y(sum), size = Math.min(64, W / 9);
      var g = el('g', { class: 'r-pin' + (on && upTo >= t + 20 ? ' is-on' : '') + (j === carry ? ' is-carried' : '') }, ridge);
      el('line', { class: 'r-stem', x1: px, x2: px, y1: py - 10, y2: py - 18 }, g);
      el('image', { href: 'assets/lp/img/' + m.plate + '-thumb.webp', x: px - size / 2, y: py - 18 - size * 4 / 3, width: size, height: size * 4 / 3, preserveAspectRatio: 'xMidYMid slice' }, g);
      el('text', { x: px + size / 2 + 8, y: py - 18 - size * 2 / 3 }, g).textContent = '+' + fmt(m.kcal);
    });
    // The number moves once per meal, when its climb is done: a counter, not a meter.
    roll(dLeft, fmt(DAY.goal - done));
    if (eaten !== lastEvent) {
      lastEvent = eaten;
      var m = DAY.meals[eaten - 1];
      dEvent.textContent = '';
      if (m) {
        var b = document.createElement('span'); b.className = 'num'; b.textContent = '+' + fmt(m.kcal) + ' kcal';
        dEvent.appendChild(document.createTextNode(m.name + ', ' + m.t + '  '));
        dEvent.appendChild(b);
      }
    }
  }
  function dayText() { dOf.textContent = fill(T('day.of'), { goal: fmt(DAY.goal) }); }
  var pinned = null;
  var dayPinned = function () { return pinned === null ? (pinned = getComputedStyle($('.day-pin')).position === 'sticky') : pinned; };
  addEventListener('resize', function () { pinned = null; });
  // The ridge is rebuilt only when the scroll moves it by a minute or more.
  var drawnAt = -1;
  function dayScroll() {
    if (reduce.matches) { if (drawnAt !== T1) { drawnAt = T1; drawRidge(T1); } return; }
    if (!dayPinned() || ridgeDrag) return;
    var r = day.getBoundingClientRect(), span = r.height - innerHeight;
    var at = Math.round(T0 + (T1 - T0) * clamp(-r.top / (span * 0.8), 0, 1));
    if (at === drawnAt) return;
    drawnAt = at; drawRidge(at);
  }
  // The ridge is also a toy: drag along it and the day plays to that minute.
  // It snaps to each meal once its climb is done.
  var ridgeEl = $('#ridge'), ridgeHint = $('#ridge-hint'), ridgeDrag = false;
  function ridgeAt(e) {
    var r = ridgeEl.getBoundingClientRect(), w = r.width - 8, x = clamp(e.clientX - r.left, 0, w);
    var t = T0 + x / w * (T1 - T0);
    DAY.meals.forEach(function (m) { var mt = mins(m.t) + 50; if (Math.abs((mt - T0) / (T1 - T0) * w - x) < 12) t = mt; });
    drawnAt = Math.round(t); drawRidge(drawnAt);
  }
  ridgeEl.addEventListener('pointerdown', function (e) {
    if (e.button) return;
    ridgeDrag = true; ridgeEl.classList.add('is-drag'); ridgeHint.classList.add('is-gone');
    if (ridgeEl.setPointerCapture) ridgeEl.setPointerCapture(e.pointerId);
    ridgeAt(e);
  });
  ridgeEl.addEventListener('pointermove', function (e) { if (ridgeDrag) ridgeAt(e); });
  ['pointerup', 'pointercancel'].forEach(function (n) { ridgeEl.addEventListener(n, function () { ridgeDrag = false; ridgeEl.classList.remove('is-drag'); }); });
  // The knob breathes once when the chart is in view, to say it can be held.
  if ('IntersectionObserver' in window && !reduce.matches) new IntersectionObserver(function (es, o) {
    if (!es[0].isIntersecting) return;
    o.disconnect();
    setTimeout(function () { ridgeEl.classList.add('is-breathe'); setTimeout(function () { ridgeEl.classList.remove('is-breathe'); }, 950); }, 400);
  }, { threshold: .6 }).observe(ridgeEl);

  // Without the pinned scene (phones), the day plays once when it comes into view.
  var dayPlayed = false;
  function dayPlay() {
    if (dayPlayed || dayPinned() || reduce.matches) return;
    var r = $('#ridge').getBoundingClientRect();
    if (r.top > innerHeight * 0.8) return;
    dayPlayed = true;
    var t0 = performance.now();
    (function f(n) { var k = clamp((n - t0) / 3200, 0, 1); drawRidge(T0 + (T1 - T0) * ease(k)); if (k < 1) requestAnimationFrame(f); })(t0);
  }

  /* ---------- 4. Ways in ---------- */
  var typed = $('#typed'), typedDone = false;
  function typeIt() {
    if (typedDone || reduce.matches) return;
    var r = typed.getBoundingClientRect();
    if (r.top > innerHeight * 0.85 || r.bottom < 0) return;
    typedDone = true;
    var s = typed.textContent, i = 0;
    typed.textContent = '';
    (function f() { typed.textContent = s.slice(0, ++i); if (i < s.length) setTimeout(f, 38 + Math.random() * 50); })();
  }

  /* ---------- 6. Progress ---------- */
  function bars() {
    var box = $('#bars'), max = Math.max(DAY.goal, Math.max.apply(null, DAY.week.map(function (d) { return d.kcal; }))) * 1.06;
    box.textContent = '';
    var wd = new Intl.DateTimeFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { weekday: 'short' });
    var dl = new Intl.DateTimeFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { weekday: 'long', day: 'numeric', month: 'long' });
    DAY.week.forEach(function (d, i) {
      var c = document.createElement('button');
      c.type = 'button';
      c.className = 'bar-d' + (d.kcal > DAY.goal ? ' is-over' : '');
      var day = new Date(d.d + 'T12:00:00'), state = T(d.kcal > DAY.goal ? 'prog.over' : 'prog.under');
      c.setAttribute('aria-label', fill(T('prog.bar'), { day: dl.format(day), kcal: fmt(d.kcal), state: state }));
      c.addEventListener('pointerenter', function () { weekDay(d, day, state); });
      c.addEventListener('focus', function () { weekDay(d, day, state); });
      c.addEventListener('click', function () { weekDay(d, day, state); });
      c.addEventListener('pointerleave', weekAvg);
      c.addEventListener('blur', weekAvg);
      c.style.setProperty('--i', i);
      var b = document.createElement('i');
      b.style.setProperty('--h', (d.kcal / max * 100).toFixed(1) + '%');
      var s = document.createElement('span');
      s.textContent = wd.format(new Date(d.d + 'T12:00:00')).replace('.', '');
      c.appendChild(b); c.appendChild(s); box.appendChild(c);
    });
    var gl = document.createElement('div');
    gl.className = 'goal-line';
    gl.style.bottom = 'calc(' + (DAY.goal / max * 100).toFixed(1) + '% * (1 - 26px / 100%) + 26px)';
    box.appendChild(gl);
    var logged = DAY.week.filter(function (d) { return d.kcal > 0; });
    var avg = logged.reduce(function (a, d) { return a + d.kcal; }, 0) / logged.length;
    figure($('#p-avg'), fmt(Math.round(avg)));
    var df = new Intl.DateTimeFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { day: 'numeric', month: 'long' });
    var a = new Date(DAY.week[0].d + 'T12:00:00'), z = new Date(DAY.week[DAY.week.length - 1].d + 'T12:00:00');
    weekTxt = [fmt(Math.round(avg)), fill(T('prog.avg'), { range: df.formatRange ? df.formatRange(a, z) : df.format(a) + '–' + df.format(z) })];
    $('#p-avg').nextElementSibling.textContent = weekTxt[1];
  }
  // Pointing at a day shows that day; leaving shows the week again.
  var weekTxt = null;
  function weekDay(d, day, state) {
    $('#bars').classList.add('is-picking');
    $$('.bar-d').forEach(function (b) { b.classList.remove('is-hot'); });
    $$('.bar-d')[DAY.week.indexOf(d)].classList.add('is-hot');
    roll($('#p-avg'), fmt(d.kcal));
    $('#p-avg').nextElementSibling.textContent = fill(T('prog.day'), { day: new Intl.DateTimeFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { weekday: 'long', day: 'numeric', month: 'long' }).format(day), state: state });
  }
  function weekAvg() {
    $('#bars').classList.remove('is-picking');
    $$('.bar-d').forEach(function (b) { b.classList.remove('is-hot'); });
    if (!weekTxt) return;
    roll($('#p-avg'), weekTxt[0]); $('#p-avg').nextElementSibling.textContent = weekTxt[1];
  }
  function weight() {
    var svg = $('#wline'), W = svg.clientWidth || 400, H = svg.clientHeight || 200;
    svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
    svg.textContent = '';
    var ws = DAY.weights, t = function (s) { return new Date(s + 'T12:00:00').getTime(); };
    var a = t(ws[0][0]), z = t(ws[ws.length - 1][0]);
    var lo = Math.min.apply(null, ws.map(function (w) { return w[1]; })) - 0.4, hi = Math.max.apply(null, ws.map(function (w) { return w[1]; })) + 0.4;
    var X = function (s) { return 6 + (t(s) - a) / (z - a) * (W - 12); }, Y = function (k) { return 10 + (hi - k) / (hi - lo) * (H - 40); };
    ws.forEach(function (w) { el('circle', { class: 'w-d', cx: X(w[0]), cy: Y(w[1]), r: 3 }, svg); });
    // The trend: a moving average, so one salty evening does not move it.
    var d = '';
    ws.forEach(function (w, i) {
      var s = ws.slice(Math.max(0, i - 2), i + 3), m = s.reduce(function (q, v) { return q + v[1]; }, 0) / s.length;
      d += (i ? ' L' : 'M') + X(w[0]).toFixed(1) + ' ' + Y(m).toFixed(1);
    });
    var p = el('path', { class: 'w-l', d: d }, svg);
    var last = ws[ws.length - 1];
    el('circle', { class: 'w-e', cx: X(last[0]), cy: Y(last[1]), r: 5 }, svg);
    var mf = new Intl.DateTimeFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { month: 'short' });
    [ws[0][0], ws[Math.floor(ws.length / 2)][0], last[0]].forEach(function (s, i) {
      el('text', { class: 'w-lab', x: X(s), y: H - 6, 'text-anchor': ['start', 'middle', 'end'][i] }, svg).textContent = mf.format(new Date(s + 'T12:00:00')).replace('.', '');
    });
    if (!reduce.matches && 'IntersectionObserver' in window) {
      var len = p.getTotalLength();
      p.style.strokeDasharray = len; p.style.strokeDashoffset = len;
      new IntersectionObserver(function (es, o) {
        if (!es[0].isIntersecting) return;
        o.disconnect();
        p.style.transition = 'stroke-dashoffset 1.6s cubic-bezier(.65,0,.35,1)';
        p.style.strokeDashoffset = 0;
      }, { threshold: .4 }).observe(svg);
    }
    var df = new Intl.DateTimeFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { day: 'numeric', month: 'long' });
    figure($('#p-kg'), fmt(last[1], 1));
    $('#p-trend').textContent = fill(T('prog.trend'), { kg: fmt(ws[0][1] - last[1], 1), from: df.format(new Date(ws[0][0] + 'T12:00:00')) });
    svg.setAttribute('aria-label', fill(T('prog.walt'), { a: fmt(ws[0][1], 1), z: fmt(last[1], 1) }));
  }
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(function (es, o) {
      if (es[0].isIntersecting) { $('#bars').classList.add('is-in'); o.disconnect(); }
    }, { threshold: .35 }).observe($('#bars'));
  } else $('#bars').classList.add('is-in');

  /* ---------- Wiring ---------- */
  function everything() {
    DAY = DAYS[lang()] || DAYS.en; horizon();
    readout(hero.classList.contains('is-read') ? data().kcal : +rKcal.textContent.replace(/\D/g, '') || 0, hero.classList.contains('is-read'));
    buildParts();
    $$('.part', partsEl).forEach(function (li) { if (hero.classList.contains('is-read')) li.classList.add('is-on'); });
    photo.alt = T('plate.' + plate + '.alt');
    apartBuild(); kin();
    screens(); dayText(); drawRidge(dayPinned() && !reduce.matches ? T0 : T1); drawnAt = -1; dayScroll(); bars(); weight();
    $('#ridge').setAttribute('aria-label', fill(T('day.alt'), { a: DAY.meals[0].t, b: DAY.meals[1].t, left: fmt(DAY.goal - DAY.meals.reduce(function (s, m) { return s + m.kcal; }, 0)), now: DAY.now }));
  }


  /* ---------- Headlines arrive word by word ---------- */
  var kinIO = 'IntersectionObserver' in window && !reduce.matches ? new IntersectionObserver(function (es) {
    es.forEach(function (e) { if (e.isIntersecting || e.boundingClientRect.bottom < 0) { e.target.classList.add('is-in'); kinIO.unobserve(e.target); } });
  }, { rootMargin: '0px 0px -10% 0px' }) : null;
  function kin() {
    $$('.kin').forEach(function (h) {
      var text = h.textContent.replace(/\s+/g, ' ').trim();
      if (h.getAttribute('aria-label') === text && h.querySelector('.w')) return;
      h.setAttribute('aria-label', text);
      h.textContent = '';
      text.split(' ').forEach(function (word, i) {
        var o = document.createElement('span'), s = document.createElement('span');
        o.className = 'w'; o.setAttribute('aria-hidden', 'true');
        s.textContent = word; s.style.setProperty('--i', i);
        o.appendChild(s); h.appendChild(o); h.appendChild(document.createTextNode(' '));
      });
      if (kinIO && !h.classList.contains('is-in')) kinIO.observe(h); else h.classList.add('is-in');
    });
  }

  /* ---------- The pointer is a viewfinder over the plate ---------- */
  var aim = $('#aim');
  if (fine && !reduce.matches) {
    var ax = -100, ay = -100, tx = -100, ty = -100, aimRaf = 0, hot = null;
    var aimLoop = function () {
      ax += (tx - ax) * 0.22; ay += (ty - ay) * 0.22;
      aim.style.transform = 'translate(' + ax.toFixed(1) + 'px,' + ay.toFixed(1) + 'px)';
      aimRaf = Math.abs(tx - ax) + Math.abs(ty - ay) > 0.3 ? requestAnimationFrame(aimLoop) : 0;
    };
    var aimOff = function () {
      hero.classList.remove('is-aiming'); aim.classList.remove('is-on', 'is-lock');
      if (hot) hot.classList.remove('is-hot'); hot = null;
    };
    hero.addEventListener('pointermove', function (e) {
      var hr = hero.getBoundingClientRect();
      var over = e.target.closest('a, button, .hero-copy, .readout, .plates');
      if (!hero.classList.contains('is-read') || over || e.clientY < 76) return aimOff();
      hero.classList.add('is-aiming'); aim.classList.add('is-on');
      var x = e.clientX, y = e.clientY, best = 64, pick = null, px = 0, py = 0;
      $$('.part', partsEl).forEach(function (li) {
        if (li.hidden) return;
        var r = li.getBoundingClientRect(), dx = li.classList.contains('is-left') ? r.right : r.left, dy = r.top + r.height / 2;
        var dd = Math.hypot(dx - x, dy - y);
        if (dd < best) { best = dd; pick = li; px = dx; py = dy; }
      });
      if (hot !== pick) {
        if (hot) hot.classList.remove('is-hot');
        hot = pick;
        if (hot) {
          hot.classList.add('is-hot');
          aim.querySelector('b').textContent = fmt(+hot.dataset.k) + ' kcal';
          aim.classList.toggle('is-flip', !hot.classList.contains('is-left'));
        }
      }
      aim.classList.toggle('is-lock', !!pick);
      tx = (pick ? px : x) - hr.left; ty = (pick ? py : y) - hr.top;
      if (!aimRaf) aimRaf = requestAnimationFrame(aimLoop);
    });
    hero.addEventListener('pointerleave', aimOff);
  }

  /* ---------- On a phone: hold the plate, then drag a lens over it ---------- */
  // A press of 180 ms on the photo starts the lens; until then the page
  // scrolls as usual. Inside the ring the photo, outside it the dots; a part
  // the ring reaches lights up, with a short buzz where the phone has one.
  var tHint = $('#touch-hint'), lens = null, lensT = 0, lensHot = null;
  if (!fine && 'ontouchstart' in window && !reduce.matches) {
    hero.classList.add('has-lens');
    var lensAt = function (x, y) {
      var sr = stage.getBoundingClientRect(), pr = photo.getBoundingClientRect(), g = geom();
      var sx = (x - sr.left) * stage.clientWidth / sr.width, sy = (y - sr.top) * stage.clientHeight / sr.height;
      var lx = (x - pr.left) * g.dw / pr.width, ly = (y - pr.top) * g.dh / pr.height, R = 100;
      var mask = 'radial-gradient(circle at ' + lx.toFixed(1) + 'px ' + ly.toFixed(1) + 'px, #000 ' + (R - .5) + 'px, transparent ' + R + 'px)';
      photo.style.webkitMaskImage = photo.style.maskImage = mask;
      ctx.clearRect(0, 0, grid.w, grid.h);
      ctx.save(); ctx.beginPath(); ctx.rect(0, 0, grid.w, grid.h); ctx.arc(sx, sy, R, 0, 6.2832, true); ctx.clip('evenodd');
      ctx.drawImage(grid.dots, 0, 0, grid.w, grid.h); ctx.restore();
      ctx.strokeStyle = '#6BCB97'; ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(sx, sy, R, 0, 6.2832); ctx.stroke();
      var pick = null, best = R;
      $$('.part', partsEl).forEach(function (li) {
        if (li.hidden) return;
        var q = project(+li.dataset.x, +li.dataset.y), dd = Math.hypot(q.x - sx, q.y - sy);
        if (dd < best) { best = dd; pick = li; }
      });
      if (pick !== lensHot) {
        if (lensHot) lensHot.classList.remove('is-hot');
        lensHot = pick;
        if (pick) { pick.classList.add('is-hot'); if (navigator.vibrate) navigator.vibrate(6); }
      }
    };
    var lensEnd = function () {
      clearTimeout(lensT);
      if (!lens || !lens.on) { lens = null; return; }
      lens = null; hero.classList.remove('is-lens');
      if (lensHot) lensHot.classList.remove('is-hot'); lensHot = null;
      photo.style.webkitMaskImage = photo.style.maskImage = 'none';
      if (grid) ctx.clearRect(0, 0, grid.w, grid.h);
    };
    stage.parentNode.addEventListener('touchstart', function (e) {
      if (e.touches.length !== 1 || !grid || !hero.classList.contains('is-read') || e.target.closest('a, button')) return;
      var t = e.touches[0], sr = stage.getBoundingClientRect();
      if (t.clientY > sr.bottom || t.clientY < sr.top) return;
      lens = { x: t.clientX, y: t.clientY, on: false };
      lensT = setTimeout(function () {
        if (!lens) return;
        lens.on = true; hero.classList.add('is-lens', 'lens-used');
        lensAt(lens.x, lens.y);
      }, 180);
    }, { passive: true });
    hero.addEventListener('touchmove', function (e) {
      if (!lens) return;
      var t = e.touches[0];
      if (!lens.on) { if (Math.hypot(t.clientX - lens.x, t.clientY - lens.y) > 10) { clearTimeout(lensT); lens = null; } return; }
      if (e.cancelable) e.preventDefault();
      lensAt(t.clientX, t.clientY);
    }, { passive: false });
    hero.addEventListener('touchend', lensEnd); hero.addEventListener('touchcancel', lensEnd);
  }

  /* ---------- Smooth scroll, for mouse and trackpad only ---------- */
  var lenis = null;
  // Inertial scroll only where the machine can carry it; native scroll is better than a stuttering one.
  if (window.Lenis && window.ResizeObserver && fine && strong && !reduce.matches) {
    lenis = new window.Lenis({ lerp: 0.11 });
    (function loop(t) { if (!lenis) return; lenis.raf(t); requestAnimationFrame(loop); })(performance.now());
    document.addEventListener('click', function (e) {
      var a = e.target.closest('a[href^="#"]');
      if (!a || a.classList.contains('skip')) return;
      var h = a.getAttribute('href'), target = h === '#top' ? 0 : document.getElementById(h.slice(1));
      if (target == null) return;
      e.preventDefault();
      lenis.scrollTo(target, { offset: h === '#top' ? 0 : -72 });
      history.pushState(null, '', h);
    });
  }

  horizon();
  // The barcode's laser sweeps once when it comes into view and again on a
  // pointer or a tap; the digits light up when it has read them.
  var code = $('.way-code');
  function zap() {
    if (reduce.matches) return;
    code.classList.remove('is-scan', 'is-hit'); void code.offsetWidth; code.classList.add('is-scan');
  }
  code.addEventListener('animationend', function () { code.classList.add('is-hit'); setTimeout(function () { code.classList.remove('is-hit'); }, 260); });
  code.addEventListener('pointerenter', zap); code.addEventListener('click', zap);
  if ('IntersectionObserver' in window) new IntersectionObserver(function (es, o) { if (es[0].isIntersecting) { zap(); o.disconnect(); } }, { threshold: .6 }).observe(code);
  // The APK's version, size and date, from the latest GitHub release. Without
  // the network the buttons simply keep their label.
  function release() {
    if (!window.fetch) return;
    fetch('https://api.github.com/repos/Nikityyy/kalorat/releases/latest').then(function (r) { return r.ok ? r.json() : null; }).then(function (r) {
      if (!r) return;
      var a = (r.assets || []).find(function (x) { return /\.apk$/.test(x.name); });
      if (!a) return;
      rel = { v: r.tag_name, mb: a.size / 1048576, d: new Date(r.published_at) };
      relText(); rollers();
    }).catch(function () {});
  }
  var rel = null;
  function relText() {
    if (!rel) return;
    var df = new Intl.DateTimeFormat(lang() === 'de' ? 'de-AT' : 'en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
    $$('[data-rel]').forEach(function (n) { n.textContent = rel.v + ' · ' + fmt(rel.mb, 1) + ' MB · ' + df.format(rel.d); n.hidden = false; });
  }
  // Labels roll on hover: the line slides up and its other side comes in
  // from below. The Android button's other side is the live release.
  function rollers() {
    $$('.btn [data-i18n], .link [data-i18n], .bar-get [data-i18n]').forEach(function (s) {
      if (!s.parentNode.classList.contains('lr')) {
        var w = document.createElement('span'); w.className = 'lr';
        s.parentNode.insertBefore(w, s); w.appendChild(s);
      }
      var k = s.getAttribute('data-i18n'), label = s.textContent, alt = label;
      if (/^cta\.android/.test(k) && rel) alt = rel.v + ' · ' + fmt(rel.mb, 1) + ' MB';
      else if (k === 'cta.iphone') alt = T('cta.iphone.roll');
      s.setAttribute('data-alt', alt.length > label.length + 2 ? label : alt);
    });
  }
  release();
  rollers();
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(placeParts);
  everything();
  startHero();
  // A language switch reads the plate again: each language is its own run
  // of the app, so the numbers differ a little, and the line says so.
  var rRun = $('#r-run'), runT = 0;
  function langRun() {
    rRun.textContent = fill(T('readout.run'), { kcal: fmt(data().kcal) });
    rRun.classList.add('is-on');
    clearTimeout(runT); runT = setTimeout(function () { rRun.classList.remove('is-on'); }, 2800);
    if (!reduce.matches && grid && hero.getBoundingClientRect().bottom > 0) read();
  }
  document.addEventListener('kalorat:lang', function () { lastEvent = -1; everything(); relText(); rollers(); langRun(); });
  var ticking = false;
  addEventListener('scroll', function () {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(function () { ticking = false; barState(); apartScroll(); handoff(); dayScroll(); carryOn(); howScrub(); dayPlay(); typeIt(); drawHorizon(); });
  }, { passive: true });
  var rt = 0;
  addEventListener('resize', function () {
    geomC = null;
    clearTimeout(rt);
    rt = setTimeout(function () { handOff(); scrubMode(); h2From = null; carryOff(); placeParts(); apartLayout(); aDotsImg = null; apartHoles(); handoff(); drawRidge(T1); drawnAt = -1; dayScroll(); weight(); if (grid && !hero.classList.contains('is-read')) read(); }, 120);
  });
  // The ridge draws itself as it rises into view.
  var hz = $('.horizon');
  function drawHorizon() {
    if (reduce.matches) { hz.style.setProperty('--draw', 0); return; }
    var r = hz.getBoundingClientRect();
    hz.style.setProperty('--draw', (1 - clamp((innerHeight - r.top) / (innerHeight * 0.55), 0, 1)).toFixed(3));
  }
  // The plate leans a little towards the pointer.
  if (matchMedia('(hover: hover) and (pointer: fine)').matches) {
    hero.addEventListener('pointermove', function (e) {
      if (reduce.matches) return;
      var x = e.clientX / innerWidth - .5, y = e.clientY / innerHeight - .5;
      stage.style.setProperty('--px', (-x * 18).toFixed(1) + 'px');
      stage.style.setProperty('--py', (-y * 12).toFixed(1) + 'px');
    });
    hero.addEventListener('pointerleave', function () { stage.style.setProperty('--px', '0px'); stage.style.setProperty('--py', '0px'); });
  }
  /* ---------- The camera keeps reading after the plate ---------- */
  // On a mouse, four corners trail the pointer below the teardown and close
  // around what can be read: a meal on the ridge and the tray show their
  // biggest parts, the barcode fires its laser, a bar or a button is framed.
  // The native pointer stays.
  if (fine && !reduce.matches) {
    var vf = document.createElement('div'), vfB = document.createElement('b');
    vf.className = 'vf'; vf.setAttribute('aria-hidden', 'true');
    for (var vi = 0; vi < 4; vi++) vf.appendChild(document.createElement('i'));
    vf.appendChild(vfB); document.body.appendChild(vf);
    var vx = 0, vy = 0, vw = 28, vh = 28, wx = 0, wy = 0, ww = 28, wh = 28, vRaf = 0, vOn = false, vT = null;
    var vLoop = function () {
      vx += (wx - vx) * .2; vy += (wy - vy) * .2; vw += (ww - vw) * .2; vh += (wh - vh) * .2;
      vf.style.transform = 'translate(' + vx.toFixed(1) + 'px,' + vy.toFixed(1) + 'px)';
      vf.style.width = vw.toFixed(1) + 'px'; vf.style.height = vh.toFixed(1) + 'px';
      vRaf = Math.abs(wx - vx) + Math.abs(wy - vy) + Math.abs(ww - vw) + Math.abs(wh - vh) > .4 ? requestAnimationFrame(vLoop) : 0;
    };
    var top3 = function (key) {
      var d = MEALS[key] && (MEALS[key][lang()] || MEALS[key].en);
      if (!d) return [];
      return d.parts.slice().sort(function (a, b) { return b.k - a.k; }).slice(0, 3).map(function (p) { return p.n + '  ' + fmt(p.g) + ' g'; });
    };
    var vLabel = function (lines) {
      vfB.textContent = '';
      lines.forEach(function (l) { var s = document.createElement('span'); s.textContent = l; vfB.appendChild(s); });
      vf.classList.toggle('has-label', lines.length > 0);
    };
    var vHide = function () { if (vOn) { vOn = false; vf.classList.remove('is-on', 'is-lock'); vT = null; } };
    document.addEventListener('pointermove', function (e) {
      if (e.pointerType !== 'mouse') return vHide();
      var t = e.target;
      // The hero and the teardown have their own instruments.
      if (!t.closest || t.closest('.hero, .apart, .bar, .free')) return vHide();
      var hit = t.closest('.r-pin, .bar-d, .way-code, .way-photo, .btn');
      if (hit !== vT) {
        vT = hit;
        if (!hit) vLabel([]);
        else if (hit.classList.contains('r-pin')) vLabel(top3(DAY.meals[$$('.r-pin', ridge).indexOf(hit)].plate));
        else if (hit.classList.contains('way-code')) { vLabel([$('.num', hit).textContent]); zap(); }
        else if (hit.classList.contains('way-photo')) vLabel(top3('tray'));
        else vLabel([]);
      }
      vf.classList.add('is-on'); vOn = true;
      vf.classList.toggle('is-lock', !!hit);
      if (hit) {
        var r = (hit.classList.contains('r-pin') ? hit.querySelector('image') : hit).getBoundingClientRect(), pad = hit.classList.contains('btn') ? 6 : 8;
        wx = r.left - pad; wy = r.top - pad; ww = r.width + 2 * pad; wh = r.height + 2 * pad;
      } else { ww = wh = 28; wx = e.clientX + 14; wy = e.clientY + 14; }
      if (!vOn || !vRaf) vRaf = requestAnimationFrame(vLoop);
    });
    document.addEventListener('pointerleave', vHide);
    addEventListener('scroll', function () { if (vT) vHide(); }, { passive: true });
  }

  // The white half's main objects arrive the way the plate did: a scan line
  // runs down them, above it the thing itself, below it still dots.
  if ('IntersectionObserver' in window && !reduce.matches && strong) {
    var scanIO = new IntersectionObserver(function (es) {
      es.forEach(function (e) {
        if (!e.isIntersecting) return;
        scanIO.unobserve(e.target);
        var n = e.target, t0 = performance.now();
        n.classList.add('is-scanning');
        (function f(t) {
          var k = clamp((t - t0) / 650, 0, 1);
          n.style.setProperty('--scan', (ease(k) * 104 - 2).toFixed(1) + '%');
          if (k < 1) requestAnimationFrame(f); else n.classList.remove('is-scanning', 'scan-wait');
        })(t0);
      });
    }, { threshold: .3 });
    $$('.ridge, .ways-list, .bars, .wline').forEach(function (n) { n.classList.add('scan-wait'); scanIO.observe(n); });
  }

  /* ---------- 7. Free: the 0 € can be read ---------- */
  // The figure is set in dots, like the plate before its scan. The pointer,
  // or a held finger, is the ring: inside it the type is solid, the dots at
  // its edge step aside, and the ring names one true thing that costs nothing.
  var fScan = $('#free-scan'), fCv = $('#free-cv'), fZero = $('.free-zero'), fTag = $('#free-tag'), fHint = $('#free-hint');
  var fx = null;
  function freeBuild() {
    if (reduce.matches || !fCv.getContext) return;
    if (!fine) fHint.textContent = T('free.hint.touch');
    var r = fZero.getBoundingClientRect(), sr = fScan.getBoundingClientRect();
    if (!r.width) return;
    var cs = getComputedStyle(fZero), W = Math.ceil(sr.width), H = Math.ceil(r.height + 40), dpr = strong ? Math.min(devicePixelRatio || 1, 2) : 1;
    fCv.width = W * dpr; fCv.height = H * dpr; fCv.style.width = W + 'px'; fCv.style.height = H + 'px';
    fCv.style.top = (r.top - sr.top - 20) + 'px';
    // The type, drawn once, to sample the dots from and to show inside the ring.
    var type = document.createElement('canvas'); type.width = W * dpr; type.height = H * dpr;
    var tc = type.getContext('2d');
    tc.setTransform(dpr, 0, 0, dpr, 0, 0);
    tc.font = cs.fontWeight + ' ' + cs.fontSize + ' ' + cs.fontFamily;
    tc.fillStyle = cs.color; tc.textBaseline = 'alphabetic';
    if ('letterSpacing' in tc) tc.letterSpacing = cs.letterSpacing;
    // The baseline that centres the glyphs' ink in the text box.
    var m = tc.measureText(fZero.textContent), base = 20 + r.height / 2 + ((m.actualBoundingBoxAscent || r.height * .7) - (m.actualBoundingBoxDescent || 0)) / 2;
    tc.fillText(fZero.textContent, r.left - sr.left, base);
    var px = tc.getImageData(0, 0, type.width, type.height).data, pitch = W < 700 ? 6 : 8, dots = [];
    for (var y = pitch / 2; y < H; y += pitch) for (var x = pitch / 2; x < W; x += pitch) {
      if (px[((Math.round(y * dpr) * type.width) + Math.round(x * dpr)) * 4 + 3] > 140) dots.push({ x: x, y: y, ox: 0, oy: 0, vx: 0, vy: 0 });
    }
    var dot = document.createElement('canvas'), ds = Math.ceil(pitch * .62 * dpr);
    dot.width = dot.height = ds;
    var dc = dot.getContext('2d'); dc.fillStyle = cs.color; dc.beginPath(); dc.arc(ds / 2, ds / 2, ds / 2, 0, 6.2832); dc.fill();
    fx = { W: W, H: H, dpr: dpr, type: type, dots: dots, dot: dot, ds: ds / dpr, ctx: fCv.getContext('2d'), px: -1e4, py: -1e4, raf: 0, on: false, x0: r.left - sr.left, tw: m.width };
    fScan.classList.add('is-dots');
    freeDraw();
  }
  function freeDraw() {
    var f = fx, c = f.ctx, R = Math.min(130, f.H * .42), moving = false;
    c.setTransform(f.dpr, 0, 0, f.dpr, 0, 0);
    c.clearRect(0, 0, f.W, f.H);
    var ry = f.py;
    f.dots.forEach(function (d) {
      var dx = d.x - f.px, dy = d.y - ry, dd = Math.hypot(dx, dy), tx = 0, ty = 0;
      // Dots in the ring's band are pushed out to its edge.
      if (f.on && dd < R + 36) { var k = (R + 36 - dd) / (R + 36); tx = dx / (dd || 1) * k * 30; ty = dy / (dd || 1) * k * 30; }
      d.vx = (d.vx + (tx - d.ox) * .12) * .78; d.vy = (d.vy + (ty - d.oy) * .12) * .78;
      d.ox += d.vx; d.oy += d.vy;
      if (Math.abs(d.vx) + Math.abs(d.vy) + Math.abs(tx - d.ox) + Math.abs(ty - d.oy) > .05) moving = true;
      if (f.on && dd < R) return;
      c.drawImage(f.dot, d.x + d.ox - f.ds / 2, d.y + d.oy - f.ds / 2, f.ds, f.ds);
    });
    if (f.on) {
      c.save(); c.beginPath(); c.arc(f.px, ry, R, 0, 6.2832); c.clip();
      c.drawImage(f.type, 0, 0, f.W, f.H); c.restore();
      c.strokeStyle = 'rgba(255,255,255,.85)'; c.lineWidth = 1; c.beginPath(); c.arc(f.px, ry, R, 0, 6.2832); c.stroke();
    }
    f.raf = moving || f.on ? requestAnimationFrame(freeDraw) : 0;
  }
  function freeAt(x, y) {
    var f = fx, cr = fCv.getBoundingClientRect();
    f.px = x - cr.left; f.py = y - cr.top;
    var inside = f.px > f.x0 - 40 && f.px < f.x0 + f.tw + 40 && f.py > 0 && f.py < f.H;
    if (!inside) return freeOff();
    if (!f.on) { f.on = true; fScan.classList.add('is-reading', 'was-read'); }
    // The ring names one fact for each quarter of the figure.
    var facts = T('free.f'), q = clamp(Math.floor((f.px - f.x0) / f.tw * facts.length), 0, facts.length - 1);
    if (fTag.textContent !== facts[q]) fTag.textContent = facts[q];
    var R = Math.min(130, f.H * .42);
    fTag.style.transform = 'translate(' + (cr.left - fScan.getBoundingClientRect().left + f.px + R * .72).toFixed(0) + 'px,' + (cr.top - fScan.getBoundingClientRect().top + f.py + R * .72).toFixed(0) + 'px)';
    if (!f.raf) f.raf = requestAnimationFrame(freeDraw);
  }
  function freeOff() {
    if (!fx || !fx.on) return;
    fx.on = false; fScan.classList.remove('is-reading');
    if (!fx.raf) fx.raf = requestAnimationFrame(freeDraw);
  }
  if (!reduce.matches && window.PointerEvent) {
    fScan.addEventListener('pointermove', function (e) { if (fx && (e.pointerType === 'mouse' || e.pressure > 0)) freeAt(e.clientX, e.clientY); });
    fScan.addEventListener('pointerdown', function (e) { if (fx) freeAt(e.clientX, e.clientY); });
    fScan.addEventListener('pointerleave', freeOff);
    fScan.addEventListener('pointerup', function (e) { if (e.pointerType !== 'mouse') freeOff(); });
    fScan.addEventListener('pointercancel', freeOff);
    // Built when the section comes near, not during the plate's arrival.
    var fNear = false, fGo = function () { if (fNear) freeBuild(); };
    var fStart = function () { fNear = true; if (document.fonts && document.fonts.ready) document.fonts.ready.then(freeBuild); else freeBuild(); };
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (es, o) { if (es[0].isIntersecting) { o.disconnect(); fStart(); } }, { rootMargin: '600px 0px' }).observe(fScan);
    } else fStart();
    document.addEventListener('kalorat:lang', function () { setTimeout(fGo, 0); });
    var frt = 0;
    addEventListener('resize', function () { clearTimeout(frt); frt = setTimeout(fGo, 150); });
  }

  barState(); dayPlay(); typeIt(); drawHorizon();
})();
