import 'dart:convert';
import 'dart:io' show File;
import '../utils/platform_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'common/app_card.dart';

class MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MealCard({super.key, required this.meal, this.onTap, this.onDelete});

  String _formatDateTime(DateTime timestamp) {
    // Format: dd.MM.yyyy HH:mm
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year.toString();
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  Widget _buildMealImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    if (PlatformUtils.isWeb) {
      try {
        // Prepare bytes
        final bytes = base64Decode(imagePath);
        return Image.memory(
          bytes,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      } catch (e) {
        // If it fails (e.g. it's a file path from mobile sync), show placeholder
        return _buildPlaceholder();
      }
    } else {
      return Image.file(
        File(imagePath),
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.steel.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: const Icon(Icons.restaurant, color: AppColors.frost),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: AppColors.steel,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  child: _buildMealImage(
                    meal.photoPaths.isNotEmpty ? meal.photoPaths.first : null,
                  ),
                ),
                const SizedBox(width: 16),

                // --- 2. Content Section ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Top Row: Name and Date/Time ---
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
                                    : AppColors.frost,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(meal.timestamp),
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              color: AppColors.frost.withValues(alpha: 0.6),
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
                          if (!meal.isPending) ...[
                            Text(
                              '${meal.calories.toInt()} ${l10n.kcal}',
                              style: AppTypography.dataMedium.copyWith(
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
                                    color: AppColors.frost.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          if (onDelete != null)
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                // Removed alignment: Alignment.centerRight to center icon
                                icon: Icon(
                                  PlatformUtils.isIOS
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
              Divider(height: 24, color: AppColors.borderGrey),
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
          style: AppTypography.dataMedium.copyWith(fontSize: 16, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 11,
            color: AppColors.frost.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
