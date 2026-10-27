import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/services/backup_reminder.dart';

void main() {
  final now = DateTime(2026, 10, 27, 12);
  DateTime ago(int days) => now.subtract(Duration(days: days));

  bool due({
    DateTime? lastBackup,
    DateTime? snoozedUntil,
    DateTime? firstMeal,
    DateTime? lastMeal,
  }) => backupDue(
    now: now,
    lastBackup: lastBackup,
    snoozedUntil: snoozedUntil,
    firstMeal: firstMeal,
    lastMeal: lastMeal,
  );

  test('no meals, nothing to back up', () {
    expect(due(), isFalse);
  });

  test('never backed up: due a week after the first meal', () {
    expect(due(firstMeal: ago(6), lastMeal: ago(0)), isFalse);
    expect(due(firstMeal: ago(7), lastMeal: ago(0)), isTrue);
  });

  test('backed up: due two weeks later if something new was logged', () {
    expect(
      due(lastBackup: ago(13), firstMeal: ago(60), lastMeal: ago(0)),
      isFalse,
    );
    expect(
      due(lastBackup: ago(14), firstMeal: ago(60), lastMeal: ago(0)),
      isTrue,
    );
    // Nothing logged since the backup: it is still complete.
    expect(
      due(lastBackup: ago(20), firstMeal: ago(60), lastMeal: ago(21)),
      isFalse,
    );
  });

  test('later quiets it until the snooze ends', () {
    expect(
      due(
        snoozedUntil: now.add(const Duration(days: 1)),
        firstMeal: ago(30),
        lastMeal: ago(0),
      ),
      isFalse,
    );
    expect(
      due(snoozedUntil: ago(1), firstMeal: ago(30), lastMeal: ago(0)),
      isTrue,
    );
  });
}
