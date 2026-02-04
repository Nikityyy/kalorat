import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'gemini_service.dart';

import 'package:flutter/foundation.dart';

class OfflineQueueService {
  final DatabaseService _databaseService;
  final Connectivity _connectivity = Connectivity();

  OfflineQueueService(this._databaseService);

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<void> processQueue(String apiKey, String language) async {
    if (!await isOnline()) return;

    final pendingMeals = _databaseService.getPendingMeals();
    if (pendingMeals.isEmpty) return;

    final geminiService = GeminiService(apiKey: apiKey, language: language);

    for (final meal in pendingMeals) {
      try {
        final result = await geminiService.analyzeMeal(meal.photoPaths);
        if (result != null) {
          final updatedMeal = meal.copyWith(
            mealName: result['meal_name'] ?? '',
            calories: (result['calories'] ?? 0).toDouble(),
            protein: (result['protein'] ?? 0).toDouble(),
            carbs: (result['carbs'] ?? 0).toDouble(),
            fats: (result['fats'] ?? 0).toDouble(),
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
