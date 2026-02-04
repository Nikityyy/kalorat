import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DatabaseService {
  static const String userBoxName = 'user_box';
  static const String mealsBoxName = 'meals_box';
  static const String weightsBoxName = 'weights_box';

  late Box<UserModel> _userBox;
  late Box<MealModel> _mealsBox;
  late Box<WeightModel> _weightsBox;

  Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocDir.path);

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
  }

  // User operations
  UserModel? getUser() {
    if (_userBox.isEmpty) return null;
    return _userBox.getAt(0);
  }

  Future<void> saveUser(UserModel user) async {
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

  List<MealModel> getPendingMeals() {
    return _mealsBox.values.where((meal) => meal.isPending).toList();
  }

  Future<void> saveMeal(MealModel meal) async {
    final existingIndex = _mealsBox.values.toList().indexWhere(
      (m) => m.id == meal.id,
    );
    if (existingIndex >= 0) {
      await _mealsBox.putAt(existingIndex, meal);
    } else {
      await _mealsBox.add(meal);
    }
  }

  Future<void> deleteMeal(String mealId) async {
    final index = _mealsBox.values.toList().indexWhere((m) => m.id == mealId);
    if (index >= 0) {
      await _mealsBox.deleteAt(index);
    }
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
