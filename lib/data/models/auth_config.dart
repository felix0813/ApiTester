import 'package:hive/hive.dart';

part 'auth_config.g.dart';

enum AuthType { none, bearer, basic, apiKey }

@HiveType(typeId: 12)
class AuthConfig {
  @HiveField(0)
  final AuthType type;
  @HiveField(1)
  final String token;
  @HiveField(2)
  final String username;
  @HiveField(3)
  final String password;
  @HiveField(4)
  final String apiKey;
  @HiveField(5)
  final String apiKeyHeader;

  const AuthConfig({
    this.type = AuthType.none,
    this.token = '',
    this.username = '',
    this.password = '',
    this.apiKey = '',
    this.apiKeyHeader = 'X-API-Key',
  });

  AuthConfig copyWith({
    AuthType? type,
    String? token,
    String? username,
    String? password,
    String? apiKey,
    String? apiKeyHeader,
  }) {
    return AuthConfig(
      type: type ?? this.type,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
      apiKey: apiKey ?? this.apiKey,
      apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'token': token,
      'username': username,
      'password': password,
      'apiKey': apiKey,
      'apiKeyHeader': apiKeyHeader,
    };
  }

  factory AuthConfig.fromMap(Map<String, dynamic> map) {
    return AuthConfig(
      type: AuthType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AuthType.none,
      ),
      token: map['token'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      apiKey: map['apiKey'] ?? '',
      apiKeyHeader: map['apiKeyHeader'] ?? 'X-API-Key',
    );
  }
}
