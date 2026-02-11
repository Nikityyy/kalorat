import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'database_service.dart';

/// Cloud sync service using Supabase PostgreSQL.
/// Handles bidirectional sync between local Hive storage and Supabase.
class SyncService {
  final DatabaseService _db;
  SupabaseClient get _client => Supabase.instance.client;

  SyncService(this._db);

  /// Get the current user ID or null if guest.
  String? get _userId => _client.auth.currentUser?.id;

  /// Sync local data to Supabase cloud.
  /// Called after login or periodically when online.
  Future<void> syncToCloud() async {
    final userId = _userId;
    if (userId == null) return;

    // Sync user profile
    final user = _db.getUser();
    if (user != null) {
      await _upsertProfile(userId, user);
    }

    // Sync meals
    final meals = _db.getAllMeals();
    for (final meal in meals) {
      await _upsertMeal(userId, meal);
    }

    // Sync weights
    final weights = _db.getAllWeights();
    for (final weight in weights) {
      await _upsertWeight(userId, weight);
    }

    // Update last sync timestamp
    if (user != null) {
      user.lastSyncTimestamp = DateTime.now();
      await _db.saveUser(user);
    }
  }

  /// Sync data from Supabase cloud to local Hive.
  /// Called after login to restore data on new device.
  Future<void> syncFromCloud() async {
    final userId = _userId;
    if (userId == null) return;

    // Fetch profile
    final profileData = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profileData != null) {
      var currentUser = _db.getUser();

      if (currentUser == null) {
        // Create new local user from cloud profile
        currentUser = UserModel(
          name: profileData['name'] ?? '',
          birthdate: DateTime.parse(profileData['birthdate']),
          height: (profileData['height'] as num?)?.toDouble() ?? 170.0,
          weight: (profileData['weight'] as num?)?.toDouble() ?? 70.0,
          language: profileData['language'] ?? 'en',
          geminiApiKey: '', // API Key not synced for security
          onboardingCompleted:
              true, // If they have a profile, they are onboarded
          goal: profileData['goal'] ?? 0,
          gender: profileData['gender'] ?? 0,
          isGuest: false,
          supabaseUserId: userId,
          photoUrl: profileData['photo_url'],
        );
      } else {
        // Merge cloud profile into local (prefer cloud for non-local-only fields)
        // PROTECT LOCAL NAME: Only use cloud name if local is empty/default or we want to force sync
        if (currentUser.name.isEmpty) {
          currentUser.name = profileData['name'] ?? currentUser.name;
        }
        currentUser.birthdate = DateTime.parse(
          profileData['birthdate'] ?? currentUser.birthdate.toIso8601String(),
        );
        currentUser.height =
            (profileData['height'] as num?)?.toDouble() ?? currentUser.height;
        currentUser.weight =
            (profileData['weight'] as num?)?.toDouble() ?? currentUser.weight;
        currentUser.goal = profileData['goal'] ?? currentUser.goal;
        currentUser.gender = profileData['gender'] ?? currentUser.gender;
        currentUser.photoUrl = profileData['photo_url'] ?? currentUser.photoUrl;
      }
      await _db.saveUser(currentUser);
    }

    // Fetch and merge meals
    final mealsData = await _client
        .from('meals')
        .select()
        .eq('user_id', userId);

    for (final mealData in mealsData) {
      final meal = _mealFromSupabase(mealData);
      await _db.saveMeal(meal);
    }

    // Fetch and merge weights
    final weightsData = await _client
        .from('weights')
        .select()
        .eq('user_id', userId);

    for (final weightData in weightsData) {
      final weight = _weightFromSupabase(weightData);
      await _db.saveWeight(weight);
    }

