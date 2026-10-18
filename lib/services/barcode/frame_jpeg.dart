import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The camera stream format a [StreamFrame] is in.
enum StreamFrameFormat { nv21, bgra8888 }

/// One frame of the native camera image stream, kept so the frame a barcode
/// was read from can become the meal photo.
class StreamFrame {
  final StreamFrameFormat format;
  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;

  /// Clockwise rotation that turns the frame upright.
  final int rotationDegrees;

  const StreamFrame({
    required this.format,
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.rotationDegrees,
  });
}

/// Turns [frame] into an upright JPEG. Runs in an isolate (see `compute`):
/// a 1080p frame takes a few hundred milliseconds.
Uint8List encodeStreamFrame(StreamFrame frame) {
  var image = switch (frame.format) {
    StreamFrameFormat.nv21 => _fromNv21(frame),
    StreamFrameFormat.bgra8888 => img.Image.fromBytes(
      width: frame.width,
      height: frame.height,
      bytes: frame.bytes.buffer,
      bytesOffset: frame.bytes.offsetInBytes,
      rowStride: frame.bytesPerRow,
      numChannels: 4,
      order: img.ChannelOrder.bgra,
    ),
  };
  final rotation = frame.rotationDegrees % 360;
  if (rotation != 0) image = img.copyRotate(image, angle: rotation);
  return img.encodeJpg(image, quality: 85);
}

img.Image _fromNv21(StreamFrame frame) {
  final w = frame.width;
  final h = frame.height;
  final bytes = frame.bytes;
  // Rows may be padded. The buffer holds h rows of Y and h/2 rows of VU,
  // which gives the real stride even when bytesPerRow describes the
  // camera's original planes.
  final rows = h + (h + 1) ~/ 2;
  final inferred = bytes.length ~/ rows;
  final stride = inferred >= w ? inferred : frame.bytesPerRow;
  if (stride < w || bytes.length < stride * rows - (stride - w)) {
    throw ArgumentError('NV21 frame is too short');
  }
  final uvStart = stride * h;
  final out = img.Image(width: w, height: h);
  final data = out.data!.buffer.asUint8List();
  var o = 0;
  for (var y = 0; y < h; y++) {
    final yRow = y * stride;
    final uvRow = uvStart + (y >> 1) * stride;
    for (var x = 0; x < w; x++) {
      final yy = bytes[yRow + x] - 16;
      final uvIndex = uvRow + (x & ~1);
      final v = bytes[uvIndex] - 128;
      final u = bytes[uvIndex + 1] - 128;
      final c = 298 * (yy < 0 ? 0 : yy);
      data[o++] = _clamp((c + 409 * v + 128) >> 8);
      data[o++] = _clamp((c - 100 * u - 208 * v + 128) >> 8);
      data[o++] = _clamp((c + 516 * u + 128) >> 8);
    }
  }
  return out;
}

int _clamp(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);
