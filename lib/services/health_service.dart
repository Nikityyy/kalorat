import 'dart:io';
import 'package:health/health.dart';
import '../models/models.dart';

/// Unified health service for Apple Health and Google Health Connect
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  bool _isConfigured = false;

  // Health data types we need for nutrition tracking
  static const List<HealthDataType> _nutritionTypes = [
    HealthDataType.DIETARY_ENERGY_CONSUMED,
    HealthDataType.DIETARY_PROTEIN_CONSUMED,
    HealthDataType.DIETARY_CARBS_CONSUMED,
    HealthDataType.DIETARY_FATS_CONSUMED,
  ];

  static const List<HealthDataType> _weightTypes = [HealthDataType.WEIGHT];

  List<HealthDataType> get _allTypes => [..._nutritionTypes, ..._weightTypes];

  // For permissions on Android (Health Connect), we must request the grouped NUTRITION type
  // instead of individual dietary types.
  List<HealthDataType> get _permissionTypes {
    if (Platform.isAndroid) {
      // Note: DIETARY_ENERGY_CONSUMED writes to Nutrition record, so NUTRITION permission covers it.
      return [HealthDataType.NUTRITION, HealthDataType.WEIGHT];
    }
    return _allTypes;
  }

  /// Configure the health plugin. Must be called before any other method.
  Future<void> configure() async {
    if (_isConfigured) return;
    await _health.configure();
    _isConfigured = true;
  }

  /// Check if Health Connect is available on Android
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return true; // iOS always has HealthKit

    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Check if we have the required health permissions
  Future<bool> hasPermissions() async {
    await configure();

    try {
      print('DEBUG: Requesting health permissions...');
      final result = await _health.hasPermissions(
        _permissionTypes,
        permissions: _permissionTypes
            .map((_) => HealthDataAccess.READ_WRITE)
            .toList(),
      );
      print('DEBUG: hasPermissions result: $result');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request health permissions from the user
  Future<bool> requestPermissions() async {
    await configure();

    try {
      final granted = await _health.requestAuthorization(
        _permissionTypes,
        permissions: _permissionTypes
            .map((_) => HealthDataAccess.READ_WRITE)
            .toList(),
      );
      return granted;
    } catch (e) {
      return false;
    }
  }

  /// Revoke health permissions
  Future<void> revokePermissions() async {
    try {
      await _health.revokePermissions();
    } catch (e) {
      // Ignore errors when revoking
    }
  }

  /// Write meal nutrition data to health platform
  Future<bool> writeMealData(MealModel meal) async {
    await configure();

    try {
      print('DEBUG: writeMealData (v2) started for meal ${meal.mealName}');

      final timestamp = meal.timestamp;
      final endTime = timestamp.add(const Duration(minutes: 1));

      // Use the unified writeMeal method which handles platform differences
      // (Nutrition record on Android, individual samples on iOS)
      final success = await _health.writeMeal(
        name: meal.mealName,
        startTime: timestamp,
        endTime: endTime,
        caloriesConsumed: meal.calories > 0 ? meal.calories : 0,
        protein: meal.protein > 0 ? meal.protein : 0,
        carbohydrates: meal.carbs > 0 ? meal.carbs : 0,
        fatTotal: meal.fats > 0 ? meal.fats : 0,
        mealType: MealType.UNKNOWN,
      );

      print('DEBUG: writeMealData finished. Success: $success');
      return success;
    } catch (e) {
      print('DEBUG: writeMealData ERROR: $e');
      return false;
    }
  }

  /// Write weight data to health platform
  Future<bool> writeWeight(double weightKg, DateTime date) async {
    await configure();

    try {
      return await _health.writeHealthData(
        value: weightKg,
        type: HealthDataType.WEIGHT,
        startTime: date,
        endTime: date,
        unit: HealthDataUnit.KILOGRAM,
      );
    } catch (e) {
      return false;
    }
  }

  /// Read weight history from health platform
  Future<List<HealthDataPoint>> readWeightHistory(
    DateTime start,
    DateTime end,
  ) async {
    await configure();

    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: _weightTypes,
      );
      return _health.removeDuplicates(data);
    } catch (e) {
      return [];
    }
  }

  /// Read today's nutrition totals from health platform
  Future<Map<String, double>> readTodayNutrition() async {
    await configure();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: _nutritionTypes,
      );

      final result = <String, double>{
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fats': 0,
      };

      for (final point in data) {
        final value = (point.value as NumericHealthValue).numericValue
            .toDouble();
        switch (point.type) {
          case HealthDataType.DIETARY_ENERGY_CONSUMED:
            result['calories'] = result['calories']! + value;
            break;
          case HealthDataType.DIETARY_PROTEIN_CONSUMED:
            result['protein'] = result['protein']! + value;
            break;
          case HealthDataType.DIETARY_CARBS_CONSUMED:
            result['carbs'] = result['carbs']! + value;
            break;
          case HealthDataType.DIETARY_FATS_CONSUMED:
            result['fats'] = result['fats']! + value;
            break;
          default:
            break;
        }
      }

      return result;
    } catch (e) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fats': 0};
    }
  }
}
