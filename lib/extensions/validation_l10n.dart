import '../l10n/app_localizations.dart';
import '../models/validation_exception.dart';

/// The text for [error] in the app language. Other errors keep their own
/// message.
String errorMessage(AppLocalizations l10n, Object error) {
  if (error is! ValidationException) {
    return error.toString().replaceFirst('Exception: ', '');
  }
  return switch (error.issue) {
    ValidationIssue.invalidMeal => l10n.validationInvalidMeal,
    ValidationIssue.negativeValue => l10n.validationNegative(
      switch (error.field) {
        ValidationField.calories => l10n.calories,
        ValidationField.protein => l10n.protein,
        ValidationField.carbs => l10n.carbs,
        ValidationField.fats => l10n.fats,
        null => '',
      },
    ),
    ValidationIssue.unrealisticNutrition => l10n.validationNutrition,
    ValidationIssue.unrealisticPortion => l10n.validationPortion,
    ValidationIssue.invalidPer100 => l10n.validationPer100,
    ValidationIssue.macrosPer100TooHigh => l10n.validationMacrosPer100,
    ValidationIssue.weightRange => l10n.validationWeightRange,
    ValidationIssue.weightInFuture => l10n.validationWeightFuture,
    ValidationIssue.duplicateMealIds => l10n.validationDuplicateMeals,
    ValidationIssue.photoLimit => l10n.rateLimitPhotos,
    ValidationIssue.mealLimit => l10n.rateLimitMeals,
  };
}
