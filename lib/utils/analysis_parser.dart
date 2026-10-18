import 'nutrition_units.dart';

/// A Gemini analysis result read into plain values. Nutrition is the base
/// value: per serving, or per 100 g / 100 ml for weighed foods. Multiply by
/// [multiplier] for the amount that was actually eaten.
class ParsedAnalysis {
  final String mealName;
  final String unit;
  final double quantityPerUnit;
  final double multiplier;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatsPer100g;
  final double? confidence;
  final String? note;
  final double? caloriesMin;
  final double? caloriesMax;
  final Map<String, double>? vitamins;
  final Map<String, double>? minerals;

  const ParsedAnalysis({
    required this.mealName,
    required this.unit,
    required this.quantityPerUnit,
    required this.multiplier,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatsPer100g,
    this.confidence,
    this.note,
    this.caloriesMin,
    this.caloriesMax,
    this.vitamins,
    this.minerals,
  });
}

ParsedAnalysis parseAnalysisResult(Map<String, dynamic> result) {
  final portion = normalizeDetectedPortion(result);
  final unit = portion.unit;
  final quantityPerUnit = quantityPerUnitFor(unit);
  var multiplier = unit == 'serving'
      ? portion.quantity
      : portion.quantity / quantityPerUnit;
  if (multiplier <= 0) multiplier = 1.0;

  double base(String key) => nutritionBaseValue(
    result,
    unit: unit,
    valueKey: key,
    referenceKey: '${key}_per_100g',
  );
  double? number(String key) => (result[key] as num?)?.toDouble();
  final note = result['uncertainty_note']?.toString().trim();

  return ParsedAnalysis(
    mealName: result['meal_name']?.toString() ?? '',
    unit: unit,
    quantityPerUnit: quantityPerUnit,
    multiplier: multiplier,
    calories: base('calories'),
    protein: base('protein'),
    carbs: base('carbs'),
    fats: base('fats'),
    caloriesPer100g: number('calories_per_100g'),
    proteinPer100g: number('protein_per_100g'),
    carbsPer100g: number('carbs_per_100g'),
    fatsPer100g: number('fats_per_100g'),
    confidence: number('confidence_score'),
    note: note != null && note.isNotEmpty ? note : null,
    caloriesMin: number('calories_min'),
    caloriesMax: number('calories_max'),
    vitamins: _doubleMap(result['vitamins']),
    minerals: _doubleMap(result['minerals']),
  );
}

Map<String, double>? _doubleMap(Object? value) {
  if (value is! Map) return null;
  return {
    for (final entry in value.entries)
      entry.key.toString(): (entry.value as num?)?.toDouble() ?? 0,
  };
}
