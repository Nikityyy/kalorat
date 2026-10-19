import 'package:hive/hive.dart';

/// The one-time hints a user has already dismissed. A hint is shown until it
/// is dismissed once, and never again after that.
enum FirstUseHint {
  /// Explains the camera the first time it is open.
  camera,

  /// Offers a Google sign-in once the first meal is saved.
  backup,
}

class FirstUseHints {
  static const _boxName = 'settings_box';

  static String _key(FirstUseHint hint) => 'hint_seen_${hint.name}';

  static bool seen(FirstUseHint hint) {
    try {
      if (!Hive.isBoxOpen(_boxName)) return true;
      return Hive.box(_boxName).get(_key(hint), defaultValue: false) == true;
    } catch (_) {
      // Without storage a hint could never be dismissed for good: stay quiet.
      return true;
    }
  }

  static Future<void> markSeen(FirstUseHint hint) async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).put(_key(hint), true);
      }
    } catch (_) {
      // The hint then only stays away until the app restarts.
    }
  }
}
