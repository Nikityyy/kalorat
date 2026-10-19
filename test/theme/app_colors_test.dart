import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/theme/app_colors.dart';
import 'package:kalorat/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  tearDown(() => AppColors.setDark(false));

  test('light palette is the original one', () {
    AppColors.setDark(false);
    expect(AppColors.canvas, AppColors.pureWhite);
    expect(AppColors.surface, AppColors.offWhite);
    expect(AppColors.border, AppColors.subtleAsh);
    expect(AppColors.text, AppColors.deepSpaceBlack);
    expect(AppColors.primary, AppColors.styrianForestColor);
  });

  test('dark palette uses the brand dark colors', () {
    AppColors.setDark(true);
    expect(AppColors.canvas, const Color(0xFF0A0A0A));
    expect(AppColors.surface, const Color(0xFF141414));
    expect(AppColors.border, const Color(0xFF27272A));
  });

  for (final dark in [false, true]) {
    test('text and buttons are readable in ${dark ? 'dark' : 'light'}', () {
      AppColors.setDark(dark);
      expect(_contrast(AppColors.text, AppColors.canvas), greaterThan(7));
      expect(_contrast(AppColors.text, AppColors.surface), greaterThan(7));
      expect(
        _contrast(AppColors.onPrimary, AppColors.primary),
        greaterThan(4.5),
      );
      expect(_contrast(AppColors.primary, AppColors.canvas), greaterThan(4.5));
    });
  }

  test('building the themes leaves the active palette untouched', () {
    AppColors.setDark(false);
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
    expect(AppColors.isDark, isFalse);
    AppColors.setDark(true);
    expect(AppTheme.lightTheme.brightness, Brightness.light);
    expect(AppColors.isDark, isTrue);
  });

  test('each theme carries its own scaffold color', () {
    expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppColors.pureWhite);
    expect(
      AppTheme.darkTheme.scaffoldBackgroundColor,
      AppColors.deepSpaceBlack,
    );
  });
}
