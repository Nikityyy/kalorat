import 'dart:math';
import 'package:hive/hive.dart';
import 'enums.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final DateTime birthdate;

  @HiveField(2)
  final double height; // in cm, clamped 50–300

  @HiveField(3)
  final double weight; // in kg, clamped 1–500

  @HiveField(4)
  final String language; // 'de' or 'en'

  @HiveField(5)
  final String geminiApiKey;

  @HiveField(6)
  final bool onboardingCompleted;

  @HiveField(7)
  final bool mealRemindersEnabled;

  @HiveField(8)
  final bool weightRemindersEnabled;

  // Stored as int for Hive backward compat; use `goal` getter for enum.
  @HiveField(9)
  final int goalIndex;

  // Stored as int? for Hive backward compat; use `gender` getter for enum.
  @HiveField(10)
  final int? genderIndex;

  @HiveField(11)
  final bool healthSyncEnabled;

  @HiveField(12)
  final bool syncMealsToHealth;

  @HiveField(13)
  final bool syncWeightToHealth;

  @HiveField(14)
  final String? supabaseUserId;

  @HiveField(15)
  final bool isGuest;

  @HiveField(16)
  final String? email;

  @HiveField(17)
  final DateTime? lastSyncTimestamp;

  @HiveField(18)
  final String? photoUrl;

  @HiveField(19)
  final bool useGramsByDefault;

  // Stored as int for Hive backward compat; use `activityLevel` getter.
  @HiveField(20)
  final int activityLevelIndex;

  // --------------- Enum accessors ---------------

  Goal get goal => Goal.fromIndex(goalIndex);
  Gender get gender => Gender.fromIndex(genderIndex ?? 0);
  Gender? get genderNullable =>
      genderIndex != null ? Gender.fromIndex(genderIndex!) : null;
  ActivityLevel get activityLevel =>
      ActivityLevel.fromIndex(activityLevelIndex);

  // --------------- Constructor ---------------

  UserModel({
    required this.name,
    required this.birthdate,
    required double height,
    required double weight,
    this.language = 'de',
    this.geminiApiKey = '',
    this.onboardingCompleted = false,
    this.mealRemindersEnabled = true,
    this.weightRemindersEnabled = true,
    int goal = 1,
    int? gender,
    this.healthSyncEnabled = false,
    this.syncMealsToHealth = true,
    this.syncWeightToHealth = true,
    this.supabaseUserId,
    this.isGuest = true,
    this.email,
    this.lastSyncTimestamp,
    this.photoUrl,
    this.useGramsByDefault = false,
    int activityLevel = 0,
  }) : height = height.clamp(50.0, 300.0),
       weight = weight.clamp(1.0, 500.0),
       goalIndex = goal.clamp(0, Goal.values.length - 1),
       genderIndex = gender?.clamp(0, Gender.values.length - 1),
       activityLevelIndex = activityLevel.clamp(
         0,
         ActivityLevel.values.length - 1,
       );

  /// Named constructor for enum-typed callers.
  UserModel.withEnums({
    required String name,
    required DateTime birthdate,
    required double height,
    required double weight,
    String language = 'de',
    String geminiApiKey = '',
    bool onboardingCompleted = false,
    bool mealRemindersEnabled = true,
    bool weightRemindersEnabled = true,
    Goal goal = Goal.maintain,
    Gender? gender,
    bool healthSyncEnabled = false,
    bool syncMealsToHealth = true,
    bool syncWeightToHealth = true,
    String? supabaseUserId,
    bool isGuest = true,
    String? email,
    DateTime? lastSyncTimestamp,
    String? photoUrl,
    bool useGramsByDefault = false,
    ActivityLevel activityLevel = ActivityLevel.sedentary,
  }) : this(
         name: name,
         birthdate: birthdate,
         height: height,
         weight: weight,
         language: language,
         geminiApiKey: geminiApiKey,
         onboardingCompleted: onboardingCompleted,
         mealRemindersEnabled: mealRemindersEnabled,
         weightRemindersEnabled: weightRemindersEnabled,
         goal: goal.index,
         gender: gender?.index,
         healthSyncEnabled: healthSyncEnabled,
         syncMealsToHealth: syncMealsToHealth,
         syncWeightToHealth: syncWeightToHealth,
         supabaseUserId: supabaseUserId,
         isGuest: isGuest,
         email: email,
         lastSyncTimestamp: lastSyncTimestamp,
         photoUrl: photoUrl,
         useGramsByDefault: useGramsByDefault,
         activityLevel: activityLevel.index,
       );

  // --------------- Computed properties ---------------

  int get age {
    final now = DateTime.now();
    int a = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      a--;
    }
    return max(0, a);
  }

  double get bmi {
    if (height <= 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25) return 'normal';
    if (bmi < 30) return 'overweight';
    return 'obese';
  }

  double get minHealthyWeight {
    if (height <= 0) return 0;
    // BMI 18.5 is lower bound of normal
    // weight = BMI * (height/100)^2
    return 18.5 * ((height / 100) * (height / 100));
  }

  double get maxHealthyWeight {
    if (height <= 0) return 0;
    // BMI 24.9 is upper bound of normal
    return 24.9 * ((height / 100) * (height / 100));
  }

  double get dailyCalorieTarget {
    // Mifflin-St Jeor Equation
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);

    // Gender adjustment
    if (gender == Gender.male) {
      bmr += 5;
    } else {
      bmr -= 161;
    }

    // Activity multiplier
    double tdee = bmr * activityLevel.multiplier;

    // Goal adjustment
    if (goal == Goal.lose) return tdee - 500;
    if (goal == Goal.gain) return tdee + 500;
    return tdee;
  }

  double get dailyProteinTarget {
    double mult = 1.5;
    if (goal == Goal.lose) mult = 1.8;
    if (goal == Goal.gain) mult = 2.0;
    return weight * mult;
  }

  double get dailyCarbTarget {
    final proteinCals = dailyProteinTarget * 4;
    final remaining = (dailyCalorieTarget - proteinCals).clamp(
      0,
      double.infinity,
    );
    return (remaining * 0.55) / 4;
  }

  double get dailyFatTarget {
    final proteinCals = dailyProteinTarget * 4;
    final remaining = (dailyCalorieTarget - proteinCals).clamp(
      0,
      double.infinity,
    );
    return (remaining * 0.45) / 9;
  }

  // --------------- copyWith ---------------

  UserModel copyWith({
    String? name,
    DateTime? birthdate,
    double? height,
    double? weight,
    String? language,
    String? geminiApiKey,
    bool? onboardingCompleted,
    bool? mealRemindersEnabled,
    bool? weightRemindersEnabled,
    int? goal,
    int? gender,
    bool? healthSyncEnabled,
    bool? syncMealsToHealth,
    bool? syncWeightToHealth,
    String? supabaseUserId,
    bool? isGuest,
    String? email,
    DateTime? lastSyncTimestamp,
    String? photoUrl,
    bool? useGramsByDefault,
    int? activityLevel,
  }) {
    return UserModel(
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      language: language ?? this.language,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      mealRemindersEnabled: mealRemindersEnabled ?? this.mealRemindersEnabled,
      weightRemindersEnabled:
          weightRemindersEnabled ?? this.weightRemindersEnabled,
      goal: goal ?? goalIndex,
      gender: gender ?? genderIndex,
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
      syncMealsToHealth: syncMealsToHealth ?? this.syncMealsToHealth,
      syncWeightToHealth: syncWeightToHealth ?? this.syncWeightToHealth,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
      isGuest: isGuest ?? this.isGuest,
      email: email ?? this.email,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      photoUrl: photoUrl ?? this.photoUrl,
      useGramsByDefault: useGramsByDefault ?? this.useGramsByDefault,
      activityLevel: activityLevel ?? activityLevelIndex,
    );
  }

  // --------------- Serialization ---------------

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
    'goal': goalIndex,
    'gender': genderIndex,
    'healthSyncEnabled': healthSyncEnabled,
    'syncMealsToHealth': syncMealsToHealth,
    'syncWeightToHealth': syncWeightToHealth,
    'supabaseUserId': supabaseUserId,
    'isGuest': isGuest,
    'email': email,
    'lastSyncTimestamp': lastSyncTimestamp?.toIso8601String(),
    'photoUrl': photoUrl,
    'useGramsByDefault': useGramsByDefault,
    'activityLevel': activityLevelIndex,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] ?? '',
    birthdate: DateTime.parse(json['birthdate']),
    height: (json['height'] as num?)?.toDouble() ?? 170.0,
    weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
    language: json['language'] ?? 'de',
    geminiApiKey: json['geminiApiKey'] ?? '',
    onboardingCompleted: json['onboardingCompleted'] ?? false,
    mealRemindersEnabled: json['mealRemindersEnabled'] ?? true,
    weightRemindersEnabled: json['weightRemindersEnabled'] ?? true,
    goal: json['goal'] ?? 1,
    gender: json['gender'] ?? 0,
    healthSyncEnabled: json['healthSyncEnabled'] ?? false,
    syncMealsToHealth: json['syncMealsToHealth'] ?? true,
    syncWeightToHealth: json['syncWeightToHealth'] ?? true,
    supabaseUserId: json['supabaseUserId'],
    isGuest: json['isGuest'] ?? true,
    email: json['email'],
    lastSyncTimestamp: json['lastSyncTimestamp'] != null
        ? DateTime.parse(json['lastSyncTimestamp'])
        : null,
    photoUrl: json['photoUrl'],
    useGramsByDefault: json['useGramsByDefault'] ?? false,
    activityLevel: json['activityLevel'] ?? 0,
  );
}
