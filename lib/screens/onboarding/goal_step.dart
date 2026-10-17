import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/bespoke_selection_card.dart';

class GoalStep extends StatefulWidget {
  final int initialIndex;
  final Function(int) onNext;
  final String language;

  const GoalStep({
    super.key,
    required this.initialIndex,
    required this.onNext,
    required this.language,
  });

  @override
  State<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends State<GoalStep> {
  late int _primaryGoalIndex;

  @override
  void initState() {
    super.initState();
    _primaryGoalIndex = widget.initialIndex;
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
                Text(l10n.whatIsYourGoal, style: AppTypography.displayMedium),
                const SizedBox(height: 32),

                _buildPrimaryOption(
                  0,
                  l10n.loseWeight,
                  l10n.burnFatSubtitle,
                  Icons.arrow_downward,
                ),
                const SizedBox(height: 12),
                _buildPrimaryOption(
                  1,
                  l10n.maintainWeight,
                  l10n.maintainSubtitle,
                  Icons.check,
                ),
                const SizedBox(height: 12),
                _buildPrimaryOption(
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
          child: ActionButton(
            text: l10n.continueButton,
            onPressed: () => widget.onNext(_primaryGoalIndex),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPrimaryOption(
    int index,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return BespokeSelectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon, color: AppColors.slate, size: 28),
      isSelected: _primaryGoalIndex == index,
      onTap: () => setState(() => _primaryGoalIndex = index),
    );
  }
}
