import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/meal_model.dart';
import 'package:kalorat/models/user_model.dart';
import 'package:kalorat/models/weight_model.dart';

/// Test helper utilities for Kalorat tests
class TestData {
  /// Creates a sample MealModel for testing
  static MealModel sampleMeal({
    String? id,
    DateTime? timestamp,
    List<String>? photoPaths,
    String mealName = 'Test Meal',
    double calories = 500,
    double protein = 25,
    double carbs = 50,
    double fats = 15,
    bool isPending = false,
  }) {
    return MealModel(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: timestamp ?? DateTime.now(),
      photoPaths: photoPaths ?? ['/test/photo.jpg'],
      mealName: mealName,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      isPending: isPending,
    );
  }

  /// Creates a sample UserModel for testing
  static UserModel sampleUser({
    String name = 'Test User',
    DateTime? birthdate,
    double height = 175,
    double weight = 70,
    String language = 'de',
    int goal = 1,
    int? gender = 0,
  }) {
    return UserModel(
      name: name,
      birthdate: birthdate ?? DateTime(1990, 1, 1),
      height: height,
      weight: weight,
      language: language,
      goal: goal,
      gender: gender,
    );
  }

  /// Creates a sample WeightModel for testing
  static WeightModel sampleWeight({
    DateTime? date,
    double weight = 75.5,
    String? note,
  }) {
    return WeightModel(
      date: date ?? DateTime.now(),
      weight: weight,
      note: note,
    );
  }

  /// Sample API response for successful meal analysis
  static Map<String, dynamic> sampleGeminiResponse({
    String mealName = 'Analyzed Meal',
    double calories = 450,
    double protein = 30,
    double carbs = 40,
    double fats = 18,
    double confidenceScore = 0.85,
  }) {
    return {
      'meal_name': mealName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'vitamins': {'A': 100.0, 'C': 50.0},
      'minerals': {'Calcium': 200.0},
      'confidence_score': confidenceScore,
      'analysis_note': 'Test analysis',
    };
  }

  /// Sample no food detected response
  static Map<String, dynamic> noFoodDetectedResponse() {
    return {'error': 'no_food_detected'};
  }
}

/// Test helper to validate Atwater formula
bool atwaterValidation(
  double calories,
  double protein,
  double carbs,
  double fats, {
  double tolerance = 0.15,
}) {
  final calculated = (protein * 4) + (carbs * 4) + (fats * 9);
  final diff = (calories - calculated).abs();
  return diff <= (calories * tolerance);
}

void main() {
  group('TestData helpers', () {
    test('sampleMeal creates valid MealModel', () {
      final meal = TestData.sampleMeal();
      expect(meal.mealName, 'Test Meal');
      expect(meal.calories, 500);
    });

    test('sampleUser creates valid UserModel', () {
      final user = TestData.sampleUser();
      expect(user.name, 'Test User');
      expect(user.height, 175);
    });

    test('sampleWeight creates valid WeightModel', () {
      final weight = TestData.sampleWeight();
      expect(weight.weight, 75.5);
    });

    test('sampleGeminiResponse creates valid response map', () {
      final response = TestData.sampleGeminiResponse();
      expect(response['meal_name'], 'Analyzed Meal');
      expect(response.containsKey('vitamins'), true);
    });
  });

  group('atwaterValidation helper', () {
    test('returns true for valid Atwater calculation', () {
      // 25*4 + 50*4 + 15*9 = 100 + 200 + 135 = 435
      expect(atwaterValidation(435, 25, 50, 15), true);
    });

    test('returns true within tolerance', () {
      // Calculated = 435, reported = 450, diff = 15, 15/450 = 0.033 < 0.15
      expect(atwaterValidation(450, 25, 50, 15), true);
    });

    test('returns false outside tolerance', () {
      // Calculated = 435, reported = 600, diff = 165, 165/600 = 0.275 > 0.15
      expect(atwaterValidation(600, 25, 50, 15), false);
    });
  });
}
