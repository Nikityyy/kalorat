import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/app_logger.dart';

class StreakData {
  final int streak;
  final int availableFreezes;
  final Set<DateTime> frozenDays;
  final List<bool> last7DaysPresence; // true = logged or frozen, false = missed (for Zeigarnik block)

  StreakData({
    required this.streak,
    required this.availableFreezes,
    required this.frozenDays,
    required this.last7DaysPresence,
  });
}

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
  bool _isMealAnalysisActive = false;

  // Stats cache for performance (invalidated via version counter)
  int _statsCacheVersion = 0;
  Map<String, double>? _cachedTodayStats;
  int _cachedTodayVersion = -1;
  Map<String, double>? _cachedWeekStats;
  int _cachedWeekVersion = -1;
  Map<String, double>? _cachedMonthStats;
  int _cachedMonthVersion = -1;
  StreakData? _cachedStreakData;
  int _cachedStreakVersion = -1;

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
  bool get isMealAnalysisActive => _isMealAnalysisActive;
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
  Future<bool> hasCameraPermission() => _pwaService.hasCameraPermission();

  bool get mealRemindersEnabled => _user?.mealRemindersEnabled ?? true;
  bool get weightRemindersEnabled => _user?.weightRemindersEnabled ?? true;

  Future<void> setMealReminders(bool enabled) async {
    await updateUser(mealRemindersEnabled: enabled);
  }

  Future<void> setWeightReminders(bool enabled) async {
    await updateUser(weightRemindersEnabled: enabled);
  }

  Future<void> refreshReminderTimezone() async {
    final user = _user;
    if (user == null) return;
    await _notificationService.refreshTimezone();
    await _notificationService.scheduleMealReminders(
      enabled: user.mealRemindersEnabled,
      language: user.language,
    );
    await _notificationService.scheduleWeightReminder(
      enabled: user.weightRemindersEnabled,
      language: user.language,
    );
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
    final migrateAccurateMode =
        _user != null && _databaseService.needsAccurateModeDefaultMigration;
    if (migrateAccurateMode && !_user!.useAccurateMode) {
      _user = _user!.copyWith(useAccurateMode: true);
      await _databaseService.saveUser(_user!);
    }
    if (_user != null) {
      await _databaseService.setDayStartHour(_user!.dayStartHour);
    }

    // Mark as initialized immediately after local DB load so the UI shows
    // without waiting for the network. Cloud sync runs in the background.
    _isInitialized = true;
    notifyListeners();

    // If session exists, sync from cloud in the background (fire-and-forget)
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && _isOnline) {
      // Do NOT await — let the UI appear immediately
      _syncService
          .syncFromCloud()
          .then((_) async {
            _user = _databaseService.getUser(); // Refresh after background sync
            if (migrateAccurateMode && _user != null) {
              _user = _user!.copyWith(useAccurateMode: true);
              await _databaseService.saveUser(_user!);
              await _syncService.syncProfile();
              await _databaseService.markAccurateModeDefaultMigrated();
            }
            _invalidateStatsCache();
            notifyListeners();
          })
          .catchError((e) {
            AppLogger.error('AppProvider', 'Background cloud sync failed', e);
          });
    } else if (session == null && migrateAccurateMode) {
      await _databaseService.markAccurateModeDefaultMigrated();
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
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pwaService.dispose();
    super.dispose();
  }

  void performUpdate() => _pwaService.performUpdate();

  void setMealAnalysisActive(bool active) {
    if (_isMealAnalysisActive == active) return;
    _isMealAnalysisActive = active;
    notifyListeners();
  }

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

  bool isMealSyncPending(String id) => _databaseService.getSyncQueue().any(
    (item) => item['id'] == id && item['type'].toString().startsWith('meal_'),
  );

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
    int? dayStartHour,
    bool? useAccurateMode,
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
          dayStartHour: 0,
          useAccurateMode: true,
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
      dayStartHour: dayStartHour ?? currentUser.dayStartHour,
      useAccurateMode: useAccurateMode ?? currentUser.useAccurateMode,
      // If new API key provided, save to secure storage and clear here.
      // If not, keep existing empty string (or whatever is there).
      // We don't want to overwrite with empty string if apiKey wasn't passed.
      geminiApiKey: apiKey != null ? '' : currentUser.geminiApiKey,
    );

    if (dayStartHour != null) {
      await _databaseService.setDayStartHour(dayStartHour);
    }

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
        useAccurateMode: _user?.useAccurateMode ?? true,
        onMealProcessed: (meal) async {
          // Update UI incrementally as each meal completes.
          _invalidateStatsCache();
          notifyListeners();

          // Sync completed meal to cloud (fire-and-forget).
          if (!(_user?.isGuest ?? true)) {
            _syncService.syncMeal(meal);
          }

          // Sync to health platform if enabled.
          if (_user?.healthSyncEnabled == true &&
              _user?.syncMealsToHealth == true) {
            await _healthService.writeMealData(meal);
          }
        },
      );
    } finally {
      _isProcessingQueue = false;
      _invalidateStatsCache();
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
            ? "Maximum erreicht. Limit von 5 Fotos pro Mahlzeit."
            : "Maximum reached. 5 photos per meal limit.",
      );
    }

    // RATE LIMIT: Max 15 meals per day
    // Only check if it's a NEW meal (not an update to an existing one)
    final existingMeal = _databaseService.hasMeal(meal.id);
    if (!existingMeal) {
      final todayMeals = _databaseService.getMealsByDate(DateTime.now());
      if (todayMeals.length >= 15) {
        final isGerman = language == 'de';
        throw Exception(
          isGerman
              ? "Maximum erreicht. Limit von 15 Mahlzeiten pro Tag."
              : "Maximum reached. 15 meals per day limit.",
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
    
    // Sync to native home widgets
    try {
      final currentStreakData = streakData;
      // Use the last element (today) to check if tracked today
      final isTrackedToday = currentStreakData.last7DaysPresence.isNotEmpty && currentStreakData.last7DaysPresence.last;
      
      WidgetService.updateWidgetData(
        streak: currentStreakData.streak,
        isTrackedToday: isTrackedToday,
        weekHistoryJson: jsonEncode(currentStreakData.last7DaysPresence),
      );
    } catch (e) {
      AppLogger.error('AppProvider', 'Failed to update widgets', e);
    }
  }

  // Weight operations
  List<WeightModel> getAllWeights() => _databaseService.getAllWeights();

  WeightModel? getWeightByDate(DateTime date) =>
      _databaseService.getWeightByDate(date);



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

  Future<void> updateWeight(WeightModel previous, WeightModel updated) async {
    final dateChanged =
        previous.date.year != updated.date.year ||
        previous.date.month != updated.date.month ||
        previous.date.day != updated.date.day;
    if (dateChanged) await deleteWeight(previous.date);
    await saveWeight(updated);
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

  Future<void> restoreLastImportBackup() async {
    await _databaseService.restoreLastImportBackup();
    _user = _databaseService.getUser();
    _invalidateStatsCache();
    notifyListeners();
  }

  bool get hasImportBackup => _databaseService.getLastImportBackup() != null;

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

  DateTime _getLogicalDayStart(DateTime date) {
    final offset = _user?.dayStartHour ?? 0;
    final logicalDate = date.subtract(Duration(hours: offset));
    return DateTime(
      logicalDate.year,
      logicalDate.month,
      logicalDate.day,
      offset,
    );
  }

  Map<String, double> getTodayStats() {
    if (_cachedTodayStats != null &&
        _cachedTodayVersion == _statsCacheVersion) {
      return _cachedTodayStats!;
    }

    final start = _getLogicalDayStart(DateTime.now());
    final end = start.add(const Duration(days: 1));
    _cachedTodayStats = getStatsForDateRange(start, end);
    _cachedTodayVersion = _statsCacheVersion;
    return _cachedTodayStats!;
  }

  Map<String, double> getWeekStats() {
    if (_cachedWeekStats != null && _cachedWeekVersion == _statsCacheVersion) {
      return _cachedWeekStats!;
    }

    final offset = _user?.dayStartHour ?? 0;
    final logicalNow = DateTime.now().subtract(Duration(hours: offset));
    final startOfLogicalWeek = logicalNow.subtract(
      Duration(days: logicalNow.weekday - 1),
    );
    final start = DateTime(
      startOfLogicalWeek.year,
      startOfLogicalWeek.month,
      startOfLogicalWeek.day,
      offset,
    );
    final end = start.add(const Duration(days: 7));

    _cachedWeekStats = getStatsForDateRange(start, end);
    _cachedWeekVersion = _statsCacheVersion;
    return _cachedWeekStats!;
  }

  Map<String, double> getMonthStats() {
    if (_cachedMonthStats != null &&
        _cachedMonthVersion == _statsCacheVersion) {
      return _cachedMonthStats!;
    }

    final offset = _user?.dayStartHour ?? 0;
    final logicalNow = DateTime.now().subtract(Duration(hours: offset));
    final start = DateTime(logicalNow.year, logicalNow.month, 1, offset);
    final end = DateTime(logicalNow.year, logicalNow.month + 1, 1, offset);

    _cachedMonthStats = getStatsForDateRange(start, end);
    _cachedMonthVersion = _statsCacheVersion;
    return _cachedMonthStats!;
  }

  /// Computes streak data forwards from the beginning of time
  StreakData get streakData {
    if (_cachedStreakData != null && _cachedStreakVersion == _statsCacheVersion) {
      return _cachedStreakData!;
    }

    final allMeals = _databaseService.getAllMeals();
    if (allMeals.isEmpty) {
      _cachedStreakData = StreakData(
        streak: 0,
        availableFreezes: 0,
        frozenDays: {},
        last7DaysPresence: List.generate(7, (_) => false),
      );
      _cachedStreakVersion = _statsCacheVersion;
      return _cachedStreakData!;
    }

    final offset = _user?.dayStartHour ?? 0;
    final uniqueDays = <DateTime>{};
    for (final m in allMeals) {
      if (!m.isPending) {
        final adjusted = m.timestamp.subtract(Duration(hours: offset));
        uniqueDays.add(DateTime(adjusted.year, adjusted.month, adjusted.day, 12 + offset));
      }
    }

    if (uniqueDays.isEmpty) {
      _cachedStreakData = StreakData(
        streak: 0,
        availableFreezes: 0,
        frozenDays: {},
        last7DaysPresence: List.generate(7, (_) => false),
      );
      _cachedStreakVersion = _statsCacheVersion;
      return _cachedStreakData!;
    }

    final sortedDays = uniqueDays.toList()..sort((a, b) => a.compareTo(b));
    
    int streak = 0;
    int availableFreezes = 0;
    int consecutiveDaysForFreeze = 0;
    Set<DateTime> frozenDays = {};

    final firstDay = sortedDays.first;
    final now = DateTime.now();
    final logicalNow = now.subtract(Duration(hours: offset));
    final today = DateTime(logicalNow.year, logicalNow.month, logicalNow.day, 12 + offset);

    DateTime checkDay = firstDay;

    while (!checkDay.isAfter(today)) {
      if (uniqueDays.contains(checkDay)) {
        streak++;
        consecutiveDaysForFreeze++;
        if (consecutiveDaysForFreeze >= 7) {
          availableFreezes = (availableFreezes + 1).clamp(0, 2);
          consecutiveDaysForFreeze = 0;
        }
      } else {
        if (checkDay == today) {
          // Do nothing, day isn't over.
        } else if (availableFreezes > 0) {
          availableFreezes--;
          streak++;
          frozenDays.add(checkDay);
          consecutiveDaysForFreeze = 0;
        } else {
          streak = 0;
          consecutiveDaysForFreeze = 0;
          frozenDays.clear();
          availableFreezes = 0;
        }
      }
      checkDay = checkDay.add(const Duration(days: 1));
    }

    // Calculate last 7 days presence for Zeigarnik UI
    // Days are [today - 6, today - 5, ..., today]
    List<bool> last7 = [];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      if (uniqueDays.contains(d) || frozenDays.contains(d)) {
        last7.add(true);
      } else {
        last7.add(false);
      }
    }

    _cachedStreakData = StreakData(
      streak: streak,
      availableFreezes: availableFreezes,
      frozenDays: frozenDays,
      last7DaysPresence: last7,
    );
    _cachedStreakVersion = _statsCacheVersion;
    return _cachedStreakData!;
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
