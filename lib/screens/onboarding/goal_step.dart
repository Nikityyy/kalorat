import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
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
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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
            isDe ? 'Was ist dein Ziel?' : 'What is your goal?',
            style: AppTypography.displayMedium,
          ),
          const SizedBox(height: 32),

          _buildOption(
            0,
            isDe ? 'Gewicht verlieren' : 'Lose Weight',
            isDe ? 'Fett verbrennen' : 'Burn fat & get lean',
            Icons.arrow_downward,
          ),
          const SizedBox(height: 16),
          _buildOption(
            1,
            isDe ? 'Gewicht halten' : 'Maintain',
            isDe ? 'Gesund & fit bleiben' : 'Stay healthy & fit',
            Icons.check,
          ),
          const SizedBox(height: 16),
          _buildOption(
            2,
            isDe ? 'Muskeln aufbauen' : 'Gain Muscle',
            isDe ? 'Masse & Stärke' : 'Build mass & strength',
            Icons.arrow_upward,
          ),

          const Spacer(),
          ActionButton(
            text: isDe ? 'Plan erstellen' : 'Create Plan',
            onPressed: () => widget.onNext(_selectedIndex),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String title, String subtitle, IconData icon) {
    return BespokeSelectionCard(
      title: title,
      subtitle: subtitle,
      icon: Icon(icon, color: AppColors.carbonBlack, size: 28),
      isSelected: _selectedIndex == index,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}
