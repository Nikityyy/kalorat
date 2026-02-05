import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static const double _borderRadius = 16.0;
  static const double _borderWidth = 1.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.limestone,
      primaryColor: AppColors.styrianForest,
      colorScheme: ColorScheme.light(
        primary: AppColors.styrianForest,
        secondary: AppColors.glacierMint,
        surface: AppColors.pebble,
        error: AppColors.kaiserRed,
        onPrimary: AppColors.pebble,
        onSurface: AppColors.slate,
      ),
      cardTheme: CardThemeData(
        color: AppColors.pebble,
        elevation: 0, // No soft shadows
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: AppColors.slate, width: _borderWidth),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.limestone,
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
          foregroundColor: AppColors.pebble,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
            side: const BorderSide(color: AppColors.slate, width: _borderWidth),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.slate,
      primaryColor: AppColors.styrianForest,
      colorScheme: ColorScheme.dark(
        primary: AppColors.styrianForest,
        secondary: AppColors.glacierMint,
        surface: const Color(0xFF1C2222),
        error: AppColors.kaiserRed,
        onPrimary: AppColors.pebble,
        onSurface: AppColors.pebble,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C2222),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: AppColors.slate, width: _borderWidth),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.pebble,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.pebble,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.pebble,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.pebble),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.slate),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.pebble),
      ),
    );
  }

  static CupertinoThemeData get iosTheme {
    return CupertinoThemeData(
      primaryColor: AppColors.styrianForest,
      scaffoldBackgroundColor: AppColors.limestone,
      barBackgroundColor: AppColors.limestone.withValues(alpha: 0.8),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.styrianForest,
        textStyle: AppTypography.bodyMedium,
        navTitleTextStyle: AppTypography.titleLarge,
        navLargeTitleTextStyle: AppTypography.displayLarge,
      ),
    );
  }
}
