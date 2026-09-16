import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/app_logger.dart';
import '../utils/nutrition_units.dart';
import 'database_service.dart';
import 'gemini_service.dart';

/// Durable, restartable meal-analysis queue.
///
/// Claims are persisted before a request starts, failures are recorded, stale
/// claims are reclaimed on the next run, and only a small number of Gemini
/// requests run concurrently to avoid quota spikes and browser saturation.
class OfflineQueueService {
  static const int defaultMaxConcurrency = 2;
  static const int maxAttempts = 3;
  static final Set<String> _claimedMealIds = <String>{};

  final DatabaseService _databaseService;
  final Connectivity _connectivity = Connectivity();
  final Future<bool> Function()? _onlineCheck;
  final GeminiService Function(String apiKey, String language) _geminiFactory;
  final int maxConcurrency;

  OfflineQueueService(
    this._databaseService, {
    Future<bool> Function()? onlineCheck,
    GeminiService Function(String apiKey, String language)? geminiFactory,
    this.maxConcurrency = defaultMaxConcurrency,
  }) : _onlineCheck = onlineCheck,
       _geminiFactory =
           geminiFactory ??
           ((apiKey, language) =>
               GeminiService(apiKey: apiKey, language: language));

  Future<bool> isOnline() async {
    if (_onlineCheck != null) return _onlineCheck();
    final result = await _connectivity.checkConnectivity();
    AppLogger.info('OfflineQueueService', 'Connectivity status: $result');

    if (result.contains(ConnectivityResult.none)) return false;
    if (kIsWeb) return true;
    return _checkConnection();
  }

  Future<bool> _checkConnection() async {
    try {
      final response = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.warning('OfflineQueueService', 'Internet check failed: $e');
      return false;
    }
  }

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<void> processQueue(
    String apiKey,
    String language, {
    bool useGrams = false,
    bool useAccurateMode = true,
    Future<void> Function(MealModel meal)? onMealProcessed,
    Future<void> Function(MealModel meal)? onMealUpdated,
  }) async {
    if (!await isOnline()) return;

    final geminiService = _geminiFactory(apiKey, language);
    await _recoverStaleRunning(onMealUpdated);

    while (true) {
      final pending = _databaseService.getPendingMeals();
      final ready = pending.where(_isReadyToRun).toList();
      if (ready.isEmpty) {
        final retryTimes = pending
            .where((meal) => meal.analysisStatus == 'retrying')
            .map((meal) => meal.analysisNextRetryAt)
            .whereType<DateTime>()
            .toList();
        if (retryTimes.isEmpty) return;
        retryTimes.sort();
        final waitFor = retryTimes.first.difference(DateTime.now().toUtc());
        if (waitFor.isNegative || waitFor == Duration.zero) continue;
        await Future<void>.delayed(waitFor);
        if (!await isOnline()) return;
        continue;
      }

      // Process a bounded batch in parallel, then pick up newly queued meals.
      for (var offset = 0; offset < ready.length; offset += maxConcurrency) {
        final batch = ready.skip(offset).take(maxConcurrency).toList();
        await Future.wait(
          batch.map(
            (meal) => _processSingleMeal(
              meal.id,
              geminiService,
              useGrams: useGrams,
              useAccurateMode: useAccurateMode,
              onMealProcessed: onMealProcessed,
              onMealUpdated: onMealUpdated,
            ),
          ),
        );
        if (!await isOnline()) return;
      }
    }
  }

  bool _isReadyToRun(MealModel meal) {
    if (!meal.isPending || meal.analysisStatus == 'failed') return false;
    if (meal.analysisStatus == 'running') return false;
    final nextRetry = meal.analysisNextRetryAt;
    return nextRetry == null || !nextRetry.isAfter(DateTime.now().toUtc());
  }

  Future<void> _recoverStaleRunning(
    Future<void> Function(MealModel meal)? onMealUpdated,
  ) async {
    // A running job cannot survive a closed Flutter/PWA process. Recover every
    // persisted running job that is not actively claimed by this process.
    for (final meal in _databaseService.getPendingMeals()) {
      if (meal.analysisStatus != 'running' ||
          _claimedMealIds.contains(meal.id)) {
        continue;
      }
      final recovered = meal.copyWith(
        analysisStatus: 'retrying',
        analysisError: 'Analysis was interrupted; retrying automatically.',
        analysisStartedAt: null,
        analysisNextRetryAt: DateTime.now().toUtc(),
      );
      await _databaseService.saveMeal(recovered);
      if (onMealUpdated != null) await onMealUpdated(recovered);
    }
  }

