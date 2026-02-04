// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

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
      mealRemindersEnabled: fields[7] as bool? ?? true,
      weightRemindersEnabled: fields[8] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.weightRemindersEnabled);
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
