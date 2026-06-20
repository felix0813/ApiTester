// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CollectionTypeAdapter extends TypeAdapter<CollectionType> {
  @override
  final int typeId = 13;

  @override
  CollectionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CollectionType.folder;
      case 1:
        return CollectionType.request;
      default:
        return CollectionType.folder;
    }
  }

  @override
  void write(BinaryWriter writer, CollectionType obj) {
    switch (obj) {
      case CollectionType.folder:
        writer.writeByte(0);
        break;
      case CollectionType.request:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CollectionItemAdapter extends TypeAdapter<CollectionItem> {
  @override
  final int typeId = 1;

  @override
  CollectionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CollectionItem(
      id: fields[0] as String?,
      name: fields[1] as String,
      parentId: fields[2] as String?,
      childIds: (fields[3] as List?)?.cast<String>(),
      type: fields[4] as CollectionType,
      requestId: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      sortOrder: fields[8] as int,
      syncAt: fields[9] as DateTime?,
      isDeleted: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CollectionItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.childIds)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.requestId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.sortOrder)
      ..writeByte(9)
      ..write(obj.syncAt)
      ..writeByte(10)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
