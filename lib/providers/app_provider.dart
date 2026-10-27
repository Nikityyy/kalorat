import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/app_badge_setting.dart';
import '../services/backup_reminder.dart';
import '../services/services.dart';
import '../services/theme_preference.dart';
import '../utils/app_logger.dart';
import '../utils/app_status.dart';
import '../utils/insights.dart';
import '../utils/platform_utils.dart';

class StreakData {
  /// Days in a row with at least one analysed meal, up to today. A day not
  /// logged yet today does not break it.
  final int streak;

  /// The last seven days, oldest first, true where a meal was logged. The
  /// home screen widget shows it.
  final List<bool> last7DaysPresence;

  StreakData({required this.streak, required this.last7DaysPresence});
}

/// Logged days in a row ending at [today], or at the day before while
/// [today] has nothing yet. Days are UTC dates at midnight.
int countStreak(Set<DateTime> loggedDays, DateTime today) {
  var day = today;
  if (!loggedDays.contains(day)) {
    day = DateTime.utc(day.year, day.month, day.day - 1);
  }
  var streak = 0;
  while (loggedDays.contains(day)) {
    streak++;
    day = DateTime.utc(day.year, day.month, day.day - 1);
  }
  return streak;
}

class AppProvider extends ChangeNotifier with WidgetsBindingObserver {
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
  bool get isProcessingQueue => _isProcessingQueue;
  String get language {
    if (_user != null) return _user!.language;
    if (_languageOverride != null) return _languageOverride!;

    // Fallback to device language
    final systemLocale = ui.PlatformDispatcher.instance.locale.languageCode;
    return systemLocale == 'de' ? 'de' : 'en';
  }

  ThemeMode get themeMode => ThemePreference.mode;

  Future<void> setThemeMode(ThemeMode mode) async {
    await ThemePreference.setMode(mode);
    notifyListeners();
  }

  String get apiKey => _secureApiKey ?? _user?.geminiApiKey ?? '';
  List<WeightModel> get weights => getAllWeights();
  bool get updateAvailable => _pwaService.updateAvailable;
  Future<bool> hasCameraPermission() => _pwaService.hasCameraPermission();

  bool get mealRemindersEnabled => _user?.mealRemindersEnabled ?? true;
  bool get weightRemindersEnabled => _user?.weightRemindersEnabled ?? true;

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
  SyncService get syncService => _syncService;
  NotificationService get notificationService => _notificationService;
  HealthService get healthService => _healthService;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
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
    _syncAppBadge();
    notifyListeners();
    unawaited(_migratePhotoStorage());

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

