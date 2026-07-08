import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/app_logger.dart';
import '../utils/nutrition_units.dart';
import 'database_service.dart';
import 'gemini_service.dart';

import 'package:flutter/foundation.dart';

class OfflineQueueService {
  final DatabaseService _databaseService;
  final Connectivity _connectivity = Connectivity();

  OfflineQueueService(this._databaseService);

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    AppLogger.info('OfflineQueueService', 'Connectivity status: $result');

    if (result.contains(ConnectivityResult.none)) {
      return false;
    }

    // On web, connectivity_plus uses navigator.onLine which is reliable.
    // We cannot do an HTTP HEAD check due to CORS restrictions.
    if (kIsWeb) return true;

    // On native, double-check with an actual HTTP request
    // in case the plugin reports a network but there's no internet.
    return await _checkConnection();
  }

  Future<bool> _checkConnection() async {
    try {
      // Standard captive portal check (Android default) or high availability site
      // Using http HEAD is cleaner than raw socket/DNS
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));

      final isConnected = response.statusCode == 200;
      AppLogger.info(
        'OfflineQueueService',
        'Internet access (HTTP): $isConnected',
      );
      return isConnected;
    } catch (e) {
      AppLogger.warning(
        'OfflineQueueService',
        'No internet access (HTTP failed): $e',
      );
      return false;
    }
  }

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<void> processQueue(
    String apiKey,
    String language, {
    bool useGrams = false,
    bool useAccurateMode = false,
  }) async {
    if (!await isOnline()) return;

    final pendingMeals = _databaseService.getPendingMeals();
    if (pendingMeals.isEmpty) return;

    final geminiService = GeminiService(apiKey: apiKey, language: language);

    for (final meal in pendingMeals) {
      try {
        final result = await geminiService.analyzeMeal(
          meal.photoPaths,
          useGrams: useGrams,
          useAccurateMode: useAccurateMode,
        );
        if (result != null) {
          final detectedPortion = normalizeDetectedPortion(result);
          final detectedUnit = detectedPortion.unit;
          final detectedQty = detectedPortion.quantity;
          final baseQuantityPerUnit = quantityPerUnitFor(detectedUnit);

          double detectedMultiplier = (detectedUnit == 'serving')
              ? detectedQty
              : (detectedQty / baseQuantityPerUnit);
          if (detectedMultiplier <= 0) detectedMultiplier = 1.0;

          final baseCalories = nutritionBaseValue(result, unit: detectedUnit, valueKey: 'calories', referenceKey: 'calories_per_100g');
          final baseProtein = nutritionBaseValue(result, unit: detectedUnit, valueKey: 'protein', referenceKey: 'protein_per_100g');
          final baseCarbs = nutritionBaseValue(result, unit: detectedUnit, valueKey: 'carbs', referenceKey: 'carbs_per_100g');
          final baseFats = nutritionBaseValue(result, unit: detectedUnit, valueKey: 'fats', referenceKey: 'fats_per_100g');

          final updatedMeal = meal.copyWith(
            mealName: result['meal_name'] ?? '',
            calories: baseCalories * detectedMultiplier,
            protein: baseProtein * detectedMultiplier,
            carbs: baseCarbs * detectedMultiplier,
            fats: baseFats * detectedMultiplier,
            caloriesPer100g: (result['calories_per_100g'] as num?)?.toDouble(),
            proteinPer100g: (result['protein_per_100g'] as num?)?.toDouble(),
            carbsPer100g: (result['carbs_per_100g'] as num?)?.toDouble(),
            fatsPer100g: (result['fats_per_100g'] as num?)?.toDouble(),
            portionMultiplier: detectedMultiplier,
            portionUnit: detectedUnit,
            quantityPerUnit: baseQuantityPerUnit,
            vitamins: result['vitamins'] != null
                ? Map<String, double>.from(
                    (result['vitamins'] as Map).map(
                      (k, v) => MapEntry(k.toString(), (v ?? 0).toDouble()),
                    ),
                  )
                : null,
            minerals: result['minerals'] != null
                ? Map<String, double>.from(
                    (result['minerals'] as Map).map(
                      (k, v) => MapEntry(k.toString(), (v ?? 0).toDouble()),
                    ),
                  )
                : null,
            isPending: false,
          );
          await _databaseService.saveMeal(updatedMeal);
        }
      } catch (e) {
        // Keep meal as pending if analysis fails
        debugPrint('Failed to process meal ${meal.id}: $e');
      }
    }
  }

  int getPendingCount() {
    return _databaseService.getPendingMeals().length;
  }
}
