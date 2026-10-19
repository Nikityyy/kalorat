import 'package:flutter/material.dart';
import '../../models/weight_model.dart';
import '../../theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../common/mono_digits.dart';
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
        for (var i = 0; i < visibleWeights.length; i++)
          _row(context, visibleWeights[i], i == visibleWeights.length - 1),
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

  Widget _row(BuildContext context, WeightModel weight, bool last) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: last ? BorderSide(color: AppColors.border) : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: MonoDigits(
              DateFormat.yMMMd(language).format(weight.date),
              style: AppTypography.body,
            ),
          ),
          if (weight.isPending) ...[
            Icon(Icons.cloud_upload_outlined, size: 16, color: AppColors.ink3),
            const SizedBox(width: 8),
          ],
          Text(
            weight.weight.toStringAsFixed(1),
            style: AppTypography.number(size: 17),
          ),
          Text(' ${l10n.kg}', style: AppTypography.secondary),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.ink2, size: 20),
            tooltip: l10n.editWeight,
            onPressed: () => widget.onEdit(weight),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.ink2, size: 20),
            tooltip: l10n.delete,
            onPressed: () => widget.onDelete(weight),
          ),
        ],
      ),
    );
  }
}
