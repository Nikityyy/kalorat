import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import 'package:kalorat/models/weight_model.dart';
import 'package:kalorat/widgets/me/weight_chart.dart';

void main() {
  test('calculates seven-day difference and a linear trend', () {
    final latest = DateTime(2026, 7, 10);
    final weights = [
      WeightModel(date: latest, weight: 70),
      WeightModel(date: latest.subtract(const Duration(days: 7)), weight: 72),
    ];

    expect(weeklyWeightDifference(weights), -2);
    final trend = linearWeightTrend(const [FlSpot(0, 72), FlSpot(7, 70)]);
    expect(trend.first.y, 72);
    expect(trend.last.y, 70);
  });

  testWidgets('sparse ranges fit their data and keep selected text white', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WeightChart(
            weights: [
              WeightModel(
                date: today.subtract(const Duration(days: 4)),
                weight: 70,
              ),
              WeightModel(date: today, weight: 71),
            ],
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('Month')).style?.color, Colors.white);
    expect(tester.widget<LineChart>(find.byType(LineChart)).data.maxX, 6);

    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text('Year')).style?.color, Colors.white);
    expect(tester.widget<LineChart>(find.byType(LineChart)).data.maxX, 6);
  });
}
