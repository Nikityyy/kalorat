import 'package:flutter/material.dart';

// HOPE LLC — Fluid Precision

class AppColors {
  // Primary/Accent
  static const Color primary = Color(0xFF0F5838); // Styrian Forest
  static const Color background = Color(0xFFFFFFFF); // Pure White canvas
  static const Color error = Color(0xFFED2939); // Signal Red
  static const Color surface = Color(0xFFF9FAFB); // Off-White surface

  // HOPE LLC — Fluid Precision
  // Kalorat Accent: Styrian Forest
  static const Color styrianForestColor = Color(0xFF0F5838); // Primary Accent
  static const Color styrianForestDark = Color(0xFF0A3C26); // Hover state
  static const Color styrianForestLight = Color(0xFF1EB070); // Light variant

  // Monochrome Canvas — Light Mode
  static const Color pureWhite = Color(0xFFFFFFFF); // Light Canvas
  static const Color offWhite = Color(0xFFF9FAFB); // Off-White Surface
  static const Color subtleAsh = Color(0xFFE5E7EB); // 1px Hard Border Light
  static const Color lightSurface = Color(0xFFF3F4F6); // Light surface card bg

  // Monochrome Canvas — Dark Mode
  static const Color deepSpaceBlack = Color(0xFF0A0A0A); // Dark Canvas
  static const Color richCharcoal = Color(0xFF141414); // Surface Dark
  static const Color darkChrome = Color(0xFF27272A); // 1px Hard Border Dark

  // Functional Colors
  static const Color signalRed = Color(0xFFED2939); // Error/Alert
  static const Color success = Color(0xFF0F5838); // Success
  static const Color warning = Color(0xFFF59E0B); // Warning Amber
  static const Color infoBlue = Color(0xFF3B82F6); // Info

  static const Color transparent = Colors.transparent;

  // Backward-compatible aliases for migration
  // These exist so old code continues to compile — migrate gradually
  static const Color styrianForest = styrianForestColor;
  static const Color glacialWhite = pureWhite;
  static const Color steel = offWhite;
  static const Color frost = deepSpaceBlack;
  static const Color borderGrey = subtleAsh;
  static const Color kaiserRed = signalRed;
  static const Color glacierMint = styrianForest;
  static const Color amber = warning;
  static const Color limestone = pureWhite;
  static const Color pebble = offWhite;
  static const Color slate = deepSpaceBlack;
}
