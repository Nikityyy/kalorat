import 'package:hive/hive.dart';

part 'meal_model.g.dart';

@HiveType(typeId: 1)
class MealModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final List<String> photoPaths;

  @HiveField(3)
  final String mealName;

  @HiveField(4)
  final double calories;

  @HiveField(5)
  final double protein;

  @HiveField(6)
  final double carbs;

  @HiveField(7)
  final double fats;

  @HiveField(8)
  final Map<String, double>? vitamins;

  @HiveField(9)
  final Map<String, double>? minerals;

  @HiveField(10)
  final bool isPending; // true if waiting for AI analysis (offline)

  @HiveField(11)
  final bool isManualEntry;

  @HiveField(12)
  final bool isCalorieOverride;

  @HiveField(13)
  final double portionMultiplier;

  @HiveField(14)
  final String portionUnit; // 'serving', 'gram', 'ml'

  @HiveField(15)
  final double quantityPerUnit; // e.g., 1.0 for serving, 100.0 for grams

  @HiveField(16)
  final double? caloriesPer100g;

  @HiveField(17)
  final double? proteinPer100g;

  @HiveField(18)
  final double? carbsPer100g;

  @HiveField(19)
  final double? fatsPer100g;

  MealModel({
    required this.id,
    required this.timestamp,
    required this.photoPaths,
    this.mealName = '',
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.vitamins,
    this.minerals,
    this.isPending = false,
    this.isManualEntry = false,
    this.isCalorieOverride = false,
    this.portionMultiplier = 1.0,
    this.portionUnit = 'serving',
    this.quantityPerUnit = 1.0,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatsPer100g,
  });

  MealModel copyWith({
    String? id,
    DateTime? timestamp,
    List<String>? photoPaths,
    String? mealName,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    Map<String, double>? vitamins,
    Map<String, double>? minerals,
    bool? isPending,
    bool? isManualEntry,
    bool? isCalorieOverride,
    double? portionMultiplier,
    String? portionUnit,
    double? quantityPerUnit,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatsPer100g,
  }) {
    return MealModel(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      photoPaths: photoPaths ?? this.photoPaths,
      mealName: mealName ?? this.mealName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      vitamins: vitamins ?? this.vitamins,
      minerals: minerals ?? this.minerals,
      isPending: isPending ?? this.isPending,
      isManualEntry: isManualEntry ?? this.isManualEntry,
      isCalorieOverride: isCalorieOverride ?? this.isCalorieOverride,
      portionMultiplier: portionMultiplier ?? this.portionMultiplier,
      portionUnit: portionUnit ?? this.portionUnit,
      quantityPerUnit: quantityPerUnit ?? this.quantityPerUnit,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatsPer100g: fatsPer100g ?? this.fatsPer100g,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'photoPaths': photoPaths,
    'mealName': mealName,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fats': fats,
    'vitamins': vitamins,
    'minerals': minerals,
    'isPending': isPending,
    'isManualEntry': isManualEntry,
    'isCalorieOverride': isCalorieOverride,
    'portionMultiplier': portionMultiplier,
    'portionUnit': portionUnit,
    'quantityPerUnit': quantityPerUnit,
    'caloriesPer100g': caloriesPer100g,
    'proteinPer100g': proteinPer100g,
    'carbsPer100g': carbsPer100g,
    'fatsPer100g': fatsPer100g,
  };

  factory MealModel.fromJson(Map<String, dynamic> json) => MealModel(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    timestamp: DateTime.parse(json['timestamp']),
    photoPaths: List<String>.from(json['photoPaths'] ?? []),
    mealName: json['mealName'] ?? '',
    calories: (json['calories'] ?? 0).toDouble(),
    protein: (json['protein'] ?? 0).toDouble(),
    carbs: (json['carbs'] ?? 0).toDouble(),
    fats: (json['fats'] ?? 0).toDouble(),
    vitamins: json['vitamins'] != null
        ? Map<String, double>.from(json['vitamins'])
        : null,
    minerals: json['minerals'] != null
        ? Map<String, double>.from(json['minerals'])
        : null,
    isPending: json['isPending'] ?? false,
    isManualEntry: json['isManualEntry'] ?? false,
    isCalorieOverride: json['isCalorieOverride'] ?? false,
    portionMultiplier: (json['portionMultiplier'] ?? 1.0).toDouble(),
    portionUnit: json['portionUnit'] ?? 'serving',
    quantityPerUnit: (json['quantityPerUnit'] ?? 1.0).toDouble(),
    caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble(),
    proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble(),
    carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble(),
    fatsPer100g: (json['fatsPer100g'] as num?)?.toDouble(),
  );
}
