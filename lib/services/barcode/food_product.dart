import '../../models/meal_model.dart';
import '../../utils/nutrition_units.dart';

/// A packaged food as Open Food Facts describes it, reduced to what a meal
/// needs. Nutrition is per 100 g, or per 100 ml for drinks.
class FoodProduct {
  final String code;
  final String name;
  final String? brand;

  /// 'gram' or 'ml'.
  final String unit;
  final double? caloriesPer100;
  final double? proteinPer100;
  final double? carbsPer100;
  final double? fatsPer100;

  /// One serving in [unit], when the package states it.
  final double? servingQuantity;

  /// The whole package in [unit].
  final double? packageQuantity;

  const FoodProduct({
    required this.code,
    required this.name,
    this.brand,
    this.unit = portionUnitGram,
    this.caloriesPer100,
    this.proteinPer100,
    this.carbsPer100,
    this.fatsPer100,
    this.servingQuantity,
    this.packageQuantity,
  });

  /// Calories and all three macros are known and physically possible.
  /// Zero is a real value (water); a missing value is not.
  bool get hasNutrition {
    final kcal = caloriesPer100;
    final protein = proteinPer100;
    final carbs = carbsPer100;
    final fats = fatsPer100;
    if (kcal == null || protein == null || carbs == null || fats == null) {
      return false;
    }
    if (kcal < 0 || protein < 0 || carbs < 0 || fats < 0) return false;
    // Pure fat has about 900 kcal per 100 g.
    if (kcal > 950) return false;
    if (protein + carbs + fats > 105) return false;
    return true;
  }

  /// "Brand Name" unless the name already says the brand.
  String get displayName {
    final brand = this.brand;
    if (brand == null || brand.isEmpty) return name;
    if (name.toLowerCase().contains(brand.toLowerCase())) return name;
    return '$brand $name';
  }

  /// The amount a meal starts with: one serving, else a small package as a
  /// whole (a can, a bar, a cup), else 100.
  double get defaultQuantity {
    final serving = servingQuantity;
    if (serving != null && serving > 0 && serving <= 2000) return serving;
    final package = packageQuantity;
    if (package != null && package > 0 && package <= 500) return package;
    return 100;
  }

  /// A new, unsaved meal of [defaultQuantity]. Nutrition stays per 100 with
  /// the amount as multiplier, so the portion control edits it like any
  /// gram or ml meal.
  MealModel toMeal({
    required String id,
    required DateTime timestamp,
    String? note,
    List<String> photoPaths = const [],
  }) => MealModel(
    id: id,
    timestamp: timestamp,
    photoPaths: photoPaths,
    mealName: displayName,
    calories: caloriesPer100 ?? 0,
    protein: proteinPer100 ?? 0,
    carbs: carbsPer100 ?? 0,
    fats: fatsPer100 ?? 0,
    caloriesPer100g: caloriesPer100,
    proteinPer100g: proteinPer100,
    carbsPer100g: carbsPer100,
    fatsPer100g: fatsPer100,
    portionUnit: unit,
    quantityPerUnit: quantityPerUnitFor(unit),
    portionMultiplier: defaultQuantity / quantityPerUnitFor(unit),
    mealContext: '$displayName$_eanTag$code)',
    analysisNote: note,
  );

  static const _eanTag = ' (EAN ';
  static final _barcodeContext = RegExp(r'^(.+) \(EAN (\d{8,14})\)$');

  /// The product name of a meal made by [toMeal], from its context; null
  /// for any other meal.
  static String? productNameOfMeal(String? mealContext) =>
      _barcodeContext.firstMatch(mealContext ?? '')?.group(1);

  /// Parses an Open Food Facts v2 `product` object; null when it has no name
  /// at all. [language] picks the localized name when there is one.
  static FoodProduct? fromOpenFoodFacts(
    String code,
    Map<String, dynamic> product, {
    String language = 'en',
  }) {
    String? text(String key) {
      final value = product[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final name =
        text('product_name_$language') ??
        text('product_name') ??
        text('product_name_en') ??
        text('generic_name_$language') ??
        text('generic_name');
    if (name == null) return null;
    final brand = text('brands')?.split(',').first.trim();

    final nutriments = product['nutriments'] is Map
        ? Map<String, dynamic>.from(product['nutriments'] as Map)
        : const <String, dynamic>{};
    double? nutrient(String key) => _number(nutriments['${key}_100g']);

    var kcal = nutrient('energy-kcal');
    if (kcal == null) {
      // Energy in kJ only: 'energy' is kJ in Open Food Facts.
      final kj = nutrient('energy-kj') ?? nutrient('energy');
      if (kj != null) kcal = kj / 4.184;
    }
    final protein = nutrient('proteins');
    final carbs = nutrient('carbohydrates');
    final fats = nutrient('fat');
    if (kcal == null && protein != null && carbs != null && fats != null) {
      kcal = protein * 4 + carbs * 4 + fats * 9;
    }

    final unit = _isLiquid(product) ? portionUnitMl : portionUnitGram;
    return FoodProduct(
      code: code,
      name: name,
      brand: brand,
      unit: unit,
      caloriesPer100: kcal == null ? null : _round(kcal, 0),
      proteinPer100: protein == null ? null : _round(protein, 1),
      carbsPer100: carbs == null ? null : _round(carbs, 1),
      fatsPer100: fats == null ? null : _round(fats, 1),
      servingQuantity: _number(product['serving_quantity']),
      packageQuantity: _number(product['product_quantity']),
    );
  }

  static final _volume = RegExp(r'\d\s*(ml|cl|dl|l)\b');
  static final _weight = RegExp(r'\d\s*(mg|g|kg)\b');

  /// Whether the product is measured in ml. The package text ("330 ml",
  /// "0,33 l") decides first: Open Food Facts gives older drinks a unit of
  /// 'g' next to it, since it once stored every quantity in grams.
  static bool _isLiquid(Map<String, dynamic> product) {
    for (final key in ['quantity', 'serving_size']) {
      final text = product[key]?.toString().toLowerCase() ?? '';
      final volume = _volume.firstMatch(text);
      final weight = _weight.firstMatch(text);
      if (volume != null && (weight == null || volume.start < weight.start)) {
        return true;
      }
      if (weight != null) return false;
    }
    for (final key in ['product_quantity_unit', 'serving_quantity_unit']) {
      final unit = product[key]?.toString().trim().toLowerCase();
      if (unit == 'ml' || unit == 'cl' || unit == 'l') return true;
    }
    return false;
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static double _round(double value, int decimals) {
    final factor = decimals == 0 ? 1 : 10;
    return (value * factor).round() / factor;
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'brand': brand,
    'unit': unit,
    'kcal': caloriesPer100,
    'protein': proteinPer100,
    'carbs': carbsPer100,
    'fats': fatsPer100,
    'serving': servingQuantity,
    'package': packageQuantity,
  };

  static FoodProduct fromJson(Map<String, dynamic> json) => FoodProduct(
    code: json['code'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String?,
    unit: json['unit'] as String? ?? portionUnitGram,
    caloriesPer100: _number(json['kcal']),
    proteinPer100: _number(json['protein']),
    carbsPer100: _number(json['carbs']),
    fatsPer100: _number(json['fats']),
    servingQuantity: _number(json['serving']),
    packageQuantity: _number(json['package']),
  );
}
