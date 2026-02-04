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
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? '',
    birthdate: DateTime.parse(json['birthdate']),
    height: (json['height'] ?? 170).toDouble(),
    weight: (json['weight'] ?? 70).toDouble(),
    language: json['language'] ?? 'de',
    geminiApiKey: json['geminiApiKey'] ?? '',
    onboardingCompleted: json['onboardingCompleted'] ?? false,
    mealRemindersEnabled: json['mealRemindersEnabled'] ?? true,
    weightRemindersEnabled: json['weightRemindersEnabled'] ?? true,
  );
}
