import 'package:flutter/painting.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/services/barcode/scan_region.dart';
import 'package:kalorat/widgets/meal_guide_frame.dart';

void main() {
  // An iPhone 12-sized view with a 9:16 portrait camera frame.
  const view = Size(390, 844);
  const frameAspect = 9 / 16;
  final guide = MealGuideOverlay.guideRect(
    view,
    const EdgeInsets.only(top: 47, bottom: 34),
  );

  bool inGuide(Rect bounds, {bool mirrored = false}) => codeInGuide(
    bounds: bounds,
    frameAspect: frameAspect,
    view: view,
    guide: guide,
    mirrored: mirrored,
  );

  test('a code held up in the middle counts', () {
    expect(inGuide(const Rect.fromLTRB(0.3, 0.42, 0.7, 0.5)), isTrue);
  });

  test('a 1D scan line counts by its length', () {
    expect(inGuide(const Rect.fromLTRB(0.3, 0.45, 0.7, 0.4505)), isTrue);
  });

  test('a small code in the background does not count', () {
    expect(inGuide(const Rect.fromLTRB(0.47, 0.44, 0.53, 0.46)), isFalse);
  });

  test('a code outside the guide does not count', () {
    expect(inGuide(const Rect.fromLTRB(0.3, 0.85, 0.7, 0.9)), isFalse);
    expect(inGuide(const Rect.fromLTRB(0.0, 0.42, 0.2, 0.5)), isFalse);
  });

  test('a front camera preview is mirrored', () {
    const left = Rect.fromLTRB(0.1, 0.42, 0.45, 0.5);
    expect(inGuide(left), isTrue);
    expect(inGuide(left, mirrored: true), isTrue);
    const edge = Rect.fromLTRB(0.0, 0.42, 0.2, 0.5);
    expect(inGuide(edge, mirrored: true), isFalse);
  });

  test('a wide frame is cropped at the sides', () {
    // Landscape 16:9 frame covering a portrait view: only the middle shows.
    expect(
      codeInGuide(
        bounds: const Rect.fromLTRB(0.05, 0.45, 0.2, 0.55),
        frameAspect: 16 / 9,
        view: view,
        guide: guide,
      ),
      isFalse,
    );
    expect(
      codeInGuide(
        bounds: const Rect.fromLTRB(0.45, 0.45, 0.55, 0.55),
        frameAspect: 16 / 9,
        view: view,
        guide: guide,
      ),
      isTrue,
    );
  });

  test('unknown sizes do not block scanning', () {
    expect(
      codeInGuide(
        bounds: const Rect.fromLTRB(0, 0, 0.01, 0.01),
        frameAspect: 0,
        view: view,
        guide: guide,
      ),
      isTrue,
    );
  });
}
