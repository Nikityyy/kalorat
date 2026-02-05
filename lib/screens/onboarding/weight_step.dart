import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/ruler_picker.dart';

class WeightStep extends StatefulWidget {
  final double initialValue;
  final Function(double) onNext;
  final String language;

  const WeightStep({
    super.key,
    required this.initialValue,
    required this.onNext,
    required this.language,
  });

  @override
  State<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<WeightStep> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
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
          Text(l10n.onboardingWeight, style: AppTypography.displayMedium),
          const SizedBox(height: 48),

          Expanded(
            child: Center(
              child: RulerPicker(
                minValue: 30,
                maxValue: 200,
                initialValue: _currentValue,
                unit: l10n.kg,
                isHorizontal: true, // Use horizontal for consistency for now
                onValueChanged: (val) => _currentValue = val,
              ),
            ),
          ),

          ActionButton(
            text: l10n.continueButton,
            onPressed: () => widget.onNext(_currentValue),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
