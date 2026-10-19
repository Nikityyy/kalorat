import 'dart:math' as math;
import 'dart:ui';

/// The shortest code counted, as a share of the guide's side. A code held up
/// to the camera spans far more; one on a package in the background less.
const minCodeShareOfGuide = 0.2;

/// Where a code at [bounds] (fractions of the upright camera frame, whose
/// width / height is [frameAspect]) shows on a preview of [view] size. The
/// preview covers the view like `BoxFit.cover`; [mirrored] for a front
/// camera. Null when the frame's shape is unknown.
Rect? codeOnScreen({
  required Rect bounds,
  required double frameAspect,
  required Size view,
  bool mirrored = false,
}) {
  if (frameAspect <= 0 || view.isEmpty) return null;
  final viewAspect = view.width / view.height;
  final shownWidth = viewAspect > frameAspect
      ? view.width
      : view.height * frameAspect;
  final shownHeight = shownWidth / frameAspect;
  final left = (view.width - shownWidth) / 2;
  final top = (view.height - shownHeight) / 2;
  final x0 = mirrored ? 1 - bounds.right : bounds.left;
  final x1 = mirrored ? 1 - bounds.left : bounds.right;
  return Rect.fromLTRB(
    left + x0 * shownWidth,
    top + bounds.top * shownHeight,
    left + x1 * shownWidth,
    top + bounds.bottom * shownHeight,
  );
}

/// Whether a code at [bounds] shows inside [guide] on a preview of [view]
/// size (see [codeOnScreen]). Its centre must lie in the guide and it must
/// be at least [minCodeShareOfGuide] of the guide long. A 1D code's bounds
/// may be just its scan line, so only the longer side counts.
bool codeInGuide({
  required Rect bounds,
  required double frameAspect,
  required Size view,
  required Rect guide,
  bool mirrored = false,
}) {
  final onScreen = codeOnScreen(
    bounds: bounds,
    frameAspect: frameAspect,
    view: view,
    mirrored: mirrored,
  );
  if (onScreen == null) return true;
  final length = math.max(onScreen.width, onScreen.height);
  return guide.contains(onScreen.center) &&
      length >= guide.shortestSide * minCodeShareOfGuide;
}

/// The box drawn around a code found at [onScreen]: a 1D code's bounds can
/// be its scan line only, so the box gets at least the shape of a barcode,
/// a little room around it, and never leaves [guide] by much.
Rect lockBox(Rect onScreen, Rect guide) {
  final long = math.max(onScreen.width, onScreen.height);
  final minShort = long * 0.7;
  var box = onScreen;
  if (box.width >= box.height && box.height < minShort) {
    box = Rect.fromCenter(
      center: box.center,
      width: box.width,
      height: minShort,
    );
  } else if (box.height > box.width && box.width < minShort) {
    box = Rect.fromCenter(
      center: box.center,
      width: minShort,
      height: box.height,
    );
  }
  box = box.inflate(math.max(10, long * 0.08));
  final limit = guide.inflate(12);
  return box.intersect(limit).isEmpty ? guide : box.intersect(limit);
}
