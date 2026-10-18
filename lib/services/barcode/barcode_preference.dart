import 'package:hive/hive.dart';

/// Whether a product found by barcode in photos replaces the analysis of the
/// photos. Off until the user turns it on; the last choice is kept, shared by
/// the notes sheet and the retry sheet.
class BarcodePreference {
  static const _boxName = 'settings_box';
  static const _key = 'use_barcode_values';

  static bool get useBarcode {
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      return Hive.box(_boxName).get(_key, defaultValue: false) == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setUseBarcode(bool value) async {
    try {
      if (Hive.isBoxOpen(_boxName)) await Hive.box(_boxName).put(_key, value);
    } catch (_) {
      // The choice then only lasts for this sheet.
    }
  }
}
