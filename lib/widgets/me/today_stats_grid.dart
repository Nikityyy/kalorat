import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../extensions/l10n_extension.dart';

class TodayStatsGrid extends StatelessWidget {
  const TodayStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final stats = provider.getTodayStats();
    final l10n = context.l10n;

    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n.calories,
                value:
                    '${stats['calories']!.toInt()} / ${user.dailyCalorieTarget.toInt()}',
                unit: l10n.kcal,
                icon: Icons.local_fire_department_outlined,
                color: AppColors.primary,
                progress: stats['calories']! / user.dailyCalorieTarget,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: l10n.protein,
                value:
                    '${stats['protein']!.toInt()} / ${user.dailyProteinTarget.toInt()}',
                unit: l10n.grams,
                icon: Icons.fitness_center_outlined,
                color: AppColors.styrianForest,
                progress: stats['protein']! / user.dailyProteinTarget,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n.carbs,
                value:
                    '${stats['carbs']!.toInt()} / ${user.dailyCarbTarget.toInt()}',
                unit: l10n.grams,
                icon: Icons.bakery_dining_outlined,
                color: AppColors.limestone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: l10n.fats,
                value:
                    '${stats['fats']!.toInt()} / ${user.dailyFatTarget.toInt()}',
                unit: l10n.grams,
                icon: Icons.opacity_outlined,
                color: AppColors.limestone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    final isPrimary =
        color == AppColors.primary || color == AppColors.styrianForest;
    final textColor = isPrimary ? AppColors.limestone : AppColors.slate;
    final subTextColor = isPrimary
        ? AppColors.limestone.withValues(alpha: 0.7)
        : AppColors.slate.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? color : AppColors.pebble,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: isPrimary ? null : Border.all(color: AppColors.pebble),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: subTextColor),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 10,
                  color: subTextColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.dataMedium.copyWith(
              color: textColor,
              fontSize: 14,
            ),
          ),
          Text(
            unit,
            style: AppTypography.bodyMedium.copyWith(
              color: subTextColor,
              fontSize: 12,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.black.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPrimary ? AppColors.limestone : AppColors.primary,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
