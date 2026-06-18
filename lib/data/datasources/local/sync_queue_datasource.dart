import 'dart:convert';
import 'package:hive/hive.dart';

class SyncQueueItem {
  final String id;
  final String action;
  final String table;
  final String recordId;
  final String? data;
  final DateTime createdAt;

  SyncQueueItem({
    required this.id,
    required this.action,
    required this.table,
    required this.recordId,
    this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'action': action,
    'table': table,
    'recordId': recordId,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) => SyncQueueItem(
    id: map['id'],
    action: map['action'],
    table: map['table'],
    recordId: map['recordId'],
    data: map['data'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}

class SyncQueueDataSource {
  static const String _boxName = 'sync_queue';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  static Future<void> enqueue(SyncQueueItem item) async {
    final items = getAll();
    items.add(item);
    await _box.put('items', jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  static List<SyncQueueItem> getAll() {
    final raw = _box.get('items', defaultValue: '[]') as String;
    final list = jsonDecode(raw) as List;
    return list.map((e) => SyncQueueItem.fromMap(e)).toList();
  }

  static Future<void> remove(String id) async {
    final items = getAll();
    items.removeWhere((e) => e.id == id);
    await _box.put('items', jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  static Future<void> clear() async {
    await _box.put('items', '[]');
  }
}
