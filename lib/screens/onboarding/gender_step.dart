import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
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
    final isDe = widget.language == 'de';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            isDe ? 'Wähle dein Geschlecht' : 'Choose your gender',
            style: AppTypography.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isDe
                ? 'Um deinen Grundumsatz zu berechnen.'
                : 'To calculate your metabolic rate.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 32),

          _buildOption(0, isDe ? 'Männlich' : 'Male', Icons.male),
          const SizedBox(height: 16),
          _buildOption(1, isDe ? 'Weiblich' : 'Female', Icons.female),
          const SizedBox(height: 16),
          _buildOption(2, isDe ? 'Divers' : 'Other', Icons.person_outline),

          const Spacer(),
          ActionButton(
            text: isDe ? 'Weiter' : 'Continue',
            onPressed: () => widget.onNext(_selectedIndex),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String title, IconData icon) {
    return BespokeSelectionCard(
      title: title,
      icon: Icon(icon, color: AppColors.carbonBlack, size: 28),
      isSelected: _selectedIndex == index,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }
}
