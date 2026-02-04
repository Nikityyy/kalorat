import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import 'common/app_card.dart';

class MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String language;

  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
    this.language = 'de',
  });

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: Colors.white,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (meal.photoPaths.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(meal.photoPaths.first),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 60,
                        height: 60,
                        color: AppColors.celadon.withValues(alpha: 0.5),
                        child: const Icon(
                          Icons.image,
                          color: AppColors.carbonBlack,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.celadon.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: AppColors.carbonBlack,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              meal.isPending
                                  ? (language == 'de'
                                        ? 'Ausstehend...'
                                        : 'Pending...')
                                  : meal.mealName.isNotEmpty
                                  ? meal.mealName
                                  : (language == 'de' ? 'Mahlzeit' : 'Meal'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: meal.isPending
                                    ? AppColors.warning
                                    : AppColors.carbonBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(meal.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.carbonBlack.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (!meal.isPending) ...[
                        Text(
                          '${meal.calories.toInt()} kcal',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors
                                .shamrock, // Highlight calories with primary color
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
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              language == 'de'
                                  ? 'Wird analysiert...'
                                  : 'Being analyzed...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.carbonBlack.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.delete
                          : Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ),
            if (!meal.isPending) ...[
              const Divider(height: 24, color: AppColors.celadon),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroChip(
                    label: language == 'de' ? 'Eiweiß' : 'Protein',
                    value: '${meal.protein.toInt()}g',
                    color: const Color(0xFF4A90E2),
                  ),
                  _MacroChip(
                    label: language == 'de' ? 'Kohlenhydrate' : 'Carbs',
                    value: '${meal.carbs.toInt()}g',
                    color: const Color(0xFFF5A623),
                  ),
                  _MacroChip(
                    label: language == 'de' ? 'Fett' : 'Fat',
                    value: '${meal.fats.toInt()}g',
                    color: const Color(0xFFD0021B),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.carbonBlack.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
