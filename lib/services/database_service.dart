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
  final Map<String, dynamic> _mealKeyById = {};
  List<MealModel>? _cachedAllMeals;
  final Map<String, dynamic> _weightKeyByDateKey = {};
  List<WeightModel>? _cachedAllWeights;
  List<Map<String, dynamic>>? _cachedSyncQueue;
  Set<String>? _cachedPendingSyncMealIds;
  Set<String>? _cachedBackupPhotoRefs;

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
    final clamped = hour.clamp(0, 6);
    if (clamped == _dayStartHour) return;
    _dayStartHour = clamped;
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

    // Open boxes and photo store in parallel: on web each box is its own
    // IndexedDB database.
    late final PhotoStore photoStore;
    final boxes = await Future.wait<dynamic>([
      _openBoxWithFallback<UserModel>(userBoxName),
      _openBoxWithFallback<MealModel>(mealsBoxName),
      _openBoxWithFallback<WeightModel>(weightsBoxName),
      _openBoxWithFallback('settings_box'),
      PhotoStore.open().then((store) => photoStore = store),
    ]);
    _userBox = boxes[0] as Box<UserModel>;
    _mealsBox = boxes[1] as Box<MealModel>;
    _weightsBox = boxes[2] as Box<WeightModel>;
    PhotoStore.instance = photoStore;

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
    try {
      _populateMealIndices(_mealsBox.toMap().entries);
      _rebuildWeightIndices();
    } catch (e) {
      AppLogger.error(
        'DatabaseService',
        'Failed to build indices (corruption?)',
        e,
      );
      rethrow;
    }
  }

  void _populateMealIndices(Iterable<MapEntry<dynamic, MealModel>> entries) {
    _mealsDateIndex.clear();
    _daysWithMeals.clear();
    _mealKeyById.clear();
    final allMeals = <MealModel>[];
    for (final MapEntry(:key, value: meal) in entries) {
      _mealKeyById[meal.id] = key;
      allMeals.add(meal);
      final dateKey = _getTimestampDateKey(meal.timestamp);
      (_mealsDateIndex[dateKey] ??= []).add(meal);
      _daysWithMeals.add(dateKey);
    }

    // Sort lists by timestamp desc
    for (final bucket in _mealsDateIndex.values) {
      if (bucket.length > 1) bucket.sort(compareMealsNewestFirst);
    }
    allMeals.sort(compareMealsNewestFirst);
    _cachedAllMeals = allMeals;
  }

  void _rebuildWeightIndices() {
    _weightKeyByDateKey.clear();
    final weights = <WeightModel>[];
    for (final MapEntry(:key, value: weight) in _weightsBox.toMap().entries) {
      _weightKeyByDateKey[_weightDateKey(weight.date)] = key;
      weights.add(weight);
    }
    weights.sort((a, b) => b.date.compareTo(a.date));
    _cachedAllWeights = weights;
  }

  String _weightDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
    _cachedAllMeals ??= _mealsBox.values.toList()
      ..sort(compareMealsNewestFirst);
    return List.of(_cachedAllMeals!);
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
      // The next calendar day, not 24 hours on: the day summer time ends
      // has 25 hours, and 24 hours after its midnight is still that day,
      // which read its meals twice.
      currentLogicalDate = DateTime(
        currentLogicalDate.year,
        currentLogicalDate.month,
        currentLogicalDate.day + 1,
      );
      daysChecked++;
    }

    meals.sort(compareMealsNewestFirst);
    return meals;
  }

  List<MealModel> getPendingMeals() {
    final meals = _cachedAllMeals ?? _mealsBox.values;
    return [for (final meal in meals) if (meal.isPending) meal];
  }

  Future<MealModel> saveMeal(MealModel meal) async {
    meal.validate();
    final updatedMeal = meal.copyWith(updatedAt: DateTime.now().toUtc());
    final existingKey = _mealKeyById[updatedMeal.id];

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
    final key = existingKey ?? updatedMeal.id;
    _mealKeyById[updatedMeal.id] = key;
    if (_cachedAllMeals case final all?) {
      if (existingKey != null) {
        all.removeWhere((m) => m.id == updatedMeal.id);
      }
      var insertAt = 0;
      while (insertAt < all.length &&
          compareMealsNewestFirst(all[insertAt], updatedMeal) < 0) {
        insertAt++;
      }
      all.insert(insertAt, updatedMeal);
    }
    await _mealsBox.put(key, updatedMeal);
    return updatedMeal;
  }

  Future<void> deleteMeal(String mealId) async {
    final key = _mealKeyById.remove(mealId) ?? mealId;
    final meal = _mealsBox.get(key);

    if (meal != null) {
      final dateKey = _getTimestampDateKey(meal.timestamp);
      _mealsDateIndex[dateKey]?.removeWhere((m) => m.id == mealId);
      if ((_mealsDateIndex[dateKey]?.isEmpty ?? true)) {
        _daysWithMeals.remove(dateKey);
      }
    }

    _cachedAllMeals?.removeWhere((m) => m.id == mealId);
    await _mealsBox.delete(key);
    if (meal != null && meal.photoPaths.any(PhotoStore.isRef)) {
      await _deleteUnreferencedPhotos(meal.photoPaths);
    }
  }

  bool hasMeal(String mealId) {
    return _mealKeyById.containsKey(mealId) || _mealsBox.containsKey(mealId);
  }

  MealModel? getMealById(String mealId) {
    final key = _mealKeyById[mealId] ?? mealId;
    return _mealsBox.get(key);
  }

  // Weight operations
  List<WeightModel> getAllWeights() {
    _cachedAllWeights ??= _weightsBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.of(_cachedAllWeights!);
  }

  /// Save multiple meals in a single batch write transaction.
  Future<void> saveMealsBatch(List<MealModel> meals) async {
    final Map<dynamic, MealModel> mealsMap = {};
    for (final meal in meals) {
      meal.validate();
      mealsMap[_mealKeyById[meal.id] ?? meal.id] = meal;
    }

    // Bulk write to Hive box
    await _mealsBox.putAll(mealsMap);

    // Rebuild in-memory indices once after the batch write is complete
    await _buildIndices();
  }

  /// Save multiple weights in a single batch write transaction.
  Future<void> saveWeightsBatch(List<WeightModel> weights) async {
    final Map<dynamic, WeightModel> weightsToPut = {};
    final List<WeightModel> weightsToAdd = [];

    for (final weight in weights) {
      weight.validate();
      final existingKey = _weightKeyByDateKey[_weightDateKey(weight.date)];
      if (existingKey != null) {
        weightsToPut[existingKey] = weight;
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
    _rebuildWeightIndices();
  }

  WeightModel? getWeightByDate(DateTime date) {
    final key = _weightKeyByDateKey[_weightDateKey(date)];
    return key == null ? null : _weightsBox.get(key);
  }

  Future<void> saveWeight(WeightModel weight) async {
    weight.validate();
    weight = weight.copyWith(
      updatedAt: DateTime.now().toUtc(),
      isPending: true,
    );
    final dateKey = _weightDateKey(weight.date);
    final existingKey = _weightKeyByDateKey[dateKey];
    if (existingKey != null) {
      await _weightsBox.put(existingKey, weight);
    } else {
      final newKey = await _weightsBox.add(weight);
      _weightKeyByDateKey[dateKey] = newKey;
    }
    _cachedAllWeights = null;
  }

  Future<void> deleteWeight(DateTime date) async {
    final key = _weightKeyByDateKey.remove(_weightDateKey(date));
    if (key != null) {
      await _weightsBox.delete(key);
      _cachedAllWeights = null;
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
    final seenMealIds = <String>{};
    for (final meal in meals) {
      meal.validate();
      if (!seenMealIds.add(meal.id)) {
        throw ValidationException(ValidationIssue.duplicateMealIds);
      }
    }
    for (final weight in weights) {
      weight.validate();
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
      _cachedBackupPhotoRefs = null;
    }

    final mealsById = {for (final meal in meals) meal.id: meal};
    try {
      await _userBox.clear();
      await _mealsBox.clear();
      await _weightsBox.clear();
      if (user != null) await _userBox.add(user);
      await _mealsBox.putAll(mealsById);
      await _weightsBox.addAll(weights);
      _populateMealIndices(mealsById.entries);
      _rebuildWeightIndices();
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
      _cachedBackupPhotoRefs = null;
    }
    return changed;
  }

  Set<String> _backupPhotoRefs() {
    if (_cachedBackupPhotoRefs case final cached?) return cached;
    final backup = Hive.box('settings_box').get('last_import_backup');
    final meals = backup is Map ? backup['meals'] : null;
    if (meals is! List) return _cachedBackupPhotoRefs = const {};
    return _cachedBackupPhotoRefs = {
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
    final meals = _cachedAllMeals ?? _mealsBox.values;
    final referenced = <String>{
      for (final meal in meals) ...meal.photoPaths,
      ..._backupPhotoRefs(),
    };
    final pending = Hive.isBoxOpen(pendingPhotosBoxName)
        ? Hive.box<dynamic>(pendingPhotosBoxName)
        : await Hive.openBox<dynamic>(pendingPhotosBoxName);
    final pendingPaths = pending.get(pendingPhotosKey);
    if (pendingPaths is List) {
      referenced.addAll(pendingPaths.whereType<String>());
    }
    return referenced;
  }

  /// Removes stored photos left behind by crashes or interrupted captures.
  Future<int> deleteOrphanPhotos() async =>
      PhotoStore.instance.deleteOrphans(await _referencedPhotoPaths());

  List<Map<String, dynamic>> _loadSyncQueue() {
    return _cachedSyncQueue ??= (Hive.box(
      'settings_box',
    ).get('sync_queue', defaultValue: const []) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  List<Map<String, dynamic>> getSyncQueue() => [
    for (final item in _loadSyncQueue()) Map<String, dynamic>.from(item),
  ];

  Set<String> getPendingSyncMealIds() {
    return _cachedPendingSyncMealIds ??= Set.unmodifiable({
      for (final item in _loadSyncQueue())
        if (item['type'].toString().startsWith('meal_')) item['id'].toString(),
    });
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
    _cachedSyncQueue = queue;
    _cachedPendingSyncMealIds = null;
    await Hive.box('settings_box').put('sync_queue', queue);
  }

  Future<void> removeFromSyncQueue(String type, String id) async {
    final queue = getSyncQueue()
      ..removeWhere((item) => item['type'] == type && item['id'] == id);
    _cachedSyncQueue = queue;
    _cachedPendingSyncMealIds = null;
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
    _cachedSyncQueue = null;
    _cachedPendingSyncMealIds = null;
    await _buildIndices();
  }
}
