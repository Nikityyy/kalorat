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
  final Set<int> _secondaryGoals = {};

  @override
  void initState() {
    super.initState();
    _primaryGoalIndex = widget.initialIndex;
  }

  void _toggleSecondary(int index) {
    setState(() {
      if (_secondaryGoals.contains(index)) {
        _secondaryGoals.remove(index);
      } else {
        _secondaryGoals.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(l10n.whatIsYourGoal, style: AppTypography.displayMedium),
                const SizedBox(height: 32),
                
                Text(
                  l10n.primaryGoal, 
                  style: AppTypography.labelLarge.copyWith(color: AppColors.slate),
                ),
                const SizedBox(height: 16),
                _buildPrimaryOption(0, l10n.loseWeight, l10n.burnFatSubtitle, Icons.arrow_downward),
                const SizedBox(height: 12),
                _buildPrimaryOption(1, l10n.maintainWeight, l10n.maintainSubtitle, Icons.check),
                const SizedBox(height: 12),
                _buildPrimaryOption(2, l10n.gainMuscle, l10n.buildMassSubtitle, Icons.arrow_upward),
                
                const SizedBox(height: 32),
                Text(
                  l10n.secondaryOutcomes, 
                  style: AppTypography.labelLarge.copyWith(color: AppColors.slate),
                ),
                const SizedBox(height: 16),
                _buildSecondaryOption(3, l10n.boostEnergy, l10n.boostEnergySubtitle, Icons.bolt),
                const SizedBox(height: 12),
                _buildSecondaryOption(4, l10n.improveSleep, l10n.improveSleepSubtitle, Icons.nightlight_round),
                const SizedBox(height: 12),
                _buildSecondaryOption(5, l10n.buildHabits, l10n.buildHabitsSubtitle, Icons.loop),
                const SizedBox(height: 32),
              ],
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionButton(
                  text: l10n.continueButton,
                  onPressed: () => widget.onNext(_primaryGoalIndex),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryOption(int index, String title, String subtitle, IconData icon) {
    return BespokeSelectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon, color: AppColors.slate, size: 28),
      isSelected: _primaryGoalIndex == index,
      onTap: () => setState(() => _primaryGoalIndex = index),
    );
  }

  Widget _buildSecondaryOption(int index, String title, String subtitle, IconData icon) {
    return BespokeSelectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon, color: AppColors.slate, size: 28),
      isSelected: _secondaryGoals.contains(index),
      onTap: () => _toggleSecondary(index),
    );
  }
}
