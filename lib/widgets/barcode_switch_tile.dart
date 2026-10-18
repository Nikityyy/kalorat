import 'package:flutter/material.dart';

import '../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// Switches between the values of a product whose barcode was read and an
/// analysis of the photo as a meal, e.g. when the code was only on a package
/// in the background.
class BarcodeSwitchTile extends StatelessWidget {
  final String productName;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Shown under the name while the switch is on; defaults to where the
  /// values come from.
  final String? onHint;

  const BarcodeSwitchTile({
    super.key,
    required this.productName,
    required this.value,
    required this.onChanged,
    this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.pebble,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                Icons.barcode_reader,
                color: value ? AppColors.styrianForest : AppColors.slate,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value
                          ? onHint ?? l10n.barcodeSwitchOn
                          : l10n.barcodeSwitchOff,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
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
