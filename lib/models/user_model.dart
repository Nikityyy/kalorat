import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime birthdate;

  @HiveField(2)
  double height; // in cm

  @HiveField(3)
  double weight; // in kg

  @HiveField(4)
  String language; // 'de' or 'en'

  @HiveField(5)
  String geminiApiKey;

  @HiveField(6)
  bool onboardingCompleted;

  @HiveField(7)
  bool mealRemindersEnabled;

  @HiveField(8)
  bool weightRemindersEnabled;

  @HiveField(9)
  int goal; // 0: Lose, 1: Maintain, 2: Gain

  @HiveField(10)
  int? gender; // 0: Male, 1: Female

  UserModel({
    required this.name,
    required this.birthdate,
    required this.height,
    required this.weight,
    this.language = 'de',
    this.geminiApiKey = '',
    this.onboardingCompleted = false,
    this.mealRemindersEnabled = true,
    this.weightRemindersEnabled = true,
    this.goal = 1,
    this.gender,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  double get dailyCalorieTarget {
    // Mifflin-St Jeor Equation
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);

    // Gender adjustment (Male: +5, Female: -161)
    // Default to Male (0) if gender is null (legacy data)
    if ((gender ?? 0) == 0) {
      bmr += 5;
    } else {
      bmr -= 161;
    }

    // Activity Multiplier (Sedentary default for now)
    double tdee = bmr * 1.2;

    // Goal Adjustment
    // 0: Lose (-500), 1: Maintain (0), 2: Gain (+500)
    if (goal == 0) return tdee - 500;
    if (goal == 2) return tdee + 500;
    return tdee;
  }

  double get dailyProteinTarget {
    // Protein Goals (g/kg bodyweight)
    // 0: Lose -> 1.8g (spare muscle in deficit)
    // 1: Maintain -> 1.5g (standard active)
    // 2: Gain -> 2.0g (muscle synthesis)

    double multiplier = 1.5;
    if (goal == 0) multiplier = 1.8;
    if (goal == 2) multiplier = 2.0;

    return weight * multiplier;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'birthdate': birthdate.toIso8601String(),
    'height': height,
    'weight': weight,
    'language': language,
    'geminiApiKey': geminiApiKey,
    'onboardingCompleted': onboardingCompleted,
    'mealRemindersEnabled': mealRemindersEnabled,
    'weightRemindersEnabled': weightRemindersEnabled,
    'goal': goal,
    'gender': gender,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? '',
    birthdate: DateTime.parse(json['birthdate']),
    height: (json['height'] ?? 170.0),
    weight: (json['weight'] ?? 70.0),
    language: json['language'] ?? 'de',
    geminiApiKey: json['geminiApiKey'] ?? '',
    onboardingCompleted: json['onboardingCompleted'] ?? false,
    mealRemindersEnabled: json['mealRemindersEnabled'] ?? true,
    weightRemindersEnabled: json['weightRemindersEnabled'] ?? true,
    goal: json['goal'] ?? 1,
    gender: json['gender'] ?? 0,
  );
}
