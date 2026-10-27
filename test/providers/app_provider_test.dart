import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/models.dart';
import 'package:kalorat/providers/app_provider.dart';
import 'package:kalorat/services/database_service.dart';

class _MemoryDatabase extends DatabaseService {
  final List<WeightModel> weights = [];

  @override
  List<WeightModel> getAllWeights() => List.of(weights);

  @override
  Future<void> saveWeight(WeightModel weight) async {
    weights.removeWhere(
      (item) =>
          item.date.year == weight.date.year &&
          item.date.month == weight.date.month &&
          item.date.day == weight.date.day,
    );
    weights.add(weight);
  }

  final Map<String, MealModel> meals = {};

  @override
  MealModel? getMealById(String mealId) => meals[mealId];

  @override
  Future<void> deleteMeal(String mealId) async => meals.remove(mealId);

  @override
  List<MealModel> getAllMeals() =>
      meals.values.toList()..sort(compareMealsNewestFirst);

  @override
  bool hasMeal(String mealId) => meals.containsKey(mealId);

  @override
  List<MealModel> getMealsByDate(DateTime date) => meals.values
      .where(
        (meal) =>
            meal.timestamp.year == date.year &&
            meal.timestamp.month == date.month &&
            meal.timestamp.day == date.day,
      )
      .toList();

  @override
  Future<MealModel> saveMeal(MealModel meal) async => meals[meal.id] = meal;
}

MealModel _meal(String id, {required bool isPending}) => MealModel(
  id: id,
  timestamp: DateTime(2026, 7, 10, 12),
  photoPaths: const [],
  isPending: isPending,
);

void main() {
  test('AppProvider updates an existing weight entry', () async {
    final database = _MemoryDatabase();
    final previous = WeightModel(date: DateTime(2026, 7, 10), weight: 70);
    database.weights.add(previous);
    final provider = AppProvider(databaseService: database);

    await provider.updateWeight(
      previous,
      WeightModel(date: previous.date, weight: 69.5),
    );

    expect(database.weights.single.weight, 69.5);
  });

  test(
    'discardPendingMeal removes only meals still awaiting analysis',
    () async {
      final database = _MemoryDatabase();
      database.meals['queued'] = _meal('queued', isPending: true);
      database.meals['logged'] = _meal('logged', isPending: false);
      final provider = AppProvider(databaseService: database);

      await provider.discardPendingMeal('queued');
      await provider.discardPendingMeal('logged');
      await provider.discardPendingMeal('missing');

      expect(database.meals.keys, ['logged']);
    },
  );

  group('quick log', () {
    MealModel logged(
      String id,
      String name,
      int day, {
      double calories = 400,
      bool isPending = false,
    }) => MealModel(
      id: id,
      timestamp: DateTime(2026, 7, day, 12),
      photoPaths: const ['kphoto:1'],
      mealName: name,
      calories: calories,
      protein: 20,
      portionMultiplier: 2,
      portionUnit: 'gram',
      quantityPerUnit: 100,
      mealContext: 'with rice',
      isPending: isPending,
    );

    test('recentDistinctMeals lists the newest meal of each name once', () {
      final database = _MemoryDatabase();
      database.meals['a'] = logged('a', 'Oatmeal', 1);
      database.meals['b'] = logged('b', 'oatmeal', 3, calories: 450);
      database.meals['c'] = logged('c', 'Toast', 2);
      database.meals['d'] = logged('d', 'Pending', 4, isPending: true);
      database.meals['e'] = logged('e', '', 5);
      database.meals['f'] = logged('f', 'Water', 6, calories: 0);
      final provider = AppProvider(databaseService: database);

      final recent = provider.recentDistinctMeals();

      expect(recent.map((meal) => meal.id), ['b', 'c']);
    });

    test('recentDistinctMeals honours the limit', () {
      final database = _MemoryDatabase();
      for (var i = 1; i <= 5; i++) {
        database.meals['m$i'] = logged('m$i', 'Meal $i', i);
      }
      final provider = AppProvider(databaseService: database);

      expect(provider.recentDistinctMeals(limit: 3), hasLength(3));
    });

    test('repeatMeal logs a copy now, with the photos', () async {
      final database = _MemoryDatabase();
      final source = logged('a', 'Oatmeal', 1);
      database.meals['a'] = source;
      final provider = AppProvider(databaseService: database);

      final copy = await provider.repeatMeal(source);

      expect(copy.id, isNot('a'));
      expect(database.meals[copy.id], same(copy));
      expect(copy.mealName, 'Oatmeal');
      expect(copy.calories, 400);
      expect(copy.protein, 20);
      expect(copy.portionMultiplier, 2);
      expect(copy.portionUnit, 'gram');
      expect(copy.quantityPerUnit, 100);
      expect(copy.mealContext, 'with rice');
      expect(copy.photoPaths, ['kphoto:1']);
      expect(copy.isPending, isFalse);
      expect(copy.timestamp.isAfter(source.timestamp), isTrue);
      expect(source.photoPaths, ['kphoto:1']);
    });
  });
}
