import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/screens/onboarding/weight_step.dart';

void main() {
  test('scale maps the semicircle angle to its value range', () {
    const size = Size(400, 250);

    expect(weightScaleFractionForPoint(const Offset(0, 226), size), 0);
    expect(weightScaleFractionForPoint(const Offset(200, 0), size), 0.5);
    expect(weightScaleFractionForPoint(const Offset(400, 226), size), 1);
    expect(weightScaleFractionForPoint(const Offset(-50, 250), size), 0);
    expect(weightScaleFractionForPoint(const Offset(450, 250), size), 1);
  });

  testWidgets('onboarding weight scale changes and submits its value', (
    tester,
  ) async {
    double? submitted;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WeightStep(
            initialValue: 70,
            language: 'en',
            onNext: (value) => submitted = value,
          ),
        ),
      ),
    );

    expect(find.text('70.0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('70.1'), findsOneWidget);

    final scale = tester.getRect(find.byKey(const ValueKey('weight-scale')));
    final center = Offset(scale.center.dx, scale.bottom - 24);
    final gesture = await tester.startGesture(
      Offset(center.dx, scale.top + 24),
    );
    await gesture.moveBy(const Offset(20, 20));
    await tester.pump();
    await gesture.moveTo(Offset(scale.right - 24, center.dy));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    await tester.tap(find.text('Continue'));
    expect(submitted, greaterThan(190));
  });
}
