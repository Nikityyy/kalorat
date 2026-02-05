import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/bespoke_wheel.dart';

class AgeStep extends StatefulWidget {
  final int initialValue;
  final Function(int) onNext;
  final String language;

  const AgeStep({
    super.key,
    required this.initialValue,
    required this.onNext,
    required this.language,
  });

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  late int _currentValue;

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
          Text(l10n.howOldAreYou, style: AppTypography.displayMedium),
          const SizedBox(height: 48),

          Expanded(
            child: Center(
              child: BespokeWheelPicker(
                options: List.generate(
                  100,
                  (index) => '${index + 10}',
                ), // 10 to 110
                initialIndex: _currentValue - 10,
                onValueChanged: (index) {
                  _currentValue = index + 10;
                },
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
