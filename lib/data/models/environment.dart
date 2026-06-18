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

  Environment({
    String? id,
    required this.name,
    Map<String, String>? variables,
    this.isActive = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _uuid.v4(),
        variables = variables ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Environment copyWith({
    String? name,
    Map<String, String>? variables,
    bool? isActive,
  }) {
    return Environment(
      id: id,
      name: name ?? this.name,
      variables: variables ?? Map<String, String>.from(this.variables),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
