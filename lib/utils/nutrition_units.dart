class NormalizedPortion {
  final String unit;
  final double quantity;

  const NormalizedPortion({required this.unit, required this.quantity});
}

const String portionUnitServing = 'serving';
const String portionUnitGram = 'gram';
const String portionUnitMl = 'ml';

String normalizePortionUnit(String? rawUnit) {
  final unit = (rawUnit ?? '').trim().toLowerCase();
  switch (unit) {
    case 'g':
    case 'gr':
    case 'gram':
    case 'grams':
    case 'gramm':
    case 'gramme':
      return portionUnitGram;
    case 'ml':
    case 'milliliter':
    case 'milliliters':
    case 'millilitre':
    case 'millilitres':
      return portionUnitMl;
    case 'l':
    case 'liter':
    case 'liters':
    case 'litre':
    case 'litres':
      return portionUnitMl;
    case 'portion':
    case 'portions':
    case 'serving':
    case 'servings':
    case 'serve':
      return portionUnitServing;
    default:
      return portionUnitServing;
  }
}

bool isPer100Unit(String unit) =>
    unit == portionUnitGram || unit == portionUnitMl;

double quantityPerUnitFor(String unit) =>
    unit == portionUnitServing ? 1.0 : 100.0;

String displayUnitFor(String unit) {
  if (unit == portionUnitGram) return 'g';
  return unit;
}

NormalizedPortion normalizeDetectedPortion(Map<String, dynamic> result) {
  final rawUnit = result['detected_unit']?.toString();
  final normalizedUnit = normalizePortionUnit(rawUnit);
  double quantity = (result['detected_quantity'] as num?)?.toDouble() ?? 1.0;

  final rawUnitLower = (rawUnit ?? '').trim().toLowerCase();
  final isLiter =
      rawUnitLower == 'l' ||
      rawUnitLower == 'liter' ||
      rawUnitLower == 'liters' ||
      rawUnitLower == 'litre' ||
      rawUnitLower == 'litres';
  if (normalizedUnit == portionUnitMl &&
      isLiter &&
      quantity > 0 &&
      quantity < 20) {
    quantity *= 1000.0;
  }

  if (quantity <= 0) {
    quantity = normalizedUnit == portionUnitServing ? 1.0 : 100.0;
  }

  return NormalizedPortion(unit: normalizedUnit, quantity: quantity);
}

double nutritionBaseValue(
  Map<String, dynamic> result, {
  required String unit,
  required String valueKey,
  required String referenceKey,
}) {
  final referenceValue = (result[referenceKey] as num?)?.toDouble();
  final value = (result[valueKey] as num?)?.toDouble();

  if (isPer100Unit(unit) && referenceValue != null) {
    return referenceValue;
  }

  return value ?? referenceValue ?? 0.0;
}

double per100ReferenceFor({
  required String unit,
  required double baseValue,
  double? explicitReference,
}) {
  if (isPer100Unit(unit)) return explicitReference ?? baseValue;
  return explicitReference ?? baseValue;
}

double scaledValueFromBase({
  required double baseValue,
  required double portionMultiplier,
}) {
  return baseValue * portionMultiplier;
}

double baseValueFromScaled({
  required double scaledValue,
  required double portionMultiplier,
}) {
  if (portionMultiplier <= 0) return scaledValue;
  return scaledValue / portionMultiplier;
}
