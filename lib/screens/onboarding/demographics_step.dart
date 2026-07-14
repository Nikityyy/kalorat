import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/bespoke_selection_card.dart';
import '../../widgets/inputs/bespoke_wheel.dart';

class DemographicsStep extends StatefulWidget {
  final int initialAge;
  final int initialGenderIndex;
  final Function(int age, int gender) onNext;
  final String language;

  const DemographicsStep({
    super.key,
    required this.initialAge,
    required this.initialGenderIndex,
    required this.onNext,
    required this.language,
  });

  @override
  State<DemographicsStep> createState() => _DemographicsStepState();
}

class _DemographicsStepState extends State<DemographicsStep> {
  late int _currentAge;
  late int _genderIndex;

  @override
  void initState() {
    super.initState();
    _currentAge = widget.initialAge;
    _genderIndex = widget.initialGenderIndex;
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
          Text(l10n.aBitAboutYou, style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          Text(l10n.calculateMetabolicRate, style: AppTypography.bodyMedium),
          const SizedBox(height: 32),
          
          Text(l10n.biologicalSex, style: AppTypography.labelLarge.copyWith(color: AppColors.slate)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BespokeSelectionCard(
                  title: l10n.male,
                  icon: const Icon(Icons.male, color: AppColors.slate, size: 28),
                  isSelected: _genderIndex == 0,
                  onTap: () => setState(() => _genderIndex = 0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BespokeSelectionCard(
                  title: l10n.female,
                  icon: const Icon(Icons.female, color: AppColors.slate, size: 28),
                  isSelected: _genderIndex == 1,
                  onTap: () => setState(() => _genderIndex = 1),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          Text(l10n.age, style: AppTypography.labelLarge.copyWith(color: AppColors.slate)),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: BespokeWheelPicker(
                options: List.generate(100, (index) => '${index + 10}'),
                initialIndex: _currentAge - 10,
                onValueChanged: (index) {
                  _currentAge = index + 10;
                },
              ),
            ),
          ),

          ActionButton(
            text: l10n.continueButton,
            onPressed: () => widget.onNext(_currentAge, _genderIndex),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
