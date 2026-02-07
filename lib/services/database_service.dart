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
    return _mealsBox.values.where((meal) {
      return meal.timestamp.year == date.year &&
          meal.timestamp.month == date.month &&
          meal.timestamp.day == date.day;
    }).toList();
  }

  List<MealModel> getMealsByDateRange(DateTime start, DateTime end) {
    return _mealsBox.values.where((meal) {
      return meal.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          meal.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
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
    // Use meal.id as Hive key for O(1) lookup
    final existingKey = _findMealKey(meal.id);
    if (existingKey != null) {
      await _mealsBox.put(existingKey, meal);
    } else {
      await _mealsBox.put(meal.id, meal);
    }
  }

  Future<void> deleteMeal(String mealId) async {
    // O(1) delete using key
    await _mealsBox.delete(mealId);
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
      return w.date.isAfter(start.subtract(const Duration(days: 1))) &&
          w.date.isBefore(end.add(const Duration(days: 1)));
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
        final meal = MealModel.fromJson(mealJson);
        await _mealsBox.add(meal);
      }
    }

    // Import weights
    if (data['weights'] != null) {
      for (final weightJson in data['weights']) {
        final weight = WeightModel.fromJson(weightJson);
        await _weightsBox.add(weight);
      }
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    await _userBox.clear();
    await _mealsBox.clear();
    await _weightsBox.clear();
  }
}
