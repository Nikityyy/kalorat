// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      name: fields[0] as String,
      birthdate: fields[1] as DateTime,
      height: fields[2] as double,
      weight: fields[3] as double,
      language: fields[4] as String,
      geminiApiKey: fields[5] as String,
      onboardingCompleted: fields[6] as bool,
      mealRemindersEnabled: fields[7] as bool,
      weightRemindersEnabled: fields[8] as bool,
      goal: fields[9] as int,
      gender: fields[10] as int?,
      healthSyncEnabled: fields[11] as bool,
      syncMealsToHealth: fields[12] as bool,
      syncWeightToHealth: fields[13] as bool,
      supabaseUserId: fields[14] as String?,
      isGuest: fields[15] as bool,
      email: fields[16] as String?,
      lastSyncTimestamp: fields[17] as DateTime?,
      photoUrl: fields[18] as String?,
      useGramsByDefault: fields[19] as bool,
      activityLevel: fields[20] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.birthdate)
      ..writeByte(2)
      ..write(obj.height)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.language)
      ..writeByte(5)
      ..write(obj.geminiApiKey)
      ..writeByte(6)
      ..write(obj.onboardingCompleted)
      ..writeByte(7)
      ..write(obj.mealRemindersEnabled)
      ..writeByte(8)
      ..write(obj.weightRemindersEnabled)
      ..writeByte(9)
      ..write(obj.goal)
      ..writeByte(10)
      ..write(obj.gender)
      ..writeByte(11)
      ..write(obj.healthSyncEnabled)
      ..writeByte(12)
      ..write(obj.syncMealsToHealth)
      ..writeByte(13)
      ..write(obj.syncWeightToHealth)
      ..writeByte(14)
      ..write(obj.supabaseUserId)
      ..writeByte(15)
      ..write(obj.isGuest)
      ..writeByte(16)
      ..write(obj.email)
      ..writeByte(17)
      ..write(obj.lastSyncTimestamp)
      ..writeByte(18)
      ..write(obj.photoUrl)
      ..writeByte(19)
      ..write(obj.useGramsByDefault)
      ..writeByte(20)
      ..write(obj.activityLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
