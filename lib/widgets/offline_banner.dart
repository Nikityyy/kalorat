import '../utils/platform_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A small status chip, not a banner: it never spans the screen or hides
/// controls. The full explanation is its screen-reader label.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      label: l10n.offlineMessage,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.borderGrey, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PlatformUtils.isIOS
                    ? CupertinoIcons.wifi_slash
                    : Icons.wifi_off,
                color: AppColors.slate,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.offlineShort,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
