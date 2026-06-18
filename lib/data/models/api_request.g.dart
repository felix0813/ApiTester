// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_request.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiRequestAdapter extends TypeAdapter<ApiRequest> {
  @override
  final int typeId = 0;

  @override
  ApiRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiRequest(
      id: fields[0] as String?,
      name: fields[1] as String,
      method: fields[2] as String,
      url: fields[3] as String,
      headers: (fields[4] as Map?)?.cast<String, String>(),
      queryParams: (fields[5] as Map?)?.cast<String, String>(),
      body: fields[6] as RequestBody?,
      auth: fields[7] as AuthConfig?,
      collectionId: fields[8] as String?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ApiRequest obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.method)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.headers)
      ..writeByte(5)
      ..write(obj.queryParams)
      ..writeByte(6)
      ..write(obj.body)
      ..writeByte(7)
      ..write(obj.auth)
      ..writeByte(8)
      ..write(obj.collectionId)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiRequestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
