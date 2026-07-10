import 'package:hive/hive.dart';

part 'meal_model.g.dart';

int compareMealsNewestFirst(MealModel a, MealModel b) {
  final aMinute = DateTime(
    a.timestamp.year,
    a.timestamp.month,
    a.timestamp.day,
    a.timestamp.hour,
    a.timestamp.minute,
  );
  final bMinute = DateTime(
    b.timestamp.year,
    b.timestamp.month,
    b.timestamp.day,
    b.timestamp.hour,
    b.timestamp.minute,
  );
  final byMinute = bMinute.compareTo(aMinute);
  if (byMinute != 0) return byMinute;

  if (a.isPending != b.isPending) return a.isPending ? -1 : 1;

  final byTimestamp = b.timestamp.compareTo(a.timestamp);
  if (byTimestamp != 0) return byTimestamp;

  return b.id.compareTo(a.id);
}

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

  @HiveField(20)
  final String? mealContext;

  @HiveField(21)
  final DateTime updatedAt;

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
    this.mealContext,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

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
    String? mealContext,
    DateTime? updatedAt,
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
      mealContext: mealContext ?? this.mealContext,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void validate() {
    if (id.trim().isEmpty || mealName.length > 200) {
      throw const FormatException('Ungültige Mahlzeit.');
    }
    final values = <String, double>{
      'Kalorien': calories,
      'Protein': protein,
      'Kohlenhydrate': carbs,
      'Fett': fats,
      'Portionsfaktor': portionMultiplier,
      'Menge pro Einheit': quantityPerUnit,
    };
    for (final entry in values.entries) {
      if (!entry.value.isFinite || entry.value < 0) {
        throw FormatException('${entry.key} darf nicht negativ sein.');
      }
    }
    if (calories > 10000 || protein > 1000 || carbs > 1000 || fats > 1000) {
      throw const FormatException('Unrealistische Nährwerte.');
    }
    if (portionMultiplier <= 0 || portionMultiplier > 1000 ||
        quantityPerUnit <= 0 || quantityPerUnit > 100000) {
      throw const FormatException('Unrealistische Portionsgröße.');
    }
    for (final value in [
      caloriesPer100g,
      proteinPer100g,
      carbsPer100g,
      fatsPer100g,
    ]) {
      if (value != null && (!value.isFinite || value < 0 || value > 1000)) {
        throw const FormatException('Ungültige Nährwerte pro 100 g.');
      }
    }
    if ([proteinPer100g, carbsPer100g, fatsPer100g]
        .whereType<double>()
        .any((value) => value > 100)) {
      throw const FormatException('Makros pro 100 g dürfen 100 g nicht überschreiten.');
    }
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
    'mealContext': mealContext,
    'updatedAt': updatedAt.toIso8601String(),
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
    mealContext: json['mealContext'],
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
  );
}
