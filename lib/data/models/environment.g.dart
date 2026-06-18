// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnvironmentAdapter extends TypeAdapter<Environment> {
  @override
  final int typeId = 2;

  @override
  Environment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Environment(
      id: fields[0] as String?,
      name: fields[1] as String,
      variables: (fields[2] as Map?)?.cast<String, String>(),
      isActive: fields[3] as bool,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      syncAt: fields[6] as DateTime?,
      isDeleted: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Environment obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.variables)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.syncAt)
      ..writeByte(7)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
