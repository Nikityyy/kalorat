/// One part of an analysed meal: what it is, how much, and its nutrition per
/// 100 g. [grams] is the amount for one base portion of the meal (portion
/// multiplier 1), so the component scales with the portion like the meal.
class MealComponent {
  final String name;
  final double grams;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;

  /// The USDA reference food the values come from; null when the model gave
  /// its own values.
  final String? ref;

  /// What is uncertain about it, in the model's words; empty when nothing.
  final String assumption;

  const MealComponent({
    required this.name,
    required this.grams,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    this.ref,
    this.assumption = '',
  });

  double get calories => kcalPer100g * grams / 100;
  double get protein => proteinPer100g * grams / 100;
  double get carbs => carbsPer100g * grams / 100;
  double get fats => fatsPer100g * grams / 100;

  MealComponent withGrams(double value) => MealComponent(
    name: name,
    grams: value,
    kcalPer100g: kcalPer100g,
    proteinPer100g: proteinPer100g,
    carbsPer100g: carbsPer100g,
    fatsPer100g: fatsPer100g,
    ref: ref,
    assumption: assumption,
  );

  /// The same amount with [factor] times the nutrition per 100 g.
  MealComponent withDensity(double factor) => MealComponent(
    name: name,
    grams: grams,
    kcalPer100g: kcalPer100g * factor,
    proteinPer100g: proteinPer100g * factor,
    carbsPer100g: carbsPer100g * factor,
    fatsPer100g: fatsPer100g * factor,
    ref: ref,
    assumption: assumption,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'grams': grams,
    'kcalPer100g': kcalPer100g,
    'proteinPer100g': proteinPer100g,
    'carbsPer100g': carbsPer100g,
    'fatsPer100g': fatsPer100g,
    'ref': ref,
    'assumption': assumption,
  };

  static MealComponent? fromMap(Object? raw) {
    if (raw is! Map) return null;
    double? number(String key) {
      final value = raw[key];
      return value is num && value.isFinite && value >= 0
          ? value.toDouble()
          : null;
    }

    final name = raw['name']?.toString() ?? '';
    final grams = number('grams');
    final kcal = number('kcalPer100g');
    final protein = number('proteinPer100g');
    final carbs = number('carbsPer100g');
    final fats = number('fatsPer100g');
    if (name.isEmpty ||
        grams == null ||
        kcal == null ||
        protein == null ||
        carbs == null ||
        fats == null) {
      return null;
    }
    return MealComponent(
      name: name,
      grams: grams,
      kcalPer100g: kcal,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatsPer100g: fats,
      ref: raw['ref']?.toString(),
      assumption: raw['assumption']?.toString() ?? '',
    );
  }

  static List<MealComponent>? listFromMaps(Object? raw) {
    if (raw is! List) return null;
    final list = [for (final item in raw) ?fromMap(item)];
    return list.isEmpty ? null : list;
  }

  /// The components of an analysis result, scaled to one base portion.
  /// Null when the result has no items in grams (older answers, barcode
  /// products, a meal described without amounts).
  static List<MealComponent>? fromAnalysisItems(
    Object? items, {
    required double multiplier,
  }) {
    if (items is! List || multiplier <= 0) return null;
    final list = <MealComponent>[];
    for (final item in items) {
      if (item is! Map || item['grams'] is! num) return null;
      final component = fromMap({
        'name': item['name'],
        'grams': (item['grams'] as num) / multiplier,
        'kcalPer100g': item['kcal_per_100g'],
        'proteinPer100g': item['protein_per_100g'],
        'carbsPer100g': item['carbs_per_100g'],
        'fatsPer100g': item['fats_per_100g'],
        'ref': item['ref'],
        'assumption': item['assumption'],
      });
      if (component == null) return null;
      list.add(component);
    }
    return list.isEmpty ? null : list;
  }
}
