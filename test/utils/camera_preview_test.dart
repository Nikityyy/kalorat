import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/utils/camera_preview.dart';

void main() {
  group('portraitPreviewAspect', () {
    test('keeps portrait ratios and inverts landscape ones', () {
      expect(portraitPreviewAspect(0.75), 0.75);
      expect(portraitPreviewAspect(4 / 3), closeTo(0.75, 1e-9));
      expect(portraitPreviewAspect(16 / 9), closeTo(9 / 16, 1e-9));
      expect(portraitPreviewAspect(1), 1);
    });

    test('falls back to 9:16 for values a browser can report at start', () {
      for (final bad in [
        0.0,
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        0 / 0,
      ]) {
        expect(portraitPreviewAspect(bad), 9 / 16, reason: '$bad');
      }
    });

    test('always yields a usable size for a preview box', () {
      for (final v in [0.0, 0.3, 0.5625, 1, 1.78, 3.5, 100, double.nan]) {
        final ratio = portraitPreviewAspect(v.toDouble());
        final height = 390 / ratio;
        expect(height.isFinite && height > 0, isTrue, reason: '$v');
      }
    });
  });
}
