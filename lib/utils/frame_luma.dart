import 'dart:typed_data';
import 'dart:ui' show Rect;

/// How bright the part of the camera picture behind a piece of interface is,
/// 0 (black) to 1 (white), from a raw frame of the image stream.
///
/// [region] is that part as fractions of the view the picture is shown in,
/// and [viewAspect] the view's width / height. The picture covers the view
/// (like `BoxFit.cover`), so part of it may lie outside. [rotation] is the
/// clockwise turn that makes the frame upright. The frame is NV21 (the Y plane
/// is read) or, with [bgra], BGRA8888. Only a few dozen pixels are read.
double? frameLuma({
  required Uint8List bytes,
  required int width,
  required int height,
  required int bytesPerRow,
  required bool bgra,
  required int rotation,
  required Rect region,
  required double viewAspect,
}) {
  if (width <= 0 || height <= 0 || viewAspect <= 0) return null;
  final turned = rotation % 180 != 0;
  final uprightW = (turned ? height : width).toDouble();
  final uprightH = (turned ? width : height).toDouble();
  final frameAspect = uprightW / uprightH;

  // The frame as shown, in view units (the view is viewAspect wide, 1 high).
  final shownW = viewAspect > frameAspect ? viewAspect : frameAspect;
  final shownH = shownW / frameAspect;
  final left = (viewAspect - shownW) / 2;
  final top = (1 - shownH) / 2;
  final u0 = (((region.left * viewAspect) - left) / shownW).clamp(0.0, 1.0);
  final u1 = (((region.right * viewAspect) - left) / shownW).clamp(0.0, 1.0);
  final v0 = ((region.top - top) / shownH).clamp(0.0, 1.0);
  final v1 = ((region.bottom - top) / shownH).clamp(0.0, 1.0);
  if (u1 <= u0 || v1 <= v0) return null;

  const cols = 8, rows = 3;
  var sum = 0.0, count = 0;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final u = u0 + (u1 - u0) * (c + .5) / cols;
      final v = v0 + (v1 - v0) * (r + .5) / rows;
      // Where that upright point lies in the frame as delivered.
      final (fx, fy) = switch (rotation % 360) {
        90 => (v, 1 - u),
        180 => (1 - u, 1 - v),
        270 => (1 - v, u),
        _ => (u, v),
      };
      final x = (fx * (width - 1)).round();
      final y = (fy * (height - 1)).round();
      final value = _luma(bytes, y * bytesPerRow + x * (bgra ? 4 : 1), bgra);
      if (value == null) continue;
      sum += value;
      count++;
    }
  }
  return count == 0 ? null : sum / count;
}

double? _luma(Uint8List bytes, int i, bool bgra) {
  if (i < 0 || i + (bgra ? 3 : 1) > bytes.length) return null;
  if (bgra) {
    return (0.0722 * bytes[i] + 0.7152 * bytes[i + 1] + 0.2126 * bytes[i + 2]) /
        255;
  }
  // The Y plane of video-range YUV runs from 16 (black) to 235 (white).
  return ((bytes[i] - 16) / 219).clamp(0.0, 1.0);
}

/// Decides, from a stream of brightness readings, whether interface over the
/// picture should be dark. Light becomes dark above [toDark] and back below
/// [toLight]; between them it stays as it was, so a reading that hovers near
/// the middle cannot make it flicker. Readings are smoothed first.
class BackdropTone {
  BackdropTone({this.toDark = .6, this.toLight = .45, this.smoothing = .4});

  final double toDark;
  final double toLight;
  final double smoothing;

  double? _level;
  bool dark = false;

  /// Takes a reading and returns whether the tone is dark now.
  bool update(double luma) {
    final level = _level == null
        ? luma
        : _level! + (luma - _level!) * smoothing;
    _level = level;
    if (dark ? level < toLight : level > toDark) dark = !dark;
    return dark;
  }

  void reset() {
    _level = null;
    dark = false;
  }
}
