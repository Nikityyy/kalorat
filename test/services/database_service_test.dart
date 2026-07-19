import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kalorat/models/models.dart';
import 'package:kalorat/services/database_service.dart';

void main() {
  late Directory directory;
  late DatabaseService database;

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
    final userBox = await Hive.openBox<UserModel>('test_users');
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
}
