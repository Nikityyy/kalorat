import 'package:flutter/material.dart';

import '../../extensions/l10n_extension.dart';
import '../../models/models.dart';
import '../../services/photo_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../common/meal_mark.dart';
import '../common/mono_digits.dart';
import '../inputs/pressable.dart';

/// One meal in a day's list: the plate large enough to recognise, its name,
/// when it was eaten with its protein, and what it added.
class MealRow extends StatelessWidget {
  final MealModel meal;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final bool syncPending;
  final bool analysisWorkerActive;
  final bool showDivider;

  const MealRow({
    super.key,
    required this.meal,
    this.onTap,
    this.onRetry,
    this.syncPending = false,
    this.analysisWorkerActive = false,
    this.showDivider = true,
  });

  static const photoSize = 64.0;

  String _analysisLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (meal.analysisStatus) {
      case 'running':
        return analysisWorkerActive
            ? l10n.analyzing
            : l10n.analysisWaitingForResume;
      case 'retrying':
        return l10n.analysisRetrying(meal.analysisAttempts);
      case 'failed':
        return l10n.analysisFailedTapToRetry;
      case 'queued':
      default:
        return l10n.pendingAnalysis;
    }
  }

  static String clock(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failed = meal.isPending && meal.analysisStatus == 'failed';
    final working =
        meal.isPending &&
        meal.analysisStatus == 'running' &&
        analysisWorkerActive;
    final name = meal.mealName.isNotEmpty ? meal.mealName : l10n.mealName;

    final subtitle = meal.isPending
        ? Text(
            _analysisLabel(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.secondary.copyWith(
              color: failed ? AppColors.negative : AppColors.ink2,
            ),
          )
        : Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: clock(meal.timestamp),
                  style: AppTypography.number(size: 15, color: AppColors.ink2),
                ),
                const TextSpan(text: '  ·  '),
                ...MonoDigits.spans(
                  l10n.gramsProtein(meal.protein.round()),
                  AppTypography.secondary,
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.secondary,
          );

    Widget trailing;
    if (failed && onRetry != null) {
      trailing = IconButton(
        onPressed: onRetry,
        tooltip: l10n.retryAnalysis,
        icon: Icon(Icons.refresh, color: AppColors.primary),
      );
    } else if (working) {
      trailing = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    } else if (meal.isPending) {
      trailing = Icon(Icons.schedule, size: 20, color: AppColors.ink3);
    } else {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            meal.calories.round().toString(),
            style: AppTypography.number(size: 18),
          ),
          Text(l10n.kcal, style: AppTypography.meta),
        ],
      );
    }

    return Semantics(
      button: onTap != null,
      child: Pressable(
        enabled: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: showDivider
                  ? Border(bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              children: [
                MealPhoto(meal: meal, size: photoSize),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      subtitle,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (syncPending) ...[
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: AppColors.ink3,
                  ),
                  const SizedBox(width: 8),
                ],
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A meal's first photo, or a flat tile with a plate glyph when it has none.
class MealPhoto extends StatelessWidget {
  final MealModel meal;
  final double size;

  const MealPhoto({super.key, required this.meal, required this.size});

  @override
  Widget build(BuildContext context) {
    final path = meal.photoPaths.isNotEmpty ? meal.photoPaths.first : null;
    final placeholder = MealMark(name: meal.mealName, size: size);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: path == null || path.isEmpty
          ? placeholder
          : Image(
              image: PhotoStore.instance.imageProvider(
                path,
                cacheWidth: (size * dpr).round(),
              ),
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