  /// Moves photos of existing web installs out of the meal records (one-time,
  /// in the background) and cleans up photos nothing references anymore.
  Future<void> _migratePhotoStorage() async {
    try {
      if (await _databaseService.migrateInlinePhotos()) {
        _invalidateStatsCache();
        notifyListeners();
      }
      await _databaseService.deleteOrphanPhotos();
    } catch (e) {
      AppLogger.error('AppProvider', 'Photo storage migration failed', e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      unawaited(_resumeAndProcessQueue());
    }
  }

  Future<void> _resumeAndProcessQueue() async {
    _isOnline = await _offlineQueueService.isOnline();
    notifyListeners();
    if (_isOnline) await processOfflineQueue();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _pwaService.dispose();
    super.dispose();
  }

  void performUpdate() => _pwaService.performUpdate();

  void setMealAnalysisActive(bool active) {
    if (_isMealAnalysisActive == active) return;
    _isMealAnalysisActive = active;
    _syncScreenAwake();
    notifyListeners();
  }

  /// The screen stays on while a meal is analysed: a locked phone suspends
  /// the web app and with it the analysis.
  void _syncScreenAwake() =>
      keepScreenOn(_isMealAnalysisActive || _isProcessingQueue);

  /// Whether the app icon shows how many meals wait for their analysis.
  bool get appBadgeEnabled =>
      AppBadgeSetting.enabled && badgePermission() == BadgePermission.granted;

  /// Whether this browser can show a count on the app icon at all.
  bool get appBadgeSupported =>
      badgePermission() != BadgePermission.unsupported;

  /// Turns the count on the app icon on or off; asks for the notification
  /// permission Safari needs for it first. Call it from a tap. Returns the
  /// permission, so a refusal can be explained.
  Future<BadgePermission> setAppBadgeEnabled(bool enabled) async {
    var permission = badgePermission();
    if (enabled && permission == BadgePermission.notAsked) {
      permission = await requestBadgePermission();
    }
    await AppBadgeSetting.setEnabled(
      enabled && permission == BadgePermission.granted,
    );
    _badgeShown = null;
    _syncAppBadge();
    notifyListeners();
    return permission;
  }

  int? _badgeShown;

  void _syncAppBadge() {
    if (!PlatformUtils.isWeb) return;
    try {
      final count = appBadgeEnabled
          ? _databaseService.getPendingMeals().length
          : 0;
      if (count == _badgeShown) return;
      _badgeShown = count;
      setAppBadge(count);
    } catch (e) {
      AppLogger.error('AppProvider', 'Failed to update the app badge', e);
    }
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

      // Revert to the newest remaining weight. With no entries left, keep the
      // last known weight: the calorie target still needs one.
      if (allWeights.isNotEmpty && _user!.weight != allWeights.first.weight) {
        await updateUser(weight: allWeights.first.weight);
      }
    }

    notifyListeners();
  }

  bool isMealSyncPending(String id) => _databaseService.getSyncQueue().any(
    (item) => item['id'] == id && item['type'].toString().startsWith('meal_'),
  );

  /// The ids of all meals waiting to sync, read from the queue once; a list
  /// asks this instead of [isMealSyncPending] per row.
  Set<String> mealIdsPendingSync() => {
    for (final item in _databaseService.getSyncQueue())
      if (item['type'].toString().startsWith('meal_')) item['id'].toString(),
  };

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
    if (apiKey != null && _isInitialized) {
      unawaited(processOfflineQueue());
    }

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
    _syncScreenAwake();
    notifyListeners();

    try {
      await _offlineQueueService.processQueue(
        apiKey,
        language,
        useGrams: _user?.useGramsByDefault ?? false,
        useAccurateMode: _user?.useAccurateMode ?? true,
        onMealUpdated: (meal) async {
          _invalidateStatsCache();
          notifyListeners();
        },
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
      _syncScreenAwake();
      _invalidateStatsCache();
      notifyListeners();
    }
  }

  Future<void> retryMealAnalysis(String mealId) async {
    await _offlineQueueService.retryMeal(
      mealId,
      onMealUpdated: (_) async {
        _invalidateStatsCache();
        notifyListeners();
      },
    );
    if (apiKey.isNotEmpty && _isOnline) unawaited(processOfflineQueue());
  }

  // Meal operations
  List<MealModel> getAllMeals() => _databaseService.getAllMeals();

  bool get hasMeals => _databaseService.hasMeals;

  ExpenditureEstimate? _cachedExpenditure;
  Object? _cachedExpenditureKey;

  /// [estimateExpenditure] over the whole history, kept until a meal or a
  /// weight changes or the day turns: it walks every meal, and the Progress
  /// screen asks on every build.
  ExpenditureEstimate expenditureEstimate() {
    final weights = this.weights;
    final dayStartHour = _user?.dayStartHour ?? 0;
    final now = DateTime.now();
    final day = logicalDay(now, dayStartHour: dayStartHour);
    final key = (
      _statsCacheVersion,
      Object.hashAll([for (final w in weights) Object.hash(w.date, w.weight)]),
      day,
      dayStartHour,
    );
    final cached = _cachedExpenditure;
    if (cached != null && key == _cachedExpenditureKey) return cached;
    _cachedExpenditureKey = key;
    return _cachedExpenditure = estimateExpenditure(
      meals: getAllMeals(),
      weights: weights,
      now: now,
      dayStartHour: dayStartHour,
    );
  }

