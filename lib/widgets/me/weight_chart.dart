import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../extensions/l10n_extension.dart';
import '../../models/weight_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

enum _WeightRange { week, month, year }

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

    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 20),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildRangeSelector(l10n),
          const SizedBox(height: 16),
          Expanded(
            child: visible.isEmpty
                ? _buildEmptyState(l10n)
                : _buildChart(context, visible),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(dynamic l10n) {
    final labels = {
      _WeightRange.week: l10n.week,
      _WeightRange.month: l10n.month,
      _WeightRange.year: l10n.year,
    };

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: _WeightRange.values.map((range) {
          final selected = range == _range;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _range = range),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.styrianForest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labels[range],
                  style: AppTypography.labelLarge.copyWith(
                    color: selected ? AppColors.pureWhite : AppColors.slate,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.borderGrey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
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
                style: AppTypography.dataLabel.copyWith(
                  color: AppColors.slate.withValues(alpha: 0.55),
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: xInterval,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final date = plotStart.add(Duration(days: value.round()));
                final label = plotDays > 60
                    ? DateFormat.MMM(
                        Localizations.localeOf(context).languageCode,
                      ).format(date)
                    : '${date.day}.${date.month}.';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: AppTypography.dataLabel.copyWith(
                      color: AppColors.slate.withValues(alpha: 0.55),
                      fontSize: 9,
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
            color: AppColors.styrianForest,
            barWidth: 3,
            dotData: FlDotData(show: weights.length <= 31),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.styrianForest.withValues(alpha: 0.12),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.styrianForest,
            getTooltipItems: (touched) => touched.map((spot) {
              final date = plotStart.add(Duration(days: spot.x.round()));
              return LineTooltipItem(
                '${date.day}.${date.month}.${date.year}\n${spot.y.toStringAsFixed(1)} ${context.l10n.kg}',
                const TextStyle(color: AppColors.pebble),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic l10n) => Center(
    child: Text(
      l10n.noDataAvailable,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.slate.withValues(alpha: 0.5),
      ),
      textAlign: TextAlign.center,
    ),
  );
}
