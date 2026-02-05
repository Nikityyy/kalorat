// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealModelAdapter extends TypeAdapter<MealModel> {
  @override
  final int typeId = 1;

  @override
  MealModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealModel(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      photoPaths: (fields[2] as List).cast<String>(),
      mealName: fields[3] as String,
      calories: fields[4] as double,
      protein: fields[5] as double,
      carbs: fields[6] as double,
      fats: fields[7] as double,
      vitamins: (fields[8] as Map?)?.cast<String, double>(),
      minerals: (fields[9] as Map?)?.cast<String, double>(),
      isPending: fields[10] as bool,
      isManualEntry: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MealModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.photoPaths)
      ..writeByte(3)
      ..write(obj.mealName)
      ..writeByte(4)
      ..write(obj.calories)
      ..writeByte(5)
      ..write(obj.protein)
      ..writeByte(6)
      ..write(obj.carbs)
      ..writeByte(7)
      ..write(obj.fats)
      ..writeByte(8)
      ..write(obj.vitamins)
      ..writeByte(9)
      ..write(obj.minerals)
      ..writeByte(10)
      ..write(obj.isPending)
      ..writeByte(11)
      ..write(obj.isManualEntry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
