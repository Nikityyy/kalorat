import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../models/models.dart';
import '../utils/platform_utils.dart';

class DatabaseService {
  static const String userBoxName = 'user_box';
  static const String mealsBoxName = 'meals_box';
  static const String weightsBoxName = 'weights_box';

  late Box<UserModel> _userBox;
  late Box<MealModel> _mealsBox;
  late Box<WeightModel> _weightsBox;

  // In-memory indices for O(1) lookup
  final Map<String, List<MealModel>> _mealsDateIndex = {};
  final Set<String> _daysWithMeals = {};

  /// Hour (0–6) at which a new calendar day starts for meal attribution.
  /// 0 = midnight (default). 4 = meals logged 00:00–03:59 count as previous day.
  int _dayStartHour = 0;

  int get dayStartHour => _dayStartHour;

  @visibleForTesting
  Future<void> initForTest({
    required Box<UserModel> userBox,
    required Box<MealModel> mealsBox,
    required Box<WeightModel> weightsBox,
  }) async {
    _userBox = userBox;
    _mealsBox = mealsBox;
    _weightsBox = weightsBox;
    await _buildIndices();
  }

  /// Update the day-start offset and rebuild indices so history reflects it.
  Future<void> setDayStartHour(int hour) async {
    _dayStartHour = hour.clamp(0, 6);
    await _buildIndices();
  }

