import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/utils/frame_luma.dart';

/// An NV21-like frame whose Y plane is [y] everywhere except the pixels where
/// [bright] says otherwise.
Uint8List yPlane(int w, int h, int Function(int x, int y) y) =>
    Uint8List.fromList([
      for (var row = 0; row < h; row++)
        for (var col = 0; col < w; col++) y(col, row),
    ]);

void main() {
  const top = Rect.fromLTRB(.3, .05, .7, .12);

  double? luma(
    Uint8List bytes,
    int w,
    int h, {
    int rotation = 0,
    bool bgra = false,
    double aspect = .5,
  }) => frameLuma(
    bytes: bytes,
    width: w,
    height: h,
    bytesPerRow: bgra ? w * 4 : w,
    bgra: bgra,
    rotation: rotation,
    region: top,
    viewAspect: aspect,
  );

  test('reads black as 0 and white as 1 from the Y plane', () {
    expect(luma(yPlane(40, 80, (_, _) => 16), 40, 80), closeTo(0, .001));
    expect(luma(yPlane(40, 80, (_, _) => 235), 40, 80), closeTo(1, .001));
  });

  test('looks at the top of the upright picture, whatever the rotation', () {
    // A landscape sensor frame, 80 x 40, turned 90 degrees clockwise to stand
    // upright: its left edge becomes the top. Only the left columns are white.
    final left = yPlane(80, 40, (x, _) => x < 20 ? 235 : 16);
    expect(luma(left, 80, 40, rotation: 90, aspect: 40 / 80), greaterThan(.9));
    expect(luma(left, 80, 40, rotation: 270, aspect: 40 / 80), lessThan(.1));
    // Upright already: the top rows only.
    final topRows = yPlane(40, 80, (_, y) => y < 20 ? 235 : 16);
    expect(luma(topRows, 40, 80), greaterThan(.9));
    expect(luma(topRows, 40, 80, rotation: 180), lessThan(.1));
  });

  test('reads BGRA frames', () {
    final white = Uint8List.fromList(List.filled(40 * 80 * 4, 255));
    expect(luma(white, 40, 80, bgra: true), closeTo(1, .001));
    final red = Uint8List.fromList([
      for (var i = 0; i < 40 * 80; i++) ...[0, 0, 255, 255],
    ]);
    expect(luma(red, 40, 80, bgra: true), closeTo(.2126, .001));
  });

  test(
    'is null when the region lies outside the picture or the frame is short',
    () {
      expect(
        frameLuma(
          bytes: Uint8List(4),
          width: 40,
          height: 80,
          bytesPerRow: 40,
          bgra: false,
          rotation: 0,
          region: top,
          viewAspect: .5,
        ),
        isNull,
      );
      expect(luma(Uint8List(0), 0, 0), isNull);
    },
  );

  group('BackdropTone', () {
    test('turns dark above the upper edge and light below the lower one', () {
      final tone = BackdropTone(smoothing: 1);
      expect(tone.update(.3), isFalse);
      expect(tone.update(.55), isFalse, reason: 'inside the band: unchanged');
      expect(tone.update(.7), isTrue);
      expect(tone.update(.5), isTrue, reason: 'inside the band: unchanged');
      expect(tone.update(.4), isFalse);
    });

    test('does not flicker on readings that hover near the middle', () {
      final tone = BackdropTone(smoothing: 1);
      final states = [
        for (final v in [.5, .56, .5, .58, .52, .57, .5]) tone.update(v),
      ];
      expect(states.toSet(), {false});
    });

    test('smooths a single bright flash away', () {
      final tone = BackdropTone();
      for (var i = 0; i < 5; i++) {
        tone.update(.2);
      }
      expect(tone.update(.95), isFalse);
    });
  });
}
