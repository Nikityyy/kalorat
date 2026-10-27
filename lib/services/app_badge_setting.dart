import 'package:hive/hive.dart';

/// Whether the app icon shows how many meals wait for their analysis. Off
/// until the user turns it on: Safari needs the notification permission
/// for it.
class AppBadgeSetting {
  static const _boxName = 'settings_box';
  static const _key = 'app_badge';

  static bool get enabled {
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      return Hive.box(_boxName).get(_key, defaultValue: false) == true;
    } catch (_) {
      return false;
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
