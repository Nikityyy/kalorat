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
      scaffoldBackgroundColor: AppColors.glacialWhite,
      primaryColor: AppColors.styrianForest,
      colorScheme: ColorScheme.light(
        primary: AppColors.styrianForest,
        secondary: AppColors.glacierMint,
        surface: AppColors.steel,
        error: AppColors.kaiserRed,
        onPrimary: AppColors.glacialWhite,
        onSurface: AppColors.frost,
      ),
      cardTheme: CardThemeData(
        color: AppColors.steel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(
            color: AppColors.borderGrey,
            width: _borderWidth,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.glacialWhite,
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
          foregroundColor: AppColors.glacialWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: const BorderSide(
              color: AppColors.borderGrey,
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
      scaffoldBackgroundColor: AppColors.frost,
      primaryColor: AppColors.styrianForest,
      colorScheme: ColorScheme.dark(
        primary: AppColors.styrianForest,
        secondary: AppColors.glacierMint,
        surface: const Color(0xFF252A2A),
        error: AppColors.kaiserRed,
        onPrimary: AppColors.glacialWhite,
        onSurface: AppColors.glacialWhite,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF252A2A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: AppColors.borderGrey.withValues(alpha: 0.3),
            width: _borderWidth,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.glacialWhite,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.glacialWhite,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.glacialWhite,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.glacialWhite,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.glacialWhite,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.glacialWhite,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.glacialWhite,
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
      scaffoldBackgroundColor: AppColors.glacialWhite,
      barBackgroundColor: AppColors.glacialWhite.withValues(alpha: 0.8),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.styrianForest,
        textStyle: AppTypography.bodyMedium,
        navTitleTextStyle: AppTypography.titleLarge,
        navLargeTitleTextStyle: AppTypography.displayLarge,
      ),
    );
  }
}
