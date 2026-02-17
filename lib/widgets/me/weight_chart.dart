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

    // 1. Get the last 7 logged entries (assuming weights is already sorted or needs sorting)
    final sortedWeights = List<WeightModel>.from(weights)
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first

    final recentWeights = sortedWeights
        .take(7)
        .toList()
        .reversed
        .toList(); // Oldest to newest for plotting

    if (recentWeights.isEmpty) {
      return _buildEmptyState(l10n);
    }

    final spots = recentWeights.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    double minWeight = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxWeight = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    // Dynamic padding for Y axis
    double minY = (minWeight - 0.5).floorToDouble();
    double maxY = (maxWeight + 0.5).ceilToDouble();
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.5)),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (recentWeights.length - 1).toDouble().clamp(0, 6),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 3,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.borderGrey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52, // Symmetric value to center the grid
                getTitlesWidget: (value, meta) => SizedBox.shrink(),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recentWeights.length) {
                    return SizedBox.shrink();
                  }

                  final date = recentWeights[index].date;
                  final now = DateTime.now();
                  final isToday =
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      isToday ? l10n.today : '${date.day}.${date.month}.',
                      style: AppTypography.dataLabel.copyWith(
                        color: AppColors.slate.withValues(
                          alpha: isToday ? 0.8 : 0.4,
                        ),
                        fontSize: 9,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxY - minY) / 3,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  // Don't show labels for the very top/bottom grid line to keep it clean
                  if (value == minY || value == maxY) {
                    return SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                    child: Text(
                      value.toStringAsFixed(1),
                      textAlign: TextAlign.left,
                      style: AppTypography.dataLabel.copyWith(
                        color: AppColors.slate.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.styrianForest,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 5,
                      color: AppColors.limestone,
                      strokeWidth: 3,
                      strokeColor: AppColors.styrianForest,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.styrianForest.withValues(alpha: 0.2),
                    AppColors.styrianForest.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppColors.styrianForest,
              tooltipBorderRadius: BorderRadius.circular(12),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map((LineBarSpot touchedSpot) {
                      final index = touchedSpot.x.toInt();
                      if (index < 0 || index >= recentWeights.length) {
                        return null;
                      }
                      final date = recentWeights[index].date;
                      final dateStr = '${date.day}.${date.month}.${date.year}';

                      return LineTooltipItem(
                        '$dateStr\n${touchedSpot.y.toStringAsFixed(1)} ${l10n.kg}',
                        AppTypography.dataLabel.copyWith(
                          color: AppColors.limestone,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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

  Widget _buildEmptyState(dynamic l10n) {
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
}
