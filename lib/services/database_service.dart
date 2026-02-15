import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
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
    _userBox = await Hive.openBox<UserModel>(userBoxName);
    _mealsBox = await Hive.openBox<MealModel>(mealsBoxName);
    _weightsBox = await Hive.openBox<WeightModel>(weightsBoxName);
    await Hive.openBox('settings_box');

    _buildIndices();
  }

  void _buildIndices() {
    _mealsDateIndex.clear();
    _daysWithMeals.clear();

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
      _mealsDateIndex[key]!.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
    return _mealsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

    // Normalize start to beginning of day
    var current = DateTime(start.year, start.month, start.day);
    // End date check needs to include the last day if 'end' falls on it
    // But typical usage is start of day to start of next day

    // Safety break for infinite loops or massive ranges (e.g. > 5 years)
    int daysChecked = 0;

    while (current.isBefore(end) && daysChecked < 2000) {
      final dateKey = _getDateKey(current);
      if (_mealsDateIndex.containsKey(dateKey)) {
        final dailyMeals = _mealsDateIndex[dateKey]!;
        // Filter by exact timestamp range
        for (final meal in dailyMeals) {
          if (!meal.timestamp.isBefore(start) && meal.timestamp.isBefore(end)) {
            meals.add(meal);
          }
        }
      }
      current = current.add(const Duration(days: 1));
      daysChecked++;
    }

    return meals;
  }

  /// Get paginated meals for infinite scroll / lazy loading
  /// Returns meals sorted by timestamp (newest first), with offset and limit
  List<MealModel> getMealsPaginated({
    required int offset,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var meals = _mealsBox.values.toList();

    // Apply date filters if provided
    if (startDate != null || endDate != null) {
      meals = meals.where((meal) {
        if (startDate != null && meal.timestamp.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && meal.timestamp.isAfter(endDate)) return false;
        return true;
      }).toList();
    }

    // Sort by newest first
    meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply pagination
    if (offset >= meals.length) return [];
    final end = (offset + limit).clamp(0, meals.length);
    return meals.sublist(offset, end);
  }

  /// Total meal count for pagination calculations
  int getMealCount({DateTime? startDate, DateTime? endDate}) {
    if (startDate == null && endDate == null) {
      return _mealsBox.length;
    }
    return _mealsBox.values.where((meal) {
      if (startDate != null && meal.timestamp.isBefore(startDate)) return false;
      if (endDate != null && meal.timestamp.isAfter(endDate)) return false;
      return true;
    }).length;
  }

  List<MealModel> getPendingMeals() {
    return _mealsBox.values.where((meal) => meal.isPending).toList();
  }

  Future<void> saveMeal(MealModel meal) async {
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
    _mealsDateIndex[newDateKey]!.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    );
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

  List<WeightModel> getWeightsByDateRange(DateTime start, DateTime end) {
    return _weightsBox.values.where((w) {
      return !w.date.isBefore(start) && w.date.isBefore(end);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> saveWeight(WeightModel weight) async {
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

  // Import all data
  Future<void> importAll(Map<String, dynamic> data) async {
    // Clear existing data
    await _mealsBox.clear();
    await _weightsBox.clear();

    // Import user
    if (data['user'] != null) {
      final user = UserModel.fromJson(data['user']);
      await saveUser(user);
    }

    // Import meals
    if (data['meals'] != null) {
      for (final mealJson in data['meals']) {
        try {
          final meal = MealModel.fromJson(mealJson);
          await _mealsBox.put(meal.id, meal); // Use ID as key
        } catch (e) {
          // Skip invalid meal
          continue;
        }
      }
    }
    _buildIndices();

    // Import weights
    if (data['weights'] != null) {
      for (final weightJson in data['weights']) {
        try {
          final weight = WeightModel.fromJson(weightJson);
          await _weightsBox.add(weight);
        } catch (e) {
          // Skip invalid weight
          continue;
        }
      }
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    await _userBox.clear();
    await _mealsBox.clear();
    await _weightsBox.clear();
    _buildIndices();
  }
}