  Future<void> init() async {
    // On web, Hive uses IndexedDB and doesn't need a path
    // On mobile, use the documents directory
    if (PlatformUtils.isWeb) {
      await Hive.initFlutter();
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocDir.path);
    }

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MealModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WeightModelAdapter());
    }

    // Open boxes
    // Open boxes with error handling
    _userBox = await _openBoxWithFallback<UserModel>(userBoxName);
    _mealsBox = await _openBoxWithFallback<MealModel>(mealsBoxName);
    _weightsBox = await _openBoxWithFallback<WeightModel>(weightsBoxName);
    await _openBoxWithFallback('settings_box');

    await _buildIndices();
  }

  Future<Box<T>> _openBoxWithFallback<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      AppLogger.error('DatabaseService', 'Failed to open box $boxName', e);
      rethrow;
    }
  }

  Future<void> _buildIndices() async {
    _mealsDateIndex.clear();
    _daysWithMeals.clear();

    try {
      for (final meal in _mealsBox.values) {
        final dateKey = _getDateKey(meal.timestamp);
        if (!_mealsDateIndex.containsKey(dateKey)) {
          _mealsDateIndex[dateKey] = [];
        }
        _mealsDateIndex[dateKey]!.add(meal);
        _daysWithMeals.add(dateKey);
      }

      // Sort lists by timestamp desc
      for (final key in _mealsDateIndex.keys) {
        _mealsDateIndex[key]!.sort(compareMealsNewestFirst);
      }
    } catch (e) {
      AppLogger.error(
        'DatabaseService',
        'Failed to build indices (corruption?)',
        e,
      );
      rethrow;
    }
  }

  /// Returns the date key for a given timestamp, adjusted by [_dayStartHour].
  /// A meal at 02:30 with dayStartHour=4 is attributed to the previous day.
  String _getDateKey(DateTime date) {
    final adjusted = date.subtract(Duration(hours: _dayStartHour));
    return '${adjusted.year}-${adjusted.month.toString().padLeft(2, '0')}-${adjusted.day.toString().padLeft(2, '0')}';
  }

  // Settings operations
  Future<void> saveOnboardingStep(int step) async {
    final box = Hive.box('settings_box');
    await box.put('onboarding_step', step);
  }

  int getOnboardingStep() {
    if (!Hive.isBoxOpen('settings_box')) return 0;
    final box = Hive.box('settings_box');
    return box.get('onboarding_step', defaultValue: 0);
  }

  bool get needsAccurateModeDefaultMigration =>
      Hive.box(
        'settings_box',
      ).get('accurate_mode_default_migrated', defaultValue: false) !=
      true;

  Future<void> markAccurateModeDefaultMigrated() =>
      Hive.box('settings_box').put('accurate_mode_default_migrated', true);

  // User operations
  UserModel? getUser() {
    if (!Hive.isBoxOpen(userBoxName)) {
      // Emergency init if somehow accessed before ready
      // This is a band-aid; ideally init() is awaited in main
      return null;
    }
    if (_userBox.isEmpty) return null;
    return _userBox.getAt(0);
  }

  Future<void> saveUser(UserModel user) async {
    if (!Hive.isBoxOpen(userBoxName)) {
      // Re-init if needed or return
      _userBox = await Hive.openBox<UserModel>(userBoxName);
    }
    if (_userBox.isEmpty) {
      await _userBox.add(user);
    } else {
      await _userBox.putAt(0, user);
    }
  }

  bool isOnboardingCompleted() {
    final user = getUser();
    return user?.onboardingCompleted ?? false;
  }

  // Meal operations
  List<MealModel> getAllMeals() {
    return _mealsBox.values.toList()..sort(compareMealsNewestFirst);
  }

  List<MealModel> getMealsByDate(DateTime date) {
    final dateKey = _getDateKey(date);
    return _mealsDateIndex[dateKey] ?? [];
  }

  bool hasMealsOnDate(DateTime date) {
    return _daysWithMeals.contains(_getDateKey(date));
  }

  List<MealModel> getMealsByDateRange(DateTime start, DateTime end) {
    final meals = <MealModel>[];

    // Normalize to logical midnights to safely iterate over all possible buckets
    var currentLogicalDate = start.subtract(Duration(hours: _dayStartHour));
    currentLogicalDate = DateTime(
      currentLogicalDate.year,
      currentLogicalDate.month,
      currentLogicalDate.day,
    );

    final endLogicalDate = end.subtract(Duration(hours: _dayStartHour));
    final endLogicalMidnight = DateTime(
      endLogicalDate.year,
      endLogicalDate.month,
      endLogicalDate.day,
    );

    // Safety break for infinite loops or massive ranges (e.g. > 5 years)
    int daysChecked = 0;

    while (!currentLogicalDate.isAfter(endLogicalMidnight) &&
        daysChecked < 2000) {
      final dateKey =
          '${currentLogicalDate.year}-${currentLogicalDate.month.toString().padLeft(2, '0')}-${currentLogicalDate.day.toString().padLeft(2, '0')}';

      if (_mealsDateIndex.containsKey(dateKey)) {
        final dailyMeals = _mealsDateIndex[dateKey]!;
        // Filter by exact timestamp range
        for (final meal in dailyMeals) {
          if (!meal.timestamp.isBefore(start) && meal.timestamp.isBefore(end)) {
            meals.add(meal);
          }
        }
      }
      currentLogicalDate = currentLogicalDate.add(const Duration(days: 1));
      daysChecked++;
    }

    meals.sort(compareMealsNewestFirst);
    return meals;
  }



  List<MealModel> getPendingMeals() {
    return _mealsBox.values.where((meal) => meal.isPending).toList();
  }

  Future<void> saveMeal(MealModel meal) async {
    meal.validate();
    meal = meal.copyWith(updatedAt: DateTime.now());
    final existingKey = _findMealKey(meal.id);

    // Update Indices
    // If updating, remove old version from index
    if (existingKey != null) {
      final oldMeal = _mealsBox.get(existingKey);
      if (oldMeal != null) {
        final oldDateKey = _getDateKey(oldMeal.timestamp);
        _mealsDateIndex[oldDateKey]?.removeWhere((m) => m.id == meal.id);
        if ((_mealsDateIndex[oldDateKey]?.isEmpty ?? true)) {
          _daysWithMeals.remove(oldDateKey);
        }
      }
    }

    // Add new version to index
    final newDateKey = _getDateKey(meal.timestamp);
    if (!_mealsDateIndex.containsKey(newDateKey)) {
      _mealsDateIndex[newDateKey] = [];
    }
    _mealsDateIndex[newDateKey]!.add(meal);
    // Sort to keep order
    _mealsDateIndex[newDateKey]!.sort(compareMealsNewestFirst);
    _daysWithMeals.add(newDateKey);

    // Save to Hive
    if (existingKey != null) {
      await _mealsBox.put(existingKey, meal);
    } else {
      await _mealsBox.put(meal.id, meal);
    }
  }

  Future<void> deleteMeal(String mealId) async {
    final key = _findMealKey(mealId) ?? mealId;
    final meal = _mealsBox.get(key);

    if (meal != null) {
      final dateKey = _getDateKey(meal.timestamp);
      _mealsDateIndex[dateKey]?.removeWhere((m) => m.id == mealId);
      if ((_mealsDateIndex[dateKey]?.isEmpty ?? true)) {
        _daysWithMeals.remove(dateKey);
      }
    }

    await _mealsBox.delete(key);
  }

  bool hasMeal(String mealId) {
    return _mealsBox.containsKey(mealId) || _findMealKey(mealId) != null;
  }

  MealModel? getMealById(String mealId) {
    final key = _findMealKey(mealId) ?? mealId;
    return _mealsBox.get(key);
  }

  /// Helper to find meal by ID when key might differ from ID
  /// (for backwards compatibility with auto-generated keys)
  dynamic _findMealKey(String mealId) {
    for (final key in _mealsBox.keys) {
      final meal = _mealsBox.get(key);
      if (meal?.id == mealId) return key;
    }
    return null;
  }

  // Weight operations
  List<WeightModel> getAllWeights() {
    return _weightsBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Save multiple meals in a single batch write transaction.
  Future<void> saveMealsBatch(List<MealModel> meals) async {
    final Map<dynamic, MealModel> mealsMap = {};
    for (final meal in meals) {
      meal.validate();
      final existingKey = _findMealKey(meal.id);
      final key = existingKey ?? meal.id;
      mealsMap[key] = meal;
    }

    // Bulk write to Hive box
    await _mealsBox.putAll(mealsMap);

    // Rebuild in-memory indices once after the batch write is complete
    await _buildIndices();
  }

  /// Save multiple weights in a single batch write transaction.
  Future<void> saveWeightsBatch(List<WeightModel> weights) async {
    final List<WeightModel> currentWeights = _weightsBox.values.toList();
    final Map<dynamic, WeightModel> weightsToPut = {};
    final List<WeightModel> weightsToAdd = [];

    for (final weight in weights) {
      weight.validate();
      final existingIndex = currentWeights.indexWhere(
        (w) =>
            w.date.year == weight.date.year &&
            w.date.month == weight.date.month &&
            w.date.day == weight.date.day,
      );
      if (existingIndex >= 0) {
        final key = _weightsBox.keyAt(existingIndex);
        weightsToPut[key] = weight;
      } else {
        weightsToAdd.add(weight);
      }
    }

    if (weightsToPut.isNotEmpty) {
      await _weightsBox.putAll(weightsToPut);
    }
    if (weightsToAdd.isNotEmpty) {
      await _weightsBox.addAll(weightsToAdd);
    }
  }

  WeightModel? getWeightByDate(DateTime date) {
    try {
      return _weightsBox.values.firstWhere(
        (w) =>
            w.date.year == date.year &&
            w.date.month == date.month &&
            w.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }



  Future<void> saveWeight(WeightModel weight) async {
    weight.validate();
    weight = weight.copyWith(updatedAt: DateTime.now(), isPending: true);
    final existingIndex = _weightsBox.values.toList().indexWhere(
      (w) =>
          w.date.year == weight.date.year &&
          w.date.month == weight.date.month &&
          w.date.day == weight.date.day,
    );
    if (existingIndex >= 0) {
      await _weightsBox.putAt(existingIndex, weight);
    } else {
      await _weightsBox.add(weight);
    }
  }

  Future<void> deleteWeight(DateTime date) async {
    final index = _weightsBox.values.toList().indexWhere(
      (w) =>
          w.date.year == date.year &&
          w.date.month == date.month &&
          w.date.day == date.day,
    );
    if (index >= 0) {
      await _weightsBox.deleteAt(index);
    }
  }

  // Export all data
  Map<String, dynamic> exportAll() {
    final user = getUser();
    return {
      'user': user?.toJson(),
      'meals': getAllMeals().map((m) => m.toJson()).toList(),
      'weights': getAllWeights().map((w) => w.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  Map<String, dynamic>? getLastImportBackup() {
    final value = Hive.box('settings_box').get('last_import_backup');
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> restoreLastImportBackup() async {
    final backup = getLastImportBackup();
    if (backup == null) throw StateError('Kein Import-Backup vorhanden.');
    await _replaceAll(backup, createBackup: false);
  }

  // Import all data
  Future<void> importAll(Map<String, dynamic> data) async {
    await _replaceAll(data, createBackup: true);
  }

  Future<void> _replaceAll(
    Map<String, dynamic> data, {
    required bool createBackup,
  }) async {
    final user = data['user'] == null
        ? null
        : UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    final meals = (data['meals'] as List? ?? const [])
        .map(
          (json) => MealModel.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
    final weights = (data['weights'] as List? ?? const [])
        .map(
          (json) =>
              WeightModel.fromJson(Map<String, dynamic>.from(json as Map)),
        )
        .toList();
    for (final meal in meals) {
      meal.validate();
    }
    for (final weight in weights) {
      weight.validate();
    }
    if (meals.map((meal) => meal.id).toSet().length != meals.length) {
      throw const FormatException('Doppelte Mahlzeiten-IDs im Import.');
    }

    final oldUser = _userBox.toMap();
    final oldMeals = _mealsBox.toMap();
    final oldWeights = _weightsBox.toMap();
    if (createBackup) {
      await Hive.box('settings_box').put('last_import_backup', exportAll());
    }

    try {
      await _userBox.clear();
      await _mealsBox.clear();
      await _weightsBox.clear();
      if (user != null) await _userBox.add(user);
      await _mealsBox.putAll({for (final meal in meals) meal.id: meal});
      await _weightsBox.addAll(weights);
      await _buildIndices();
    } catch (_) {
      await _userBox.clear();
      await _mealsBox.clear();
      await _weightsBox.clear();
      await _userBox.putAll(oldUser);
      await _mealsBox.putAll(oldMeals);
      await _weightsBox.putAll(oldWeights);
      await _buildIndices();
      rethrow;
    }
  }

  List<Map<String, dynamic>> getSyncQueue() {
    final raw = Hive.box(
      'settings_box',
    ).get('sync_queue', defaultValue: const []);
    return (raw as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> queueSync(String type, String id) async {
    final entity = type.split('_').first;
    final queue = getSyncQueue()
      ..removeWhere(
        (item) =>
            item['id'] == id &&
            item['type'].toString().startsWith('${entity}_'),
      )
      ..add({
        'type': type,
        'id': id,
        'queuedAt': DateTime.now().toIso8601String(),
      });
    await Hive.box('settings_box').put('sync_queue', queue);
  }

  Future<void> removeFromSyncQueue(String type, String id) async {
    final queue = getSyncQueue()
      ..removeWhere((item) => item['type'] == type && item['id'] == id);
    await Hive.box('settings_box').put('sync_queue', queue);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _userBox.clear();
    await _mealsBox.clear();
    await _weightsBox.clear();
    _buildIndices();
  }
}
