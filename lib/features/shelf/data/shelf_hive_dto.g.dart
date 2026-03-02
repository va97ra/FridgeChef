// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelf_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShelfHiveDtoAdapter extends TypeAdapter<ShelfHiveDto> {
  @override
  final int typeId = 1;

  @override
  ShelfHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShelfHiveDto(
      id: fields[0] as String,
      name: fields[1] as String,
      inStock: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ShelfHiveDto obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.inStock);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShelfHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
