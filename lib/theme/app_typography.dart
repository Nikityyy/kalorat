import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Primary Font: Outfit with tight tracking for headlines
  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.styrianForest,
    height: 1.1,
    letterSpacing: -1.0, // Tight, engineered headline
  );

  static TextStyle get displayMedium => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.styrianForest,
    height: 1.2,
    letterSpacing: -1.0, // Tight, engineered headline
  );

  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.styrianForest,
    letterSpacing: -0.5,
  );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.frost,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.frost.withValues(alpha: 0.8),
  );

  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.glacialWhite,
    letterSpacing: 0.5,
  );

  // Data Font: JetBrains Mono for numerical precision
  static TextStyle get heroNumber => GoogleFonts.jetBrainsMono(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.styrianForest,
    letterSpacing: -1.0,
  );

  static TextStyle get dataLabel => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.styrianForest,
  );

  static TextStyle get dataMedium => GoogleFonts.jetBrainsMono(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.styrianForest,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.frost.withValues(alpha: 0.7),
  );

  static TextStyle get buttonLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.glacialWhite,
  );
}
