import 'package:hive/hive.dart';

part 'meal_model.g.dart';

@HiveType(typeId: 1)
class MealModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  List<String> photoPaths;

  @HiveField(3)
  String mealName;

  @HiveField(4)
  double calories;

  @HiveField(5)
  double protein;

  @HiveField(6)
  double carbs;

  @HiveField(7)
  double fats;

  @HiveField(8)
  Map<String, double>? vitamins;

  @HiveField(9)
  Map<String, double>? minerals;

  @HiveField(10)
  bool isPending; // true if waiting for AI analysis (offline)

  @HiveField(11)
  bool isManualEntry;

  @HiveField(12)
  bool isCalorieOverride;

  @HiveField(13)
  double portionMultiplier;

  @HiveField(14)
  String portionUnit; // 'serving', 'gram', 'ml'

  @HiveField(15)
  double quantityPerUnit; // e.g., 1.0 for serving, 100.0 for grams

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
  );
}
