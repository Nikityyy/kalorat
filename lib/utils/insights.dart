import '../models/meal_model.dart';
import '../models/weight_model.dart';

/// kcal in a kilogram of body weight change, the usual rule of thumb.
const kcalPerKg = 7700.0;

/// Pure calculations behind the weekly summary and the estimated daily burn.
/// Days are "logical" days: a day starts at [dayStartHour] (see UserModel).

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The logical day [time] belongs to, as a date without time.
DateTime logicalDay(DateTime time, {int dayStartHour = 0}) =>
    _dateOnly(time.subtract(Duration(hours: dayStartHour)));

/// What was logged on one logical day.
class DayIntake {
  final DateTime day;
  final double calories;
  final double protein;
  final int meals;

  const DayIntake(this.day, this.calories, this.protein, this.meals);

  bool get logged => meals > 0;
}

/// Totals per logical day of the analysed meals (pending ones have no values
/// yet), keyed by the day.
Map<DateTime, DayIntake> dailyTotals(
  Iterable<MealModel> meals, {
  int dayStartHour = 0,
}) {
  final totals = <DateTime, DayIntake>{};
  for (final meal in meals) {
    if (meal.isPending) continue;
    final day = logicalDay(meal.timestamp, dayStartHour: dayStartHour);
    final before = totals[day];
    totals[day] = DayIntake(
      day,
      (before?.calories ?? 0) + meal.calories,
      (before?.protein ?? 0) + meal.protein,
      (before?.meals ?? 0) + 1,
    );
  }
  return totals;
}

class WeeklySummary {
  /// The seven completed days before today, oldest first.
  final List<DayIntake> days;

  /// Average over the days with meals; null when there are none.
  final double? avgCalories;
  final double? avgProtein;
  final double targetCalories;

  /// Change from the weigh-in before the week (or the first one in it) to the
  /// latest one; null when there are fewer than two weigh-ins to compare.
  final double? weightChange;
  final int weightSpanDays;

  const WeeklySummary({
    required this.days,
    required this.avgCalories,
    required this.avgProtein,
    required this.targetCalories,
    required this.weightChange,
    required this.weightSpanDays,
  });

  int get daysLogged => days.where((d) => d.logged).length;

  /// Average intake minus the target; null without meals.
  double? get differenceToTarget =>
      avgCalories == null ? null : avgCalories! - targetCalories;
}

/// The last seven completed days (today is still being logged) against the
/// daily target.
WeeklySummary weeklySummary({
  required Iterable<MealModel> meals,
  required Iterable<WeightModel> weights,
  required double targetCalories,
  required DateTime now,
  int dayStartHour = 0,
}) {
  final today = logicalDay(now, dayStartHour: dayStartHour);
  final totals = dailyTotals(meals, dayStartHour: dayStartHour);
  final days = <DayIntake>[
    for (var i = 7; i >= 1; i--)
      () {
        final day = DateTime(today.year, today.month, today.day - i);
        return totals[day] ?? DayIntake(day, 0, 0, 0);
      }(),
  ];
  final logged = days.where((d) => d.logged).toList();
  double? average(double Function(DayIntake) pick) => logged.isEmpty
      ? null
      : logged.map(pick).reduce((a, b) => a + b) / logged.length;

  final windowStart = days.first.day;
  final sorted = weights.toList()..sort((a, b) => a.date.compareTo(b.date));
  final inWindow = sorted
      .where((w) => !_dateOnly(w.date).isBefore(windowStart))
      .where((w) => !_dateOnly(w.date).isAfter(today))
      .toList();
  // The weigh-in just before the week is the better baseline, when recent.
  final before = sorted
      .where((w) => _dateOnly(w.date).isBefore(windowStart))
      .where(
        (w) => _dateOnly(
          w.date,
        ).isAfter(windowStart.subtract(const Duration(days: 15))),
      )
      .lastOrNull;
  WeightModel? from = before ?? inWindow.firstOrNull;
  final to = inWindow.lastOrNull;
  double? change;
  var span = 0;
  if (from != null && to != null && !identical(from, to)) {
    change = to.weight - from.weight;
    span = _dateOnly(to.date).difference(_dateOnly(from.date)).inDays;
  }

  return WeeklySummary(
    days: days,
    avgCalories: average((d) => d.calories),
    avgProtein: average((d) => d.protein),
    targetCalories: targetCalories,
    weightChange: change,
    weightSpanDays: span,
  );
}

enum ExpenditureStatus {
  /// [ExpenditureEstimate.kcal] is set.
  ready,

