import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../extensions/l10n_extension.dart';
import '../../models/weight_model.dart';
import '../../theme/app_colors.dart';
import '../common/mono_digits.dart';
import '../common/segmented_tabs.dart';
import '../../theme/app_typography.dart';

enum _WeightRange { week, month, year }

double? weeklyWeightDifference(List<WeightModel> weights) {
  if (weights.length < 2) return null;
  final sorted = List<WeightModel>.from(weights)
    ..sort((a, b) => b.date.compareTo(a.date));
  final latest = sorted.first;
  final cutoff = latest.date.subtract(const Duration(days: 7));
  final previous = sorted.where((weight) => !weight.date.isAfter(cutoff));
  return previous.isEmpty ? null : latest.weight - previous.first.weight;
}

List<FlSpot> linearWeightTrend(List<FlSpot> spots) {
  if (spots.length < 2) return const [];
  final meanX =
      spots.map((spot) => spot.x).reduce((a, b) => a + b) / spots.length;
  final meanY =
      spots.map((spot) => spot.y).reduce((a, b) => a + b) / spots.length;
  final denominator = spots
      .map((spot) => (spot.x - meanX) * (spot.x - meanX))
      .reduce((a, b) => a + b);
  if (denominator == 0) return const [];
  final slope =
      spots
          .map((spot) => (spot.x - meanX) * (spot.y - meanY))
          .reduce((a, b) => a + b) /
      denominator;
  double y(double x) => meanY + slope * (x - meanX);
  return [
    FlSpot(spots.first.x, y(spots.first.x)),
    FlSpot(spots.last.x, y(spots.last.x)),
  ];
}

class WeightChart extends StatefulWidget {
  final List<WeightModel> weights;

  const WeightChart({super.key, required this.weights});

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  _WeightRange _range = _WeightRange.month;

  int get _days => switch (_range) {
    _WeightRange.week => 7,
    _WeightRange.month => 30,
    _WeightRange.year => 365,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = DateUtils.dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: _days - 1));
    final visible = widget.weights.where((weight) {
      final date = DateUtils.dateOnly(weight.date);
      return !date.isBefore(start) && !date.isAfter(today);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final latest = widget.weights.isEmpty
        ? null
        : widget.weights.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    final difference = weeklyWeightDifference(widget.weights);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (latest != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                latest.weight.toStringAsFixed(1),
                style: AppTypography.hero(size: 44),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.kg,
                style: AppTypography.body.copyWith(color: AppColors.ink2),
              ),
            ],
          ),
          if (difference != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: MonoDigits(
                l10n.weeklyDifference(
                  '${difference >= 0 ? '+' : '−'}${difference.abs().toStringAsFixed(1)}',
                ),
                style: AppTypography.secondary,
              ),
            ),
          const SizedBox(height: 16),
        ],
        SegmentedTabs(
          labels: [l10n.week, l10n.month, l10n.year],
          selected: _range.index,
          onChanged: (i) => setState(() => _range = _WeightRange.values[i]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: visible.isEmpty
              ? _buildEmptyState(l10n)
              : _buildChart(context, visible),
        ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, List<WeightModel> weights) {
    final firstDate = DateUtils.dateOnly(weights.first.date);
    final lastDate = DateUtils.dateOnly(weights.last.date);
    final dataSpan = lastDate.difference(firstDate).inDays;
    final paddingDays = (dataSpan * 0.05).round().clamp(1, 14);
    final plotStart = firstDate.subtract(Duration(days: paddingDays));
    final plotEnd = lastDate.add(Duration(days: paddingDays));
    final plotDays = plotEnd.difference(plotStart).inDays;
    final spots = weights
        .map(
          (weight) => FlSpot(
            DateUtils.dateOnly(
              weight.date,
            ).difference(plotStart).inDays.toDouble(),
            weight.weight,
          ),
        )
        .toList();
    final trend = linearWeightTrend(spots);
    final lowest = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final highest = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    var minY = (lowest - 1).floorToDouble();
    var maxY = (highest + 1).ceilToDouble();
    if (minY == maxY) maxY = minY + 2;
    final yInterval = (maxY - minY) / 4;
    final xInterval = switch (_range) {
      _WeightRange.week => 1.0,
      _WeightRange.month ||
      _WeightRange.year => (plotDays / 4).clamp(1.0, double.infinity),
    };

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: plotDays.toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yInterval,
              reservedSize: 44,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(1),
                style: AppTypography.number(
                  size: 12,
                  weight: FontWeight.w400,
                  color: AppColors.ink3,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: xInterval,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final date = plotStart.add(Duration(days: value.round()));
                final label = plotDays > 60
                    ? DateFormat.MMM(
                        Localizations.localeOf(context).languageCode,
                      ).format(date)
                    : DateFormat.Md(
                        Localizations.localeOf(context).languageCode,
                      ).format(date);
                // The first and last dates sit on the chart's edges; keep
                // them inside it instead of half cut off.
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(
                    label,
                    style: AppTypography.number(
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppColors.ink3,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(show: weights.length <= 31),
            belowBarData: BarAreaData(show: true, color: AppColors.accentSoft),
          ),
          if (trend.isNotEmpty)
            LineChartBarData(
              spots: trend,
              isCurved: false,
              color: AppColors.ink3,
              barWidth: 1.2,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primary,
            getTooltipItems: (touched) => touched.map((spot) {
              final date = plotStart.add(Duration(days: spot.x.round()));
              return LineTooltipItem(
                '${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(date)}\n${spot.y.toStringAsFixed(1)} ${context.l10n.kg}',
                TextStyle(color: AppColors.onPrimary),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) => Center(
    child: Text(
      l10n.noDataAvailable,
      style: AppTypography.secondary,
      textAlign: TextAlign.center,
    ),
  );
}
