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
    color: AppColors.text,
    height: 1.1,
    letterSpacing: -1.0, // Tight, engineered headline
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: outfit,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
    letterSpacing: -1.0, // Tight, engineered headline
  );

  static TextStyle get titleLarge => TextStyle(
    fontFamily: outfit,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
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
    color: AppColors.primary,
    letterSpacing: -1.0,
  );

  static TextStyle get dataMedium => TextStyle(
    fontFamily: mono,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: outfit,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text.withValues(alpha: 0.7),
  );

  // The redesign's scale. Words are Outfit, every number is JetBrains Mono.

  /// Screen titles.
  static TextStyle get title => TextStyle(
    fontFamily: outfit,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.4,
    color: AppColors.text,
  );

  /// Section headings.
  static TextStyle get heading => TextStyle(
    fontFamily: outfit,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.text,
  );

  /// Body text and list row titles.
  static TextStyle get body => TextStyle(
    fontFamily: outfit,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.text,
  );

  /// The second line of a row, captions.
  static TextStyle get secondary => TextStyle(
    fontFamily: outfit,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.ink2,
  );

  /// Small print: axis labels, timestamps.
  static TextStyle get meta => TextStyle(
    fontFamily: outfit,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.ink3,
  );

  /// The one big number of a screen.
  static TextStyle hero({double size = 80}) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -size * 0.06,
    color: AppColors.text,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// A number inside a line of text, at the size of that text.
  static TextStyle number({
    double size = 17,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) => TextStyle(
    fontFamily: mono,
    fontSize: size - 1,
    fontWeight: weight,
    height: 1.3,
    letterSpacing: -0.2,
    color: color ?? AppColors.text,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
