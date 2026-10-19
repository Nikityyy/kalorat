import 'package:flutter/material.dart' show ThemeMode;
import 'package:hive/hive.dart';

/// Which theme the user picked: follow the system, or always light or dark.
/// Follows the system until the user chooses.
class ThemePreference {
  static const _boxName = 'settings_box';
  static const _key = 'theme_mode';

  static ThemeMode get mode {
    try {
      if (!Hive.isBoxOpen(_boxName)) return ThemeMode.system;
      return parse(Hive.box(_boxName).get(_key) as String?);
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static Future<void> setMode(ThemeMode mode) async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).put(_key, mode.name);
      }
    } catch (_) {
      // The choice then only lasts until the app restarts.
    }
  }

  static ThemeMode parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