  Future<bool> _processSingleMeal(
    String mealId,
    GeminiService geminiService, {
    required bool useGrams,
    required bool useAccurateMode,
    Future<void> Function(MealModel meal)? onMealProcessed,
    Future<void> Function(MealModel meal)? onMealUpdated,
  }) async {
    if (!_claimedMealIds.add(mealId)) return false;
    var meal = _databaseService.getMealById(mealId);
    if (meal == null || !_isReadyToRun(meal)) {
      _claimedMealIds.remove(mealId);
      return false;
    }
    final attempt = meal.analysisAttempts + 1;
    meal = meal.copyWith(
      analysisStatus: 'running',
      analysisAttempts: attempt,
      analysisStartedAt: DateTime.now().toUtc(),
      analysisError: null,
    );
    await _databaseService.saveMeal(meal);
    if (onMealUpdated != null) await onMealUpdated(meal);

    try {
      Map<String, dynamic>? result;
      await for (final event in geminiService.analyzeMealStream(
        meal.photoPaths,
        useGrams: useGrams,
        useAccurateMode: useAccurateMode,
        mealContext: meal.mealContext,
      )) {
        if (event is AnalysisResult) result = event.data;
      }
      if (result == null) throw const FormatException('Empty analysis result');
      if (result['error'] == 'no_food_detected') {
        throw GeminiError(GeminiErrorType.noFood, 'No food detected');
      }

      final detectedPortion = normalizeDetectedPortion(result);
      final detectedUnit = detectedPortion.unit;
      final detectedQty = detectedPortion.quantity;
      final baseQuantityPerUnit = quantityPerUnitFor(detectedUnit);
      var detectedMultiplier = detectedUnit == 'serving'
          ? detectedQty
          : detectedQty / baseQuantityPerUnit;
      if (detectedMultiplier <= 0) detectedMultiplier = 1.0;

      final updatedMeal = meal.copyWith(
        mealName: result['meal_name']?.toString() ?? '',
        calories:
            nutritionBaseValue(
              result,
              unit: detectedUnit,
              valueKey: 'calories',
              referenceKey: 'calories_per_100g',
            ) *
            detectedMultiplier,
        protein:
            nutritionBaseValue(
              result,
              unit: detectedUnit,
              valueKey: 'protein',
              referenceKey: 'protein_per_100g',
            ) *
            detectedMultiplier,
        carbs:
            nutritionBaseValue(
              result,
              unit: detectedUnit,
              valueKey: 'carbs',
              referenceKey: 'carbs_per_100g',
            ) *
            detectedMultiplier,
        fats:
            nutritionBaseValue(
              result,
              unit: detectedUnit,
              valueKey: 'fats',
              referenceKey: 'fats_per_100g',
            ) *
            detectedMultiplier,
        caloriesPer100g: (result['calories_per_100g'] as num?)?.toDouble(),
        proteinPer100g: (result['protein_per_100g'] as num?)?.toDouble(),
        carbsPer100g: (result['carbs_per_100g'] as num?)?.toDouble(),
        fatsPer100g: (result['fats_per_100g'] as num?)?.toDouble(),
        portionMultiplier: detectedMultiplier,
        portionUnit: detectedUnit,
        quantityPerUnit: baseQuantityPerUnit,
        vitamins: _toDoubleMap(result['vitamins']),
        minerals: _toDoubleMap(result['minerals']),
        analysisConfidence:
            ((result['confidence_score'] as num?)?.toDouble() ?? 0.5).clamp(
              0.0,
              1.0,
            ),
        analysisNote:
            result['uncertainty_note']?.toString().trim().isNotEmpty == true
            ? result['uncertainty_note'].toString().trim()
            : null,
        caloriesMin: (result['calories_min'] as num?)?.toDouble(),
        caloriesMax: (result['calories_max'] as num?)?.toDouble(),
        isPending: false,
        analysisStatus: 'completed',
        analysisError: null,
        analysisStartedAt: null,
        analysisNextRetryAt: null,
      );
      await _databaseService.saveMeal(updatedMeal);
      if (onMealUpdated != null) await onMealUpdated(updatedMeal);
      if (onMealProcessed != null) await onMealProcessed(updatedMeal);
      return true;
    } catch (e) {
      final current = _databaseService.getMealById(mealId);
      if (current == null) return false;
      final exhausted = attempt >= maxAttempts;
      final exponent = (attempt - 1).clamp(0, 2).toInt();
      final retryDelay = Duration(seconds: 5 * (1 << exponent));
      final failed = current.copyWith(
        analysisStatus: exhausted ? 'failed' : 'retrying',
        analysisError: _safeErrorMessage(e),
        analysisNextRetryAt: exhausted
            ? null
            : DateTime.now().toUtc().add(retryDelay),
      );
      await _databaseService.saveMeal(failed);
      if (onMealUpdated != null) await onMealUpdated(failed);
      AppLogger.warning(
        'OfflineQueueService',
        'Meal $mealId ${exhausted ? 'failed permanently' : 'scheduled for retry'}: $e',
      );
      return false;
    } finally {
      _claimedMealIds.remove(mealId);
    }
  }

  Future<void> retryMeal(
    String mealId, {
    Future<void> Function(MealModel meal)? onMealUpdated,
  }) async {
    final meal = _databaseService.getMealById(mealId);
    if (meal == null || !meal.isPending) return;
    final queued = meal.copyWith(
      analysisStatus: 'queued',
      analysisAttempts: 0,
      analysisError: null,
      analysisStartedAt: null,
      analysisNextRetryAt: DateTime.now().toUtc(),
    );
    await _databaseService.saveMeal(queued);
    if (onMealUpdated != null) await onMealUpdated(queued);
  }

  String _safeErrorMessage(Object error) {
    if (error is GeminiError) return error.message;
    final message = error.toString();
    return message.length > 220 ? message.substring(0, 220) : message;
  }

  Map<String, double>? _toDoubleMap(dynamic value) {
    if (value is! Map) return null;
    return Map<String, double>.from(
      value.map(
        (key, item) => MapEntry(key.toString(), (item as num).toDouble()),
      ),
    );
  }

  int getPendingCount() => _databaseService
      .getPendingMeals()
      .where((meal) => meal.analysisStatus != 'failed')
      .length;
}
