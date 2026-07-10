import 'package:flutter/material.dart';
import '../../models/weight_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../extensions/l10n_extension.dart';

class WeightList extends StatefulWidget {
  final List<WeightModel> weights;
  final Function(WeightModel) onDelete;
  final Function(WeightModel) onEdit;

  const WeightList({
    super.key,
    required this.weights,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<WeightList> createState() => _WeightListState();
}

class _WeightListState extends State<WeightList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.weights.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleWeights = _expanded
        ? widget.weights
        : widget.weights.take(5).toList();

    return Column(
      children: [
        ...visibleWeights.map(
          (weight) => Container(
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
                    if (weight.isPending) ...[
                      const Icon(Icons.cloud_upload_outlined, size: 16),
                      const SizedBox(width: 8),
                    ],
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
                        Icons.edit_outlined,
                        color: AppColors.slate,
                        size: 20,
                      ),
                      tooltip: context.l10n.editWeight,
                      onPressed: () => widget.onEdit(weight),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.slate, // Muted slate, not red
                        size: 20,
                      ),
                      onPressed: () => widget.onDelete(weight),
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
          ),
        ),
        if (widget.weights.length > 5)
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(
              _expanded
                  ? context.l10n.showLess
                  : context.l10n.showAllWeights(widget.weights.length),
            ),
          ),
      ],
    );
  }
}
