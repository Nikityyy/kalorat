// Builds assets/lp/meals.js from Kalorat's own analysis of the three photos
// (tools/data/analysis.json, made by running the app's GeminiService on them),
// where each part sits on the photo (positions.json) and the photo credits.
// The contour lines of each plate's "calorie terrain" are computed here, once,
// so the page needs no contour library.
//
//   npm i d3-contour@4 && node tools/build-meals.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { contours } from 'd3-contour';

const here = path.dirname(fileURLToPath(import.meta.url));
const read = (f) => JSON.parse(fs.readFileSync(path.join(here, 'data', f), 'utf8'));
const analysis = read('analysis.json'), positions = read('positions.json'), credits = read('credits.json');

// Per photo: size, how the page frames it (the point kept in view and a zoom
// over "cover"), the colour of the ground at its edge, and how wide one hill is.
const PHOTOS = {
  breakfast: { w: 3000, h: 2000, focus: [0.36, 0.48], zoom: 1.75, ground: '#DCE5EC', spread: 0.052, mobile: [0.34, 0.47, 1.35] },
  lunch:     { w: 3000, h: 2000, focus: [0.00, 0.50], zoom: 1.0,  ground: '#B8C8D1', spread: 0.075, mobile: [0.2, 0.5, 1.0] },
  dinner:    { w: 3000, h: 3000, focus: [0.50, 0.49], zoom: 1.12, ground: '#E0E3E7', spread: 0.07, mobile: [0.5, 0.49, 1.0] },
};
const TIMES = { breakfast: '08:12', lunch: '12:41', dinner: '19:05' };
const VB = 1000; // the SVG's viewBox is 1000 wide

// Gemini sometimes answers per mille or per cent instead of fractions.
const frac = (v) => v == null ? null : v > 100 ? v / 1000 : v > 1 ? v / 100 : v;
const r1 = (v) => Math.round(v * 10) / 10;

function inside([x, y], ring) {
  let c = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i], [xj, yj] = ring[j];
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) c = !c;
  }
  return c;
}

// Douglas-Peucker: drops points a viewer cannot see (within eps units).
function simplify(pts, eps) {
  if (pts.length < 4) return pts;
  const keep = new Uint8Array(pts.length); keep[0] = keep[pts.length - 1] = 1;
  const stack = [[0, pts.length - 1]];
  while (stack.length) {
    const [a, b] = stack.pop(); let idx = -1, max = eps;
    const [ax, ay] = pts[a], [bx, by] = pts[b], dx = bx - ax, dy = by - ay, len = Math.hypot(dx, dy) || 1;
    for (let i = a + 1; i < b; i++) { const d = Math.abs(dy * pts[i][0] - dx * pts[i][1] + bx * ay - by * ax) / len; if (d > max) { max = d; idx = i; } }
    if (idx > 0) { keep[idx] = 1; stack.push([a, idx], [idx, b]); }
  }
  return pts.filter((_, i) => keep[i]);
}
// A closed ring starts and ends on one point; simplify its two halves.
function simplifyRing(pts, eps) {
  const m = Math.floor(pts.length / 2);
  if (pts.length < 8) return pts;
  return simplify(pts.slice(0, m + 1), eps).concat(simplify(pts.slice(m), eps).slice(1));
}

function terrain(photo, parts) {
  const gw = 180, gh = Math.round(gw * photo.h / photo.w), field = new Float64Array(gw * gh);
  const sig = photo.spread * gw, seen = parts.filter((p) => p.x != null);
  for (let y = 0; y < gh; y++) for (let x = 0; x < gw; x++) {
    let v = 0;
    for (const p of seen) { const d2 = (x - p.x * gw) ** 2 + (y - p.y * gh) ** 2; v += p.k * Math.exp(-d2 / (2 * sig * sig)); }
    field[y * gw + x] = v;
  }
  const top = Math.max(...field), n = 12;
  const levels = Array.from({ length: n }, (_, i) => top * (0.05 + 0.9 * i / (n - 1)));
  const s = VB / gw, out = [];
  contours().size([gw, gh]).thresholds(levels)(field).forEach((c, lvl) => {
    c.coordinates.forEach((poly) => {
      const ring = poly[0];
      // The part this ring belongs to: the biggest summit inside it.
      let part = -1, best = -1;
      seen.forEach((p) => { if (p.k > best && inside([p.x * gw, p.y * gh], ring)) { best = p.k; part = parts.indexOf(p); } });
      const d = poly.map((rg) => 'M' + simplifyRing(rg.map(([x, y]) => [x * s, y * s]), 1.2).map(([x, y]) => `${Math.round(x)} ${Math.round(y)}`).join('L') + 'Z').join('');
      out.push([lvl, part, d]);
    });
  });
  return { levels: n, paths: out };
}

const MEALS = {};
for (const meal of Object.keys(PHOTOS)) {
  const photo = PHOTOS[meal], c = credits[meal];
  MEALS[meal] = { img: meal, w: photo.w, h: photo.h, focus: photo.focus, zoom: photo.zoom, mobile: photo.mobile, ground: photo.ground, vh: Math.round(VB * photo.h / photo.w), t: TIMES[meal],
    credit: { name: c.user, url: c.link } };
  for (const lang of ['en', 'de']) {
    const a = analysis[`${meal}.${lang}`], pos = positions[`${meal}.${lang}`];
    const parts = a.parts.map((p, i) => {
      const q = pos.find((x) => x.n === p.n) || pos[i] || {};
      return { n: p.n, g: Math.round(p.g), k: Math.round(p.k), x: frac(q.x), y: frac(q.y) };
    }).sort((p, q) => q.k - p.k);
    MEALS[meal][lang] = {
      name: a.name, kcal: Math.round(a.kcal), sure: Math.round((a.sure || 0) * 100), lo: Math.round(a.lo), hi: Math.round(a.hi),
      est: (a.estimates || []).map(Math.round), parts: parts.map((p) => ({ ...p, x: p.x == null ? null : r1(p.x * 1000) / 1000, y: p.y == null ? null : r1(p.y * 1000) / 1000 })),
      map: terrain(photo, parts),
    };
  }
}

const out = path.join(here, '..', 'assets', 'lp', 'meals.js');
fs.writeFileSync(out, '// Generated by tools/build-meals.mjs: Kalorat\'s own results for the three photos (one run per language), and their contour maps.\nwindow.KALORAT_MEALS = ' + JSON.stringify(MEALS) + ';\n');
console.log(out, (fs.statSync(out).size / 1024).toFixed(1) + ' KB');
for (const m of Object.keys(MEALS)) for (const l of ['en', 'de']) console.log(m, l, MEALS[m][l].kcal, MEALS[m][l].est, MEALS[m][l].map.paths.length, 'paths', MEALS[m][l].parts.map((p) => `${p.n}:${p.x},${p.y}`).join(' | '));
