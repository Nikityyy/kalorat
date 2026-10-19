import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/providers/app_provider.dart';

DateTime _d(int day) => DateTime.utc(2026, 10, day);

void main() {
  final today = _d(19);

  test('counts the days in a row that end today', () {
    expect(countStreak({_d(17), _d(18), _d(19)}, today), 3);
  });

  test('a day not logged yet today does not break the streak', () {
    expect(countStreak({_d(16), _d(17), _d(18)}, today), 3);
  });

  test('a missed day ends the streak, with no freeze to bridge it', () {
    expect(countStreak({_d(10), _d(11), _d(12), _d(14), _d(15)}, _d(15)), 2);
    expect(countStreak({_d(15), _d(16)}, today), 0);
  });

  test('no meals, no streak', () {
    expect(countStreak({}, today), 0);
  });

  test('runs across a month boundary', () {
    expect(
      countStreak({
        DateTime.utc(2026, 9, 30),
        DateTime.utc(2026, 10, 1),
      }, DateTime.utc(2026, 10, 1)),
      2,
    );
  });
}
