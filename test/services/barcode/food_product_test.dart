import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/services/barcode/food_product.dart';

Map<String, dynamic> sprite() => {
  'code': '5000112674453',
  'product_name': 'Sprite Lemon-Lime',
  'product_name_de': 'Sprite Zitrone-Limette',
  'brands': 'Sprite,Coca-Cola',
  'quantity': '330 ml',
  'product_quantity': '330',
  'product_quantity_unit': 'ml',
  'serving_quantity': '330',
  'serving_quantity_unit': 'ml',
  'nutriments': {
    'energy-kcal_100g': 33,
    'energy-kj_100g': 139,
    'energy_100g': 139,
    'fat_100g': 0,
    'carbohydrates_100g': 7.9,
    'sugars_100g': 7.9,
    'proteins_100g': 0,
    'salt_100g': 0.03,
  },
};

void main() {
  test('a drink is read per 100 ml with one can as the serving', () {
    final product = FoodProduct.fromOpenFoodFacts('5000112674453', sprite())!;

    expect(product.name, 'Sprite Lemon-Lime');
    expect(product.brand, 'Sprite');
    expect(product.displayName, 'Sprite Lemon-Lime');
    expect(product.unit, 'ml');
    expect(product.caloriesPer100, 33);
    expect(product.carbsPer100, 7.9);
    expect(product.proteinPer100, 0);
    expect(product.fatsPer100, 0);
    expect(product.hasNutrition, isTrue);
    expect(product.defaultQuantity, 330);
  });

  test('the localized name wins', () {
    final product = FoodProduct.fromOpenFoodFacts(
      '5000112674453',
      sprite(),
      language: 'de',
    )!;
    expect(product.name, 'Sprite Zitrone-Limette');
    expect(product.displayName, 'Sprite Zitrone-Limette');
  });

  test('the meal holds per-100 values and the can as multiplier', () {
    final product = FoodProduct.fromOpenFoodFacts('5000112674453', sprite())!;
    final meal = product.toMeal(
      id: '1',
      timestamp: DateTime(2026, 10, 18, 12),
      note: 'Open Food Facts',
    );

    expect(meal.mealName, 'Sprite Lemon-Lime');
    expect(meal.calories, 33);
    expect(meal.carbs, 7.9);
    expect(meal.portionUnit, 'ml');
    expect(meal.quantityPerUnit, 100);
    expect(meal.portionMultiplier, closeTo(3.3, 1e-9));
    expect(meal.caloriesPer100g, 33);
    expect(meal.photoPaths, isEmpty);
    expect(meal.analysisConfidence, isNull);
    expect(meal.analysisNote, 'Open Food Facts');
    expect(meal.mealContext, contains('5000112674453'));
  });

  test('energy in kJ only is converted, and missing kcal is computed', () {
    final kj = FoodProduct.fromOpenFoodFacts('1', {
      'product_name': 'Bread',
      'nutriments': {
        'energy_100g': 1046,
        'proteins_100g': 9,
        'carbohydrates_100g': 45,
        'fat_100g': 3,
      },
    })!;
    expect(kj.caloriesPer100, 250);
    expect(kj.unit, 'gram');

    final macros = FoodProduct.fromOpenFoodFacts('1', {
      'product_name': 'Bread',
      'nutriments': {
        'proteins_100g': 10,
        'carbohydrates_100g': 50,
        'fat_100g': 2,
      },
    })!;
    expect(macros.caloriesPer100, 258);
  });

  test('missing or impossible nutrition is not usable', () {
    final noMacros = FoodProduct.fromOpenFoodFacts('1', {
      'product_name': 'Chips',
      'nutriments': {'energy-kcal_100g': 540},
    })!;
    expect(noMacros.hasNutrition, isFalse);

    final impossible = FoodProduct.fromOpenFoodFacts('1', {
      'product_name': 'Typo',
      'nutriments': {
        'energy-kcal_100g': 2300,
        'proteins_100g': 5,
        'carbohydrates_100g': 60,
        'fat_100g': 30,
      },
    })!;
    expect(impossible.hasNutrition, isFalse);

    final water = FoodProduct.fromOpenFoodFacts('1', {
      'product_name': 'Water',
      'quantity': '1,5 l',
      'nutriments': {
        'energy-kcal_100g': 0,
        'proteins_100g': 0,
        'carbohydrates_100g': 0,
        'fat_100g': 0,
      },
    })!;
    expect(water.hasNutrition, isTrue);
    expect(water.unit, 'ml');
  });

  test('the package text wins over a unit of g on a drink', () {
    FoodProduct product(Map<String, dynamic> fields) =>
        FoodProduct.fromOpenFoodFacts('1', {'product_name': 'X', ...fields})!;
    // Older Open Food Facts entries: grams next to a volume.
    expect(
      product({
        'quantity': '330 ml',
        'product_quantity_unit': 'g',
        'serving_quantity_unit': 'g',
      }).unit,
      'ml',
    );
    expect(product({'serving_size': '250ml (250 g)'}).unit, 'ml');
    expect(product({'quantity': '33 cl'}).unit, 'ml');
    expect(product({'quantity': '500 g', 'serving_size': '30 g'}).unit, 'gram');
    expect(product({'quantity': '1 kg (1 l)'}).unit, 'gram');
    expect(product({'product_quantity_unit': 'ml'}).unit, 'ml');
    expect(product({}).unit, 'gram');
  });

  test('a product without a name is no product', () {
    expect(FoodProduct.fromOpenFoodFacts('1', {'brands': 'X'}), isNull);
  });

  test('the starting amount: serving, small package, else 100', () {
    FoodProduct product({double? serving, double? package}) => FoodProduct(
      code: '1',
      name: 'X',
      servingQuantity: serving,
      packageQuantity: package,
    );
    expect(product(serving: 30, package: 500).defaultQuantity, 30);
    expect(product(package: 125).defaultQuantity, 125);
    expect(product(package: 1000).defaultQuantity, 100);
    expect(product().defaultQuantity, 100);
  });

  test('the brand is added when the name lacks it', () {
    const product = FoodProduct(
      code: '1',
      name: 'Joghurt',
      brand: 'Berglandmilch',
    );
    expect(product.displayName, 'Berglandmilch Joghurt');
  });

  test('json round trip keeps every value', () {
    final product = FoodProduct.fromOpenFoodFacts('5000112674453', sprite())!;
    final copy = FoodProduct.fromJson(product.toJson());
    expect(copy.toJson(), product.toJson());
  });

  test('a meal from a barcode is recognised by its context', () {
    final product = FoodProduct.fromOpenFoodFacts('5000112674453', sprite())!;
    final meal = product.toMeal(id: '1', timestamp: DateTime(2026, 10, 18));

    expect(
      FoodProduct.productNameOfMeal(meal.mealContext),
      'Sprite Lemon-Lime',
    );
    expect(FoodProduct.productNameOfMeal('Pasta with pesto'), isNull);
    expect(FoodProduct.productNameOfMeal(null), isNull);
  });
}
