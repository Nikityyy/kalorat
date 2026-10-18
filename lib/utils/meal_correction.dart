import '../models/meal_model.dart';
import 'nutrition_units.dart';

enum CalorieChoiceKind { lower, original, higher }

/// A calorie value one tap can set, for the portion as shown.
class CalorieChoice {
  final CalorieChoiceKind kind;
  final int kcal;

  const CalorieChoice(this.kind, this.kcal);
}

/// What a tap can set for [meal]: the lower and the upper end of the AI's
/// range and [originalCalories], the value before any correction. Ends that
/// round to the same number appear once (the original wins), sorted by
/// calories. Without a range there is nothing to choose from and the list is
/// empty.
List<CalorieChoice> calorieChoices(
  MealModel meal,
  double portionMultiplier, {
  required double originalCalories,
}) {
  final min = meal.caloriesMin;
  final max = meal.caloriesMax;
  if (min == null || max == null || max - min < 1) return const [];
  final original = (originalCalories * portionMultiplier).round();
  final lower = (min * portionMultiplier).round();
  final higher = (max * portionMultiplier).round();
  final choices = [
    CalorieChoice(CalorieChoiceKind.original, original),
    if (lower != original) CalorieChoice(CalorieChoiceKind.lower, lower),
    if (higher != original && higher != lower)
      CalorieChoice(CalorieChoiceKind.higher, higher),
  ]..sort((a, b) => a.kcal.compareTo(b.kcal));
  return choices;
}

/// [meal] with its calories set to [calories] (for the portion as shown).
/// Protein, carbs and fat follow in proportion, so the macros still add up to
/// the calories. The AI's range stays, so the choice can be changed again.
MealModel mealWithCalories(
  MealModel meal, {
  required double portionMultiplier,
  required double calories,
}) {
  final shown = meal.calories * portionMultiplier;
  final ratio = shown > 0 ? calories / shown : 1.0;
  final per100 = isPer100Unit(meal.portionUnit);
  final base = baseValueFromScaled(
    scaledValue: calories,
    portionMultiplier: portionMultiplier,
  );
  final protein = meal.protein * ratio;
  final carbs = meal.carbs * ratio;
  final fats = meal.fats * ratio;
  return meal.copyWith(
    calories: base,
    protein: protein,
    carbs: carbs,
    fats: fats,
    caloriesPer100g: per100 ? base : meal.caloriesPer100g,
    proteinPer100g: per100 && meal.proteinPer100g != null
        ? protein
        : meal.proteinPer100g,
    carbsPer100g: per100 && meal.carbsPer100g != null
        ? carbs
        : meal.carbsPer100g,
    fatsPer100g: per100 && meal.fatsPer100g != null ? fats : meal.fatsPer100g,
    isCalorieOverride: true,
  );
}
