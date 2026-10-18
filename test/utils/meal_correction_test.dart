import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/meal_model.dart';
import 'package:kalorat/utils/meal_correction.dart';

MealModel meal({
  double calories = 500,
  double? min = 420,
  double? max = 580,
  String unit = 'serving',
  double? caloriesPer100g,
}) => MealModel(
  id: '1',
  timestamp: DateTime(2026, 10, 18),
  photoPaths: const [],
  calories: calories,
  protein: 30,
  carbs: 50,
  fats: 20,
  caloriesMin: min,
  caloriesMax: max,
  portionUnit: unit,
  caloriesPer100g: caloriesPer100g,
);

void main() {
  group('calorieChoices', () {
    test('offers the ends of the range and the original for the portion', () {
      final choices = calorieChoices(meal(), 1.5, originalCalories: 500);
      expect(choices.map((c) => c.kcal), [630, 750, 870]);
      expect(choices.map((c) => c.kind), [
        CalorieChoiceKind.lower,
        CalorieChoiceKind.original,
        CalorieChoiceKind.higher,
      ]);
    });

    test('keeps the original after a correction', () {
      final corrected = mealWithCalories(
        meal(),
        portionMultiplier: 1,
        calories: 420,
      );
      final choices = calorieChoices(corrected, 1, originalCalories: 500);
      expect(choices.map((c) => c.kcal), [420, 500, 580]);
    });

    test('has nothing to offer without a range', () {
      expect(
        calorieChoices(meal(min: null, max: null), 1, originalCalories: 500),
        isEmpty,
      );
      expect(
        calorieChoices(meal(min: 500, max: 500), 1, originalCalories: 500),
        isEmpty,
      );
    });

    test('shows an end that equals the original once, as the original', () {
      final choices = calorieChoices(
        meal(calories: 420),
        1,
        originalCalories: 420,
      );
      expect(choices.map((c) => c.kcal), [420, 580]);
      expect(choices.first.kind, CalorieChoiceKind.original);
    });
  });

  group('mealWithCalories', () {
    test('sets the calories and scales the macros with them', () {
      final corrected = mealWithCalories(
        meal(),
        portionMultiplier: 1,
        calories: 400,
      );
      expect(corrected.calories, 400);
      expect(corrected.protein, closeTo(24, 1e-9));
      expect(corrected.carbs, closeTo(40, 1e-9));
      expect(corrected.fats, closeTo(16, 1e-9));
      expect(corrected.isCalorieOverride, isTrue);
    });

    test('keeps the range so another choice stays possible', () {
      final corrected = mealWithCalories(
        meal(),
        portionMultiplier: 1,
        calories: 420,
      );
      expect(corrected.caloriesMin, 420);
      expect(corrected.caloriesMax, 580);
    });

    test('works on the base values of a scaled portion', () {
      // 3.3 x 33 kcal per 100 ml is 109 kcal; ask for 120.
      final corrected = mealWithCalories(
        meal(calories: 33, min: null, max: null, unit: 'ml'),
        portionMultiplier: 3.3,
        calories: 120,
      );
      expect(corrected.calories * 3.3, closeTo(120, 1e-9));
      expect(corrected.caloriesPer100g, closeTo(120 / 3.3, 1e-9));
    });

    test('a meal without calories only gets the new number', () {
      final corrected = mealWithCalories(
        MealModel(
          id: '1',
          timestamp: DateTime(2026, 10, 18),
          photoPaths: const [],
        ),
        portionMultiplier: 1,
        calories: 300,
      );
      expect(corrected.calories, 300);
      expect(corrected.protein, 0);
    });
  });
}
