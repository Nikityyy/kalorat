import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../utils/app_logger.dart';
import 'database_service.dart';

bool shouldReplaceVersion(DateTime candidate, DateTime current) =>
    candidate.toUtc().isAfter(current.toUtc());

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
    await _processSyncQueue();

    // Sync user profile
    final user = _db.getUser();
    if (user != null) {
      await _upsertProfile(userId, user);
    }

    // 1. Bulk Sync Meals to Supabase
    final meals = _db.getAllMeals();
    if (meals.isNotEmpty) {
      final mealsData = meals.map((meal) => _mealData(userId, meal)).toList();

      await _client.from('meals').upsert(mealsData);
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
          'note': weight.note,
          'updated_at': weight.updatedAt.toIso8601String(),
        };
      }).toList();

      await _client.from('weights').upsert(weightsData);
      final updatedWeights = pendingWeights
          .map((w) => w.copyWith(isPending: false))
          .toList();
      await _db.saveWeightsBatch(updatedWeights);
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
    await _processSyncQueue();
    await _applyTombstones(userId);

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
          useAccurateMode: profileData['use_accurate_mode'] ?? true,
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
      final localMeal = _db.getMealById(cloudMeal.id);
      if (localMeal != null &&
          !shouldReplaceVersion(cloudMeal.updatedAt, localMeal.updatedAt)) {
        continue;
      }
      MealModel finalMeal = cloudMeal;

      // Preserve local photo paths if they exist
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
      final local = _db.getWeightByDate(weight.date);
      if (local != null &&
          !shouldReplaceVersion(weight.updatedAt, local.updatedAt)) {
        continue;
      }
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

  Future<void> syncNow() async {
    await syncFromCloud();
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
      caloriesPer100g: (data['calories_per_100g'] as num?)?.toDouble(),
      proteinPer100g: (data['protein_per_100g'] as num?)?.toDouble(),
      carbsPer100g: (data['carbs_per_100g'] as num?)?.toDouble(),
      fatsPer100g: (data['fats_per_100g'] as num?)?.toDouble(),
      mealContext: data['meal_context'] as String?,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at']).toUtc()
          : null,
    );
  }

  WeightModel _weightFromSupabase(Map<String, dynamic> data) {
    return WeightModel(
      date: DateTime.parse(data['date']),
      weight: (data['weight'] as num).toDouble(),
      note: data['note'] as String?,
      isPending: false, // Content from cloud is by definition synced
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at']).toUtc()
          : null,
    );
  }

  // --- Public individual sync methods for incremental updates ---

  /// Sync a single meal to cloud (create or update).
  /// Returns true if successful, false otherwise.
  Future<bool> syncMeal(MealModel meal) async {
    await _db.queueSync('meal_upsert', meal.id);
    final userId = _userId;
    if (userId == null) return false;

    try {
      final current = _db.getMealById(meal.id) ?? meal;
      if (await _canUpsert(userId, 'meal', meal.id, current.updatedAt)) {
        await _client.from('meals').upsert(_mealData(userId, current));
      }
      await _db.removeFromSyncQueue('meal_upsert', meal.id);
      return true;
    } catch (e) {
      // Log error but don't throw - local operation should succeed
      AppLogger.error('SyncService', 'Failed to sync meal ${meal.id}', e);
      return false;
    }
  }

  /// Sync a single weight entry to cloud (create or update).
  Future<bool> syncWeight(WeightModel weight) async {
    final dateKey = weight.date.toIso8601String().split('T')[0];
    await _db.queueSync('weight_upsert', dateKey);
    final userId = _userId;
    if (userId == null) return false;

    try {
      final current = _db.getWeightByDate(weight.date) ?? weight;
      if (await _canUpsert(userId, 'weight', dateKey, current.updatedAt)) {
        await _client.from('weights').upsert({
          'id': '${userId}_$dateKey',
          'user_id': userId,
          'date': current.date.toIso8601String(),
          'weight': current.weight,
          'note': current.note,
          'updated_at': current.updatedAt.toIso8601String(),
        });
      }
      await _db.saveWeightsBatch([current.copyWith(isPending: false)]);
      await _db.removeFromSyncQueue('weight_upsert', dateKey);
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
    await _db.queueSync('meal_delete', mealId);
    final userId = _userId;
    if (userId == null) return false;

    try {
      await _deleteWithTombstone(userId, 'meal', mealId);
      await _db.removeFromSyncQueue('meal_delete', mealId);
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
    final dateKey = date.toIso8601String().split('T')[0];
    await _db.queueSync('weight_delete', dateKey);
    final userId = _userId;
    if (userId == null) return false;

    try {
      await _deleteWithTombstone(userId, 'weight', dateKey);
      await _db.removeFromSyncQueue('weight_delete', dateKey);
      return true;
    } catch (e) {
      AppLogger.error('SyncService', 'Failed to delete weight from cloud', e);
      return false;
    }
  }

  Map<String, dynamic> _mealData(String userId, MealModel meal) => {
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
    'calories_per_100g': meal.caloriesPer100g,
    'protein_per_100g': meal.proteinPer100g,
    'carbs_per_100g': meal.carbsPer100g,
    'fats_per_100g': meal.fatsPer100g,
    'meal_context': meal.mealContext,
    'updated_at': meal.updatedAt.toUtc().toIso8601String(),
  };

  Future<void> _deleteWithTombstone(
    String userId,
    String entityType,
    String entityId,
  ) async {
    await _client.from('sync_tombstones').upsert({
      'user_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'deleted_at': DateTime.now().toIso8601String(),
    });
    if (entityType == 'meal') {
      await _client
          .from('meals')
          .delete()
          .eq('id', entityId)
          .eq('user_id', userId);
    } else {
      await _client.from('weights').delete().eq('id', '${userId}_$entityId');
    }
  }

  Future<void> _processSyncQueue() async {
    final userId = _userId;
    if (userId == null) return;
    for (final item in List<Map<String, dynamic>>.from(_db.getSyncQueue())) {
      final type = item['type'] as String;
      final id = item['id'] as String;
      if (type == 'meal_delete') {
        await _deleteWithTombstone(userId, 'meal', id);
      } else if (type == 'weight_delete') {
        await _deleteWithTombstone(userId, 'weight', id);
      } else if (type == 'meal_upsert') {
        final meal = _db.getMealById(id);
        if (meal != null &&
            await _canUpsert(userId, 'meal', id, meal.updatedAt)) {
          await _client.from('meals').upsert(_mealData(userId, meal));
        }
      } else if (type == 'weight_upsert') {
        final date = DateTime.parse(id);
        final weight = _db.getWeightByDate(date);
        if (weight != null &&
            await _canUpsert(userId, 'weight', id, weight.updatedAt)) {
          await _client.from('weights').upsert({
            'id': '${userId}_$id',
            'user_id': userId,
            'date': weight.date.toIso8601String(),
            'weight': weight.weight,
            'note': weight.note,
            'updated_at': weight.updatedAt.toIso8601String(),
          });
        }
      }
      await _db.removeFromSyncQueue(type, id);
    }
  }

  Future<void> _applyTombstones(String userId) async {
    final rows = await _client
        .from('sync_tombstones')
        .select()
        .eq('user_id', userId);
    for (final row in rows) {
      final type = row['entity_type'];
      final id = row['entity_id'] as String;
      final deletedAt = DateTime.parse(row['deleted_at']);
      if (type == 'meal') {
        final local = _db.getMealById(id);
        if (local != null && shouldReplaceVersion(deletedAt, local.updatedAt)) {
          await _db.deleteMeal(id);
        }
      } else if (type == 'weight') {
        final date = DateTime.parse(id);
        final local = _db.getWeightByDate(date);
        if (local != null && shouldReplaceVersion(deletedAt, local.updatedAt)) {
          await _db.deleteWeight(date);
        }
      }
    }
  }

  Future<bool> _canUpsert(
    String userId,
    String entityType,
    String entityId,
    DateTime localUpdatedAt,
  ) async {
    final tombstone = await _client
        .from('sync_tombstones')
        .select('deleted_at')
        .eq('user_id', userId)
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .maybeSingle();
    if (tombstone != null &&
        !shouldReplaceVersion(
          localUpdatedAt,
          DateTime.parse(tombstone['deleted_at']).toUtc(),
        )) {
      return false;
    }

    final table = entityType == 'meal' ? 'meals' : 'weights';
    final cloudId = entityType == 'meal' ? entityId : '${userId}_$entityId';
    final remote = await _client
        .from(table)
        .select('updated_at')
        .eq('id', cloudId)
        .maybeSingle();
    return remote == null ||
        shouldReplaceVersion(
          localUpdatedAt,
          DateTime.parse(remote['updated_at']).toUtc(),
        );
  }
}
