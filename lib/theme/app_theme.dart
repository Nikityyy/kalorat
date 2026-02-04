import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lavenderBlush,
      primaryColor: AppColors.shamrock,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.shamrock,
        primary: AppColors.shamrock,
        secondary: AppColors.emerald,
        surface: AppColors.celadon,
        background: AppColors.lavenderBlush,
        onBackground: AppColors.carbonBlack,
        onSurface: AppColors.carbonBlack,
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.celadon,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.carbonBlack,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        titleLarge: AppTypography.titleLarge,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        labelLarge: AppTypography.labelLarge,
      ),
      iconTheme: const IconThemeData(color: AppColors.carbonBlack),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.shamrock,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32), // More rounded for brand
          ),
          elevation: 2,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF101414),
      primaryColor: AppColors.emerald,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.shamrock,
        primary: AppColors.emerald,
        secondary: AppColors.shamrock,
        surface: const Color(0xFF1C2222),
        background: const Color(0xFF101414),
        onBackground: Colors.white,
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A3333),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: Colors.white),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: Colors.white,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(color: Colors.white),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: Colors.white70),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: Colors.white70),
        labelLarge: AppTypography.labelLarge.copyWith(color: Colors.white),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  static CupertinoThemeData get iosTheme {
    return CupertinoThemeData(
      primaryColor: AppColors.shamrock,
      scaffoldBackgroundColor: AppColors.lavenderBlush,
      barBackgroundColor: const Color(0x80FFF2F4),
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.carbonBlack,
        textStyle: AppTypography.bodyMedium,
        navTitleTextStyle: AppTypography.titleLarge,
        navLargeTitleTextStyle: AppTypography.displayLarge,
      ),
    );
  }
}
