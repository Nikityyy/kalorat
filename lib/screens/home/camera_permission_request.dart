import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../../widgets/inputs/action_button.dart';

/// Explains why the camera is needed and asks for access.
class CameraPermissionRequest extends StatelessWidget {
  final VoidCallback onGrant;

  const CameraPermissionRequest({super.key, required this.onGrant});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.12),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.cameraNeeded,
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.cameraPermissionText,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.text.withValues(alpha: 0.65),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ActionButton(
                      text: l10n.grantPermission,
                      onPressed: onGrant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
