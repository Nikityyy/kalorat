import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/inputs/action_button.dart';
import '../../widgets/inputs/bespoke_selection_card.dart';

class ActivityLevelStep extends StatefulWidget {
  final int initialLevel;
  final Function(int) onNext;

  const ActivityLevelStep({
    super.key,
    required this.initialLevel,
    required this.onNext,
  });

  @override
  State<ActivityLevelStep> createState() => _ActivityLevelStepState();
}

class _ActivityLevelStepState extends State<ActivityLevelStep> {
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
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
          Text(l10n.activityLevel, style: AppTypography.displayMedium),
          const SizedBox(height: 8),
          Text(
            l10n.activityLevelSubtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.slate.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildOption(
                    0,
                    l10n.sedentary,
                    l10n.sedentarySubtitle,
                    Icons.weekend_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildOption(
                    1,
                    l10n.lightlyActive,
                    l10n.lightlyActiveSubtitle,
                    Icons.directions_walk_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildOption(
                    2,
                    l10n.moderatelyActive,
                    l10n.moderatelyActiveSubtitle,
                    Icons.directions_run_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildOption(
                    3,
                    l10n.activeLevel,
                    l10n.activeSubtitle,
                    Icons.fitness_center_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildOption(
                    4,
                    l10n.veryActive,
                    l10n.veryActiveSubtitle,
                    Icons.landscape_outlined,
                  ),
                ],
              ),
            ),
          ),

          ActionButton(
            text: l10n.continueButton,
            onPressed: () => widget.onNext(_selectedLevel),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOption(int level, String title, String subtitle, IconData icon) {
    return BespokeSelectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon, color: AppColors.slate, size: 28),
      isSelected: _selectedLevel == level,
      onTap: () => setState(() => _selectedLevel = level),
    );
  }
}
