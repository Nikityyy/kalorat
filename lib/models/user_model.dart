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

  @HiveField(11)
  bool healthSyncEnabled;

  @HiveField(12)
  bool syncMealsToHealth;

  @HiveField(13)
  bool syncWeightToHealth;

  @HiveField(14)
  String? supabaseUserId;

  @HiveField(15)
  bool isGuest;

  @HiveField(16)
  String? email;

  @HiveField(17)
  DateTime? lastSyncTimestamp;

  @HiveField(18)
  String? photoUrl;

  @HiveField(19)
  bool useGramsByDefault;

  @HiveField(20)
  int activityLevel; // 0: Sedentary, 1: Light, 2: Moderate, 3: Active, 4: Very Active

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
    this.healthSyncEnabled = false,
    this.syncMealsToHealth = true,
    this.syncWeightToHealth = true,
    this.supabaseUserId,
    this.isGuest = true,
    this.email,
    this.lastSyncTimestamp,
    this.photoUrl,
    this.useGramsByDefault = false,
    this.activityLevel = 0,
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

    // Activity Multiplier based on user's activity level
    const multipliers = [1.2, 1.375, 1.55, 1.725, 1.9];
    double tdee = bmr * multipliers[activityLevel.clamp(0, 4)];

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

  double get dailyCarbTarget {
    // ~50% of remaining calories after protein → divide by 4 kcal/g
    final proteinCals = dailyProteinTarget * 4;
    final remaining = (dailyCalorieTarget - proteinCals).clamp(
      0,
      double.infinity,
    );
    return (remaining * 0.55) / 4; // 55% of remaining → carbs
  }

  double get dailyFatTarget {
    // ~25-30% of total calories → divide by 9 kcal/g
    final proteinCals = dailyProteinTarget * 4;
    final remaining = (dailyCalorieTarget - proteinCals).clamp(
      0,
      double.infinity,
    );
    return (remaining * 0.45) / 9; // 45% of remaining → fats
  }

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
      goal: goal ?? this.goal,
      gender: gender ?? this.gender,
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
      syncMealsToHealth: syncMealsToHealth ?? this.syncMealsToHealth,
      syncWeightToHealth: syncWeightToHealth ?? this.syncWeightToHealth,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
      isGuest: isGuest ?? this.isGuest,
      email: email ?? this.email,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      photoUrl: photoUrl ?? this.photoUrl,
      useGramsByDefault: useGramsByDefault ?? this.useGramsByDefault,
      activityLevel: activityLevel ?? this.activityLevel,
    );
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
    'healthSyncEnabled': healthSyncEnabled,
    'syncMealsToHealth': syncMealsToHealth,
    'syncWeightToHealth': syncWeightToHealth,
    'supabaseUserId': supabaseUserId,
    'isGuest': isGuest,
    'email': email,
    'lastSyncTimestamp': lastSyncTimestamp?.toIso8601String(),
    'photoUrl': photoUrl,
    'useGramsByDefault': useGramsByDefault,
    'activityLevel': activityLevel,
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
