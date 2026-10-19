import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Stands in for the photo of a meal that has none: typed meals, a photo
/// that could not be read, meals synced from another device. The first
/// letter of the name on the soft accent, so a list of them still reads as
/// food and not as missing pictures. The caller clips the shape.
class MealMark extends StatelessWidget {
  final String name;
  final double size;

  /// Fills its parent instead of a [size] square; [size] still sets the
  /// letter.
  final bool fill;

  const MealMark({
    super.key,
    required this.name,
    required this.size,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty
        ? null
        : trimmed.characters.first.toUpperCase();
    return Container(
      width: fill ? null : size,
      height: fill ? null : size,
      color: AppColors.accentSoft,
      alignment: Alignment.center,
      child: letter == null
          ? Icon(Icons.restaurant, color: AppColors.primary, size: size * 0.4)
          : Text(
              letter,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: AppTypography.outfit,
                fontSize: size * 0.44,
                fontWeight: FontWeight.w600,
                height: 1,
                color: AppColors.primary,
              ),
            ),
    );
  }
}
