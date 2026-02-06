import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  late final OfflineQueueService _offlineQueueService;
  late final ExportImportService _exportImportService;
  final NotificationService _notificationService = NotificationService();
  final HealthService _healthService = HealthService();

  UserModel? _user;
  String? _languageOverride;
  bool _isOnline = true;
  bool _isInitialized = false;
  bool _isProcessingQueue = false;

  // Stats cache for performance (invalidated on meal changes)
  Map<String, double>? _cachedTodayStats;
  DateTime? _cachedTodayStatsDate;
  Map<String, double>? _cachedWeekStats;
  int? _cachedWeekNumber;
  Map<String, double>? _cachedMonthStats;
  int? _cachedMonth;

  UserModel? get user => _user;
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  bool get isOnboardingCompleted => _user?.onboardingCompleted ?? false;
  String get language {
    if (_user != null) return _user!.language;
    if (_languageOverride != null) return _languageOverride!;

    // Fallback to device language
    final systemLocale = ui.PlatformDispatcher.instance.locale.languageCode;
    return systemLocale == 'de' ? 'de' : 'en';
  }

  String get apiKey => _user?.geminiApiKey ?? '';
  int get pendingMealsCount => _offlineQueueService.getPendingCount();

  bool get mealRemindersEnabled => _user?.mealRemindersEnabled ?? true;
  bool get weightRemindersEnabled => _user?.weightRemindersEnabled ?? true;

  Future<void> setMealReminders(bool enabled) async {
    await updateUser(mealRemindersEnabled: enabled);
  }

  Future<void> setWeightReminders(bool enabled) async {
    await updateUser(weightRemindersEnabled: enabled);
  }

  DatabaseService get databaseService => _databaseService;
  OfflineQueueService get offlineQueueService => _offlineQueueService;
  ExportImportService get exportImportService => _exportImportService;
  NotificationService get notificationService => _notificationService;
  HealthService get healthService => _healthService;

  Future<void> init() async {
    await _databaseService.init();
    _offlineQueueService = OfflineQueueService(_databaseService);
    _exportImportService = ExportImportService(_databaseService);
    await _notificationService.init();

    _user = _databaseService.getUser();
    _isOnline = await _offlineQueueService.isOnline();

    // Listen to connectivity changes
    _offlineQueueService.connectivityStream.listen((result) async {
      final wasOffline = !_isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);
      notifyListeners();

      // Process queue when coming back online
      if (_isOnline && wasOffline && !_isProcessingQueue) {
        await processOfflineQueue();
      }
    });

    // Process any pending meals on startup if online
    if (_isOnline) {
      await processOfflineQueue();
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> saveUser(UserModel user) async {
    await _databaseService.saveUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> deleteWeight(DateTime date) async {
    await _databaseService.deleteWeight(date);

    // Refresh user weight if we deleted the current weight
    if (_user != null) {
      final allWeights = _databaseService.getAllWeights();
      allWeights.sort((a, b) => b.date.compareTo(a.date));

      if (allWeights.isNotEmpty) {
        // Revert to the newest available weight
        if (_user!.weight != allWeights.first.weight) {
          await updateUser(weight: allWeights.first.weight);
        }
      } else {
        // If all weights are deleted, reset user's weight to null or default
        await updateUser(weight: null);
      }
    }

    notifyListeners();
  }

  Future<void> updateUser({
    String? name,
    DateTime? birthdate,
    double? height,
    double? weight,
    String? language,
    String? apiKey,
    bool? onboardingCompleted,
    bool? mealRemindersEnabled,
    bool? weightRemindersEnabled,
    int? goal,
    int? gender,
    bool? healthSyncEnabled,
    bool? syncMealsToHealth,
    bool? syncWeightToHealth,
  }) async {
    if (_user == null) return;

    _user = UserModel(
      name: name ?? _user!.name,
      birthdate: birthdate ?? _user!.birthdate,
      height: height ?? _user!.height,
      weight: weight ?? _user!.weight,
      language: language ?? _user!.language,
      geminiApiKey: apiKey ?? _user!.geminiApiKey,
      onboardingCompleted: onboardingCompleted ?? _user!.onboardingCompleted,
      mealRemindersEnabled: mealRemindersEnabled ?? _user!.mealRemindersEnabled,
      weightRemindersEnabled:
          weightRemindersEnabled ?? _user!.weightRemindersEnabled,
      goal: goal ?? _user!.goal,
      gender: gender ?? _user!.gender,
      healthSyncEnabled: healthSyncEnabled ?? _user!.healthSyncEnabled,
      syncMealsToHealth: syncMealsToHealth ?? _user!.syncMealsToHealth,
      syncWeightToHealth: syncWeightToHealth ?? _user!.syncWeightToHealth,
    );

    await _databaseService.saveUser(_user!);

    // Update notifications if reminder settings changed
    if (mealRemindersEnabled != null || weightRemindersEnabled != null) {
      await _notificationService.scheduleMealReminders(
        enabled: _user!.mealRemindersEnabled,
        language: _user!.language,
      );
      await _notificationService.scheduleWeightReminder(
        enabled: _user!.weightRemindersEnabled,
        language: _user!.language,
      );
    }

    notifyListeners();
  }

  Future<void> updateLanguage(String languageCode) async {
    if (_user != null) {
      await updateUser(language: languageCode);
    } else {
      _languageOverride = languageCode;
      notifyListeners();
    }
  }

  Future<void> processOfflineQueue() async {
    if (_isProcessingQueue || apiKey.isEmpty) return;

    _isProcessingQueue = true;
    notifyListeners();

    try {
      await _offlineQueueService.processQueue(apiKey, language);
    } finally {
      _isProcessingQueue = false;
      notifyListeners();
    }
  }

  // Meal operations
  List<MealModel> getAllMeals() => _databaseService.getAllMeals();

  List<MealModel> getMealsByDate(DateTime date) =>
      _databaseService.getMealsByDate(date);

  List<MealModel> getMealsByDateRange(DateTime start, DateTime end) =>
      _databaseService.getMealsByDateRange(start, end);

  Future<void> saveMeal(MealModel meal) async {
    await _databaseService.saveMeal(meal);
    _invalidateStatsCache(); // Invalidate on meal change

    // Sync to health platform if enabled
    if (_user?.healthSyncEnabled == true &&
        _user?.syncMealsToHealth == true &&
        !meal.isPending) {
      await _healthService.writeMealData(meal);
    }

    notifyListeners();
  }

  Future<void> deleteMeal(String mealId) async {
    await _databaseService.deleteMeal(mealId);
    _invalidateStatsCache(); // Invalidate on meal change
    notifyListeners();
  }

  /// Clears all cached stats - called when meals are modified
  void _invalidateStatsCache() {
    _cachedTodayStats = null;
    _cachedWeekStats = null;
    _cachedMonthStats = null;
  }

  // Weight operations
  List<WeightModel> getAllWeights() => _databaseService.getAllWeights();

  WeightModel? getWeightByDate(DateTime date) =>
      _databaseService.getWeightByDate(date);

  List<WeightModel> getWeightsByDateRange(DateTime start, DateTime end) =>
      _databaseService.getWeightsByDateRange(start, end);

  Future<void> saveWeight(WeightModel weight) async {
    await _databaseService.saveWeight(weight);

    // Update user's current weight ONLY if this is the most recent entry
    if (_user != null) {
      final allWeights = _databaseService.getAllWeights();
      // Sort by date descending (newest first)
      allWeights.sort((a, b) => b.date.compareTo(a.date));

      if (allWeights.isNotEmpty &&
          !weight.date.isBefore(allWeights.first.date)) {
        // If the new weight is equal to or after the newest existing weight, update profile
        await updateUser(weight: weight.weight);
      }
    }

    // Sync to health platform if enabled
    if (_user?.healthSyncEnabled == true && _user?.syncWeightToHealth == true) {
      await _healthService.writeWeight(weight.weight, weight.date);
    }

    notifyListeners();
  }

  // Export/Import
  Future<String?> exportData() => _exportImportService.exportData();

  Future<bool> importData() async {
    final success = await _exportImportService.importData();
    if (success) {
      _user = _databaseService.getUser();
      notifyListeners();
    }
    return success;
  }

  // Stats helpers
  Map<String, double> getStatsForDateRange(DateTime start, DateTime end) {
    final meals = getMealsByDateRange(start, end);
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (final meal in meals) {
      if (!meal.isPending) {
        totalCalories += meal.calories;
        totalProtein += meal.protein;
        totalCarbs += meal.carbs;
        totalFats += meal.fats;
      }
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fats': totalFats,
      'mealCount': meals.where((m) => !m.isPending).length.toDouble(),
    };
  }

  Map<String, double> getTodayStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if cache is valid for today
    if (_cachedTodayStats != null && _cachedTodayStatsDate == today) {
      return _cachedTodayStats!;
    }

    final start = today;
    final end = start.add(const Duration(days: 1));
    _cachedTodayStats = getStatsForDateRange(start, end);
    _cachedTodayStatsDate = today;
    return _cachedTodayStats!;
  }

  Map<String, double> getWeekStats() {
    final now = DateTime.now();
    final weekNumber = ((now.day + now.month * 31 + now.year * 365) ~/ 7);

    // Check if cache is valid for this week
    if (_cachedWeekStats != null && _cachedWeekNumber == weekNumber) {
      return _cachedWeekStats!;
    }

    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    _cachedWeekStats = getStatsForDateRange(startOfWeek, endOfWeek);
    _cachedWeekNumber = weekNumber;
    return _cachedWeekStats!;
  }

  Map<String, double> getMonthStats() {
    final now = DateTime.now();
    final currentMonth = now.year * 12 + now.month;

    // Check if cache is valid for this month
    if (_cachedMonthStats != null && _cachedMonth == currentMonth) {
      return _cachedMonthStats!;
    }

    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    _cachedMonthStats = getStatsForDateRange(start, end);
    _cachedMonth = currentMonth;
    return _cachedMonthStats!;
  }
}
