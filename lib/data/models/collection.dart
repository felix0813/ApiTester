import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'collection.g.dart';

const _uuid = Uuid();

enum CollectionType { folder, request }

@HiveType(typeId: 1)
class CollectionItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String? parentId;
  @HiveField(3)
  List<String> childIds;
  @HiveField(4)
  CollectionType type;
  @HiveField(5)
  String? requestId;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  DateTime updatedAt;
  @HiveField(8)
  int sortOrder;
  @HiveField(9)
  DateTime? syncAt;
  @HiveField(10)
  bool isDeleted;

  CollectionItem({
    String? id,
    required this.name,
    this.parentId,
    List<String>? childIds,
    this.type = CollectionType.folder,
    this.requestId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sortOrder = 0,
    this.syncAt,
    this.isDeleted = false,
  })  : id = id ?? _uuid.v4(),
        childIds = childIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isFolder => type == CollectionType.folder;
  bool get isRequest => type == CollectionType.request;

  CollectionItem copyWith({
    String? name,
    String? parentId,
    bool clearParentId = false,
    List<String>? childIds,
    CollectionType? type,
    String? requestId,
    bool clearRequestId = false,
    int? sortOrder,
    DateTime? syncAt,
    bool? isDeleted,
  }) {
    return CollectionItem(
      id: id,
      name: name ?? this.name,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      childIds: childIds ?? List<String>.from(this.childIds),
      type: type ?? this.type,
      requestId: clearRequestId ? null : (requestId ?? this.requestId),
      sortOrder: sortOrder ?? this.sortOrder,
      syncAt: syncAt ?? this.syncAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
