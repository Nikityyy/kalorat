import 'dart:math' as math;
import 'dart:ui';

/// The shortest code counted, as a share of the guide's side. A code held up
/// to the camera spans far more; one on a package in the background less.
const minCodeShareOfGuide = 0.2;

/// Whether a code at [bounds] (fractions of the upright camera frame, whose
/// width / height is [frameAspect]) shows inside [guide] on a preview of
/// [view] size. The preview covers the view like `BoxFit.cover`;
/// [mirrored] for a front camera. Its centre must lie in the guide and it
/// must be at least [minCodeShareOfGuide] of the guide long. A 1D code's
/// bounds may be just its scan line, so only the longer side counts.
bool codeInGuide({
  required Rect bounds,
  required double frameAspect,
  required Size view,
  required Rect guide,
  bool mirrored = false,
}) {
  if (frameAspect <= 0 || view.isEmpty) return true;
  final viewAspect = view.width / view.height;
  final shownWidth = viewAspect > frameAspect
      ? view.width
      : view.height * frameAspect;
  final shownHeight = shownWidth / frameAspect;
  final left = (view.width - shownWidth) / 2;
  final top = (view.height - shownHeight) / 2;
  final x0 = mirrored ? 1 - bounds.right : bounds.left;
  final x1 = mirrored ? 1 - bounds.left : bounds.right;
  final onScreen = Rect.fromLTRB(
    left + x0 * shownWidth,
    top + bounds.top * shownHeight,
    left + x1 * shownWidth,
    top + bounds.bottom * shownHeight,
  );
  final length = math.max(onScreen.width, onScreen.height);
  return guide.contains(onScreen.center) &&
      length >= guide.shortestSide * minCodeShareOfGuide;
}
