import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/bespoke_selection_card.dart';
import '../../widgets/common/adaptive.dart';

/// The name and the goal on one page.
class AboutStep extends StatefulWidget {
  final String? initialName;
  final int initialGoalIndex;
  final void Function(String name, int goalIndex) onNext;

  const AboutStep({
    super.key,
    required this.onNext,
    this.initialName,
    required this.initialGoalIndex,
  });

  @override
  State<AboutStep> createState() => _AboutStepState();
}

class _AboutStepState extends State<AboutStep> {
  late final TextEditingController _controller;
  late int _goalIndex;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _goalIndex = widget.initialGoalIndex;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = context.l10n.nameValidationError);
      return;
    }
    widget.onNext(name, _goalIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(l10n.onboardingName, style: AppTypography.displayMedium),
                const SizedBox(height: 8),
                Text(l10n.nameSubtitle, style: AppTypography.bodyMedium),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofillHints: const [AutofillHints.givenName],
                  textCapitalization: TextCapitalization.words,
                  magnifierConfiguration: fieldMagnifier,
                  style: AppTypography.displayMedium,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: l10n.onboardingNameHint,
                    hintStyle: AppTypography.displayMedium.copyWith(
                      color: AppColors.text.withValues(alpha: 0.3),
                    ),
                    errorText: _errorMessage,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.surface, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(l10n.whatIsYourGoal, style: AppTypography.titleLarge),
                const SizedBox(height: 16),
                _goalOption(
                  0,
                  l10n.loseWeight,
                  l10n.burnFatSubtitle,
                  Icons.arrow_downward,
                ),
                const SizedBox(height: 12),
                _goalOption(
                  1,
                  l10n.maintainWeight,
                  l10n.maintainSubtitle,
                  Icons.check,
                ),
                const SizedBox(height: 12),
                _goalOption(
                  2,
                  l10n.gainMuscle,
                  l10n.buildMassSubtitle,
                  Icons.arrow_upward,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ActionButton(text: l10n.continueButton, onPressed: _submit),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _goalOption(int index, String title, String subtitle, IconData icon) {
    return BespokeSelectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon, color: AppColors.text, size: 28),
      isSelected: _goalIndex == index,
      onTap: () => setState(() => _goalIndex = index),
    );
  }
}
