// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_body.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KeyValuePairAdapter extends TypeAdapter<KeyValuePair> {
  @override
  final int typeId = 10;

  @override
  KeyValuePair read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeyValuePair(
      key: fields[0] as String,
      value: fields[1] as String,
      enabled: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, KeyValuePair obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyValuePairAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RequestBodyAdapter extends TypeAdapter<RequestBody> {
  @override
  final int typeId = 11;

  @override
  RequestBody read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RequestBody(
      type: fields[0] as BodyType,
      jsonContent: fields[1] as String,
      formFields: (fields[2] as List).cast<KeyValuePair>(),
    );
  }

  @override
  void write(BinaryWriter writer, RequestBody obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.jsonContent)
      ..writeByte(2)
      ..write(obj.formFields);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestBodyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
