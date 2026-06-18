import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'environment.g.dart';

const _uuid = Uuid();

@HiveType(typeId: 2)
class Environment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  Map<String, String> variables;
  @HiveField(3)
  bool isActive;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  DateTime updatedAt;
  @HiveField(6)
  DateTime? syncAt;
  @HiveField(7)
  bool isDeleted;

  Environment({
    String? id,
    required this.name,
    Map<String, String>? variables,
    this.isActive = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncAt,
    this.isDeleted = false,
  })  : id = id ?? _uuid.v4(),
        variables = variables ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Environment copyWith({
    String? name,
    Map<String, String>? variables,
    bool? isActive,
    DateTime? syncAt,
    bool? isDeleted,
  }) {
    return Environment(
      id: id,
      name: name ?? this.name,
      variables: variables ?? Map<String, String>.from(this.variables),
      isActive: isActive ?? this.isActive,
      syncAt: syncAt ?? this.syncAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
