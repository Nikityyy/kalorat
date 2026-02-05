import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 36,
    fontWeight: FontWeight.w800, // Bold and tight
    color: AppColors.styrianForest,
    height: 1.1,
  );

  static TextStyle get displayMedium => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.styrianForest,
    height: 1.2,
  );

  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.styrianForest,
  );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.slate,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.slate.withValues(alpha: 0.8),
  );

  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.pebble,
    letterSpacing: 0.5,
  );

  // Data Font: Monospace for Calories and Macros
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
}
