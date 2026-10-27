import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kalorat/models/models.dart';
import 'package:kalorat/services/database_service.dart';

void main() {
  late Directory directory;
  late DatabaseService database;
  late Box<UserModel> userBox;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kalorat_database_test_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MealModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WeightModelAdapter());
    }
    await Hive.openBox<dynamic>('settings_box');
    userBox = await Hive.openBox<UserModel>(DatabaseService.userBoxName);
    final mealsBox = await Hive.openBox<MealModel>('test_meals');
    final weightsBox = await Hive.openBox<WeightModel>('test_weights');
    database = DatabaseService();
    await database.initForTest(
      userBox: userBox,
      mealsBox: mealsBox,
      weightsBox: weightsBox,
    );
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('persists activity level through a Hive reload', () async {
    await database.saveUser(
      UserModel(
        name: 'Activity Test',
        birthdate: DateTime(1990, 1, 1),
        height: 175,
        weight: 70,
        activityLevel: 3,
      ),
    );

    await userBox.flush();
    expect(userBox.length, 1);

    await userBox.close();
    final reopened = await Hive.openBox<UserModel>(DatabaseService.userBoxName);
    final reloaded = reopened.getAt(0);

    expect(reloaded, isNotNull);
    expect(reloaded!.activityLevelIndex, 3);
    expect(reloaded.activityLevel, ActivityLevel.active);
  });

  test('invalid import leaves existing meals and weights untouched', () async {
    final existingMeal = MealModel(
      id: 'existing',
      timestamp: DateTime(2026, 7, 10, 12),
      photoPaths: const [],
      mealName: 'Existing',
    );
    await database.saveMeal(existingMeal);
    await database.saveWeight(
      WeightModel(date: DateTime(2026, 7, 10), weight: 70),
    );

    await expectLater(
      database.importAll({
        'version': '1.0',
        'meals': [existingMeal.toJson()],
        'weights': [
          WeightModel(date: DateTime(2026, 7, 9), weight: 11).toJson(),
        ],
      }),
      throwsFormatException,
    );
    expect(database.getAllMeals().single.id, 'existing');
    expect(database.getAllWeights().single.weight, 70);
  });

  test('date ranges use the edited meal timestamp', () async {
    await database.saveMeal(
      MealModel(
        id: 'meal',
        timestamp: DateTime(2026, 7, 8, 12),
        photoPaths: const [],
      ),
    );
    await database.saveMeal(
      database
          .getMealById('meal')!
          .copyWith(timestamp: DateTime(2026, 7, 10, 12)),
    );

    expect(
      database
          .getMealsByDateRange(DateTime(2026, 7, 10), DateTime(2026, 7, 11))
          .single
          .id,
      'meal',
    );
    expect(database.getMealsByDate(DateTime(2026, 7, 8)), isEmpty);
  });

  test('meal at 3am is attributed to previous day when dayStartHour is 4', () async {
    await database.setDayStartHour(4);
    final lateNightMeal = MealModel(
      id: 'late_night',
      timestamp: DateTime(2026, 7, 19, 3), // 19th July 3:00 AM
      photoPaths: const [],
      mealName: 'Late Snack',
    );
    await database.saveMeal(lateNightMeal);

    // Should appear in history of 18th July
    final mealsOn18th = database.getMealsByDate(DateTime(2026, 7, 18));
    expect(mealsOn18th.map((m) => m.id), contains('late_night'));

    final mealsByRangeOn18th = database.getMealsByDateRange(
      DateTime(2026, 7, 18, 4),
      DateTime(2026, 7, 19, 4),
    );
    expect(mealsByRangeOn18th.map((m) => m.id), contains('late_night'));
  });

  // The day summer time ends has 25 hours; in a time zone with summer time
  // (e.g. TZ=Europe/Berlin) stepping 24 hours from its midnight stayed on it
  // and listed its meals twice. Elsewhere this covers the plain case.
  test('lists each meal once on the day summer time ends', () async {
    for (final hour in [0, 4]) {
      await database.setDayStartHour(hour);
      await database.saveMeal(
        MealModel(
          id: 'beer',
          timestamp: DateTime(2026, 10, 25, 21, 36),
          photoPaths: const [],
          mealName: 'Beer',
          calories: 194,
        ),
      );
      await database.saveMeal(
        MealModel(
          id: 'late',
          timestamp: DateTime(2026, 10, 25, 23, 30),
          photoPaths: const [],
          mealName: 'Late snack',
          calories: 100,
        ),
      );

      final day = database.getMealsByDateRange(
        DateTime(2026, 10, 25, hour),
        DateTime(2026, 10, 26, hour),
      );
      expect(day.map((m) => m.id), ['late', 'beer'], reason: 'day start $hour');

      final week = database.getMealsByDateRange(
        DateTime(2026, 10, 20, hour),
        DateTime(2026, 10, 27, hour),
      );
      expect(
        week.map((m) => m.id),
        ['late', 'beer'],
        reason: 'day start $hour',
      );
    }
  });

  test('onboarding steps saved before the redesign map to the same screen', () {
    int migrate(int step, bool web) =>
        DatabaseService.migrateLegacyOnboardingStep(step, isWeb: web);

    // Web: welcome..activity (0-5) unchanged; loading (6) -> daily target (6);
    // daily target 7 -> 6, login 8 -> 7, api key 9 -> 8; contract and
    // saving (10, 11) -> saving (9).
    expect(
      [for (var i = 0; i <= 11; i++) migrate(i, true)],
      [0, 1, 2, 3, 4, 5, 6, 6, 7, 8, 9, 9],
    );
    // Native has health and notification steps after login.
    expect(
      [for (var i = 0; i <= 13; i++) migrate(i, false)],
      [0, 1, 2, 3, 4, 5, 6, 6, 7, 8, 9, 10, 11, 11],
    );
  });

  test('keeps sync cursors per key and clears them with the data', () async {
    expect(database.getSyncCursor('tombstones_a'), isNull);
    final first = DateTime.utc(2026, 7, 10, 10);
    final second = first.add(const Duration(hours: 1));
    await database.setSyncCursor('tombstones_a', first);
    await database.setSyncCursor('tombstones_b', second);
    expect(database.getSyncCursor('tombstones_a'), first);
    expect(database.getSyncCursor('tombstones_b'), second);

    await database.clearAll();
    expect(database.getSyncCursor('tombstones_a'), isNull);
    expect(database.getSyncCursor('tombstones_b'), isNull);
  });
}
