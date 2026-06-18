import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'history_entry.g.dart';

const _uuid = Uuid();

@HiveType(typeId: 3)
class HistoryEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String method;
  @HiveField(2)
  final String url;
  @HiveField(3)
  final int? statusCode;
  @HiveField(4)
  final int durationMs;
  @HiveField(5)
  final int bodySize;
  @HiveField(6)
  final DateTime sentAt;
  @HiveField(7)
  final String? requestSnapshot;

  HistoryEntry({
    String? id,
    required this.method,
    required this.url,
    this.statusCode,
    this.durationMs = 0,
    this.bodySize = 0,
    DateTime? sentAt,
    this.requestSnapshot,
  })  : id = id ?? _uuid.v4(),
        sentAt = sentAt ?? DateTime.now();
}
