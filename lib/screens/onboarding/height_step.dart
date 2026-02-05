import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/ruler_picker.dart';

class HeightStep extends StatefulWidget {
  final double initialValue;
  final Function(double) onNext;
  final String language;

  const HeightStep({
    super.key,
    required this.initialValue,
    required this.onNext,
    required this.language,
  });

  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDe = widget.language == 'de';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            isDe ? 'Wie groß bist du?' : 'How tall are you?',
            style: AppTypography.displayMedium,
          ),
          const SizedBox(height: 48),

          Expanded(
            child: Center(
              child: RulerPicker(
                minValue: 100,
                maxValue: 250,
                initialValue: _currentValue,
                unit: 'cm',
                onValueChanged: (val) => _currentValue = val,
              ),
            ),
          ),

          ActionButton(
            text: isDe ? 'Weiter' : 'Continue',
            onPressed: () => widget.onNext(_currentValue),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
