import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../widgets/inputs/action_button.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  final String language;
  final Function(String) onLanguageChanged;

  const WelcomeStep({
    super.key,
    required this.onNext,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDe = language == 'de';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Language Switcher (Top Right)
          Align(
            alignment: Alignment.topRight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.celadon),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLangOption('DE', isDe),
                  _buildLangOption('EN', !isDe),
                ],
              ),
            ),
          ),

          Spacer(),
          // Branding
          Text(
            'Kalorat',
            style: AppTypography.displayLarge.copyWith(fontSize: 42),
          ),
          const SizedBox(height: 16),
          Text(
            isDe
                ? 'Kalorien, schön getrackt.'
                : 'Calories, tracked beautifully.',
            style: AppTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ActionButton(
            text: isDe ? 'Los geht\'s' : 'Get Started',
            onPressed: onNext,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLangOption(String code, bool isActive) {
    return GestureDetector(
      onTap: () => onLanguageChanged(code.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.shamrock : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          code,
          style: AppTypography.labelLarge.copyWith(
            color: isActive ? Colors.white : AppColors.carbonBlack,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
