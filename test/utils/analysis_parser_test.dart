import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/utils/analysis_parser.dart';

void main() {
  test('reads a per-serving result with the serving count as multiplier', () {
    final parsed = parseAnalysisResult({
      'meal_name': 'Pasta',
      'calories': 400,
      'protein': 14,
      'carbs': 70,
      'fats': 8,
      'detected_unit': 'serving',
      'detected_quantity': 1.5,
      'confidence_score': 0.8,
      'uncertainty_note': '  sauce unclear ',
      'calories_min': 500,
      'calories_max': 700,
      'vitamins': {'c': 3},
    });
    expect(parsed.mealName, 'Pasta');
    expect(parsed.unit, 'serving');
    expect(parsed.quantityPerUnit, 1.0);
    expect(parsed.multiplier, 1.5);
    expect(parsed.calories, 400);
    expect(parsed.confidence, 0.8);
    expect(parsed.note, 'sauce unclear');
    expect(parsed.caloriesMin, 500);
    expect(parsed.vitamins, {'c': 3.0});
    expect(parsed.minerals, isNull);
  });

  test('uses per-100 g reference values and amount / 100 for weighed food', () {
    final parsed = parseAnalysisResult({
      'meal_name': 'Rice',
      'calories': 650,
      'calories_per_100g': 130,
      'protein_per_100g': 2.7,
      'carbs_per_100g': 28,
      'fats_per_100g': 0.3,
      'detected_unit': 'gram',
      'detected_quantity': 250,
    });
    expect(parsed.unit, 'gram');
    expect(parsed.quantityPerUnit, 100.0);
    expect(parsed.multiplier, 2.5);
    expect(parsed.calories, 130);
    expect(parsed.protein, 2.7);
    expect(parsed.caloriesPer100g, 130);
  });

  test('falls back to one serving and empty values for a sparse result', () {
    final parsed = parseAnalysisResult({'calories': 90});
    expect(parsed.mealName, '');
    expect(parsed.unit, 'serving');
    expect(parsed.multiplier, 1.0);
    expect(parsed.calories, 90);
    expect(parsed.protein, 0);
    expect(parsed.note, isNull);
    expect(parsed.confidence, isNull);
  });

  test('treats an empty uncertainty note as none', () {
    expect(parseAnalysisResult({'uncertainty_note': '   '}).note, isNull);
  });
}
