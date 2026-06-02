import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../utils/app_logger.dart';
import 'database_service.dart';

/// Cloud sync service using Supabase PostgreSQL.
/// Handles bidirectional sync between local Hive storage and Supabase.
class SyncService {
  final DatabaseService _db;
  SupabaseClient get _client => Supabase.instance.client;

  SyncService(this._db);

  /// Get the current user ID or null if guest.
  String? get _userId => _client.auth.currentUser?.id;

  /// Sync local data to Supabase cloud using bulk operations.
  Future<void> syncToCloud() async {
    final userId = _userId;
    if (userId == null) return;

    // Sync user profile
    final user = _db.getUser();
    if (user != null) {
      await _upsertProfile(userId, user);
    }

    // 1. Bulk Sync Meals to Supabase
    final meals = _db.getAllMeals();
    if (meals.isNotEmpty) {
      final mealsData = meals
          .map(
            (meal) => {
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
              'portion_unit': meal.portionUnit,
              'quantity_per_unit': meal.quantityPerUnit,
            },
          )
          .toList();

      try {
        await _client.from('meals').upsert(mealsData);
      } catch (e) {
        AppLogger.error('SyncService', 'Failed to bulk sync meals to cloud', e);
      }
    }

    // 2. Bulk Sync Weights (Delta sync) to Supabase
    final weights = _db.getAllWeights();
    final pendingWeights = weights.where((w) => w.isPending).toList();
    if (pendingWeights.isNotEmpty) {
      final weightsData = pendingWeights.map((weight) {
        final dateKey = weight.date.toIso8601String().split('T')[0];
        return {
          'id': '${userId}_$dateKey',
          'user_id': userId,
          'date': weight.date.toIso8601String(),
          'weight': weight.weight,
        };
      }).toList();

      try {
        await _client.from('weights').upsert(weightsData);
        // Mark as synced locally in a single batch
        final updatedWeights = pendingWeights
            .map((w) => w.copyWith(isPending: false))
            .toList();
        await _db.saveWeightsBatch(updatedWeights);
      } catch (e) {
        AppLogger.error(
          'SyncService',
          'Failed to bulk sync weights to cloud',
          e,
        );
      }
    }

    // Update last sync timestamp
    if (user != null) {
      final updated = user.copyWith(lastSyncTimestamp: DateTime.now());
      await _db.saveUser(updated);
    }
  }

