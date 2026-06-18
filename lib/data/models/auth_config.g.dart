// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthConfigAdapter extends TypeAdapter<AuthConfig> {
  @override
  final int typeId = 12;

  @override
  AuthConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthConfig(
      type: fields[0] as AuthType,
      token: fields[1] as String,
      username: fields[2] as String,
      password: fields[3] as String,
      apiKey: fields[4] as String,
      apiKeyHeader: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuthConfig obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.token)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.apiKey)
      ..writeByte(5)
      ..write(obj.apiKeyHeader);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
