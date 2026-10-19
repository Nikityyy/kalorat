import 'package:flutter/material.dart';

// Nikita Berger — Fluid Precision

/// The brand palette.
///
/// The named brand colors (`pureWhite`, `deepSpaceBlack`, …) are fixed. The
/// role colors (`canvas`, `surface`, `border`, `text`, `primary`, `onPrimary`,
/// …) follow the theme: [setDark] is
/// called whenever the theme changes, and the app is rebuilt, so a widget just
/// reads them where it builds.
class AppColors {
  static bool _dark = false;

  static bool get isDark => _dark;

  static void setDark(bool dark) => _dark = dark;

  // Brand colors, fixed in both themes.
  static const Color styrianForestColor = Color(0xFF0F5838); // Primary Accent
  static const Color styrianForestLight = Color(0xFF1EB070); // Light variant

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF9FAFB);
  static const Color subtleAsh = Color(0xFFE5E7EB); // 1px hard border, light

  static const Color deepSpaceBlack = Color(0xFF0A0A0A); // Dark canvas
  static const Color richCharcoal = Color(0xFF141414); // Dark surface
  static const Color darkChrome = Color(0xFF27272A); // 1px hard border, dark
  static const Color darkText = Color(0xFFFAFAFA); // Text on the dark canvas

  // Functional colors, fixed.
  static const Color signalRed = Color(0xFFED2939); // Error/Alert

  // Roles that follow the theme.

  /// The screen behind everything.
  static Color get canvas => _dark ? deepSpaceBlack : pureWhite;

  /// Cards and fields, a step above the canvas.
  static Color get surface => _dark ? richCharcoal : offWhite;

  /// 1px borders and dividers.
  static Color get border => _dark ? darkChrome : subtleAsh;

  /// Text and icons on the canvas.
  static Color get text => _dark ? darkText : deepSpaceBlack;

  /// The accent: fills, and text or icons in the accent color. In the dark
  /// theme it is the light brand green, which reads on the dark canvas.
  static Color get primary => _dark ? styrianForestLight : styrianForestColor;

  /// Text and icons on a [primary] fill.
  static Color get onPrimary => _dark ? deepSpaceBlack : pureWhite;

  /// Secondary text: captions, units, the second line of a row.
  static Color get ink2 =>
      _dark ? const Color(0xFFA3A9A5) : const Color(0xFF4B524E);

  /// Tertiary text and inactive glyphs (axis labels, the inactive tab).
  static Color get ink3 =>
      _dark ? const Color(0xFF868C88) : const Color(0xFF687069);

  /// A wash of the accent: the area under the day's ridge, selected rows.
  static Color get accentSoft => _dark
      ? styrianForestLight.withValues(alpha: 0.14)
      : styrianForestColor.withValues(alpha: 0.08);

  /// Destructive actions and errors.
  static Color get negative => _dark ? const Color(0xFFFF5A66) : signalRed;
}
