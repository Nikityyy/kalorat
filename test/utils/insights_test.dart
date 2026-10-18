import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/meal_model.dart';
import 'package:kalorat/models/weight_model.dart';
import 'package:kalorat/utils/insights.dart';

MealModel meal(DateTime at, double calories, {double protein = 0}) => MealModel(
  id: '${at.microsecondsSinceEpoch}-$calories',
  timestamp: at,
  photoPaths: const [],
  calories: calories,
  protein: protein,
);

WeightModel weigh(DateTime day, double kg) =>
    WeightModel(date: day, weight: kg, isPending: false);

void main() {
  final now = DateTime(2026, 10, 18, 15);
  DateTime daysAgo(int n, [int hour = 12]) =>
      DateTime(2026, 10, 18 - n, hour);

  group('dailyTotals', () {
    test('adds meals per day and skips pending ones', () {
      final totals = dailyTotals([
        meal(daysAgo(1, 8), 400, protein: 20),
        meal(daysAgo(1, 19), 600, protein: 30),
        meal(daysAgo(2), 500),
        MealModel(
          id: 'p',
          timestamp: daysAgo(2),
          photoPaths: const [],
          calories: 9999,
          isPending: true,
        ),
      ]);

      expect(totals[DateTime(2026, 10, 17)]!.calories, 1000);
      expect(totals[DateTime(2026, 10, 17)]!.protein, 50);
      expect(totals[DateTime(2026, 10, 17)]!.meals, 2);
      expect(totals[DateTime(2026, 10, 16)]!.calories, 500);
    });

    test('a night meal belongs to the day before when the day starts late', () {
      final totals = dailyTotals([
        meal(DateTime(2026, 10, 17, 1), 300),
        meal(DateTime(2026, 10, 17, 12), 700),
      ], dayStartHour: 4);

      expect(totals[DateTime(2026, 10, 16)]!.calories, 300);
      expect(totals[DateTime(2026, 10, 17)]!.calories, 700);
    });
  });

  group('weeklySummary', () {
    test('averages the logged days of the last 7 completed days', () {
      final summary = weeklySummary(
        meals: [
          meal(daysAgo(1), 2000, protein: 100),
          meal(daysAgo(2), 2400, protein: 120),
          meal(daysAgo(7), 1600, protein: 80),
          // Today is still being logged and the day before the week is out.
          meal(daysAgo(0), 300),
          meal(daysAgo(8), 5000),
        ],
        weights: const [],
        targetCalories: 2000,
        now: now,
      );

      expect(summary.days, hasLength(7));
      expect(summary.days.first.day, DateTime(2026, 10, 11));
      expect(summary.days.last.day, DateTime(2026, 10, 17));
      expect(summary.daysLogged, 3);
      expect(summary.avgCalories, 2000);
      expect(summary.avgProtein, 100);
      expect(summary.differenceToTarget, 0);
      expect(summary.weightChange, isNull);
    });

    test('without meals there is no average', () {
      final summary = weeklySummary(
        meals: const [],
        weights: const [],
        targetCalories: 2000,
        now: now,
      );
      expect(summary.avgCalories, isNull);
      expect(summary.differenceToTarget, isNull);
      expect(summary.daysLogged, 0);
    });

    test('weight change is measured from the weigh-in before the week', () {
      final summary = weeklySummary(
        meals: const [],
        weights: [
          weigh(daysAgo(10), 82.0),
          weigh(daysAgo(3), 81.4),
          weigh(daysAgo(0), 81.0),
        ],
        targetCalories: 2000,
        now: now,
      );
      expect(summary.weightChange, closeTo(-1.0, 1e-9));
      expect(summary.weightSpanDays, 10);
    });

    test('with two weigh-ins in the week they are compared', () {
      final summary = weeklySummary(
        meals: const [],
        weights: [weigh(daysAgo(5), 80.0), weigh(daysAgo(1), 80.6)],
        targetCalories: 2000,
        now: now,
      );
      expect(summary.weightChange, closeTo(0.6, 1e-9));
      expect(summary.weightSpanDays, 4);
    });

    test('one weigh-in alone shows no change', () {
      final summary = weeklySummary(
        meals: const [],
        weights: [weigh(daysAgo(2), 80.0)],
        targetCalories: 2000,
        now: now,
      );
      expect(summary.weightChange, isNull);
    });

    test('an old weigh-in is no baseline', () {
      final summary = weeklySummary(
        meals: const [],
        weights: [weigh(daysAgo(40), 90.0), weigh(daysAgo(2), 80.0)],
        targetCalories: 2000,
        now: now,
      );
      expect(summary.weightChange, isNull);
    });
  });

  group('estimateExpenditure', () {
    // 21 days of 2500 kcal, one weigh-in every three days.
    List<MealModel> meals({double kcal = 2500, int from = 22, int to = 1}) => [
      for (var i = from; i >= to; i--) meal(daysAgo(i), kcal),
    ];

    test('steady weight means intake is the burn', () {
      final estimate = estimateExpenditure(
        meals: meals(),
        weights: [for (var i = 21; i >= 0; i -= 3) weigh(daysAgo(i), 80)],
        now: now,
      );
      expect(estimate.status, ExpenditureStatus.ready);
      expect(estimate.kcal, closeTo(2500, 1));
      expect(estimate.weightRatePerWeek, closeTo(0, 1e-9));
    });

    test('losing weight means the burn is above the intake', () {
      // -0.1 kg every three days: -0.0333 kg a day = -257 kcal a day.
      final estimate = estimateExpenditure(
        meals: meals(),
        weights: [
          for (var i = 21; i >= 0; i -= 3) weigh(daysAgo(i), 80 + i / 30),
        ],
        now: now,
      );
      expect(estimate.status, ExpenditureStatus.ready);
      expect(estimate.kcal, closeTo(2500 + 7700 / 30, 1));
      expect(estimate.weightRatePerWeek, closeTo(-7 / 30, 1e-9));
    });

    test('gaining weight means the burn is below the intake', () {
      final estimate = estimateExpenditure(
        meals: meals(),
        weights: [
          for (var i = 21; i >= 0; i -= 3) weigh(daysAgo(i), 80 - i / 30),
        ],
        now: now,
      );
      expect(estimate.kcal, closeTo(2500 - 7700 / 30, 1));
    });

    test('a noisy scale is smoothed by the trend line', () {
      // Flat weight with +-0.6 kg of water noise.
      final noise = [0.6, -0.5, 0.4, -0.6, 0.5, -0.4, 0.3, -0.3];
      final estimate = estimateExpenditure(
        meals: meals(),
        weights: [
          for (var k = 0; k < noise.length; k++)
            weigh(daysAgo(21 - k * 3), 80 + noise[k]),
        ],
        now: now,
      );
      expect(estimate.status, ExpenditureStatus.ready);
      expect(estimate.kcal, closeTo(2500, 400));
    });

    test('needs enough weigh-ins', () {
      final estimate = estimateExpenditure(
        meals: meals(),
        weights: [weigh(daysAgo(20), 80), weigh(daysAgo(0), 80)],
        now: now,
      );
      expect(estimate.status, ExpenditureStatus.needsData);
      expect(estimate.weighIns, 2);
    });

    test('needs weigh-ins that are far enough apart', () {
      final estimate = estimateExpenditure(
        meals: meals(),
        weights: [
          weigh(daysAgo(5), 80),
          weigh(daysAgo(3), 80),
          weigh(daysAgo(1), 80),
        ],
        now: now,
      );
      expect(estimate.status, ExpenditureStatus.needsData);
      expect(estimate.spanDays, 4);
    });

    test('needs most days in between to be logged', () {
      final estimate = estimateExpenditure(
        meals: [for (var i = 20; i >= 1; i -= 3) meal(daysAgo(i), 2500)],
        weights: [for (var i = 21; i >= 0; i -= 3) weigh(daysAgo(i), 80)],
        now: now,
      );
      expect(estimate.status, ExpenditureStatus.needsData);
      expect(estimate.loggedDays, lessThan(10));
    });

    test('today is not counted, it is still being logged', () {
      final withToday = estimateExpenditure(
        meals: [...meals(), meal(daysAgo(0), 100)],
        weights: [for (var i = 21; i >= 0; i -= 3) weigh(daysAgo(i), 80)],
        now: now,
      );
      expect(withToday.kcal, closeTo(2500, 1));
    });

    test('forgotten meals give an implausible burn instead of a number', () {
      final estimate = estimateExpenditure(
        meals: meals(kcal: 500),
        weights: [for (var i = 21; i >= 0; i -= 3) weigh(daysAgo(i), 80)],
        now: now,
      );
      expect(estimate.status, ExpenditureStatus.implausible);
      expect(estimate.kcal, isNull);
    });

    test('weigh-ins older than the window are ignored', () {
      final estimate = estimateExpenditure(
        meals: meals(),
        weights: [
          weigh(daysAgo(60), 95),
          for (var i = 21; i >= 0; i -= 3) weigh(daysAgo(i), 80),
        ],
        now: now,
      );
      expect(estimate.kcal, closeTo(2500, 1));
    });
  });
}
