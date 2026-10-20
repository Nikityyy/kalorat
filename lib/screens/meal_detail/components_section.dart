import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../extensions/l10n_extension.dart';
import '../../models/meal_component.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/haptics.dart';
import '../../widgets/common/mono_digits.dart';
import '../../widgets/common/warm_up.dart';

/// A no-break space: between a number and its unit, so "180 g" stays on one
/// line and the Mono face does not widen the gap. Not the narrow one
/// (U+202F): the app's fonts lack it, and the browser then loads a fallback
/// font for it.
const _unitGap = ' ';

/// "Auf dem Teller": what the meal is made of, one ruled row per component
/// with its amount and calories as shown (portion included). A tap edits it.
class MealComponentsSection extends StatelessWidget {
  final List<MealComponent> components;
  final double multiplier;
  final ValueChanged<int> onEdit;

  const MealComponentsSection({
    super.key,
    required this.components,
    required this.multiplier,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = components.fold<double>(0, (sum, c) => sum + c.calories);
    final ranked = [...components]
      ..sort((a, b) => b.calories.compareTo(a.calories));
    final topShare = ranked.length >= 3 && total > 0
        ? ((ranked[0].calories + ranked[1].calories) / total * 100).round()
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(l10n.componentsTitle, style: AppTypography.heading),
            ),
            Text(l10n.componentsTapToEdit, style: AppTypography.meta),
          ],
        ),
        if (topShare != null) ...[
          const SizedBox(height: 4),
          MonoDigits(
            l10n.componentsTopShare(ranked[0].name, ranked[1].name, topShare),
            style: AppTypography.secondary,
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < components.length; i++)
          _ComponentRow(
            component: components[i],
            multiplier: multiplier,
            last: i == components.length - 1,
            onTap: () {
              Haptics.tick();
              onEdit(i);
            },
          ),
      ],
    );
  }
}

class _ComponentRow extends StatelessWidget {
  final MealComponent component;
  final double multiplier;
  final bool last;
  final VoidCallback onTap;

  const _ComponentRow({
    required this.component,
    required this.multiplier,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final grams = (component.grams * multiplier).round();
    final kcal = (component.calories * multiplier).round();
    final assumption = component.assumption.trim();
    return Semantics(
      button: true,
      label: '${component.name}, $grams ${l10n.grams}, $kcal ${l10n.kcal}',
      hint: l10n.componentEditHint,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border),
              bottom: last
                  ? BorderSide(color: AppColors.border)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(component.name, style: AppTypography.body),
                    if (assumption.isNotEmpty)
                      Text(
                        assumption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: _NumberUnit(
                  value: '$grams',
                  unit: l10n.grams,
                  size: 15,
                  weight: FontWeight.w600,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$kcal',
                  textAlign: TextAlign.right,
                  style: AppTypography.number(size: 16, color: AppColors.ink2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A Mono number with its unit in Outfit after a no-break space.
class _NumberUnit extends StatelessWidget {
  final String value;
  final String unit;
  final double size;
  final FontWeight weight;
  final double unitSize;

  const _NumberUnit({
    required this.value,
    required this.unit,
    this.size = 17,
    this.weight = FontWeight.w500,
    double? unitSize,
  }) : unitSize = unitSize ?? size;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: AppTypography.number(size: size, weight: weight),
          ),
          TextSpan(
            text: '$_unitGap$unit',
            style: AppTypography.secondary.copyWith(fontSize: unitSize),
          ),
        ],
      ),
    );
  }
}

/// What the edit sheet asks for: the component's new amount (as shown,
/// portion included), or its removal.
class ComponentEdit {
  final double? grams;
  const ComponentEdit.amount(double this.grams);
  const ComponentEdit.remove() : grams = null;
}

/// Edits one component's amount as shown. [mealCalories] is the meal's
/// calories as shown, for the "meal now" line. Null when closed.
Future<ComponentEdit?> showComponentSheet(
  BuildContext context, {
  required MealComponent component,
  required double multiplier,
  required double mealCalories,
  required bool canRemove,
}) => showModalBottomSheet<ComponentEdit>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ComponentSheet(
    component: component,
    multiplier: multiplier,
    mealCalories: mealCalories,
    canRemove: canRemove,
  ),
);

/// The sheet as [showComponentSheet] shows it, for [WarmUp.run].
Widget componentSheetWarmUp(BuildContext context) => WarmUpSheet(
  child: _ComponentSheet(
    component: MealComponent(
      // Never seen; any text in the sheet's style will do.
      name: context.l10n.componentsTitle,
      grams: 180,
      kcalPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28,
      fatsPer100g: 0.3,
    ),
    multiplier: 1,
    mealCalories: 520,
    canRemove: true,
  ),
);

class _ComponentSheet extends StatefulWidget {
  final MealComponent component;
  final double multiplier;
  final double mealCalories;
  final bool canRemove;

  const _ComponentSheet({
    required this.component,
    required this.multiplier,
    required this.mealCalories,
    required this.canRemove,
  });

  @override
  State<_ComponentSheet> createState() => _ComponentSheetState();
}

class _ComponentSheetState extends State<_ComponentSheet> {
  static const _factors = [0.5, 0.75, 1.0, 1.5];

  late final double _original = (widget.component.grams * widget.multiplier)
      .roundToDouble();
  late double _grams = _original;

  double get _step => _grams < 50 ? 5 : 10;

  void _set(double grams) {
    final value = grams.clamp(0, 5000).roundToDouble();
    if (value == _grams) return;
    Haptics.selection();
    setState(() => _grams = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final factorFormat = NumberFormat('0.##', locale);
    final c = widget.component;
    final kcal = c.kcalPer100g * _grams / 100;
    final mealNow = widget.mealCalories - c.calories * widget.multiplier + kcal;
    final per100 = l10n.componentPer100(c.kcalPer100g.round());
    final source = c.ref != null && c.ref != 'other'
        ? '${l10n.componentSourceUsda} · $per100'
        : per100;
    // "Gekocht." reads as a sentence end before the source.
    final assumption = c.assumption.trim().replaceFirst(RegExp(r'[.。]+$'), '');
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(c.name, style: AppTypography.heading),
            const SizedBox(height: 4),
            MonoDigits(
              assumption.isNotEmpty ? '$assumption · $source' : source,
              style: AppTypography.secondary,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StepButton(
                  icon: Icons.remove_rounded,
                  label: l10n.componentLess,
                  onTap: _grams > 0 ? () => _set(_grams - _step) : null,
                ),
                Expanded(
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${_grams.round()}',
                            style: AppTypography.hero(size: 48),
                          ),
                          TextSpan(
                            text: '$_unitGap${l10n.grams}',
                            style: AppTypography.body.copyWith(
                              color: AppColors.ink2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  label: l10n.componentMore,
                  onTap: () => _set(_grams + _step),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: MonoDigits(
                l10n.componentMealNow(kcal.round(), mealNow.round()),
                style: AppTypography.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (var i = 0; i < _factors.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _FactorChip(
                      label: '${factorFormat.format(_factors[i])}×',
                      selected:
                          _grams == (_original * _factors[i]).roundToDouble(),
                      onTap: () => _set(_original * _factors[i]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (widget.canRemove) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Haptics.tick();
                        Navigator.pop(context, const ComponentEdit.remove());
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.negative,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: shape,
                      ),
                      child: Text(l10n.componentRemove),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Haptics.confirm();
                      Navigator.pop(context, ComponentEdit.amount(_grams));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: shape,
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.componentApply,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          side: BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              size: 24,
              color: onTap == null ? AppColors.ink3 : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _FactorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FactorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: AppTypography.number(
                size: 16,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
