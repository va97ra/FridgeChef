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
      catalogId: fields[3] as String?,
      canonicalName: (fields[4] as String?) ?? (fields[1] as String),
      category: (fields[5] as String?) ?? 'other',
      supportCanonicals: (fields[6] as List?)?.cast<String>() ?? const [],
      isBlend: (fields[7] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ShelfHiveDto obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.inStock)
      ..writeByte(3)
      ..write(obj.catalogId)
      ..writeByte(4)
      ..write(obj.canonicalName)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.supportCanonicals)
      ..writeByte(7)
      ..write(obj.isBlend);
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
