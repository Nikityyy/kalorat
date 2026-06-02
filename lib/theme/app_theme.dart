import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static const double borderRadius = 12.0;
  static const double _borderWidth = 1.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepSpaceBlack,
      primaryColor: AppColors.styrianForest,
      colorScheme: ColorScheme.dark(
        primary: AppColors.styrianForest,
        secondary: AppColors.styrianForest,
        surface: AppColors.richCharcoal,
        error: AppColors.signalRed,
        onPrimary: AppColors.pureWhite,
        onSurface: AppColors.pureWhite,
      ),
      cardTheme: CardThemeData(
        color: AppColors.richCharcoal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: AppColors.darkChrome, width: _borderWidth),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.pureWhite,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.pureWhite,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.pureWhite,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.pureWhite,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.pureWhite),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.pureWhite,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.pureWhite,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static CupertinoThemeData get iosTheme {
    return CupertinoThemeData(
      primaryColor: AppColors.styrianForest,
      scaffoldBackgroundColor: AppColors.pureWhite,
      barBackgroundColor: AppColors.pureWhite.withValues(alpha: 0.8),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.styrianForest,
        textStyle: AppTypography.bodyMedium,
        navTitleTextStyle: AppTypography.titleLarge,
        navLargeTitleTextStyle: AppTypography.displayLarge,
      ),
    );
  }
}
