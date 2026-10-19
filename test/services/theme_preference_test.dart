import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kalorat/services/theme_preference.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('theme_pref_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('follows the system until the user chooses', () async {
    await Hive.openBox('settings_box');
    expect(ThemePreference.mode, ThemeMode.system);
  });

  test('remembers light and dark, and can go back to system', () async {
    await Hive.openBox('settings_box');
    await ThemePreference.setMode(ThemeMode.dark);
    expect(ThemePreference.mode, ThemeMode.dark);
    await ThemePreference.setMode(ThemeMode.light);
    expect(ThemePreference.mode, ThemeMode.light);
    await ThemePreference.setMode(ThemeMode.system);
    expect(ThemePreference.mode, ThemeMode.system);
  });

  test('an unknown stored value falls back to system', () {
    expect(ThemePreference.parse('purple'), ThemeMode.system);
    expect(ThemePreference.parse(null), ThemeMode.system);
  });

  test('without storage it stays on system and does not throw', () async {
    expect(ThemePreference.mode, ThemeMode.system);
    await ThemePreference.setMode(ThemeMode.dark);
    expect(ThemePreference.mode, ThemeMode.system);
  });
}
