/// Why a meal, a weight or an import was refused. The screens show it in the
/// app language (see `validationMessage`); [message] is for logs only.
enum ValidationIssue {
  invalidMeal,
  negativeValue,
  unrealisticNutrition,
  unrealisticPortion,
  invalidPer100,
  macrosPer100TooHigh,
  weightRange,
  weightInFuture,
  duplicateMealIds,
  photoLimit,
  mealLimit,
}

/// The value that was negative, for [ValidationIssue.negativeValue].
enum ValidationField { calories, protein, carbs, fats }

class ValidationException extends FormatException {
  final ValidationIssue issue;
  final ValidationField? field;

  ValidationException(this.issue, {this.field})
    : super(field == null ? issue.name : '${issue.name}:${field.name}');
}
