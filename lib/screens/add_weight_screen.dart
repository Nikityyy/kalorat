import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:kalorat/theme/app_colors.dart';
import 'package:kalorat/extensions/l10n_extension.dart';
import 'package:kalorat/extensions/validation_l10n.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/adaptive.dart';
import '../widgets/app_toast.dart';

class AddWeightScreen extends StatefulWidget {
  final WeightModel? initialWeight;

  const AddWeightScreen({super.key, this.initialWeight});

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  late TextEditingController _weightController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialWeight?.date ?? DateTime.now();
    final provider = context.read<AppProvider>();
    final weights = provider.weights;
    _weightController = TextEditingController(
      text: widget.initialWeight != null
          ? widget.initialWeight!.weight.toStringAsFixed(1)
          : weights.isNotEmpty
          ? weights.first.weight.toStringAsFixed(1)
          : provider.user?.weight.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialWeight == null
              ? context.l10n.addWeight
              : context.l10n.editWeight,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.date,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderGrey),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Text(
                  DateFormat.yMd(
                    Localizations.localeOf(context).toString(),
                  ).format(_selectedDate),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.weightKg,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              magnifierConfiguration: fieldMagnifier,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 24),
              decoration: InputDecoration(
                hintText: '70.0',
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.styrianForest,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                context.l10n.save,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate(BuildContext context) async {
    final date = await pickDate(
      context,
      initial: _selectedDate,
      first: DateTime(2020),
      last: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  void _save() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight < 20 || weight > 400) {
      AppToast.show(
        context,
        context.l10n.weightRangeError,
        kind: AppToastKind.info,
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final previous = provider.weights.isEmpty
        ? null
        : provider.weights.first.weight;
    if (previous != null &&
        (weight - previous).abs() > 10 &&
        (weight - previous).abs() / previous > 0.1) {
      final confirmed = await showConfirmDialog(
        context,
        title: context.l10n.largeWeightJump,
        message: context.l10n.confirmWeightJump(
          previous.toStringAsFixed(1),
          weight.toStringAsFixed(1),
        ),
        confirmLabel: context.l10n.save,
      );
      if (!confirmed) return;
    }

    try {
      final updated = WeightModel(
        date: _selectedDate,
        weight: weight,
        note: widget.initialWeight?.note,
      );
      if (widget.initialWeight == null) {
        await provider.saveWeight(updated);
      } else {
        await provider.updateWeight(widget.initialWeight!, updated);
      }
    } on FormatException catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          errorMessage(context.l10n, e),
          kind: AppToastKind.info,
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      AppToast.show(context, context.l10n.weightSaved, kind: AppToastKind.info);
    }
  }
}
