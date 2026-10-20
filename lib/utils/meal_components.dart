import '../models/meal_component.dart';
import '../models/meal_model.dart';
import 'nutrition_units.dart';

/// A meal after its components changed, with the portion multiplier that
/// goes with it.
class ComponentChange {
  final MealModel meal;
  final double multiplier;

  const ComponentChange(this.meal, this.multiplier);
}

/// Recomputes [meal]'s base nutrition from [components]. [meal] holds base
/// values (multiplier 1) as the detail screen edits them.
///
/// For a weighed meal the base is per 100 g, so the components are scaled
/// back to 100 g and the change in weight moves into the multiplier.
ComponentChange applyComponents(
  MealModel meal,
  List<MealComponent> components,
  double multiplier,
) {
  var list = components;
  var newMultiplier = multiplier;
  final weighed = isPer100Unit(meal.portionUnit);
  final grams = list.fold<double>(0, (sum, c) => sum + c.grams);
  if (weighed && grams > 0) {
    final scale = meal.quantityPerUnit / grams;
    newMultiplier = multiplier / scale;
    list = [for (final c in list) c.withGrams(c.grams * scale)];
  }

  double sum(double Function(MealComponent) value) =>
      list.fold<double>(0, (total, c) => total + value(c));
  final calories = sum((c) => c.calories);
  final oldTotal = meal.calories * multiplier;
  final newTotal = calories * newMultiplier;
  final ratio = oldTotal > 0 ? newTotal / oldTotal : 1.0;
  double? scaled(double? value) =>
      value == null ? null : value * ratio * multiplier / newMultiplier;

  final protein = sum((c) => c.protein);
  final carbs = sum((c) => c.carbs);
  final fats = sum((c) => c.fats);
  return ComponentChange(
    meal.copyWith(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      caloriesPer100g: weighed ? calories : meal.caloriesPer100g,
      proteinPer100g: weighed ? protein : meal.proteinPer100g,
      carbsPer100g: weighed ? carbs : meal.carbsPer100g,
      fatsPer100g: weighed ? fats : meal.fatsPer100g,
      caloriesMin: scaled(meal.caloriesMin),
      caloriesMax: scaled(meal.caloriesMax),
      isCalorieOverride: false,
      components: list.isEmpty ? null : list,
    ),
    newMultiplier,
  );
}
