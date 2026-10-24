import 'package:hive/hive.dart';

/// Whether a meal from gallery photos is logged at the time the first photo
/// was taken. On until the user turns it off, and remembered either way.
class PhotoTimeSetting {
  static const _boxName = 'settings_box';
  static const _key = 'use_photo_time';

  static bool get enabled {
    try {
      if (!Hive.isBoxOpen(_boxName)) return true;
      return Hive.box(_boxName).get(_key, defaultValue: true) != false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabled(bool value) async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).put(_key, value);
      }
    } catch (_) {
      // The choice then only lasts until the app restarts.
    }
  }
}
