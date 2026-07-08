import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/app_logger.dart';
import '../utils/nutrition_units.dart';
import '../models/models.dart';
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

  /// Max number of concurrent API calls for background analysis.
  static const int _maxConcurrency = 3;

  /// Processes all pending meals in the queue.
  ///
  /// [onMealProcessed] is called after each meal is successfully analyzed
  /// and saved, allowing the caller (AppProvider) to update UI, stats, and
  /// trigger sync incrementally rather than waiting for the whole batch.
  Future<void> processQueue(
    String apiKey,
    String language, {
    bool useGrams = false,
    bool useAccurateMode = false,
    Future<void> Function(MealModel meal)? onMealProcessed,
  }) async {
    if (!await isOnline()) return;

    // Collect IDs upfront — we'll re-fetch each meal fresh from DB before
    // processing to avoid stale references and respect deletions.
    final pendingIds =
        _databaseService.getPendingMeals().map((m) => m.id).toList();
    if (pendingIds.isEmpty) return;

    final geminiService = GeminiService(apiKey: apiKey, language: language);

    // Process in chunks of _maxConcurrency for parallel speedup.
    for (int i = 0; i < pendingIds.length; i += _maxConcurrency) {
      final chunk = pendingIds.sublist(
        i,
        (i + _maxConcurrency).clamp(0, pendingIds.length),
      );

      await Future.wait(
        chunk.map((mealId) => _processSingleMeal(
              mealId,
              geminiService,
              useGrams: useGrams,
              useAccurateMode: useAccurateMode,
              onMealProcessed: onMealProcessed,
            )),
      );
    }
  }

  /// Processes a single pending meal by ID.
  ///
  /// Re-fetches the meal from DB to get a fresh reference and to check
  /// whether it was deleted while queued.
  Future<void> _processSingleMeal(
    String mealId,
    GeminiService geminiService, {
    required bool useGrams,
    required bool useAccurateMode,
    Future<void> Function(MealModel meal)? onMealProcessed,
  }) async {
    try {
      // Fresh fetch — if the meal was deleted while queued, skip it.
      final meal = _databaseService.getMealById(mealId);
      if (meal == null || !meal.isPending) return;

      final result = await geminiService.analyzeMeal(
        meal.photoPaths,
        useGrams: useGrams,
        useAccurateMode: useAccurateMode,
      );

      // Re-check existence AFTER the (slow) API call — the user may have
      // deleted the meal while we were waiting for the response.
      if (!_databaseService.hasMeal(mealId)) {
        AppLogger.info(
          'OfflineQueueService',
          'Meal $mealId deleted during analysis, skipping save',
        );
        return;
      }

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

        // Notify caller so UI/stats/sync update incrementally.
        if (onMealProcessed != null) {
          await onMealProcessed(updatedMeal);
        }
      }
    } catch (e) {
      // Keep meal as pending if analysis fails
      debugPrint('Failed to process meal $mealId: $e');
    }
  }

  int getPendingCount() {
    return _databaseService.getPendingMeals().length;
  }
}
