import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../utils/haptics.dart';
import 'pressable.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const ActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      enabled: onPressed != null && !isLoading,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary, // Primary Forest Green
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: Semantics(
            container: true,
            button: true,
            enabled: onPressed != null && !isLoading,
            child: InkWell(
              onTap: () {
                if (!isLoading) {
                  Haptics.tick();
                  onPressed?.call();
                }
              },
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        text,
                        style: AppTypography.labelLarge.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
