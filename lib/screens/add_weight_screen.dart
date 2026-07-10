import '../utils/platform_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kalorat/theme/app_colors.dart';
import 'package:kalorat/extensions/l10n_extension.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

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
                  '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
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
                foregroundColor: AppColors.pebble,
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
    if (PlatformUtils.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _selectedDate,
            maximumDate: DateTime.now(),
            onDateTimeChanged: (date) => setState(() => _selectedDate = date),
          ),
        ),
      );
    } else {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (date != null) setState(() => _selectedDate = date);
    }
  }

  void _save() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight < 20 || weight > 400) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.weightRangeError)));
      return;
    }

    final provider = context.read<AppProvider>();
    final previous = provider.weights.isEmpty
        ? null
        : provider.weights.first.weight;
    if (previous != null &&
        (weight - previous).abs() > 10 &&
        (weight - previous).abs() / previous > 0.1) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.largeWeightJump),
          content: Text(
            context.l10n.confirmWeightJump(
              previous.toStringAsFixed(1),
              weight.toStringAsFixed(1),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.save),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.weightSaved)));
    }
  }
}
