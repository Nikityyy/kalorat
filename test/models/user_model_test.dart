import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/user_model.dart';
import 'package:kalorat/models/enums.dart';

void main() {
  group('UserModel', () {
    group('constructor', () {
      test('creates valid UserModel with required fields', () {
        final user = UserModel(
          name: 'Test User',
          birthdate: DateTime(1990, 5, 15),
          height: 175,
          weight: 70,
        );

        expect(user.name, 'Test User');
        expect(user.birthdate, DateTime(1990, 5, 15));
        expect(user.height, 175);
        expect(user.weight, 70);
        expect(user.language, 'de'); // default
        expect(user.geminiApiKey, ''); // default
        expect(user.onboardingCompleted, false); // default
        expect(user.goal, Goal.maintain); // default: Maintain
      });

      test('creates valid UserModel with all fields', () {
        final user = UserModel(
          name: 'Full User',
          birthdate: DateTime(1985, 1, 1),
          height: 180,
          weight: 80,
          language: 'en',
          geminiApiKey: 'test-api-key',
          onboardingCompleted: true,
          mealRemindersEnabled: false,
          weightRemindersEnabled: false,
          goal: 0, // Lose
          gender: 1, // Female
          healthSyncEnabled: true,
          syncMealsToHealth: true,
          syncWeightToHealth: false,
        );

        expect(user.language, 'en');
        expect(user.geminiApiKey, 'test-api-key');
        expect(user.onboardingCompleted, true);
        expect(user.mealRemindersEnabled, false);
        expect(user.goal, Goal.lose);
        expect(user.gender, Gender.female);
        expect(user.healthSyncEnabled, true);
      });
    });

    group('age calculation', () {
      test('calculates age correctly when birthday has passed', () {
        // Assuming current date is Feb 6, 2026
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1), // Birthday already passed
          height: 175,
          weight: 70,
        );

        expect(user.age, 36);
      });

      test('calculates age correctly when birthday has not passed', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 12, 31), // Birthday not yet
          height: 175,
          weight: 70,
        );

        expect(user.age, 35);
      });

      test('calculates age for birthday today', () {
        final now = DateTime.now();
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(2000, now.month, now.day),
          height: 175,
          weight: 70,
        );

        final expectedAge = now.year - 2000;
        expect(user.age, expectedAge);
      });
    });

    group('BMI calculation', () {
      test('calculates BMI correctly', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180, // 1.8m
          weight: 75, // 75kg
        );

        // BMI = 75 / (1.8 * 1.8) = 75 / 3.24 ≈ 23.15
        expect(user.bmi, closeTo(23.15, 0.01));
      });

      test('returns correct BMI category for underweight', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 55, // BMI ≈ 17
        );

        expect(user.bmiCategory, 'underweight');
      });

      test('returns correct BMI category for normal', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 75, // BMI ≈ 23
        );

        expect(user.bmiCategory, 'normal');
      });

      test('returns correct BMI category for overweight', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 90, // BMI ≈ 27.8
        );

        expect(user.bmiCategory, 'overweight');
      });

      test('returns correct BMI category for obese', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 175,
          weight: 100, // BMI ≈ 32.7
        );

        expect(user.bmiCategory, 'obese');
      });
    });

    group('dailyCalorieTarget (TDEE)', () {
      test('calculates correct TDEE for male, maintain goal', () {
        final user = UserModel(
          name: 'Test Male',
          birthdate: DateTime(1990, 1, 1), // age ~36
          height: 180,
          weight: 80,
          gender: 0, // Male
          goal: 1, // Maintain
        );

        // BMR = (10 * 80) + (6.25 * 180) - (5 * 36) + 5
        // BMR = 800 + 1125 - 180 + 5 = 1750
        // TDEE = 1750 * 1.2 = 2100
        expect(user.dailyCalorieTarget, closeTo(2100, 10));
      });

      test('calculates correct TDEE for female, maintain goal', () {
        final user = UserModel(
          name: 'Test Female',
          birthdate: DateTime(1990, 1, 1), // age ~36
          height: 165,
          weight: 60,
          gender: 1, // Female
          goal: 1, // Maintain
        );

        // BMR = (10 * 60) + (6.25 * 165) - (5 * 36) - 161
        // BMR = 600 + 1031.25 - 180 - 161 = 1290.25
        // TDEE = 1290.25 * 1.2 ≈ 1548.3
        expect(user.dailyCalorieTarget, closeTo(1548, 10));
      });

      test('applies deficit for lose goal', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 80,
          gender: 0,
          goal: 0, // Lose
        );

        // TDEE - 500 = 2100 - 500 = 1600
        expect(user.dailyCalorieTarget, closeTo(1600, 10));
      });

      test('applies surplus for gain goal', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 80,
          gender: 0,
          goal: 2, // Gain
        );

        // TDEE + 500 = 2100 + 500 = 2600
        expect(user.dailyCalorieTarget, closeTo(2600, 10));
      });

      test('defaults to male when gender is null', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 80,
          gender: null,
          goal: 1,
        );

        // Should use male formula (+5)
        expect(user.dailyCalorieTarget, closeTo(2100, 10));
      });
    });

    group('dailyProteinTarget', () {
      test('calculates protein for maintain goal (1.5g/kg)', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 80,
          goal: 1, // Maintain
        );

        expect(user.dailyProteinTarget, 120); // 80 * 1.5
      });

      test('calculates protein for lose goal (1.8g/kg)', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 80,
          goal: 0, // Lose
        );

        expect(user.dailyProteinTarget, 144); // 80 * 1.8
      });

      test('calculates protein for gain goal (2.0g/kg)', () {
        final user = UserModel(
          name: 'Test',
          birthdate: DateTime(1990, 1, 1),
          height: 180,
          weight: 80,
          goal: 2, // Gain
        );

        expect(user.dailyProteinTarget, 160); // 80 * 2.0
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final user = UserModel(
          name: 'Test User',
          birthdate: DateTime(1990, 5, 15),
          height: 175,
          weight: 70,
          language: 'en',
          geminiApiKey: 'api-key',
          onboardingCompleted: true,
          mealRemindersEnabled: false,
          weightRemindersEnabled: false,
          goal: 0,
          gender: 1,
          healthSyncEnabled: true,
          syncMealsToHealth: true,
          syncWeightToHealth: false,
        );

        final json = user.toJson();

        expect(json['name'], 'Test User');
        expect(json['birthdate'], '1990-05-15T00:00:00.000');
        expect(json['height'], 175);
        expect(json['weight'], 70);
        expect(json['language'], 'en');
        expect(json['geminiApiKey'], 'api-key');
        expect(json['onboardingCompleted'], true);
        expect(json['goal'], 0);
        expect(json['gender'], 1);
        expect(json['healthSyncEnabled'], true);
      });
    });

    group('fromJson', () {
      test('deserializes from valid JSON', () {
        final json = {
          'name': 'Test User',
          'birthdate': '1990-05-15T00:00:00.000',
          'height': 175.0,
          'weight': 70.0,
          'language': 'en',
          'geminiApiKey': 'api-key',
          'onboardingCompleted': true,
          'goal': 0,
          'gender': 1,
        };

        final user = UserModel.fromJson(json);

        expect(user.name, 'Test User');
        expect(user.height, 175.0);
        expect(user.weight, 70.0);
        expect(user.goal, Goal.lose);
        expect(user.gender, Gender.female);
      });

      test('handles missing fields with defaults', () {
        final json = {'birthdate': '1990-05-15T00:00:00.000'};

        final user = UserModel.fromJson(json);

        expect(user.name, '');
        expect(user.height, 170.0); // default
        expect(user.weight, 70.0); // default
        expect(user.language, 'de'); // default
        expect(user.goal, Goal.maintain); // default: Maintain
        expect(user.gender, Gender.male); // default: Male
      });

      test('handles integer height/weight by converting to double', () {
        final json = {
          'birthdate': '1990-05-15T00:00:00.000',
          'height': 175, // int
          'weight': 70, // int
        };

        final user = UserModel.fromJson(json);

        expect(user.height, isA<double>());
        expect(user.weight, isA<double>());
      });
    });

    group('roundtrip serialization', () {
      test('toJson -> fromJson produces equivalent object', () {
        final original = UserModel(
          name: 'Roundtrip User',
          birthdate: DateTime(1985, 7, 20),
          height: 182.5,
          weight: 78.3,
          language: 'en',
          geminiApiKey: 'secret-key',
          onboardingCompleted: true,
          mealRemindersEnabled: false,
          weightRemindersEnabled: true,
          goal: 2,
          gender: 0,
          healthSyncEnabled: true,
          syncMealsToHealth: true,
          syncWeightToHealth: true,
        );

        final json = original.toJson();
        final restored = UserModel.fromJson(json);

        expect(restored.name, original.name);
        expect(restored.height, original.height);
        expect(restored.weight, original.weight);
        expect(restored.language, original.language);
        expect(restored.goal, original.goal);
        expect(restored.gender, original.gender);
        expect(restored.healthSyncEnabled, original.healthSyncEnabled);
      });
    });
  });
}
