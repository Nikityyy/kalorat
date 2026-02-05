import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'common/app_card.dart';

class MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MealCard({super.key, required this.meal, this.onTap, this.onDelete});

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: AppColors.pebble,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Image Section ---
                if (meal.photoPaths.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(meal.photoPaths.first),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.pebble.withValues(alpha: 0.5),
                        child: const Icon(Icons.image, color: AppColors.slate),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.pebble.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, color: AppColors.slate),
                  ),
                const SizedBox(width: 16),

                // --- 2. Content Section (Split into Top and Bottom Rows) ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Top Row: Name and Time ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              meal.isPending
                                  ? l10n.pendingAnalysis
                                  : meal.mealName.isNotEmpty
                                  ? meal.mealName
                                  : l10n.mealName,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: meal.isPending
                                    ? AppColors.error
                                    : AppColors.slate,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(meal.timestamp),
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              color: AppColors.slate.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // --- Bottom Row: Calories and Delete Button ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side: Calories or Pending State
                          if (!meal.isPending) ...[
                            Text(
                              '${meal.calories.toInt()} ${l10n.kcal}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.styrianForest,
                              ),
                            ),
                          ] else
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.analyzing,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 12,
                                    color: AppColors.slate.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          // Right side: Delete Button
                          if (onDelete != null)
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerRight,
                                icon: Icon(
                                  Platform.isIOS
                                      ? CupertinoIcons.delete
                                      : Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 22,
                                ),
                                onPressed: onDelete,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Macros Divider ---
            if (!meal.isPending) ...[
              const Divider(height: 24, color: AppColors.pebble),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroChip(
                    label: l10n.protein,
                    value: '${meal.protein.toInt()}${l10n.grams}',
                    color: AppColors.styrianForest,
                  ),
                  _MacroChip(
                    label: l10n.carbs,
                    value: '${meal.carbs.toInt()}${l10n.grams}',
                    color: AppColors.styrianForest,
                  ),
                  _MacroChip(
                    label: l10n.fats,
                    value: '${meal.fats.toInt()}${l10n.grams}',
                    color: AppColors.styrianForest,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(fontSize: 16, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 11,
            color: AppColors.slate.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
