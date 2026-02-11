import 'package:flutter/material.dart';
import '../../models/weight_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

class WeightList extends StatelessWidget {
  final List<WeightModel> weights;
  final Function(WeightModel) onDelete;
  final String language;

  const WeightList({
    super.key,
    required this.weights,
    required this.onDelete,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentWeights = weights.take(5).toList();

    return Column(
      children: recentWeights.map((weight) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.limestone,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.pebble),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${weight.date.day}.${weight.date.month}.${weight.date.year}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.slate.withValues(alpha: 0.7),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${weight.weight.toStringAsFixed(1)} kg',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.slate, // Muted slate, not red
                      size: 20,
                    ),
                    onPressed: () => onDelete(weight),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
