import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/utils/nutrition_units.dart';

void main() {
  group('nutrition unit helpers', () {
    test('normalize detected units to app-supported values', () {
      expect(normalizePortionUnit('grams'), portionUnitGram);
      expect(normalizePortionUnit('g'), portionUnitGram);
      expect(normalizePortionUnit('milliliters'), portionUnitMl);
      expect(normalizePortionUnit('servings'), portionUnitServing);
      expect(normalizePortionUnit('unexpected'), portionUnitServing);
    });

    test('convert liter quantities to ml', () {
      final portion = normalizeDetectedPortion({
        'detected_unit': 'liters',
        'detected_quantity': 0.25,
      });

      expect(portion.unit, portionUnitMl);
      expect(portion.quantity, 250);
    });

    test('use reference values as base values for ml entries', () {
      final result = {
        'calories': 1280,
        'calories_per_100g': 64,
        'detected_unit': 'ml',
        'detected_quantity': 200,
      };

      expect(
        nutritionBaseValue(
          result,
          unit: portionUnitMl,
          valueKey: 'calories',
          referenceKey: 'calories_per_100g',
        ),
        64,
      );
    });
  });
}
