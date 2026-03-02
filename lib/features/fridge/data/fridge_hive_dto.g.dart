// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fridge_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FridgeHiveDtoAdapter extends TypeAdapter<FridgeHiveDto> {
  @override
  final int typeId = 0;

  @override
  FridgeHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FridgeHiveDto(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      unitStr: fields[3] as String,
      expiresAt: fields[4] as DateTime?,
      calories: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, FridgeHiveDto obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.unitStr)
      ..writeByte(4)
      ..write(obj.expiresAt)
      ..writeByte(5)
      ..write(obj.calories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FridgeHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