    // Update last sync timestamp
    final user = _db.getUser();
    if (user != null) {
      user.lastSyncTimestamp = DateTime.now();
      await _db.saveUser(user);
    }
  }

  /// Smart merge: upload local data to cloud when logging into existing account.
  /// Preserves cloud data while adding any local-only entries.
  Future<void> mergeLocalToCloud() async {
    final userId = _userId;
    if (userId == null) return;

    // First pull cloud data
    await syncFromCloud();

    // Then push local data (upsert won't duplicate)
    await syncToCloud();
  }

  /// Delete all user data from Supabase (GDPR compliance).
  Future<void> deleteAllData() async {
    final userId = _userId;
    if (userId == null) return;

    await _client.from('meals').delete().eq('user_id', userId);
    await _client.from('weights').delete().eq('user_id', userId);
    await _client.from('profiles').delete().eq('id', userId);
  }

  /// Export all user data as JSON string (GDPR data request).
  Future<String> exportUserData() async {
    final userId = _userId;
    if (userId == null) {
      // Export local data only for guests
      return jsonEncode(_db.exportAll());
    }

    // Fetch all cloud data
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    final meals = await _client.from('meals').select().eq('user_id', userId);

    final weights = await _client
        .from('weights')
        .select()
        .eq('user_id', userId);

    return jsonEncode({
      'profile': profile,
      'meals': meals,
      'weights': weights,
      'exportDate': DateTime.now().toIso8601String(),
      'userId': userId,
    });
  }

  // --- Private helpers ---

  Future<void> _upsertProfile(String userId, UserModel user) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'name': user.name,
      'birthdate': user.birthdate.toIso8601String(),
      'height': user.height,
      'weight': user.weight,
      'language': user.language,
      'goal': user.goal,
      'gender': user.gender,
      'updated_at': DateTime.now().toIso8601String(),
      'photo_url': user.photoUrl,
    });
  }

  Future<void> _upsertMeal(String userId, MealModel meal) async {
    await _client.from('meals').upsert({
      'id': meal.id,
      'user_id': userId,
      'timestamp': meal.timestamp.toIso8601String(),
      'meal_name': meal.mealName,
      'calories': meal.calories,
      'protein': meal.protein,
      'carbs': meal.carbs,
      'fats': meal.fats,
      'vitamins': meal.vitamins,
      'minerals': meal.minerals,
      'is_pending': meal.isPending,
      'is_manual_entry': meal.isManualEntry,
      'is_calorie_override': meal.isCalorieOverride,
      'portion_multiplier': meal.portionMultiplier,
      // Note: photoPaths are local file paths, not synced to cloud
    });
  }

  Future<void> _upsertWeight(String userId, WeightModel weight) async {
    final dateKey = weight.date.toIso8601String().split('T')[0];
    await _client.from('weights').upsert({
      'id': '${userId}_$dateKey',
      'user_id': userId,
      'date': weight.date.toIso8601String(),
      'weight': weight.weight,
    });
  }

  MealModel _mealFromSupabase(Map<String, dynamic> data) {
    return MealModel(
      id: data['id'],
      timestamp: DateTime.parse(data['timestamp']),
      photoPaths: [], // Photos are local-only
      mealName: data['meal_name'] ?? '',
      calories: (data['calories'] as num?)?.toDouble() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
      fats: (data['fats'] as num?)?.toDouble() ?? 0,
      vitamins: data['vitamins'] != null
          ? Map<String, double>.from(data['vitamins'])
          : null,
      minerals: data['minerals'] != null
          ? Map<String, double>.from(data['minerals'])
          : null,
      isPending: data['is_pending'] ?? false,
      isManualEntry: data['is_manual_entry'] ?? false,
      isCalorieOverride: data['is_calorie_override'] ?? false,
      portionMultiplier:
          (data['portion_multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  WeightModel _weightFromSupabase(Map<String, dynamic> data) {
    return WeightModel(
      date: DateTime.parse(data['date']),
      weight: (data['weight'] as num).toDouble(),
    );
  }

  // --- Public individual sync methods for incremental updates ---

  /// Sync a single meal to cloud (create or update).
  /// Returns true if successful, false otherwise.
  Future<bool> syncMeal(MealModel meal) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      await _upsertMeal(userId, meal);
      return true;
    } catch (e) {
      // Log error but don't throw - local operation should succeed
      print('SyncService: Failed to sync meal ${meal.id}: $e');
      return false;
    }
  }

  /// Sync a single weight entry to cloud (create or update).
  Future<bool> syncWeight(WeightModel weight) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      await _upsertWeight(userId, weight);
      return true;
    } catch (e) {
      print('SyncService: Failed to sync weight: $e');
      return false;
    }
  }

  /// Sync profile changes to cloud.
  Future<bool> syncProfile() async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final user = _db.getUser();
      if (user != null) {
        await _upsertProfile(userId, user);
        return true;
      }
      return false;
    } catch (e) {
      print('SyncService: Failed to sync profile: $e');
      return false;
    }
  }

  /// Delete a meal from cloud storage.
  Future<bool> deleteMealFromCloud(String mealId) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      await _client.from('meals').delete().eq('id', mealId);
      return true;
    } catch (e) {
      print('SyncService: Failed to delete meal $mealId from cloud: $e');
      return false;
    }
  }

  /// Delete a weight entry from cloud storage.
  Future<bool> deleteWeightFromCloud(DateTime date) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final dateKey = date.toIso8601String().split('T')[0];
      await _client.from('weights').delete().eq('id', '${userId}_$dateKey');
      return true;
    } catch (e) {
      print('SyncService: Failed to delete weight from cloud: $e');
      return false;
    }
  }
}
