import 'package:flutter/material.dart';

import '../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/meal_time_label.dart';

/// Logs a meal from gallery photos at the time the first photo was taken
/// instead of now. The line under the title is always the time the meal will
/// be logged at.
class PhotoTimeTile extends StatelessWidget {
  final DateTime takenAt;
  final bool value;
  final ValueChanged<bool> onChanged;

  const PhotoTimeTile({
    super.key,
    required this.takenAt,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: value ? AppColors.primary : AppColors.text,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.photoTimeTitle,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Text(
                        value
                            ? mealTimeLabel(l10n, language, takenAt)
                            : l10n.photoTimeOff,
                        key: ValueKey(value),
                        style: AppTypography.bodySmall.copyWith(
                          color: value ? AppColors.primary : AppColors.text,
                          fontWeight: value ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: AppColors.primary,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
