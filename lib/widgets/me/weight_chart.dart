import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/weight_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../extensions/l10n_extension.dart';

class WeightChart extends StatelessWidget {
  final List<WeightModel> weights;

  const WeightChart({super.key, required this.weights});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (weights.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.limestone,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppColors.pebble),
        ),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: AppColors.slate.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDataAvailable,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.slate.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final recentWeights = weights.take(14).toList().reversed.toList();
    double minWeight = recentWeights
        .map((e) => e.weight)
        .reduce((a, b) => a < b ? a : b);
    double maxWeight = recentWeights
        .map((e) => e.weight)
        .reduce((a, b) => a > b ? a : b);

    // Dynamic padding
    double minY = (minWeight - 1).floorToDouble();
    double maxY = (maxWeight + 1).ceilToDouble();
    // Ensure we have some range
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.borderGrey),
        // No boxShadow - flat design mandate
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppColors.borderGrey, strokeWidth: 1),
            drawVerticalLine: true,
            verticalInterval: 1,
            getDrawingVerticalLine: (value) => FlLine(
              color: AppColors.borderGrey.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recentWeights.length) {
                    return const SizedBox.shrink();
                  }
                  final date = recentWeights[index].date;
                  final dateStr = '${date.day}.${date.month}';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dateStr,
                      style: AppTypography.dataLabel.copyWith(
                        color: AppColors.slate.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxY - minY) / 4,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == minY || value == maxY) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: AppTypography.dataLabel.copyWith(
                      color: AppColors.slate.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: recentWeights.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.weight);
              }).toList(),
              isCurved: false, // Stepped technical plot
              color: AppColors.styrianForest,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.limestone,
                      strokeWidth: 2,
                      strokeColor: AppColors.styrianForest,
                    ),
              ),
              belowBarData: BarAreaData(
                show: false,
              ), // No gradient fill - flat design
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppColors.styrianForest,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map((LineBarSpot touchedSpot) {
                      final index = touchedSpot.x.toInt();
                      // Check index bounds safety
                      if (index < 0 || index >= recentWeights.length) {
                        return null;
                      }
                      final date = recentWeights[index].date;
                      final dateStr = '${date.day}.${date.month}';

                      final textStyle = AppTypography.dataLabel.copyWith(
                        color: AppColors.limestone,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                      return LineTooltipItem(
                        '$dateStr\n${touchedSpot.y.toStringAsFixed(1)} ${l10n.kg}',
                        textStyle,
                      );
                    })
                    .whereType<LineTooltipItem>()
                    .toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
