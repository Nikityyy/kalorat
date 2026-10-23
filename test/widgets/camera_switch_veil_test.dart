import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/screens/home/camera_switch_veil.dart';

// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Widget _veil({
  required bool fadeIn,
  required bool reveal,
  required VoidCallback onDone,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CameraSwitchVeil(
    snapshot: _png,
    mirrored: false,
    fadeIn: fadeIn,
    reveal: reveal,
    onDone: onDone,
  ),
);

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.byType(Opacity)).opacity;

void main() {
  testWidgets('without fadeIn it covers at once', (tester) async {
    await tester.pumpWidget(_veil(fadeIn: false, reveal: false, onDone: () {}));
    expect(_opacity(tester), 1);
  });

  testWidgets('with fadeIn it fades in over the cover duration', (
    tester,
  ) async {
    await tester.pumpWidget(_veil(fadeIn: true, reveal: false, onDone: () {}));
    expect(_opacity(tester), 0);

    await tester.pump(CameraSwitchVeil.coverDuration ~/ 2);
    final half = _opacity(tester);
    expect(half, greaterThan(0));
    expect(half, lessThan(1));

    await tester.pump(CameraSwitchVeil.coverDuration);
    expect(_opacity(tester), 1);
  });

  testWidgets('revealing fades it out and reports when it is gone', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      _veil(fadeIn: true, reveal: false, onDone: () => done++),
    );
    await tester.pump(CameraSwitchVeil.coverDuration);
    expect(done, 0);

    await tester.pumpWidget(
      _veil(fadeIn: true, reveal: true, onDone: () => done++),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacity(tester), allOf(greaterThan(0), lessThan(1)));
    expect(done, 0);

    await tester.pump(const Duration(milliseconds: 500));
    expect(_opacity(tester), 0);
    expect(done, 1);
  });
}
