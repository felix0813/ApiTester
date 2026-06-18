// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 3;

  @override
  HistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntry(
      id: fields[0] as String?,
      method: fields[1] as String,
      url: fields[2] as String,
      statusCode: fields[3] as int?,
      durationMs: fields[4] as int,
      bodySize: fields[5] as int,
      sentAt: fields[6] as DateTime?,
      requestSnapshot: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.method)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.statusCode)
      ..writeByte(4)
      ..write(obj.durationMs)
      ..writeByte(5)
      ..write(obj.bodySize)
      ..writeByte(6)
      ..write(obj.sentAt)
      ..writeByte(7)
      ..write(obj.requestSnapshot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