  /// Sync data from Supabase cloud to local Hive using batch database writes.
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
          birthdate: profileData['birthdate'] != null
              ? (DateTime.tryParse(profileData['birthdate']) ??
                    DateTime(2000, 1, 1))
              : DateTime(2000, 1, 1),
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
          dayStartHour: profileData['day_start_hour'] ?? 0,
          useAccurateMode: profileData['use_accurate_mode'] ?? false,
        );
      } else {
        // Merge cloud profile into local (cloud is source of truth for profile fields).
        // Always prefer cloud values when they exist; only keep local value as fallback.
        final cloudName = profileData['name'] as String?;
        final cloudHeight = (profileData['height'] as num?)?.toDouble();
        final cloudWeight = (profileData['weight'] as num?)?.toDouble();
        final cloudGoal = profileData['goal'] as int?;
        final cloudGender = profileData['gender'] as int?;
        final cloudBirthdate = profileData['birthdate'] != null
            ? DateTime.tryParse(profileData['birthdate'])
            : null;
        final cloudPhoto = profileData['photo_url'] as String?;
        final cloudDayStart = profileData['day_start_hour'] as int?;
        final cloudAccurateMode = profileData['use_accurate_mode'] as bool?;

        currentUser = currentUser.copyWith(
          name: (cloudName != null && cloudName.isNotEmpty)
              ? cloudName
              : currentUser.name,
          birthdate: cloudBirthdate ?? currentUser.birthdate,
          height: cloudHeight ?? currentUser.height,
          weight: cloudWeight ?? currentUser.weight,
          goal: cloudGoal ?? currentUser.goalIndex,
          gender: cloudGender ?? currentUser.genderIndex,
          photoUrl: cloudPhoto ?? currentUser.photoUrl,
          dayStartHour: cloudDayStart ?? currentUser.dayStartHour,
          useAccurateMode: cloudAccurateMode ?? currentUser.useAccurateMode,
        );
      }
      await _db.saveUser(currentUser);
    }

    // 1. Fetch and batch merge meals
    final mealsData = await _client
        .from('meals')
        .select()
        .eq('user_id', userId);

    final List<MealModel> mealsToSave = [];
    for (final mealData in mealsData) {
      final cloudMeal = _mealFromSupabase(mealData);
      MealModel finalMeal = cloudMeal;

      // Preserve local photo paths if they exist
      final localMeal = _db.getMealById(cloudMeal.id);
      if (localMeal != null && localMeal.photoPaths.isNotEmpty) {
        finalMeal = cloudMeal.copyWith(photoPaths: localMeal.photoPaths);
      }

      mealsToSave.add(finalMeal);
    }

    if (mealsToSave.isNotEmpty) {
      await _db.saveMealsBatch(mealsToSave);
    }

    // 2. Fetch and batch merge weights
    final weightsData = await _client
        .from('weights')
        .select()
        .eq('user_id', userId);

    final List<WeightModel> weightsToSave = [];
    for (final weightData in weightsData) {
      final weight = _weightFromSupabase(weightData);
      weightsToSave.add(weight);
    }

    if (weightsToSave.isNotEmpty) {
      await _db.saveWeightsBatch(weightsToSave);
    }

    // Update last sync timestamp
    final user = _db.getUser();
    if (user != null) {
      final updated = user.copyWith(lastSyncTimestamp: DateTime.now());
      await _db.saveUser(updated);
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
      'goal': user.goalIndex,
      'gender': user.genderIndex,
      'day_start_hour': user.dayStartHour,
      'updated_at': DateTime.now().toIso8601String(),
      'photo_url': user.photoUrl,
      'use_accurate_mode': user.useAccurateMode,
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
      portionUnit: data['portion_unit'] ?? 'serving',
      quantityPerUnit: (data['quantity_per_unit'] as num?)?.toDouble() ?? 1.0,
    );
  }

  WeightModel _weightFromSupabase(Map<String, dynamic> data) {
    return WeightModel(
      date: DateTime.parse(data['date']),
      weight: (data['weight'] as num).toDouble(),
      isPending: false, // Content from cloud is by definition synced
    );
  }

  // --- Public individual sync methods for incremental updates ---

  /// Sync a single meal to cloud (create or update).
  /// Returns true if successful, false otherwise.
  Future<bool> syncMeal(MealModel meal) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
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
        'portion_unit': meal.portionUnit,
        'quantity_per_unit': meal.quantityPerUnit,
      });
      return true;
    } catch (e) {
      // Log error but don't throw - local operation should succeed
      AppLogger.error('SyncService', 'Failed to sync meal ${meal.id}', e);
      return false;
    }
  }

  /// Sync a single weight entry to cloud (create or update).
  Future<bool> syncWeight(WeightModel weight) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final dateKey = weight.date.toIso8601String().split('T')[0];
      await _client.from('weights').upsert({
        'id': '${userId}_$dateKey',
        'user_id': userId,
        'date': weight.date.toIso8601String(),
        'weight': weight.weight,
      });
      await _db.saveWeight(weight.copyWith(isPending: false));
      return true;
    } catch (e) {
      AppLogger.error('SyncService', 'Failed to sync weight', e);
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
      AppLogger.error('SyncService', 'Failed to sync profile', e);
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
      AppLogger.error(
        'SyncService',
        'Failed to delete meal $mealId from cloud',
        e,
      );
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
      AppLogger.error('SyncService', 'Failed to delete weight from cloud', e);
      return false;
    }
  }
}
