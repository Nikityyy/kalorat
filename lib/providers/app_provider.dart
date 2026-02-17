import 'dart:async';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/app_logger.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  late final OfflineQueueService _offlineQueueService;
  late final ExportImportService _exportImportService;
  late final SyncService _syncService;
  final NotificationService _notificationService;
  final HealthService _healthService;
  final StorageService _storageService;
  final PwaService _pwaService;

  StreamSubscription? _connectivitySubscription;

  UserModel? _user;
  String? _secureApiKey;
  String? _languageOverride;
  bool _isOnline = true;
  bool _isInitialized = false;
  bool _isProcessingQueue = false;

  // Stats cache for performance (invalidated via version counter)
  int _statsCacheVersion = 0;
  Map<String, double>? _cachedTodayStats;
  int _cachedTodayVersion = -1;
  Map<String, double>? _cachedWeekStats;
  int _cachedWeekVersion = -1;
  Map<String, double>? _cachedMonthStats;
  int _cachedMonthVersion = -1;

  /// Constructor with optional DI for testing.
  AppProvider({
    DatabaseService? databaseService,
    NotificationService? notificationService,
    HealthService? healthService,
    StorageService? storageService,
  }) : _databaseService = databaseService ?? DatabaseService(),
       _notificationService = notificationService ?? NotificationService(),
       _healthService = healthService ?? HealthService(),
       _storageService = storageService ?? StorageService(),
       _pwaService = PwaService();

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

  String get apiKey => _secureApiKey ?? _user?.geminiApiKey ?? '';
  List<WeightModel> get weights => getAllWeights();
  int get pendingMealsCount => _offlineQueueService.getPendingCount();
  bool get updateAvailable => _pwaService.updateAvailable;

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
  SyncService get syncService => _syncService;
  NotificationService get notificationService => _notificationService;
  HealthService get healthService => _healthService;

  Future<void> init() async {
    _pwaService.init();
    _pwaService.updateAvailableStream.listen((available) {
      if (available) notifyListeners();
    });

    await _databaseService.init();
    _offlineQueueService = OfflineQueueService(_databaseService);
    _exportImportService = ExportImportService(_databaseService);
    _syncService = SyncService(_databaseService);
    await _notificationService.init();

    _isOnline = await _offlineQueueService.isOnline();
    _secureApiKey = await _storageService.getApiKey();

    // Load user from DB
    _user = _databaseService.getUser();

    // If session exists, sync from cloud to restore data
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && _isOnline) {
      await _syncService.syncFromCloud();
      _user = _databaseService.getUser(); // Refresh after sync
    }

    // Migration: If key exists in insecure storage but not secure storage, migrate it
    if (_user != null &&
        _user!.geminiApiKey.isNotEmpty &&
        (_secureApiKey == null || _secureApiKey!.isEmpty)) {
      await _storageService.saveApiKey(_user!.geminiApiKey);
      _secureApiKey = _user!.geminiApiKey;

      // Clear from insecure storage
      final updatedUser = _user!.copyWith(geminiApiKey: '');
      await _databaseService.saveUser(updatedUser);
      _user = updatedUser;
      AppLogger.info('AppProvider', 'Migrated API key to secure storage');
    }

    // Listen to connectivity changes
    _connectivitySubscription = _offlineQueueService.connectivityStream.listen((
      result,
    ) async {
      final wasOffline = !_isOnline;
      // Use robust check instead of raw plugin result
      if (result.contains(ConnectivityResult.none)) {
        _isOnline = false;
      } else {
        _isOnline = await _offlineQueueService.isOnline();
      }
      notifyListeners();

      // Process queue when coming back online
      if (_isOnline && wasOffline && !_isProcessingQueue) {
        await processOfflineQueue();
      }
    });

    // Schedule notifications for existing users with reminders enabled
    if (_user != null) {
      await _notificationService.scheduleMealReminders(
        enabled: _user!.mealRemindersEnabled,
        language: _user!.language,
      );
      await _notificationService.scheduleWeightReminder(
        enabled: _user!.weightRemindersEnabled,
        language: _user!.language,
      );
    }

    // Process any pending meals on startup if online
    if (_isOnline) {
      await processOfflineQueue();
    }

    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pwaService.dispose();
    super.dispose();
  }

  void performUpdate() => _pwaService.performUpdate();

  Future<void> saveUser(UserModel user) async {
    await _databaseService.saveUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> deleteWeight(DateTime date) async {
    await _databaseService.deleteWeight(date);

    // Sync deletion to cloud (fire-and-forget)
    _syncService.deleteWeightFromCloud(date);

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

  Future<void> loginWithSupabase({
    required String userId,
    required String email,
    String? photoUrl,
  }) async {
    // 1. Sync FROM cloud first to check for existing profile/data
    // This relies on the current auth session being active
    await _syncService.syncFromCloud();

    // 2. Refresh local user from DB (syncFromCloud may have created/updated it)
    _user = _databaseService.getUser();

    // 3. Update local user with current auth details
    // If _user was null (fresh install, no cloud data), this creates a default user
    // If _user exists, this updates email/photo/ID
    await updateUser(
      supabaseUserId: userId,
      email: email,
      isGuest: false,
      photoUrl: photoUrl,
    );

    // 4. Force a full push to cloud to ensure everything is in sync
    await _syncService.syncToCloud();

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
    String? supabaseUserId,
    bool? isGuest,
    String? email,
    DateTime? lastSyncTimestamp,
    String? photoUrl,
    bool? useGramsByDefault,
    int? activityLevel,
  }) async {
    // If user is null (e.g. during onboarding before first save), create a new one
    // Use device language for new users instead of hardcoded 'en'
    final systemLocale = ui.PlatformDispatcher.instance.locale.languageCode;
    final defaultLanguage = systemLocale == 'de' ? 'de' : 'en';

    final currentUser =
        _user ??
        UserModel(
          // Defaults for new user
          name: '',
          birthdate: DateTime.now(),
          height: 170.0,
          weight: 70.0,
          language: defaultLanguage,
          geminiApiKey: '',
          onboardingCompleted: false,
          mealRemindersEnabled: true,
          weightRemindersEnabled: true,
          goal: 0,
          gender: 0,
          healthSyncEnabled: false,
          syncMealsToHealth: false,
          syncWeightToHealth: false,
          isGuest: true,
          useGramsByDefault: false,
          activityLevel: 0,
        );

    _user = currentUser.copyWith(
      name: name ?? currentUser.name,
      birthdate: birthdate ?? currentUser.birthdate,
      height: height ?? currentUser.height,
      weight: weight ?? currentUser.weight,
      language: language ?? currentUser.language,
      onboardingCompleted:
          onboardingCompleted ?? currentUser.onboardingCompleted,
      mealRemindersEnabled:
          mealRemindersEnabled ?? currentUser.mealRemindersEnabled,
      weightRemindersEnabled:
          weightRemindersEnabled ?? currentUser.weightRemindersEnabled,
      goal: goal ?? currentUser.goalIndex,
      gender: gender ?? currentUser.genderIndex,
      healthSyncEnabled: healthSyncEnabled ?? currentUser.healthSyncEnabled,
      syncMealsToHealth: syncMealsToHealth ?? currentUser.syncMealsToHealth,
      syncWeightToHealth: syncWeightToHealth ?? currentUser.syncWeightToHealth,
      supabaseUserId: supabaseUserId ?? currentUser.supabaseUserId,
      isGuest: isGuest ?? currentUser.isGuest,
      email: email ?? currentUser.email,
      lastSyncTimestamp: lastSyncTimestamp ?? currentUser.lastSyncTimestamp,
      photoUrl: photoUrl ?? currentUser.photoUrl,
      useGramsByDefault: useGramsByDefault ?? currentUser.useGramsByDefault,
      activityLevel: activityLevel ?? currentUser.activityLevelIndex,
      // If new API key provided, save to secure storage and clear here.
      // If not, keep existing empty string (or whatever is there).
      // We don't want to overwrite with empty string if apiKey wasn't passed.
      geminiApiKey: apiKey != null ? '' : currentUser.geminiApiKey,
    );

    if (apiKey != null) {
      await _storageService.saveApiKey(apiKey);
      _secureApiKey = apiKey;
    }

    await _databaseService.saveUser(_user!);

    // Sync profile to cloud (fire-and-forget, only if not guest)
    if (!(_user!.isGuest)) {
      _syncService.syncProfile();
    }

    // Update notifications if reminder settings changed
    if (mealRemindersEnabled != null || weightRemindersEnabled != null) {
      // Request permissions when a reminder is being enabled
      if ((mealRemindersEnabled == true) || (weightRemindersEnabled == true)) {
        await _notificationService.requestPermissions();
      }
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
      await _offlineQueueService.processQueue(
        apiKey,
        language,
        useGrams: _user?.useGramsByDefault ?? false,
      );
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
    // RATE LIMIT: Max 5 photos per meal
    if (meal.photoPaths.length > 5) {
      final isGerman = language == 'de';
      // Manual fallback if context unavailable, though usually handled by UI
      throw Exception(
        isGerman
            ? "Der Guide sagt: Pack leicht. 5 Fotos genügen."
            : "The Guide says: Pack light. 5 photos are enough.",
      );
    }

    // RATE LIMIT: Max 10 meals per day
    // Only check if it's a NEW meal (not an update to an existing one)
    final existingMeal = _databaseService.hasMeal(meal.id);
    if (!existingMeal) {
      final todayMeals = _databaseService.getMealsByDate(DateTime.now());
      if (todayMeals.length >= 10) {
        final isGerman = language == 'de';
        throw Exception(
          isGerman
              ? "Der Guide sagt: Ruh dich etwas aus, du hast heute genug getrackt."
              : "The Guide says: Rest a bit, you've tracked enough for today.",
        );
      }
    }

    await _databaseService.saveMeal(meal);
    _invalidateStatsCache(); // Invalidate on meal change

    // Sync meal to cloud (fire-and-forget, only if not pending and not guest)
    if (!meal.isPending && !(_user?.isGuest ?? true)) {
      _syncService.syncMeal(meal);
    }

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

    // Sync deletion to cloud (fire-and-forget)
    if (!(_user?.isGuest ?? true)) {
      _syncService.deleteMealFromCloud(mealId);
    }

    notifyListeners();
  }

  /// Clears all cached stats - called when meals are modified
  void _invalidateStatsCache() {
    _statsCacheVersion++;
  }

  // Weight operations
  List<WeightModel> getAllWeights() => _databaseService.getAllWeights();

  WeightModel? getWeightByDate(DateTime date) =>
      _databaseService.getWeightByDate(date);

  List<WeightModel> getWeightsByDateRange(DateTime start, DateTime end) =>
      _databaseService.getWeightsByDateRange(start, end);

  Future<void> saveWeight(WeightModel weight) async {
    await _databaseService.saveWeight(weight);

    // Sync weight to cloud (fire-and-forget)
    if (!(_user?.isGuest ?? true)) {
      _syncService.syncWeight(weight);
    }

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
    if (_cachedTodayStats != null &&
        _cachedTodayVersion == _statsCacheVersion) {
      return _cachedTodayStats!;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(const Duration(days: 1));
    _cachedTodayStats = getStatsForDateRange(today, end);
    _cachedTodayVersion = _statsCacheVersion;
    return _cachedTodayStats!;
  }

  Map<String, double> getWeekStats() {
    if (_cachedWeekStats != null && _cachedWeekVersion == _statsCacheVersion) {
      return _cachedWeekStats!;
    }

    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(start.year, start.month, start.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    _cachedWeekStats = getStatsForDateRange(startOfWeek, endOfWeek);
    _cachedWeekVersion = _statsCacheVersion;
    return _cachedWeekStats!;
  }

  Map<String, double> getMonthStats() {
    if (_cachedMonthStats != null &&
        _cachedMonthVersion == _statsCacheVersion) {
      return _cachedMonthStats!;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    _cachedMonthStats = getStatsForDateRange(start, end);
    _cachedMonthVersion = _statsCacheVersion;
    return _cachedMonthStats!;
  }

  /// Computes streak: consecutive days (ending today) with at least 1 meal
  int get currentStreak {
    int streak = 0;
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);

    while (true) {
      final meals = _databaseService.getMealsByDate(day);
      if (meals.where((m) => !m.isPending).isEmpty) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Returns stats with daily averages for a date range
  Map<String, double> getStatsWithDailyAvg(DateTime start, DateTime end) {
    final stats = getStatsForDateRange(start, end);
    final now = DateTime.now();
    // Days elapsed = min(today, end) - start, at least 1
    final effectiveEnd = end.isBefore(now) ? end : now;
    int days = effectiveEnd.difference(start).inDays;
    if (days < 1) days = 1;
    stats['dailyAvgCalories'] = stats['calories']! / days;
    stats['dailyAvgProtein'] = stats['protein']! / days;
    stats['dailyAvgCarbs'] = stats['carbs']! / days;
    stats['dailyAvgFats'] = stats['fats']! / days;
    stats['days'] = days.toDouble();
    return stats;
  }
}
