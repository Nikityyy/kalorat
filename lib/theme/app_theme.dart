import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static const double borderRadius = 12.0;

  /// Surfaces that meet the screen edge (bottom sheets), closer to the
  /// device's own corners than a card is.
  static const double sheetRadius = 24.0;
  static const double _borderWidth = 1.0;

  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  // Built once: the app root rebuilds on every provider change, and building
  // and comparing two full themes each time is not free.
  static final ThemeData lightTheme = _build(Brightness.light);

  static final ThemeData darkTheme = _build(Brightness.dark);

  /// Builds one theme from the role colors. They follow [AppColors.setDark],
  /// so that is set for the duration and put back afterwards.
  static ThemeData _build(Brightness brightness) {
    final before = AppColors.isDark;
    AppColors.setDark(brightness == Brightness.dark);
    try {
      return _theme(brightness);
    } finally {
      AppColors.setDark(before);
    }
  }

  static ThemeData _theme(Brightness brightness) {
    final border = BorderSide(color: AppColors.border, width: _borderWidth);
    final flatShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: border,
    );
    final dark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      error: AppColors.signalRed,
      onError: AppColors.pureWhite,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      // No elevation tint: surfaces are separated by 1px borders only.
      surfaceTint: Colors.transparent,
      // Field outlines, unselected controls and secondary text. Light keeps
      // the full text color (what ColorScheme.light defaults to); dark uses
      // neutral greys that read on the dark canvas.
      outline: dark ? const Color(0xFF71717A) : AppColors.text,
      outlineVariant: dark ? AppColors.border : AppColors.text,
      onSurfaceVariant: dark ? const Color(0xFFA1A1AA) : AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.outfit,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      primaryColor: AppColors.primary,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: flatShape,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
        ),
        foregroundColor: AppColors.text,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        titleLarge: AppTypography.titleLarge,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelLarge: AppTypography.labelLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: flatShape,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        shape: flatShape,
        titleTextStyle: AppTypography.heading,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.ink2),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          minimumSize: const Size(48, 44),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(sheetRadius),
          ),
          side: border,
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(elevation: 0, shape: flatShape),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.canvas,
        elevation: 0,
        shape: flatShape,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        shape: flatShape,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        shape: flatShape,
      ),
      // Horizontal slide on Apple platforms; slide with a cross-fade
      // elsewhere. Both are the native motion of the platform.
      // iOS has no ink ripple: a press only highlights. Android keeps it.
      splashFactory: _apple ? NoSplash.splashFactory : null,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
