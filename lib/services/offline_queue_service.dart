import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/app_logger.dart';
import '../utils/nutrition_units.dart';
import 'database_service.dart';
import 'gemini_service.dart';

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

    if (kIsWeb) return true;

    return await _checkConnection();
  }

  Future<bool> _checkConnection() async {
    try {
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
    Future<void> Function(MealModel meal)? onMealProcessed,
  }) async {
    if (!await isOnline()) return;

    final geminiService = GeminiService(apiKey: apiKey, language: language);

    // Keep draining meals added while an earlier background analysis runs.
    while (true) {
      final pendingIds = _databaseService
          .getPendingMeals()
          .map((m) => m.id)
          .toList();
      if (pendingIds.isEmpty) return;
      final pendingIdSet = pendingIds.toSet();

      var processedAny = false;
      for (final mealId in pendingIds) {
        final processed = await _processSingleMeal(
          mealId,
          geminiService,
          useGrams: useGrams,
          useAccurateMode: useAccurateMode,
          onMealProcessed: onMealProcessed,
        );
        processedAny = processed || processedAny;
      }

      final hasNewPending = _databaseService.getPendingMeals().any(
        (meal) => !pendingIdSet.contains(meal.id),
      );
      if (!processedAny && !hasNewPending) return;
    }
  }

  Future<bool> _processSingleMeal(
    String mealId,
    GeminiService geminiService, {
    required bool useGrams,
    required bool useAccurateMode,
    Future<void> Function(MealModel meal)? onMealProcessed,
  }) async {
    try {
      final meal = _databaseService.getMealById(mealId);
      if (meal == null || !meal.isPending) return false;

      Map<String, dynamic>? result;
      await for (final event in geminiService.analyzeMealStream(
        meal.photoPaths,
        useGrams: useGrams,
        useAccurateMode: useAccurateMode,
        mealContext: meal.mealContext,
      )) {
        if (event is AnalysisResult) {
          result = event.data;
        }
      }

      if (!_databaseService.hasMeal(mealId)) {
        AppLogger.info(
          'OfflineQueueService',
          'Meal $mealId deleted during analysis, skipping save',
        );
        return false;
      }

      if (result == null) return false;

      final detectedPortion = normalizeDetectedPortion(result);
      final detectedUnit = detectedPortion.unit;
      final detectedQty = detectedPortion.quantity;
      final baseQuantityPerUnit = quantityPerUnitFor(detectedUnit);

      double detectedMultiplier = detectedUnit == 'serving'
          ? detectedQty
          : detectedQty / baseQuantityPerUnit;
      if (detectedMultiplier <= 0) detectedMultiplier = 1.0;

      final baseCalories = nutritionBaseValue(
        result,
        unit: detectedUnit,
        valueKey: 'calories',
        referenceKey: 'calories_per_100g',
      );
      final baseProtein = nutritionBaseValue(
        result,
        unit: detectedUnit,
        valueKey: 'protein',
        referenceKey: 'protein_per_100g',
      );
      final baseCarbs = nutritionBaseValue(
        result,
        unit: detectedUnit,
        valueKey: 'carbs',
        referenceKey: 'carbs_per_100g',
      );
      final baseFats = nutritionBaseValue(
        result,
        unit: detectedUnit,
        valueKey: 'fats',
        referenceKey: 'fats_per_100g',
      );

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

      if (onMealProcessed != null) {
        await onMealProcessed(updatedMeal);
      }
      return true;
    } catch (e) {
      debugPrint('Failed to process meal $mealId: $e');
      return false;
    }
  }

  int getPendingCount() {
    return _databaseService.getPendingMeals().length;
  }
}
