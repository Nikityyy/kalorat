import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static const double borderRadius = 12.0;
  static const double _borderWidth = 1.0;

  static final RoundedRectangleBorder _flatShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadius),
    side: const BorderSide(color: AppColors.subtleAsh, width: _borderWidth),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.outfit,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.pureWhite,
      primaryColor: AppColors.styrianForest,
      colorScheme: ColorScheme.light(
        primary: AppColors.styrianForest,
        secondary: AppColors.styrianForest,
        surface: AppColors.offWhite,
        error: AppColors.signalRed,
        onPrimary: AppColors.pureWhite,
        onSurface: AppColors.deepSpaceBlack,
        // No elevation tint: surfaces are separated by 1px borders only.
        surfaceTint: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.offWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: AppColors.subtleAsh,
            width: _borderWidth,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge,
        foregroundColor: AppColors.styrianForest,
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
          backgroundColor: AppColors.styrianForest,
          foregroundColor: AppColors.pureWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: const BorderSide(
              color: AppColors.subtleAsh,
              width: _borderWidth,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        shape: _flatShape,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadius),
          ),
          side: BorderSide(color: AppColors.subtleAsh, width: _borderWidth),
        ),
      ),
      snackBarTheme: SnackBarThemeData(elevation: 0, shape: _flatShape),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        shape: _flatShape,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        shape: _flatShape,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        shape: _flatShape,
      ),
      // Horizontal slide on Apple platforms; slide with a cross-fade
      // elsewhere. Both are the native motion of the platform.
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
