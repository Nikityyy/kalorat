// Shrinks and encodes photos as JPEG off the main thread.
//
// On the main thread canvas.toBlob waits for the browser to be idle, which a
// page drawing the camera preview every frame never is: Chrome then gives up
// waiting after a second, so every photo took more than a second to appear.
// Safari encodes there instead, freezing the page while it does. A worker
// has neither problem.
//
// Messages in:  { id, bitmap, max, quality, mirrored } (ImageBitmap,
//               transferred) or { id, bytes, max, quality } (an encoded
//               photo, decoded here with its EXIF orientation applied).
//               max is the longest side of the result.
// Messages out: { type: 'ready', ok } once, then { id, bytes } or
//               { id, error } per job.
// Jobs run one after another, so at most one full size picture is decoded
// at a time.
'use strict';

var ok = false;
try {
  ok =
    typeof OffscreenCanvas === 'function' &&
    typeof OffscreenCanvas.prototype.convertToBlob === 'function' &&
    !!new OffscreenCanvas(1, 1).getContext('2d');
} catch (_) {}
postMessage({ type: 'ready', ok: ok });

var queue = Promise.resolve();

onmessage = function (e) {
  var job = e.data;
  queue = queue.then(function () {
    return run(job).then(
      function (bytes) {
        postMessage({ id: job.id, bytes: bytes }, [bytes.buffer]);
      },
      function (error) {
        postMessage({ id: job.id, error: String(error) });
      }
    );
  });
};

function run(job) {
  var source = job.bitmap
    ? Promise.resolve(job.bitmap)
    : createImageBitmap(new Blob([job.bytes]), { imageOrientation: 'from-image' });
  return source.then(function (bitmap) {
    try {
      var scale = Math.min(1, job.max / Math.max(bitmap.width, bitmap.height));
      var w = Math.max(1, Math.round(bitmap.width * scale));
      var h = Math.max(1, Math.round(bitmap.height * scale));
      var canvas = new OffscreenCanvas(w, h);
      var ctx = canvas.getContext('2d', { alpha: false });
      ctx.fillStyle = '#FFFFFF'; // JPEG has no alpha
      ctx.fillRect(0, 0, w, h);
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'high';
      if (job.mirrored) {
        ctx.translate(w, 0);
        ctx.scale(-1, 1);
      }
      ctx.drawImage(bitmap, 0, 0, w, h);
      return canvas.convertToBlob({ type: 'image/jpeg', quality: job.quality });
    } finally {
      if (bitmap.close) bitmap.close();
    }
  }).then(function (blob) {
    return blob.arrayBuffer();
  }).then(function (buffer) {
    return new Uint8Array(buffer);
  });
}
