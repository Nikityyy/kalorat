import 'package:flutter/material.dart';

import '../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// A one-time hint: what a screen is for, with a way to dismiss it for good.
/// [onDark] sets it on the camera, where it needs a dark background.
class FirstUseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final String? dismissLabel;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool onDark;

  const FirstUseCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onDismiss,
    this.dismissLabel,
    this.actionLabel,
    this.onAction,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final background = onDark
        ? Colors.black.withValues(alpha: 0.78)
        : AppColors.surface;
    final foreground = onDark ? Colors.white : AppColors.text;

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: onDark ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: onDark ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTypography.bodyMedium.copyWith(
                color: foreground.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: foreground,
                    ),
                    child: Text(dismissLabel ?? l10n.hintGotIt),
                  ),
                  if (actionLabel != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        foregroundColor: onDark
                            ? Colors.white
                            : AppColors.primary,
                      ),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
