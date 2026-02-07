import '../../utils/platform_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIos = PlatformUtils.isIOS;

    if (isIos) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: AppColors.styrianForest,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.heavyImpact(); // Mechanical click feel
                onPressed?.call();
              },
        child: isLoading
            ? const CupertinoActivityIndicator(color: AppColors.glacialWhite)
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.glacialWhite, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text, style: AppTypography.labelLarge),
                ],
              ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading
          ? null
          : () {
              HapticFeedback.heavyImpact(); // Mechanical click feel
              onPressed?.call();
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.styrianForest,
        foregroundColor: AppColors.glacialWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          side: const BorderSide(color: AppColors.borderGrey, width: 1),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.glacialWhite,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(text, style: AppTypography.labelLarge),
              ],
            ),
    );
  }
}
