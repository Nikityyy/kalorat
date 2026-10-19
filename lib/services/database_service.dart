import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';
import '../models/models.dart';
import '../utils/platform_utils.dart';
import '../utils/photo_downscale.dart';
import 'photo_store.dart';

class DatabaseService {
  static const String userBoxName = 'user_box';
  static const String mealsBoxName = 'meals_box';
  static const String weightsBoxName = 'weights_box';
  static const String pendingPhotosBoxName = 'pending_photos_box';
  static const String pendingPhotosKey = 'pending_photos';

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
    PhotoStore? photoStore,
  }) async {
    if (photoStore != null) PhotoStore.instance = photoStore;
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

    // Open boxes in parallel: on web each box is its own IndexedDB database.
    final boxes = await Future.wait<Box<dynamic>>([
      _openBoxWithFallback<UserModel>(userBoxName),
      _openBoxWithFallback<MealModel>(mealsBoxName),
      _openBoxWithFallback<WeightModel>(weightsBoxName),
      _openBoxWithFallback('settings_box'),
    ]);
    _userBox = boxes[0] as Box<UserModel>;
    _mealsBox = boxes[1] as Box<MealModel>;
    _weightsBox = boxes[2] as Box<WeightModel>;
    PhotoStore.instance = await PhotoStore.open();

    if (_userBox.isNotEmpty) {
      _dayStartHour = _userBox.getAt(0)?.dayStartHour ?? 0;
    }

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
        final dateKey = _getTimestampDateKey(meal.timestamp);
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

  /// Always converts a physical meal timestamp to its logical date key.
  String _getTimestampDateKey(DateTime timestamp) {
    final adjusted = timestamp.subtract(Duration(hours: _dayStartHour));
    return '${adjusted.year}-${adjusted.month.toString().padLeft(2, '0')}-${adjusted.day.toString().padLeft(2, '0')}';
  }

  /// Returns the logical date key for a given timestamp or date lookup.
  String _getDateKey(DateTime date) {
    if (date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0 &&
        date.microsecond == 0) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return _getTimestampDateKey(date);
  }

  // Settings operations
  /// Onboarding steps were renumbered when the loading and contract steps were
  /// removed; steps saved before that carry no version marker.
  static const _onboardingStepsVersion = 2;

  Future<void> saveOnboardingStep(int step) async {
    final box = Hive.box('settings_box');
    await box.put('onboarding_step', step);
    await box.put('onboarding_steps_version', _onboardingStepsVersion);
  }

  int getOnboardingStep({required bool isWeb}) {
    if (!Hive.isBoxOpen('settings_box')) return 0;
    final box = Hive.box('settings_box');
    final step = box.get('onboarding_step', defaultValue: 0) as int;
    if (box.get('onboarding_steps_version') == _onboardingStepsVersion) {
      return step;
    }
    return migrateLegacyOnboardingStep(step, isWeb: isWeb);
  }

  /// Maps a step saved by the 12/14 step onboarding to the current one.
  /// Removed: step 6 (loading) and the contract step before the last one.
  @visibleForTesting
  static int migrateLegacyOnboardingStep(int step, {required bool isWeb}) {
    final legacyContract = isWeb ? 10 : 12;
    final lastStep = isWeb ? 9 : 11;
    if (step <= 6) return step;
    if (step < legacyContract) return step - 1;
    return lastStep;
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
    final oldDayStart = _dayStartHour;
    if (!Hive.isBoxOpen(userBoxName)) {
      // Re-init if needed or return
      _userBox = await Hive.openBox<UserModel>(userBoxName);
    }
    if (_userBox.isEmpty) {
      await _userBox.add(user);
    } else {
      await _userBox.putAt(0, user);
    }
    _dayStartHour = user.dayStartHour;
    if (oldDayStart != _dayStartHour) {
      await _buildIndices();
    }
  }

  bool isOnboardingCompleted() {
    final user = getUser();
    return user?.onboardingCompleted ?? false;
  }

  // Meal operations
  bool get hasMeals => _mealsBox.isNotEmpty;

  List<MealModel> getAllMeals() {
    return _mealsBox.values.toList()..sort(compareMealsNewestFirst);
  }

  List<MealModel> getMealsByDate(DateTime date) {
    final dateKey = _getDateKey(date);
    return _mealsDateIndex[dateKey] ?? [];
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

  Future<MealModel> saveMeal(MealModel meal) async {
    meal.validate();
    final updatedMeal = meal.copyWith(updatedAt: DateTime.now().toUtc());
    final existingKey = _findMealKey(updatedMeal.id);

    // Update Indices
    // If updating, remove old version from index
    if (existingKey != null) {
      final oldMeal = _mealsBox.get(existingKey);
      if (oldMeal != null) {
        final oldDateKey = _getTimestampDateKey(oldMeal.timestamp);
        _mealsDateIndex[oldDateKey]?.removeWhere((m) => m.id == updatedMeal.id);
        if ((_mealsDateIndex[oldDateKey]?.isEmpty ?? true)) {
          _daysWithMeals.remove(oldDateKey);
        }
      }
    }

    // Add new version to index
    final newDateKey = _getTimestampDateKey(updatedMeal.timestamp);
    if (!_mealsDateIndex.containsKey(newDateKey)) {
      _mealsDateIndex[newDateKey] = [];
    }
    _mealsDateIndex[newDateKey]!.add(updatedMeal);
    // Sort to keep order
    _mealsDateIndex[newDateKey]!.sort(compareMealsNewestFirst);
    _daysWithMeals.add(newDateKey);

    // Save to Hive
    if (existingKey != null) {
      await _mealsBox.put(existingKey, updatedMeal);
    } else {
      await _mealsBox.put(updatedMeal.id, updatedMeal);
    }
    return updatedMeal;
  }

  Future<void> deleteMeal(String mealId) async {
    final key = _findMealKey(mealId) ?? mealId;
    final meal = _mealsBox.get(key);

    if (meal != null) {
      final dateKey = _getTimestampDateKey(meal.timestamp);
      _mealsDateIndex[dateKey]?.removeWhere((m) => m.id == mealId);
      if ((_mealsDateIndex[dateKey]?.isEmpty ?? true)) {
        _daysWithMeals.remove(dateKey);
      }
    }

    await _mealsBox.delete(key);
    if (meal != null) await _deleteUnreferencedPhotos(meal.photoPaths);
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
    weight = weight.copyWith(
      updatedAt: DateTime.now().toUtc(),
      isPending: true,
    );
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

  // Export all data. Photos stay `kphoto:` references; use
  // [exportAllWithPhotos] for files that leave the app.
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

  /// Like [exportAll], with stored photos inlined as base64 so the export is
  /// self-contained.
  Future<Map<String, dynamic>> exportAllWithPhotos() async {
    final data = exportAll();
    final meals = <Map<String, dynamic>>[];
    for (final meal in data['meals'] as List) {
      final json = Map<String, dynamic>.from(meal as Map);
      final inlined = <String>[];
      for (final path in List<String>.from(json['photoPaths'] as List)) {
        if (!PhotoStore.isRef(path)) {
          inlined.add(path);
          continue;
        }
        final bytes = await PhotoStore.instance.read(path);
        if (bytes != null) inlined.add(base64Encode(bytes));
      }
      json['photoPaths'] = inlined;
      meals.add(json);
    }
    data['meals'] = meals;
    return data;
  }

  Map<String, dynamic>? getLastImportBackup() {
    final value = Hive.box('settings_box').get('last_import_backup');
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> restoreLastImportBackup() async {
    final backup = getLastImportBackup();
    if (backup == null) throw StateError('No import backup');
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
      throw ValidationException(ValidationIssue.duplicateMealIds);
    }
    final newPhotoRefs = <String>[];
    for (var i = 0; i < meals.length; i++) {
      if (!meals[i].photoPaths.any(PhotoStore.isInlineBase64)) continue;
      final refs = await _storeInlinePhotos(meals[i].photoPaths);
      newPhotoRefs.addAll(refs.where((r) => !meals[i].photoPaths.contains(r)));
      meals[i] = meals[i].copyWith(photoPaths: refs);
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
      for (final ref in newPhotoRefs) {
        await PhotoStore.instance.delete(ref);
      }
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

  // --------------- Photos ---------------

  Future<List<String>> _storeInlinePhotos(List<String> paths) async {
    final result = <String>[];
    for (final path in paths) {
      if (!PhotoStore.isInlineBase64(path)) {
        result.add(path);
        continue;
      }
      final raw = base64Decode(path);
      final bytes = await downscaleForStorage(raw);
      result.add(await PhotoStore.instance.save(bytes));
    }
    return result;
  }

  /// Moves photos that older web versions stored inline as base64 into the
  /// photo store, so existing users get the fast startup too. Safe to
  /// interrupt: a meal is only rewritten after its photos are stored, and an
  /// interrupted run continues on the next start. Returns whether anything
  /// changed.
  Future<bool> migrateInlinePhotos() async {
    var changed = false;
    final keys = _mealsBox.keys
        .where(
          (key) =>
              _mealsBox.get(key)?.photoPaths.any(PhotoStore.isInlineBase64) ??
              false,
        )
        .toList();
    for (final key in keys) {
      final original = _mealsBox.get(key);
      if (original == null) continue;
      final refs = await _storeInlinePhotos(original.photoPaths);
      // The meal may have been edited or deleted while photos were stored.
      final current = _mealsBox.get(key);
      if (current == null ||
          !listEquals(current.photoPaths, original.photoPaths)) {
        for (final ref in refs.where((r) => !original.photoPaths.contains(r))) {
          await PhotoStore.instance.delete(ref);
        }
        continue;
      }
      await _mealsBox.put(key, current.copyWith(photoPaths: refs));
      changed = true;
    }
    changed = await _migrateImportBackupPhotos() || changed;
    if (changed) await _buildIndices();
    return changed;
  }

  /// The import backup lives in `settings_box`, which loads at startup.
  Future<bool> _migrateImportBackupPhotos() async {
    final settings = Hive.box('settings_box');
    final backup = getLastImportBackup();
    final meals = backup?['meals'];
    if (meals is! List) return false;
    var changed = false;
    final migrated = <Map<String, dynamic>>[];
    for (final meal in meals) {
      final json = Map<String, dynamic>.from(meal as Map);
      final paths = List<String>.from(json['photoPaths'] as List? ?? const []);
      if (paths.any(PhotoStore.isInlineBase64)) {
        json['photoPaths'] = await _storeInlinePhotos(paths);
        changed = true;
      }
      migrated.add(json);
    }
    if (changed) {
      await settings.put('last_import_backup', {...backup!, 'meals': migrated});
    }
    return changed;
  }

  Set<String> _backupPhotoRefs() {
    final meals = getLastImportBackup()?['meals'];
    if (meals is! List) return const {};
    return {
      for (final meal in meals)
        for (final path in (meal as Map)['photoPaths'] as List? ?? const [])
          if (path is String && PhotoStore.isRef(path)) path,
    };
  }

  Future<void> _deleteUnreferencedPhotos(List<String> paths) async {
    final referenced = await _referencedPhotoPaths();
    for (final path in paths) {
      if (PhotoStore.isRef(path) && !referenced.contains(path)) {
        await PhotoStore.instance.delete(path);
      }
    }
  }

  /// Photos still used by a meal, the import backup or an unsent capture.
  Future<Set<String>> _referencedPhotoPaths() async {
    final referenced = <String>{
      for (final meal in _mealsBox.values) ...meal.photoPaths,
      ..._backupPhotoRefs(),
    };
    final pending = await Hive.openBox<dynamic>(pendingPhotosBoxName);
    final pendingPaths = pending.get(pendingPhotosKey);
    if (pendingPaths is List) {
      referenced.addAll(pendingPaths.whereType<String>());
    }
    return referenced;
  }

  /// Removes stored photos left behind by crashes or interrupted captures.
  Future<int> deleteOrphanPhotos() async =>
      PhotoStore.instance.deleteOrphans(await _referencedPhotoPaths());

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

  /// Remembers when a cloud sync step last completed (see SyncService).
  DateTime? getSyncCursor(String key) {
    final raw = Hive.box('settings_box').get('sync_cursor_$key');
    return raw is String ? DateTime.tryParse(raw)?.toUtc() : null;
  }

  Future<void> setSyncCursor(String key, DateTime value) => Hive.box(
    'settings_box',
  ).put('sync_cursor_$key', value.toUtc().toIso8601String());

  // Clear all data
  Future<void> clearAll() async {
    final settings = Hive.box('settings_box');
    for (final key in settings.keys.toList()) {
      if (key is String && key.startsWith('sync_cursor_')) {
        await settings.delete(key);
      }
    }
    await _userBox.clear();
    await _mealsBox.clear();
    await _weightsBox.clear();
    _buildIndices();
  }
}