  MealModel? getMealById(String id) => _databaseService.getMealById(id);

  List<MealModel> getMealsByDate(DateTime date) =>
      _databaseService.getMealsByDate(date);

  List<MealModel> getMealsByDateRange(DateTime start, DateTime end) =>
      _databaseService.getMealsByDateRange(start, end);

  /// Meals a day can hold; Today shows the count against it once it gets
  /// close.
  static const maxMealsPerDay = 15;

  Future<void> saveMeal(MealModel meal) async {
    // RATE LIMIT: Max 5 photos per meal
    if (meal.photoPaths.length > 5) {
      throw ValidationException(ValidationIssue.photoLimit);
    }

    // RATE LIMIT: Max [maxMealsPerDay] meals per day
    // Only check if it's a NEW meal (not an update to an existing one)
    final existingMeal = _databaseService.hasMeal(meal.id);
    if (!existingMeal) {
      final todayMeals = _databaseService.getMealsByDate(DateTime.now());
      if (todayMeals.length >= maxMealsPerDay) {
        throw ValidationException(ValidationIssue.mealLimit);
      }
    }

    final savedMeal = await _databaseService.saveMeal(meal);
    _invalidateStatsCache(); // Invalidate on meal change

    // Sync meal to cloud (fire-and-forget, only if not pending and not guest)
    if (!savedMeal.isPending && !(_user?.isGuest ?? true)) {
      _syncService.syncMeal(savedMeal);
    }

    // Sync to health platform if enabled
    if (_user?.healthSyncEnabled == true &&
        _user?.syncMealsToHealth == true &&
        !savedMeal.isPending) {
      await _healthService.writeMealData(savedMeal);
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

  /// Logged meals the user can log again: newest first, one per name.
  List<MealModel> recentDistinctMeals({int limit = 6}) {
    final seen = <String>{};
    final result = <MealModel>[];
    for (final meal in _databaseService.getAllMeals()) {
      final name = meal.mealName.trim();
      if (meal.isPending || name.isEmpty || meal.calories <= 0) continue;
      if (!seen.add(name.toLowerCase())) continue;
      result.add(meal);
      if (result.length == limit) break;
    }
    return result;
  }

  /// Logs [source] again as a new meal eaten now, with its photos: a
  /// stored photo is only deleted once no meal uses it any more.
  Future<MealModel> repeatMeal(MealModel source) async {
    final copy = MealModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      photoPaths: List.of(source.photoPaths),
      mealName: source.mealName,
      calories: source.calories,
      protein: source.protein,
      carbs: source.carbs,
      fats: source.fats,
      vitamins: source.vitamins,
      minerals: source.minerals,
      isManualEntry: source.isManualEntry,
      isCalorieOverride: source.isCalorieOverride,
      portionMultiplier: source.portionMultiplier,
      portionUnit: source.portionUnit,
      quantityPerUnit: source.quantityPerUnit,
      caloriesPer100g: source.caloriesPer100g,
      proteinPer100g: source.proteinPer100g,
      carbsPer100g: source.carbsPer100g,
      fatsPer100g: source.fatsPer100g,
      mealContext: source.mealContext,
      analysisConfidence: source.analysisConfidence,
      analysisNote: source.analysisNote,
      caloriesMin: source.caloriesMin,
      caloriesMax: source.caloriesMax,
      components: source.components,
    );
    await saveMeal(copy);
    return copy;
  }

  /// Deletes [mealId] if it is still waiting for analysis; logged meals stay.
  Future<void> discardPendingMeal(String mealId) async {
    if (_databaseService.getMealById(mealId)?.isPending != true) return;
    await deleteMeal(mealId);
  }

  /// Clears all cached stats - called when meals are modified
  void _invalidateStatsCache() {
    _statsCacheVersion++;
    _syncAppBadge();

    // Sync to native home widgets. The web has none, and the streak walks
    // every meal.
    if (PlatformUtils.isWeb) return;
    try {
      final currentStreakData = streakData;
      // Use the last element (today) to check if tracked today
      final isTrackedToday =
          currentStreakData.last7DaysPresence.isNotEmpty &&
          currentStreakData.last7DaysPresence.last;

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
  /// Exports all data as a backup file. Anything but a cancelled share
  /// sheet counts as a backup for the reminder on Today.
  Future<String?> exportData() async {
    final result = await _exportImportService.exportData();
    if (result != null && result != 'web_cancelled') {
      await BackupReminder.markBackedUp();
      notifyListeners();
    }
    return result;
  }

  Object? _backupDueKey;
  bool _backupDue = false;

  /// Whether Today reminds to back up: only while the meals exist on this
  /// device alone (no cloud account), see [backupDue].
  bool get backupReminderDue {
    final user = _user;
    if (user == null || !user.isGuest) return false;
    final now = DateTime.now();
    final key = (
      _statsCacheVersion,
      BackupReminder.lastBackup,
      BackupReminder.snoozedUntil,
      DateTime(now.year, now.month, now.day, now.hour),
    );
    if (key == _backupDueKey) return _backupDue;
    _backupDueKey = key;
    // The oldest meal, and the last change to any meal: a meal logged now
    // can carry an earlier time (a gallery photo).
    DateTime? firstMeal;
    DateTime? lastChange;
    for (final meal in _databaseService.getAllMeals()) {
      if (firstMeal == null || meal.timestamp.isBefore(firstMeal)) {
        firstMeal = meal.timestamp;
      }
      final changed = meal.updatedAt.toLocal();
      if (lastChange == null || changed.isAfter(lastChange)) {
        lastChange = changed;
      }
    }
    return _backupDue = backupDue(
      now: now,
      lastBackup: BackupReminder.lastBackup,
      snoozedUntil: BackupReminder.snoozedUntil,
      firstMeal: firstMeal,
      lastMeal: lastChange,
    );
  }

  Future<void> snoozeBackupReminder() async {
    await BackupReminder.snooze();
    notifyListeners();
  }

  Future<String?> exportMarkdownReport(dynamic l10n) =>
      _exportImportService.exportMarkdownReport(l10n);

  Future<bool> importData() async {
    final success = await _exportImportService.importData();
    if (success) {
      _user = _databaseService.getUser();
      // The imported meals replace the ones the cached totals were built from.
      _invalidateStatsCache();
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

  /// Counts the logged days in a row that end today, or yesterday while
  /// today has nothing logged yet.
  StreakData get streakData {
    if (_cachedStreakData != null &&
        _cachedStreakVersion == _statsCacheVersion) {
      return _cachedStreakData!;
    }

    final offset = _user?.dayStartHour ?? 0;
    final loggedDays = <DateTime>{};
    for (final m in _databaseService.getAllMeals()) {
      if (!m.isPending) {
        final adjusted = m.timestamp.subtract(Duration(hours: offset));
        loggedDays.add(
          DateTime.utc(adjusted.year, adjusted.month, adjusted.day),
        );
      }
    }

    final logicalNow = DateTime.now().subtract(Duration(hours: offset));
    final today = DateTime.utc(
      logicalNow.year,
      logicalNow.month,
      logicalNow.day,
    );

    _cachedStreakData = StreakData(
      streak: countStreak(loggedDays, today),
      last7DaysPresence: [
        for (var i = 6; i >= 0; i--)
          loggedDays.contains(
            DateTime.utc(today.year, today.month, today.day - i),
          ),
      ],
    );
    _cachedStreakVersion = _statsCacheVersion;
    return _cachedStreakData!;
  }
}
