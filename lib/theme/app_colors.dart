import 'package:flutter/material.dart';

class AppColors {
  // The Glacial Kit (Brand Identity 2.0)
  static const Color styrianForest = Color(0xFF0F5838); // Primary - Deep Green
  static const Color glacialWhite = Color(
    0xFFFAFAFC,
  ); // Canvas - Cool Off-White
  static const Color steel = Color(0xFFF0F2F5); // Surface Light
  static const Color frost = Color(0xFF1A1F1F); // Surface Dark
  static const Color kaiserRed = Color(0xFFED2939); // Action/Alert - Signal Red
  static const Color glacierMint = Color(0xFF3ED685); // Success
  static const Color amber = Color(0xFFFFBF00); // Warning/Alert
  static const Color borderGrey = Color(0xFFD1D5DB); // Topographic Border

  // Functional Assignments
  static const Color primary = styrianForest;
  static const Color background = glacialWhite;
  static const Color surface = steel;
  static const Color surfaceDark = frost;
  static const Color error = kaiserRed;
  static const Color success = glacierMint;
  static const Color warning = amber;
  static const Color border = borderGrey;

  static const Color transparent = Colors.transparent;

  // Legacy aliases (for gradual migration)
  static const Color limestone = glacialWhite;
  static const Color pebble = steel;
  static const Color slate = frost;
}