  /// Too few logged days or weigh-ins so far.
  needsData,

  /// The numbers do not add up to a believable burn: meals or weigh-ins are
  /// probably missing.
  implausible,
}

class ExpenditureEstimate {
  final ExpenditureStatus status;

  /// Estimated kcal burnt per day; set when [status] is ready.
  final double? kcal;

  /// Average intake over the logged days considered.
  final double? avgIntake;

  /// Weight trend in kg per week (negative when losing).
  final double? weightRatePerWeek;
  final int loggedDays;
  final int weighIns;
  final int spanDays;

  const ExpenditureEstimate({
    required this.status,
    this.kcal,
    this.avgIntake,
    this.weightRatePerWeek,
    this.loggedDays = 0,
    this.weighIns = 0,
    this.spanDays = 0,
  });
}

const expenditureWindowDays = 28;
const expenditureMinWeighIns = 3;
const expenditureMinSpanDays = 10;
const expenditureMinLoggedDays = 10;
const _expenditureMinLoggedShare = 0.6;

/// Estimates the real daily burn: what was eaten, minus what the weight trend
/// says was stored (or plus what it says was used up).
///
/// burn = average intake − weight change per day × 7700 kcal/kg
///
/// The weight trend is the least-squares line through the weigh-ins of the
/// last [expenditureWindowDays] days, which smooths out water weight. The
/// intake is averaged over the days with meals between the first and the last
/// weigh-in; today is left out, it is still being logged. The result is only
/// as good as the logging: it needs enough weigh-ins and logged days.
ExpenditureEstimate estimateExpenditure({
  required Iterable<MealModel> meals,
  required Iterable<WeightModel> weights,
  required DateTime now,
  int dayStartHour = 0,
}) {
  final today = logicalDay(now, dayStartHour: dayStartHour);
  final windowStart = DateTime(
    today.year,
    today.month,
    today.day - expenditureWindowDays,
  );
  final points =
      weights
          .where((w) => !_dateOnly(w.date).isBefore(windowStart))
          .where((w) => !_dateOnly(w.date).isAfter(today))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  if (points.length < 2) {
    return ExpenditureEstimate(
      status: ExpenditureStatus.needsData,
      weighIns: points.length,
    );
  }

  final firstDay = _dateOnly(points.first.date);
  final lastDay = _dateOnly(points.last.date);
  final span = lastDay.difference(firstDay).inDays;

  final totals = dailyTotals(meals, dayStartHour: dayStartHour);
  var loggedDays = 0;
  var calories = 0.0;
  for (var i = 0; i < span; i++) {
    final day = DateTime(firstDay.year, firstDay.month, firstDay.day + i);
    final total = totals[day];
    if (day.isBefore(today) && total != null && total.logged) {
      loggedDays++;
      calories += total.calories;
    }
  }

  ExpenditureEstimate needsData() => ExpenditureEstimate(
    status: ExpenditureStatus.needsData,
    loggedDays: loggedDays,
    weighIns: points.length,
    spanDays: span,
  );
  if (points.length < expenditureMinWeighIns ||
      span < expenditureMinSpanDays ||
      loggedDays < expenditureMinLoggedDays ||
      loggedDays < span * _expenditureMinLoggedShare) {
    return needsData();
  }

  // Least squares: weight (kg) against days since the first weigh-in.
  final xs = [
    for (final p in points) _dateOnly(p.date).difference(firstDay).inDays,
  ];
  final n = points.length;
  final meanX = xs.reduce((a, b) => a + b) / n;
  final meanY = points.map((p) => p.weight).reduce((a, b) => a + b) / n;
  var sxy = 0.0;
  var sxx = 0.0;
  for (var i = 0; i < n; i++) {
    sxy += (xs[i] - meanX) * (points[i].weight - meanY);
    sxx += (xs[i] - meanX) * (xs[i] - meanX);
  }
  final slopePerDay = sxx == 0 ? 0.0 : sxy / sxx;

  final avgIntake = calories / loggedDays;
  final burn = avgIntake - slopePerDay * kcalPerKg;
  final believable = burn >= 1000 && burn <= 6000;
  return ExpenditureEstimate(
    status: believable
        ? ExpenditureStatus.ready
        : ExpenditureStatus.implausible,
    kcal: believable ? burn : null,
    avgIntake: avgIntake,
    weightRatePerWeek: slopePerDay * 7,
    loggedDays: loggedDays,
    weighIns: n,
    spanDays: span,
  );
}
