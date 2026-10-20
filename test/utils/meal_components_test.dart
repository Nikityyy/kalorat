import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/meal_component.dart';
import 'package:kalorat/models/meal_model.dart';
import 'package:kalorat/utils/analysis_parser.dart';
import 'package:kalorat/utils/meal_components.dart';
import 'package:kalorat/utils/meal_correction.dart';
import 'package:kalorat/utils/nutrition_units.dart';

const rice = MealComponent(
  name: 'Reis',
  grams: 200,
  kcalPer100g: 130,
  proteinPer100g: 2.7,
  carbsPer100g: 28.2,
  fatsPer100g: 0.3,
  ref: 'rice_white_cooked',
);
const oil = MealComponent(
  name: 'Öl',
  grams: 10,
  kcalPer100g: 884,
  proteinPer100g: 0,
  carbsPer100g: 0,
  fatsPer100g: 100,
);

void main() {
  test('analysis items become components for one base portion', () {
    final parsed = parseAnalysisResult({
      'meal_name': 'Reis',
      'detected_unit': 'serving',
      'detected_quantity': 2,
      'calories': 130,
      'protein': 2.7,
      'carbs': 28.2,
      'fats': 0.3,
      'items': [
        {
          'name': 'Reis',
          'grams': 200,
          'ref': 'rice_white_cooked',
          'kcal_per_100g': 130,
          'protein_per_100g': 2.7,
          'carbs_per_100g': 28.2,
          'fats_per_100g': 0.3,
          'assumption': '',
        },
      ],
    });
    expect(parsed.multiplier, 2);
    expect(parsed.components!.single.grams, 100);
    expect(parsed.components!.single.ref, 'rice_white_cooked');
  });

  test('items without grams give no components', () {
    expect(
      MealComponent.fromAnalysisItems([
        {'name': 'Reis', 'calories': 260},
      ], multiplier: 1),
      isNull,
    );
  });

  test('changing a component in a serving meal moves the totals', () {
    final meal = MealModel(
      id: 'm',
      timestamp: DateTime(2026),
      photoPaths: const [],
      calories: 348.4,
      protein: 5.4,
      carbs: 56.4,
      fats: 10.6,
      caloriesMin: 300,
      caloriesMax: 400,
      isCalorieOverride: true,
      components: const [rice, oil],
    );

    final change = applyComponents(meal, [rice.withGrams(100), oil], 1);

    expect(change.multiplier, 1);
    expect(change.meal.calories, closeTo(130 + 88.4, 0.001));
    expect(change.meal.fats, closeTo(0.3 + 10, 0.001));
    expect(change.meal.isCalorieOverride, isFalse);
    // The range follows the estimate.
    expect(change.meal.caloriesMin, closeTo(300 * 218.4 / 348.4, 0.01));
    expect(change.meal.components!.first.grams, 100);
  });

  test('a weighed meal keeps 100 g per base and moves the weight', () {
    // 210 g on the plate: base per 100 g, multiplier 2.1.
    final perHundred = [rice.withGrams(200 / 2.1), oil.withGrams(10 / 2.1)];
    final meal = MealModel(
      id: 'w',
      timestamp: DateTime(2026),
      photoPaths: const [],
      portionUnit: portionUnitGram,
      quantityPerUnit: 100,
      calories: 348.4 / 2.1,
      components: perHundred,
    );

    final change = applyComponents(meal, [perHundred.first], 2.1);

    // Only the rice is left: 200 g in total.
    expect(change.multiplier, closeTo(2.0, 0.0001));
    expect(change.meal.components!.single.grams, closeTo(100, 0.0001));
    expect(change.meal.calories, closeTo(130, 0.001));
    expect(change.meal.caloriesPer100g, closeTo(130, 0.001));
    expect(change.meal.calories * change.multiplier, closeTo(260, 0.001));
  });

  test('a one-tap correction scales the components with the meal', () {
    final meal = MealModel(
      id: 'c',
      timestamp: DateTime(2026),
      photoPaths: const [],
      calories: 348.4,
      protein: 5.4,
      carbs: 56.4,
      fats: 10.6,
      components: const [rice, oil],
    );

    final lower = mealWithCalories(
      meal,
      portionMultiplier: 1,
      calories: 348.4 / 2,
    );

    final sum = lower.components!.fold<double>(0, (t, c) => t + c.calories);
    expect(sum, closeTo(lower.calories, 0.001));
    expect(lower.components!.first.grams, closeTo(100, 0.001));
  });

  test('components survive a json round trip', () {
    final meal = MealModel(
      id: 'j',
      timestamp: DateTime(2026),
      photoPaths: const [],
      components: const [rice, oil],
    );
    final back = MealModel.fromJson(meal.toJson());
    expect(back.components!.length, 2);
    expect(back.components!.last.fatsPer100g, 100);
  });

  test('a model kcal that disagrees with its macros follows the macros', () {
    expect(atwaterConsistentKcal(300, protein: 0, carbs: 25, fats: 0), 100);
    expect(atwaterConsistentKcal(105, protein: 0, carbs: 25, fats: 0), 105);
    // Beer: alcohol has energy but no macro.
    expect(
      atwaterConsistentKcal(
        43,
        protein: 0.5,
        carbs: 3.6,
        fats: 0,
        liquid: true,
      ),
      43,
    );
  });

  test('model text loses its html entities', () {
    expect(
      decodeHtmlEntities('H&auml;hnchen &amp; Kn&ouml;del'),
      'Hähnchen & Knödel',
    );
  });
}
