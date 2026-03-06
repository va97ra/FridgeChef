import 'package:hive/hive.dart';

class UserRecipeHiveDto extends HiveObject {
  final String id;
  final String recipeJson;
  final String signature;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRecipeHiveDto({
    required this.id,
    required this.recipeJson,
    required this.signature,
    required this.createdAt,
    required this.updatedAt,
  });
}

class UserRecipeHiveDtoAdapter extends TypeAdapter<UserRecipeHiveDto> {
  @override
  final int typeId = 2;

  @override
  UserRecipeHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return UserRecipeHiveDto(
      id: fields[0] as String,
      recipeJson: fields[1] as String,
      signature: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserRecipeHiveDto obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recipeJson)
      ..writeByte(2)
      ..write(obj.signature)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRecipeHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
