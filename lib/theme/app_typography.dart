import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  /// Bundled font families (see `pubspec.yaml`); nothing is fetched at runtime.
  static const String outfit = 'Outfit';
  static const String mono = 'JetBrains Mono';

  // Primary Font: Outfit with tight tracking for headlines
  static TextStyle get displayLarge => TextStyle(
    fontFamily: outfit,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.styrianForest,
    height: 1.1,
    letterSpacing: -1.0, // Tight, engineered headline
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: outfit,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.styrianForest,
    height: 1.2,
    letterSpacing: -1.0, // Tight, engineered headline
  );

  static TextStyle get titleLarge => TextStyle(
    fontFamily: outfit,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.styrianForest,
    letterSpacing: -0.5,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: outfit,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: outfit,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text.withValues(alpha: 0.8),
  );

  static TextStyle get labelLarge => TextStyle(
    fontFamily: outfit,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.5,
  );

  // Data Font: JetBrains Mono for numerical precision
  static TextStyle get heroNumber => TextStyle(
    fontFamily: mono,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.styrianForest,
    letterSpacing: -1.0,
  );

  static TextStyle get dataLabel => TextStyle(
    fontFamily: mono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.styrianForest,
  );

  static TextStyle get dataMedium => TextStyle(
    fontFamily: mono,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.styrianForest,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: outfit,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text.withValues(alpha: 0.7),
  );

  static TextStyle get buttonLarge => TextStyle(
    fontFamily: outfit,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
  );
}
