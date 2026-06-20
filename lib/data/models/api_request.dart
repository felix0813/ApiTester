import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'request_body.dart';
import 'auth_config.dart';

part 'api_request.g.dart';

const _uuid = Uuid();

@HiveType(typeId: 0)
class ApiRequest {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String method;
  @HiveField(3)
  String url;
  @HiveField(4)
  Map<String, String> headers;
  @HiveField(5)
  Map<String, String> queryParams;
  @HiveField(6)
  RequestBody? body;
  @HiveField(7)
  AuthConfig? auth;
  @HiveField(8)
  String? collectionId;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  DateTime updatedAt;
  @HiveField(11)
  DateTime? syncAt;
  @HiveField(12)
  bool isDeleted;
  @HiveField(13)
  String preRequestScript;
  @HiveField(14)
  String testsScript;

  ApiRequest({
    String? id,
    this.name = 'Untitled Request',
    this.method = 'GET',
    this.url = '',
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    this.body,
    this.auth,
    this.collectionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncAt,
    this.isDeleted = false,
    this.preRequestScript = '',
    this.testsScript = '',
  })  : id = id ?? _uuid.v4(),
        headers = headers ?? {},
        queryParams = queryParams ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ApiRequest copyWith({
    String? name,
    String? method,
    String? url,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    RequestBody? body,
    AuthConfig? auth,
    String? collectionId,
    bool clearCollectionId = false,
    bool clearBody = false,
    bool clearAuth = false,
    DateTime? syncAt,
    bool? isDeleted,
    String? preRequestScript,
    String? testsScript,
  }) {
    return ApiRequest(
      id: id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? Map<String, String>.from(this.headers),
      queryParams: queryParams ?? Map<String, String>.from(this.queryParams),
      body: clearBody ? null : (body ?? this.body),
      auth: clearAuth ? null : (auth ?? this.auth),
      collectionId: clearCollectionId ? null : (collectionId ?? this.collectionId),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      syncAt: syncAt ?? this.syncAt,
      isDeleted: isDeleted ?? this.isDeleted,
      preRequestScript: preRequestScript ?? this.preRequestScript,
      testsScript: testsScript ?? this.testsScript,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'method': method,
      'url': url,
      'headers': headers,
      'queryParams': queryParams,
      'body': body?.toMap(),
      'auth': auth?.toMap(),
      'collectionId': collectionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ApiRequest.fromMap(Map<String, dynamic> map) {
    return ApiRequest(
      id: map['id'],
      name: map['name'] ?? 'Untitled Request',
      method: map['method'] ?? 'GET',
      url: map['url'] ?? '',
      headers: Map<String, String>.from(map['headers'] ?? {}),
      queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
      body: map['body'] != null ? RequestBody.fromMap(map['body']) : null,
      auth: map['auth'] != null ? AuthConfig.fromMap(map['auth']) : null,
      collectionId: map['collectionId'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
