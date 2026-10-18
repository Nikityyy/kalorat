// Decodes retail barcodes (EAN-13, EAN-8, UPC-A, UPC-E) from camera frames
// off the main thread with zxing-cpp compiled to WebAssembly.
//
// Messages in:  { id, bitmap, still } (ImageBitmap, transferred) or
//               { id, image: { data, width, height } } (RGBA, transferred)
//               still: a photo rather than a camera frame; every pass is
//               tried at once.
// Messages out: { type: 'ready', canvas } once the decoder is loaded, then
//               { type: 'result', id, text, format, box, aspect, ms } per
//               frame (text is null when nothing was found). box is
//               [left, top, right, bottom] of the code as fractions of the
//               frame, aspect the frame's width / height.
'use strict';
importScripts('zxing/zxing_reader.js');

var READER = {
  formats: ['EAN13', 'EAN8', 'UPCA', 'UPCE'],
  tryHarder: true,
  tryRotate: true, // 90° steps
  tryInvert: false,
  tryDownscale: true,
  maxNumberOfSymbols: 1,
};
// zxing reads lines within about ±15° of horizontal or vertical. Every other
// frame is also read tilted by ±30°, so codes at any angle are found.
var TILTS = [Math.PI / 6, -Math.PI / 6];

var hasCanvas = typeof OffscreenCanvas !== 'undefined';
var canvas = null;
var ctx = null;
var tiltCanvas = null;
var tiltCtx = null;
var frame = 0;

ZXingWASM.prepareZXingModule({
  overrides: {
    locateFile: function (path, prefix) {
      return path.endsWith('.wasm')
        ? new URL('zxing/zxing_reader.wasm', self.location.href).href
        : prefix + path;
    },
  },
  fireImmediately: true,
}).then(
  function () {
    self.postMessage({ type: 'ready', canvas: hasCanvas });
  },
  function (error) {
    self.postMessage({ type: 'error', message: String(error) });
  }
);

function imageFromBitmap(bitmap) {
  var w = bitmap.width;
  var h = bitmap.height;
  if (!canvas || canvas.width !== w || canvas.height !== h) {
    canvas = new OffscreenCanvas(w, h);
    ctx = canvas.getContext('2d', { willReadFrequently: true });
  }
  ctx.drawImage(bitmap, 0, 0);
  bitmap.close();
  return ctx.getImageData(0, 0, w, h);
}

function tiltedSize(image, angle) {
  var cos = Math.abs(Math.cos(angle));
  var sin = Math.abs(Math.sin(angle));
  return {
    w: Math.ceil(image.width * cos + image.height * sin),
    h: Math.ceil(image.width * sin + image.height * cos),
  };
}

function tilted(image, angle) {
  var size = tiltedSize(image, angle);
  var w = size.w;
  var h = size.h;
  if (!tiltCanvas || tiltCanvas.width !== w || tiltCanvas.height !== h) {
    tiltCanvas = new OffscreenCanvas(w, h);
    tiltCtx = tiltCanvas.getContext('2d', { willReadFrequently: true });
  }
  tiltCtx.setTransform(1, 0, 0, 1, 0, 0);
  tiltCtx.fillStyle = '#808080';
  tiltCtx.fillRect(0, 0, w, h);
  tiltCtx.translate(w / 2, h / 2);
  tiltCtx.rotate(angle);
  tiltCtx.drawImage(canvas, -image.width / 2, -image.height / 2);
  return tiltCtx.getImageData(0, 0, w, h);
}

async function read(image) {
  var results = await ZXingWASM.readBarcodes(image, READER);
  for (var i = 0; i < results.length; i++) {
    if (results[i].isValid && results[i].text) return results[i];
  }
  return null;
}

// The corners of a code found in the tilted copy, turned back into the
// frame: the copy was drawn rotated by angle about both centres.
function untilt(points, image, angle) {
  var size = tiltedSize(image, angle);
  var cos = Math.cos(-angle);
  var sin = Math.sin(-angle);
  return points.map(function (p) {
    var x = p.x - size.w / 2;
    var y = p.y - size.h / 2;
    return {
      x: x * cos - y * sin + image.width / 2,
      y: x * sin + y * cos + image.height / 2,
    };
  });
}

function corners(result) {
  var p = result.position;
  return p ? [p.topLeft, p.topRight, p.bottomRight, p.bottomLeft] : null;
}

function box(points, image) {
  if (!points) return null;
  var xs = points.map(function (p) { return p.x; });
  var ys = points.map(function (p) { return p.y; });
  var clamp = function (v) { return Math.max(0, Math.min(1, v)); };
  return [
    clamp(Math.min.apply(null, xs) / image.width),
    clamp(Math.min.apply(null, ys) / image.height),
    clamp(Math.max.apply(null, xs) / image.width),
    clamp(Math.max.apply(null, ys) / image.height),
  ];
}

// One message at a time: a photo and a camera frame share the canvases.
var queue = Promise.resolve();
self.onmessage = function (event) {
  queue = queue.then(function () {
    return handle(event.data);
  });
};

async function handle(msg) {
  var started = performance.now();
  var found = null;
  var points = null;
  var image = null;
  try {
    image = msg.bitmap
      ? imageFromBitmap(msg.bitmap)
      : new ImageData(new Uint8ClampedArray(msg.image.data), msg.image.width, msg.image.height);
    found = await read(image);
    if (found) points = corners(found);
    // Tilted passes need the frame in a canvas.
    var angles = !msg.bitmap ? [] : msg.still ? TILTS : frame % 2 === 1 ? [TILTS[(frame >> 1) % 2]] : [];
    for (var i = 0; !found && i < angles.length; i++) {
      found = await read(tilted(image, angles[i]));
      if (found && corners(found)) points = untilt(corners(found), image, angles[i]);
    }
    if (!msg.still) frame++;
  } catch (error) {
    self.postMessage({ type: 'error', message: String(error) });
  }
  self.postMessage({
    type: 'result',
    id: msg.id,
    text: found ? found.text : null,
    format: found ? found.format : null,
    box: found && image ? box(points, image) : null,
    aspect: image ? image.width / image.height : 0,
    ms: Math.round(performance.now() - started),
  });
}
