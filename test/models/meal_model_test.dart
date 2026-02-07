import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/meal_model.dart';

void main() {
  group('MealModel', () {
    group('constructor', () {
      test('creates a valid MealModel with required fields', () {
        final meal = MealModel(
          id: 'test-id',
          timestamp: DateTime(2026, 2, 6, 12, 0),
          photoPaths: ['/test/photo.jpg'],
        );

        expect(meal.id, 'test-id');
        expect(meal.timestamp, DateTime(2026, 2, 6, 12, 0));
        expect(meal.photoPaths, ['/test/photo.jpg']);
        expect(meal.mealName, '');
        expect(meal.calories, 0);
        expect(meal.protein, 0);
        expect(meal.carbs, 0);
        expect(meal.fats, 0);
        expect(meal.isPending, false);
        expect(meal.isManualEntry, false);
        expect(meal.isCalorieOverride, false);
        expect(meal.portionMultiplier, 1.0);
      });

      test('creates a valid MealModel with all fields', () {
        final meal = MealModel(
          id: 'test-id',
          timestamp: DateTime(2026, 2, 6, 12, 0),
          photoPaths: ['/test/photo.jpg'],
          mealName: 'Test Meal',
          calories: 500,
          protein: 25,
          carbs: 50,
          fats: 15,
          vitamins: {'A': 100.0, 'C': 50.0},
          minerals: {'Calcium': 200.0},
          isPending: true,
          isManualEntry: true,
          isCalorieOverride: true,
          portionMultiplier: 2.5,
        );

        expect(meal.mealName, 'Test Meal');
        expect(meal.calories, 500);
        expect(meal.protein, 25);
        expect(meal.carbs, 50);
        expect(meal.fats, 15);
        expect(meal.vitamins, {'A': 100.0, 'C': 50.0});
        expect(meal.minerals, {'Calcium': 200.0});
        expect(meal.isPending, true);
        expect(meal.isManualEntry, true);
        expect(meal.isCalorieOverride, true);
        expect(meal.portionMultiplier, 2.5);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final original = MealModel(
          id: 'test-id',
          timestamp: DateTime(2026, 2, 6),
          photoPaths: ['/test/photo.jpg'],
          mealName: 'Original',
          calories: 100,
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.mealName, original.mealName);
        expect(copy.calories, original.calories);
      });

      test('copies with changes', () {
        final original = MealModel(
          id: 'test-id',
          timestamp: DateTime(2026, 2, 6),
          photoPaths: ['/test/photo.jpg'],
          mealName: 'Original',
          calories: 100,
        );

        final copy = original.copyWith(
          mealName: 'Updated',
          calories: 200,
          isPending: true,
          portionMultiplier: 1.5,
        );

        expect(copy.id, original.id);
        expect(copy.mealName, 'Updated');
        expect(copy.calories, 200);
        expect(copy.isPending, true);
        expect(copy.portionMultiplier, 1.5);
      });
    });

    group('toJson', () {
      test('serializes all fields to JSON', () {
        final meal = MealModel(
          id: 'test-id',
          timestamp: DateTime(2026, 2, 6, 12, 0),
          photoPaths: ['/test/photo.jpg'],
          mealName: 'Test Meal',
          calories: 500,
          protein: 25,
          carbs: 50,
          fats: 15,
          vitamins: {'A': 100.0},
          minerals: {'Calcium': 200.0},
          isPending: false,
          isManualEntry: true,
          isCalorieOverride: false,
        );

        final json = meal.toJson();

        expect(json['id'], 'test-id');
        expect(json['timestamp'], '2026-02-06T12:00:00.000');
        expect(json['photoPaths'], ['/test/photo.jpg']);
        expect(json['mealName'], 'Test Meal');
        expect(json['calories'], 500);
        expect(json['protein'], 25);
        expect(json['carbs'], 50);
        expect(json['fats'], 15);
        expect(json['vitamins'], {'A': 100.0});
        expect(json['minerals'], {'Calcium': 200.0});
        expect(json['isPending'], false);
        expect(json['isManualEntry'], true);
        expect(json['isCalorieOverride'], false);
      });
    });

    group('fromJson', () {
      test('deserializes from valid JSON', () {
        final json = {
          'id': 'test-id',
          'timestamp': '2026-02-06T12:00:00.000',
          'photoPaths': ['/test/photo.jpg'],
          'mealName': 'Test Meal',
          'calories': 500,
          'protein': 25,
          'carbs': 50,
          'fats': 15,
          'vitamins': {'A': 100.0},
          'minerals': {'Calcium': 200.0},
          'isPending': false,
          'isManualEntry': true,
          'isCalorieOverride': false,
          'portionMultiplier': 2.0,
        };

        final meal = MealModel.fromJson(json);

        expect(meal.id, 'test-id');
        expect(meal.mealName, 'Test Meal');
        expect(meal.calories, 500);
        expect(meal.protein, 25);
        expect(meal.vitamins, {'A': 100.0});
        expect(meal.portionMultiplier, 2.0);
      });

      test('handles null/missing fields with defaults', () {
        final json = {'timestamp': '2026-02-06T12:00:00.000'};

        final meal = MealModel.fromJson(json);

        expect(meal.id, isNotEmpty);
        expect(meal.mealName, '');
        expect(meal.calories, 0);
        expect(meal.protein, 0);
        expect(meal.isPending, false);
        expect(meal.portionMultiplier, 1.0);
      });

      test('handles integer values by converting to double', () {
        final json = {
          'timestamp': '2026-02-06T12:00:00.000',
          'calories': 500, // int, not double
          'protein': 25,
          'carbs': 50,
          'fats': 15,
        };

        final meal = MealModel.fromJson(json);

        expect(meal.calories, 500.0);
        expect(meal.calories, isA<double>());
        expect(meal.protein, isA<double>());
      });
    });

    group('roundtrip serialization', () {
      test('toJson -> fromJson produces equivalent object', () {
        final original = MealModel(
          id: 'roundtrip-test',
          timestamp: DateTime(2026, 2, 6, 12, 30, 45),
          photoPaths: ['/test/photo.jpg', '/test/photo.jpg'],
          mealName: 'Roundtrip Meal',
          calories: 750.5,
          protein: 30.2,
          carbs: 80.1,
          fats: 25.7,
          vitamins: {'A': 100.0, 'C': 50.0, 'D': 25.0},
          minerals: {'Calcium': 200.0, 'Iron': 10.0},
          isPending: true,
          isManualEntry: true,
          isCalorieOverride: true,
          portionMultiplier: 3.5,
        );

        final json = original.toJson();
        final restored = MealModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.mealName, original.mealName);
        expect(restored.calories, original.calories);
        expect(restored.protein, original.protein);
        expect(restored.carbs, original.carbs);
        expect(restored.fats, original.fats);
        expect(restored.vitamins, original.vitamins);
        expect(restored.minerals, original.minerals);
        expect(restored.isPending, original.isPending);
        expect(restored.isManualEntry, original.isManualEntry);
        expect(restored.isCalorieOverride, original.isCalorieOverride);
        expect(restored.portionMultiplier, original.portionMultiplier);
      });
    });
  });
}
