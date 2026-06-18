import 'package:hive/hive.dart';

part 'request_body.g.dart';

enum BodyType { json, formData }

@HiveType(typeId: 10)
class KeyValuePair {
  @HiveField(0)
  final String key;
  @HiveField(1)
  final String value;
  @HiveField(2)
  final bool enabled;

  const KeyValuePair({
    required this.key,
    this.value = '',
    this.enabled = true,
  });
}

@HiveType(typeId: 11)
class RequestBody {
  @HiveField(0)
  final BodyType type;
  @HiveField(1)
  final String jsonContent;
  @HiveField(2)
  final List<KeyValuePair> formFields;

  const RequestBody({
    this.type = BodyType.json,
    this.jsonContent = '{}',
    this.formFields = const [],
  });

  RequestBody copyWith({
    BodyType? type,
    String? jsonContent,
    List<KeyValuePair>? formFields,
  }) {
    return RequestBody(
      type: type ?? this.type,
      jsonContent: jsonContent ?? this.jsonContent,
      formFields: formFields ?? this.formFields,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'jsonContent': jsonContent,
      'formFields': formFields.map((f) => {
        'key': f.key,
        'value': f.value,
        'enabled': f.enabled,
      }).toList(),
    };
  }

  factory RequestBody.fromMap(Map<String, dynamic> map) {
    return RequestBody(
      type: BodyType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BodyType.json,
      ),
      jsonContent: map['jsonContent'] ?? '{}',
      formFields: (map['formFields'] as List?)
          ?.map((f) => KeyValuePair(
                key: f['key'] ?? '',
                value: f['value'] ?? '',
                enabled: f['enabled'] ?? true,
              ))
          .toList() ??
          [],
    );
  }
}
