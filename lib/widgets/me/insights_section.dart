import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../extensions/l10n_extension.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/insights.dart';
import '../common/app_card.dart';

/// The last seven days against the target, and the burn the logged meals and
/// weigh-ins point to.
class InsightsSection extends StatelessWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    if (user == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final meals = provider.getAllMeals();
    final weights = provider.weights;
    final summary = weeklySummary(
      meals: meals,
      weights: weights,
      targetCalories: user.dailyCalorieTarget,
      now: now,
      dayStartHour: user.dayStartHour,
    );
    final burn = estimateExpenditure(
      meals: meals,
      weights: weights,
      now: now,
      dayStartHour: user.dayStartHour,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeeklySummaryCard(summary: summary, locale: provider.language),
        const SizedBox(height: 12),
        BurnCard(
          estimate: burn,
          formulaKcal: user.maintenanceCalories,
          locale: provider.language,
        ),
      ],
    );
  }
}

String _number(num value, String locale) =>
    NumberFormat.decimalPattern(locale).format(value.round());

/// A signed number with one decimal and a real minus sign.
String _signed(double value, String locale) {
  final text = NumberFormat('+0.0;-0.0', locale).format(value);
  return text.replaceFirst('-', '−');
}

class WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  final String locale;

  const WeeklySummaryCard({
    super.key,
    required this.summary,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final average = summary.avgCalories;
    final difference = summary.differenceToTarget;

    return AppCard(
      backgroundColor: AppColors.glacialWhite,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.weeklySummaryTitle,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  l10n.weeklyDaysLogged(summary.daysLogged, 7),
                  textAlign: TextAlign.end,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (average == null)
            Text(l10n.weeklyNoMeals, style: AppTypography.bodyMedium)
          else ...[
            Text(l10n.weeklyAvgIntake, style: AppTypography.bodySmall),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _number(average, locale),
                      style: AppTypography.heroNumber.copyWith(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(l10n.kcal, style: AppTypography.bodySmall),
              ],
            ),
            if (difference != null) ...[
              const SizedBox(height: 2),
              Text(
                _differenceText(l10n, difference),
                style: AppTypography.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            _DayBars(summary: summary, locale: locale),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.borderGrey),
          ),
          _WeightRow(summary: summary, locale: locale),
        ],
      ),
    );
  }

  String _differenceText(AppLocalizations l10n, double difference) {
    final kcal = _number(difference.abs(), locale);
    if (difference.abs() < 25) return l10n.weeklyOnTarget;
    return difference > 0
        ? l10n.weeklyAboveTarget(kcal)
        : l10n.weeklyBelowTarget(kcal);
  }
}

class _WeightRow extends StatelessWidget {
  final WeeklySummary summary;
  final String locale;

  const _WeightRow({required this.summary, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final change = summary.weightChange;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            change == null ? l10n.weeklyWeightNeedMore : l10n.weight,
            style: change == null
                ? AppTypography.bodySmall
                : AppTypography.bodyMedium,
          ),
        ),
        if (change != null)
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_signed(change, locale)} ${l10n.kg}',
                    style: AppTypography.dataMedium,
                  ),
                ),
                Text(
                  l10n.weeklyWeightSpan(summary.weightSpanDays),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One bar per day, with the target as a line across them.
class _DayBars extends StatelessWidget {
  final WeeklySummary summary;
  final String locale;

  const _DayBars({required this.summary, required this.locale});

  static const _chartHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final target = summary.targetCalories;
    final highest = summary.days
        .map((d) => d.calories)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final scaleMax = (highest > target ? highest : target) * 1.15;
    final dayFormat = DateFormat.E(locale);
    String label(DateTime day) {
      final name = dayFormat
          .format(day)
          .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
      return name.substring(0, name.length < 2 ? name.length : 2);
    }

    final spoken = summary.days
        .where((d) => d.logged)
        .map(
          (d) =>
              '${DateFormat.MMMEd(locale).format(d.day)}: ${_number(d.calories, locale)} ${l10n.kcal}',
        )
        .join(', ');

    return Semantics(
      label: '${l10n.weeklySummaryTitle}. $spoken',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _chartHeight,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _chartHeight * target / scaleMax,
                    child: Container(height: 1, color: AppColors.slate),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final day in summary.days)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: day.logged
                                    ? (_chartHeight * day.calories / scaleMax)
                                          .clamp(3.0, _chartHeight)
                                    : 3,
                                decoration: BoxDecoration(
                                  color: day.logged
                                      ? AppColors.primary
                                      : AppColors.borderGrey,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final day in summary.days)
                  Expanded(
                    child: Text(
                      label(day.day),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.weeklyTarget(_number(target, locale)),
              style: AppTypography.bodySmall.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class BurnCard extends StatelessWidget {
  final ExpenditureEstimate estimate;
  final double formulaKcal;
  final String locale;

  const BurnCard({
    super.key,
    required this.estimate,
    required this.formulaKcal,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kcal = estimate.kcal;

    return AppCard(
      backgroundColor: AppColors.glacialWhite,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.burnTitle,
            style: AppTypography.labelLarge.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: 10),
          if (estimate.status == ExpenditureStatus.ready && kcal != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _number(kcal, locale),
                      style: AppTypography.heroNumber.copyWith(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${l10n.kcal} / ${l10n.day.toLowerCase()}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.burnBasis(estimate.loggedDays, estimate.weighIns),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.burnWeightTrend(
                _signed(estimate.weightRatePerWeek ?? 0, locale),
              ),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.burnFormula(_number(formulaKcal, locale)),
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.burnDisclaimer,
              style: AppTypography.bodySmall.copyWith(fontSize: 12),
            ),
          ] else if (estimate.status == ExpenditureStatus.implausible)
            Text(l10n.burnImplausible, style: AppTypography.bodyMedium)
          else
            Text(
              l10n.burnNeedsData(estimate.loggedDays, estimate.weighIns),
              style: AppTypography.bodyMedium,
            ),
        ],
      ),
    );
  }
}
