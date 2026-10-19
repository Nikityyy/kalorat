import 'package:flutter/material.dart';
import 'package:kalorat/l10n/app_localizations.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/inputs/action_button.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSignIn;
  final String language;
  final Function(String) onLanguageChanged;

  const WelcomeStep({
    super.key,
    required this.onNext,
    required this.onSignIn,
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppColors.surface),
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
          Image.asset(
            AppColors.isDark
                ? 'assets/kalorat-textlogo-dark.webp'
                : 'assets/kalorat-textlogo.webp',
            width: 300,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.welcomeSlogan,
            style: AppTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ActionButton(
            text: AppLocalizations.of(context)!.getStarted,
            onPressed: onNext,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onSignIn,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text(
              AppLocalizations.of(context)!.welcomeHaveAccount,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.text,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Text(
          code,
          style: AppTypography.labelLarge.copyWith(
            color: isActive ? AppColors.onPrimary : AppColors.text,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
