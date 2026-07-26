import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/bespoke_selection_card.dart';

class GenderStep extends StatefulWidget {
  final Function(int) onNext;
  final int initialIndex;
  final String language;

  const GenderStep({
    super.key,
    required this.onNext,
    required this.initialIndex,
    required this.language,
  });

  @override
  State<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<GenderStep> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(l10n.chooseGender, style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          Text(l10n.calculateMetabolicRate, style: AppTypography.bodyMedium),
          const SizedBox(height: 32),

          _buildOption(0, l10n.male),
          const SizedBox(height: 16),
          _buildOption(1, l10n.female),

          const Spacer(),
          ActionButton(
            text: l10n.continueButton,
            onPressed: () => widget.onNext(_selectedIndex),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String title) {
    return BespokeSelectionCard(
      title: title,
      isSelected: _selectedIndex == index,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}
