// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeightModelAdapter extends TypeAdapter<WeightModel> {
  @override
  final int typeId = 2;

  @override
  WeightModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeightModel(
      date: fields[0] as DateTime,
      weight: fields[1] as double,
      note: fields[2] as String?,
      isPending: fields[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, WeightModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.weight)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.isPending);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
