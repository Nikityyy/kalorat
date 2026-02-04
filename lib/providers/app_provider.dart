import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  late final OfflineQueueService _offlineQueueService;
  late final ExportImportService _exportImportService;
  final NotificationService _notificationService = NotificationService();

  UserModel? _user;
  bool _isOnline = true;
  bool _isInitialized = false;
  bool _isProcessingQueue = false;

  UserModel? get user => _user;
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;
  bool get isOnboardingCompleted => _user?.onboardingCompleted ?? false;
  String get language => _user?.language ?? 'de';
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
    notifyListeners();
  }

  Future<void> deleteMeal(String mealId) async {
    await _databaseService.deleteMeal(mealId);
    notifyListeners();
  }

  // Weight operations
  List<WeightModel> getAllWeights() => _databaseService.getAllWeights();

  WeightModel? getWeightByDate(DateTime date) =>
      _databaseService.getWeightByDate(date);

  List<WeightModel> getWeightsByDateRange(DateTime start, DateTime end) =>
      _databaseService.getWeightsByDateRange(start, end);

  Future<void> saveWeight(WeightModel weight) async {
    await _databaseService.saveWeight(weight);

    // Update user's current weight
    if (_user != null) {
      await updateUser(weight: weight.weight);
    }

    notifyListeners();
  }

  Future<void> deleteWeight(DateTime date) async {
    await _databaseService.deleteWeight(date);
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
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return getStatsForDateRange(start, end);
  }

  Map<String, double> getWeekStats() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return getStatsForDateRange(startOfWeek, endOfWeek);
  }

  Map<String, double> getMonthStats() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return getStatsForDateRange(start, end);
  }
}
