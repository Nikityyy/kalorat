import 'package:hive/hive.dart';

/// How long a device's meals may go without a backup before Today reminds,
/// and how long "Später" quiets the reminder.
const firstBackupAfter = Duration(days: 7);
const backupEvery = Duration(days: 14);
const backupSnooze = Duration(days: 7);

/// Whether a device whose meals exist only on it is due for a backup: a week
/// after its first meal if it never had one, then every two weeks in which
/// something new was logged.
bool backupDue({
  required DateTime now,
  required DateTime? lastBackup,
  required DateTime? snoozedUntil,
  required DateTime? firstMeal,
  required DateTime? lastMeal,
}) {
  if (firstMeal == null || lastMeal == null) return false;
  if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;
  if (lastBackup == null) return now.difference(firstMeal) >= firstBackupAfter;
  return now.difference(lastBackup) >= backupEvery &&
      lastMeal.isAfter(lastBackup);
}

/// When this device's data was last exported, and the reminder's snooze.
class BackupReminder {
  static const _boxName = 'settings_box';
  static const _lastKey = 'last_backup_at';
  static const _snoozeKey = 'backup_reminder_snoozed_until';

  static DateTime? _read(String key) {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final value = Hive.box(_boxName).get(key);
      return value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _write(String key, DateTime value) async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).put(key, value.millisecondsSinceEpoch);
      }
    } catch (_) {
      // The reminder then only knows until the app restarts.
    }
  }

  static DateTime? get lastBackup => _read(_lastKey);

  static DateTime? get snoozedUntil => _read(_snoozeKey);

  static Future<void> markBackedUp() => _write(_lastKey, DateTime.now());

  static Future<void> snooze() =>
      _write(_snoozeKey, DateTime.now().add(backupSnooze));
}
