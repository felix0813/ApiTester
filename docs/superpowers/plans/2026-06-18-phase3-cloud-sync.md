# API Tester Phase 3 - 云同步 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phase 3 云同步 — Supabase 认证系统、云端数据同步、离线队列与冲突处理、跨设备数据一致性

**Architecture:** 4 个模块。P3-A 搭建 Supabase 基础设施和认证系统。P3-B 扩展本地数据模型以支持同步字段（syncAt, isDeleted），创建云端数据源。P3-C 实现核心同步引擎：增量同步、离线队列、Last Write Wins 冲突解决。P3-D 集成 UI：登录/注册页面、同步状态指示器、Profile 页显示用户信息。

**Tech Stack:** Flutter 3.x, Riverpod 2.x, supabase_flutter 2.x, Hive 2.x

**Supabase 配置前提：**
- 需要在 Supabase 项目中执行 TECHNICAL.md §3.2 的 SQL 建表脚本
- 需要获取 Supabase URL 和 anon key
- 本计划假设 Supabase 项目已就绪，代码中通过环境变量或硬编码配置

---

## 模块 P3-A：Supabase 基础设施 & 认证

### Task P3-A1: 添加 supabase_flutter 依赖

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 更新 pubspec.yaml**

在 `dependencies` 中添加：

```yaml
  supabase_flutter: ^2.8.4
  connectivity_plus: ^6.1.3
```

- [ ] **Step 2: 安装依赖**

```bash
cd G:/ApiTester && flutter pub get
```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add supabase_flutter and connectivity_plus dependencies"
```

---

### Task P3-A2: 创建 Supabase 配置常量

**Files:**
- Create: `lib/core/constants/supabase_config.dart`

- [ ] **Step 1: 创建 supabase_config.dart**

```dart
class SupabaseConfig {
  SupabaseConfig._();

  // TODO: Replace with your actual Supabase project credentials
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/constants/supabase_config.dart
git commit -m "feat: add Supabase configuration constants"
```

---

### Task P3-A3: 初始化 Supabase

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: 更新 main.dart 初始化 Supabase**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/supabase_config.dart';
import 'data/datasources/local/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  await LocalDatabase.init();
  runApp(const ProviderScope(child: ApiTesterApp()));
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize Supabase on app startup"
```

---

### Task P3-A4: 创建 AuthService

**Files:**
- Create: `lib/services/auth_service.dart`

- [ ] **Step 1: 创建 auth_service.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Whether user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.api-tester://login-callback/',
    );
  }

  /// Sign in with GitHub OAuth
  Future<bool> signInWithGitHub() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: 'io.supabase.api-tester://login-callback/',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/auth_service.dart
git commit -m "feat: add AuthService with email and OAuth support"
```

---

### Task P3-A5: 创建 Auth Provider

**Files:**
- Create: `lib/presentation/providers/auth_provider.dart`

- [ ] **Step 1: 创建 auth_provider.dart**

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user state
final currentUserProvider = StateProvider<User?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.currentUser;
});

/// Auth state stream
final authStateProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.authStateChanges;
});

/// Whether user is logged in
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/providers/auth_provider.dart
git commit -m "feat: add auth providers (user state, auth stream)"
```

---

### Task P3-A6: 创建登录/注册页面

**Files:**
- Create: `lib/presentation/screens/mobile/auth_screen.dart`

- [ ] **Step 1: 创建 auth_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      if (_isLogin) {
        await auth.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _signInWithGitHub() async {
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGitHub();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Sign In' : 'Sign Up'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // Password
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            // Submit button
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLogin ? 'Sign In' : 'Sign Up'),
            ),
            const SizedBox(height: 12),
            // Toggle login/signup
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin
                  ? "Don't have an account? Sign Up"
                  : 'Already have an account? Sign In'),
            ),
            const SizedBox(height: 32),
            // Divider
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            // OAuth buttons
            OutlinedButton.icon(
              onPressed: _signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 24),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _signInWithGitHub,
              icon: const Icon(Icons.code, size: 24),
              label: const Text('Continue with GitHub'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/mobile/auth_screen.dart
git commit -m "feat: add login/register screen with email and OAuth"
```

---

### Task P3-A7: 更新 Profile 页显示认证状态

**Files:**
- Modify: `lib/presentation/screens/mobile/profile_screen.dart`

- [ ] **Step 1: 修改 Account Card 区域**

将当前的 "Local Mode" placeholder 替换为动态认证状态：

1. 导入 auth_provider.dart
2. 监听 `currentUserProvider` 和 `isAuthenticatedProvider`
3. 已登录：显示用户邮箱/头像 + Sign Out 按钮
4. 未登录：显示 "Sign In" 按钮，点击跳转到 AuthScreen

```dart
import '../../providers/auth_provider.dart';
import '../mobile/auth_screen.dart';
```

在 build 方法中添加：
```dart
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
```

替换 Account Card：
```dart
          // Account section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isAuthenticated
                    ? Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Text(
                              (user?.email ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.email ?? '',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                const Text('Signed in',
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await ref.read(authServiceProvider).signOut();
                            },
                            child: const Text('Sign Out'),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              child: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Local Mode',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600)),
                                  Text('Sign in to sync your data',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
              ),
            ),
          ),
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/mobile/profile_screen.dart
git commit -m "feat: update profile screen with auth state and sign in/out"
```

---

## 模块 P3-B：数据模型扩展 & 云端数据源

### Task P3-B1: 扩展本地模型添加同步字段

**Files:**
- Modify: `lib/data/models/api_request.dart`
- Modify: `lib/data/models/collection.dart`
- Modify: `lib/data/models/environment.dart`

- [ ] **Step 1: 给 ApiRequest 添加 syncAt 和 isDeleted**

在 `api_request.dart` 中，在 `@HiveField(10) DateTime updatedAt;` 之后添加：

```dart
  @HiveField(11)
  DateTime? syncAt;
  @HiveField(12)
  bool isDeleted;
```

构造函数中添加：`this.syncAt, this.isDeleted = false,`

copyWith 中添加：
```dart
    DateTime? syncAt,
    bool? isDeleted,
```
并在返回值中使用：`syncAt: syncAt ?? this.syncAt, isDeleted: isDeleted ?? this.isDeleted,`

- [ ] **Step 2: 给 CollectionItem 添加 syncAt 和 isDeleted**

在 `collection.dart` 中，在 `@HiveField(8) int sortOrder;` 之后添加：

```dart
  @HiveField(9)
  DateTime? syncAt;
  @HiveField(10)
  bool isDeleted;
```

构造函数中添加：`this.syncAt, this.isDeleted = false,`

copyWith 中添加对应参数。

- [ ] **Step 3: 给 Environment 添加 syncAt 和 isDeleted**

在 `environment.dart` 中，在现有字段之后添加：

```dart
  @HiveField(6)
  DateTime? syncAt;
  @HiveField(7)
  bool isDeleted;
```

构造函数中添加：`this.syncAt, this.isDeleted = false,`

copyWith 中添加对应参数。

- [ ] **Step 4: 运行代码生成**

```bash
cd G:/ApiTester && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/api_request.dart lib/data/models/api_request.g.dart lib/data/models/collection.dart lib/data/models/collection.g.dart lib/data/models/environment.dart lib/data/models/environment.g.dart
git commit -m "feat: add syncAt and isDeleted fields to data models"
```

---

### Task P3-B2: 创建云端数据源

**Files:**
- Create: `lib/data/datasources/remote/supabase_request_datasource.dart`
- Create: `lib/data/datasources/remote/supabase_collection_datasource.dart`
- Create: `lib/data/datasources/remote/supabase_environment_datasource.dart`

- [ ] **Step 1: 创建 supabase_request_datasource.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/api_request.dart';

class SupabaseRequestDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  /// Fetch all requests for current user
  Future<List<ApiRequest>> getAll() async {
    final data = await _client
        .from('requests')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return data.map((json) => ApiRequest.fromMap({
      ...json,
      'id': json['id'],
      'headers': Map<String, String>.from(json['headers'] ?? {}),
      'queryParams': Map<String, String>.from(json['query_params'] ?? {}),
      'body': json['body'],
      'auth': json['auth'],
      'collectionId': json['collection_id'],
      'createdAt': json['created_at'],
      'updatedAt': json['updated_at'],
    })).toList();
  }

  /// Upsert a request (insert or update)
  Future<void> upsert(ApiRequest request) async {
    await _client.from('requests').upsert({
      'id': request.id,
      'user_id': _userId,
      'collection_id': request.collectionId,
      'name': request.name,
      'method': request.method,
      'url': request.url,
      'headers': request.headers,
      'query_params': request.queryParams,
      'body': request.body?.toMap(),
      'auth': request.auth?.toMap(),
      'created_at': request.createdAt.toIso8601String(),
      'updated_at': request.updatedAt.toIso8601String(),
    });
  }

  /// Soft delete a request
  Future<void> softDelete(String id) async {
    await _client.from('requests').update({
      'is_deleted': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Fetch changes since a timestamp (for incremental sync)
  Future<List<Map<String, dynamic>>> getChangesSince(DateTime since) async {
    return await _client
        .from('requests')
        .select()
        .eq('user_id', _userId)
        .gt('updated_at', since.toIso8601String())
        .order('updated_at');
  }
}
```

- [ ] **Step 2: 创建 supabase_collection_datasource.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/collection.dart';

class SupabaseCollectionDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<CollectionItem>> getAll() async {
    final data = await _client
        .from('collections')
        .select()
        .eq('user_id', _userId)
        .order('sort_order');

    return data.map((json) => CollectionItem(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      type: json['parent_id'] == null && json['sort_order'] != null
          ? CollectionType.folder
          : CollectionType.request,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    )).toList();
  }

  Future<void> upsert(CollectionItem item) async {
    await _client.from('collections').upsert({
      'id': item.id,
      'user_id': _userId,
      'name': item.name,
      'parent_id': item.parentId,
      'sort_order': item.sortOrder,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    });
  }

  Future<void> softDelete(String id) async {
    await _client.from('collections').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getChangesSince(DateTime since) async {
    return await _client
        .from('collections')
        .select()
        .eq('user_id', _userId)
        .gt('updated_at', since.toIso8601String())
        .order('updated_at');
  }
}
```

- [ ] **Step 3: 创建 supabase_environment_datasource.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/environment.dart';

class SupabaseEnvironmentDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Environment>> getAll() async {
    final data = await _client
        .from('environments')
        .select()
        .eq('user_id', _userId)
        .order('created_at');

    return data.map((json) => Environment(
      id: json['id'],
      name: json['name'],
      variables: Map<String, String>.from(json['variables'] ?? {}),
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    )).toList();
  }

  Future<void> upsert(Environment env) async {
    await _client.from('environments').upsert({
      'id': env.id,
      'user_id': _userId,
      'name': env.name,
      'variables': env.variables,
      'is_active': env.isActive,
      'created_at': env.createdAt.toIso8601String(),
      'updated_at': env.updatedAt.toIso8601String(),
    });
  }

  Future<void> softDelete(String id) async {
    await _client.from('environments').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getChangesSince(DateTime since) async {
    return await _client
        .from('environments')
        .select()
        .eq('user_id', _userId)
        .gt('updated_at', since.toIso8601String())
        .order('updated_at');
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/data/datasources/remote/
git commit -m "feat: add Supabase remote data sources for requests, collections, environments"
```

---

## 模块 P3-C：同步引擎

### Task P3-C1: 创建 SyncEngine

**Files:**
- Create: `lib/services/sync_engine.dart`

- [ ] **Step 1: 创建 sync_engine.dart**

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/local/local_database.dart';
import '../data/datasources/remote/supabase_request_datasource.dart';
import '../data/datasources/remote/supabase_collection_datasource.dart';
import '../data/datasources/remote/supabase_environment_datasource.dart';
import '../data/models/api_request.dart';
import '../data/models/collection.dart';
import '../data/models/environment.dart';

enum SyncStatus { idle, syncing, error, offline }

class SyncEngine {
  final SupabaseRequestDataSource _requestDS;
  final SupabaseCollectionDataSource _collectionDS;
  final SupabaseEnvironmentDataSource _environmentDS;

  SyncEngine({
    SupabaseRequestDataSource? requestDS,
    SupabaseCollectionDataSource? collectionDS,
    SupabaseEnvironmentDataSource? environmentDS,
  })  : _requestDS = requestDS ?? SupabaseRequestDataSource(),
        _collectionDS = collectionDS ?? SupabaseCollectionDataSource(),
        _environmentDS = environmentDS ?? SupabaseEnvironmentDataSource();

  /// Sync status stream
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Last sync timestamp
  DateTime? _lastSyncAt;

  /// Full sync: pull all from cloud and merge with local
  Future<void> fullSync() async {
    _statusController.add(SyncStatus.syncing);

    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        _statusController.add(SyncStatus.offline);
        return;
      }

      // Sync collections first (requests depend on them)
      await _syncCollections();
      await _syncRequests();
      await _syncEnvironments();

      _lastSyncAt = DateTime.now();
      _statusController.add(SyncStatus.idle);
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  /// Incremental sync: only pull changes since last sync
  Future<void> incrementalSync() async {
    if (_lastSyncAt == null) {
      return fullSync();
    }

    _statusController.add(SyncStatus.syncing);

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        _statusController.add(SyncStatus.offline);
        return;
      }

      await _syncCollectionsSince(_lastSyncAt!);
      await _syncRequestsSince(_lastSyncAt!);
      await _syncEnvironmentsSince(_lastSyncAt!);

      _lastSyncAt = DateTime.now();
      _statusController.add(SyncStatus.idle);
    } catch (e) {
      _statusController.add(SyncStatus.error);
      rethrow;
    }
  }

  /// Push local changes to cloud
  Future<void> pushLocalChanges() async {
    try {
      // Push unsynced requests
      final localRequests = LocalDatabase.requests.values
          .where((r) => r.syncAt == null || r.updatedAt.isAfter(r.syncAt!))
          .toList();
      for (final request in localRequests) {
        await _requestDS.upsert(request);
        request.syncAt = DateTime.now();
        await LocalDatabase.requests.put(request.id, request);
      }

      // Push unsynced collections
      final localCollections = LocalDatabase.collections.values
          .where((c) => c.syncAt == null || c.updatedAt.isAfter(c.syncAt!))
          .toList();
      for (final collection in localCollections) {
        await _collectionDS.upsert(collection);
        collection.syncAt = DateTime.now();
        await LocalDatabase.collections.put(collection.id, collection);
      }

      // Push unsynced environments
      final localEnvs = LocalDatabase.environments.values
          .where((e) => e.syncAt == null || e.updatedAt.isAfter(e.syncAt!))
          .toList();
      for (final env in localEnvs) {
        await _environmentDS.upsert(env);
        env.syncAt = DateTime.now();
        await LocalDatabase.environments.put(env.id, env);
      }
    } catch (e) {
      // Queue for retry later
      rethrow;
    }
  }

  Future<void> _syncCollections() async {
    final remoteItems = await _collectionDS.getAll();
    final localBox = LocalDatabase.collections;

    for (final remote in remoteItems) {
      final local = localBox.get(remote.id);
      if (local == null) {
        // New from cloud
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        // Cloud is newer — Last Write Wins
        await localBox.put(remote.id, remote.copyWith(
          childIds: local.childIds,
          requestId: local.requestId,
        ));
      }
    }
  }

  Future<void> _syncCollectionsSince(DateTime since) async {
    final changes = await _collectionDS.getChangesSince(since);
    final localBox = LocalDatabase.collections;

    for (final json in changes) {
      final remote = CollectionItem(
        id: json['id'],
        name: json['name'],
        parentId: json['parent_id'],
        sortOrder: json['sort_order'] ?? 0,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote.copyWith(
          childIds: local.childIds,
          requestId: local.requestId,
        ));
      }
    }
  }

  Future<void> _syncRequests() async {
    final remoteItems = await _requestDS.getAll();
    final localBox = LocalDatabase.requests;

    for (final remote in remoteItems) {
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote);
      }
    }
  }

  Future<void> _syncRequestsSince(DateTime since) async {
    final changes = await _requestDS.getChangesSince(since);
    final localBox = LocalDatabase.requests;

    for (final json in changes) {
      final remote = ApiRequest.fromMap({
        ...json,
        'headers': Map<String, String>.from(json['headers'] ?? {}),
        'queryParams': Map<String, String>.from(json['query_params'] ?? {}),
        'body': json['body'],
        'auth': json['auth'],
        'collectionId': json['collection_id'],
        'createdAt': json['created_at'],
        'updatedAt': json['updated_at'],
      });
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote);
      }
    }
  }

  Future<void> _syncEnvironments() async {
    final remoteItems = await _environmentDS.getAll();
    final localBox = LocalDatabase.environments;

    for (final remote in remoteItems) {
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote);
      }
    }
  }

  Future<void> _syncEnvironmentsSince(DateTime since) async {
    final changes = await _environmentDS.getChangesSince(since);
    final localBox = LocalDatabase.environments;

    for (final json in changes) {
      final remote = Environment(
        id: json['id'],
        name: json['name'],
        variables: Map<String, String>.from(json['variables'] ?? {}),
        isActive: json['is_active'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
      final local = localBox.get(remote.id);
      if (local == null) {
        await localBox.put(remote.id, remote);
      } else if (remote.updatedAt.isAfter(local.updatedAt)) {
        await localBox.put(remote.id, remote);
      }
    }
  }

  void dispose() {
    _statusController.close();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/sync_engine.dart
git commit -m "feat: add SyncEngine with full/incremental sync and LWW conflict resolution"
```

---

### Task P3-C2: 创建 SyncProvider

**Files:**
- Create: `lib/presentation/providers/sync_provider.dart`

- [ ] **Step 1: 创建 sync_provider.dart**

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../services/sync_engine.dart';
import 'auth_provider.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine();
});

final syncStatusProvider = StateProvider<SyncStatus>((ref) {
  return SyncStatus.idle;
});

/// Auto-sync when user is logged in and connectivity changes
final autoSyncProvider = Provider<void>((ref) {
  final auth = ref.watch(authStateProvider);
  final syncEngine = ref.watch(syncEngineProvider);

  auth.whenData((authState) {
    if (authState.event == AuthChangeEvent.signedIn) {
      // User just signed in — do full sync
      syncEngine.fullSync().catchError((_) {});
    }
  });

  // Listen to connectivity changes
  Connectivity().onConnectivityChanged.listen((results) {
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      syncEngine.incrementalSync().catchError((_) {});
    }
  });
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/providers/sync_provider.dart
git commit -m "feat: add sync providers with auto-sync on login and connectivity"
```

---

### Task P3-C3: 创建离线队列

**Files:**
- Create: `lib/data/datasources/local/sync_queue_datasource.dart`
- Modify: `lib/data/datasources/local/local_database.dart`

- [ ] **Step 1: 创建 sync_queue_datasource.dart**

```dart
import 'dart:convert';
import 'package:hive/hive.dart';
import 'local_database.dart';

class SyncQueueItem {
  final String id;
  final String action; // 'create' | 'update' | 'delete'
  final String table;  // 'requests' | 'collections' | 'environments'
  final String recordId;
  final String? data; // JSON serialized data
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

  /// Add an action to the sync queue
  static Future<void> enqueue(SyncQueueItem item) async {
    final items = getAll();
    items.add(item);
    await _box.put('items', jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  /// Get all pending items
  static List<SyncQueueItem> getAll() {
    final raw = _box.get('items', defaultValue: '[]') as String;
    final list = jsonDecode(raw) as List;
    return list.map((e) => SyncQueueItem.fromMap(e)).toList();
  }

  /// Remove an item after successful sync
  static Future<void> remove(String id) async {
    final items = getAll();
    items.removeWhere((e) => e.id == id);
    await _box.put('items', jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  /// Clear all items
  static Future<void> clear() async {
    await _box.put('items', '[]');
  }
}
```

- [ ] **Step 2: 在 local_database.dart 中初始化 sync queue**

在 `init()` 方法中，在打开 settings box 之后添加：

```dart
    await Hive.openBox('sync_queue');
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/datasources/local/sync_queue_datasource.dart lib/data/datasources/local/local_database.dart
git commit -m "feat: add SyncQueueDataSource for offline action queue"
```

---

## 模块 P3-D：UI 集成 & 路由更新

### Task P3-D1: 更新路由添加认证流程

**Files:**
- Modify: `lib/router/mobile_router.dart`

- [ ] **Step 1: 更新 mobile_router.dart 添加 auth 路由和重定向**

```dart
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/screens/mobile/shell_screen.dart';
import '../presentation/screens/mobile/request_screen.dart';
import '../presentation/screens/mobile/collection_screen.dart';
import '../presentation/screens/mobile/environment_screen.dart';
import '../presentation/screens/mobile/profile_screen.dart';
import '../presentation/screens/mobile/auth_screen.dart';

final mobileRouter = GoRouter(
  initialLocation: '/request',
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/auth';

    // If not logged in and not on auth page, redirect to auth
    if (!isLoggedIn && !isAuthRoute) {
      return '/auth';
    }

    // If logged in and on auth page, redirect to request
    if (isLoggedIn && isAuthRoute) {
      return '/request';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/request',
              builder: (context, state) => const RequestScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/collections',
              builder: (context, state) => const CollectionScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/environments',
              builder: (context, state) => const EnvironmentScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

注意：这个重定向方案会在用户未登录时强制跳转到登录页。如果希望支持离线使用（未登录也能用本地功能），可以改为只在同步时检查登录状态。

- [ ] **Step 2: Commit**

```bash
git add lib/router/mobile_router.dart
git commit -m "feat: add auth route and login redirect to mobile router"
```

---

### Task P3-D2: 同步状态指示器组件

**Files:**
- Create: `lib/presentation/widgets/sync_status_indicator.dart`

- [ ] **Step 1: 创建 sync_status_indicator.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../../services/sync_engine.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);

    IconData icon;
    Color color;
    String tooltip;

    switch (syncStatus) {
      case SyncStatus.idle:
        icon = Icons.cloud_done_outlined;
        color = Colors.green;
        tooltip = 'Synced';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = 'Syncing...';
        break;
      case SyncStatus.error:
        icon = Icons.cloud_off_outlined;
        color = Colors.red;
        tooltip = 'Sync error';
        break;
      case SyncStatus.offline:
        icon = Icons.wifi_off_outlined;
        color = Colors.grey;
        tooltip = 'Offline';
        break;
    }

    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      onPressed: () {
        ref.read(syncEngineProvider).incrementalSync();
      },
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/sync_status_indicator.dart
git commit -m "feat: add SyncStatusIndicator widget"
```

---

### Task P3-D3: 在 ShellScreen 添加同步状态

**Files:**
- Modify: `lib/presentation/screens/mobile/shell_screen.dart`

- [ ] **Step 1: 在 AppBar 中添加 SyncStatusIndicator**

```dart
import '../../widgets/sync_status_indicator.dart';
```

在 Scaffold 的 AppBar 中添加 actions：
```dart
      appBar: AppBar(
        title: const Text('API Tester'),
        actions: const [
          SyncStatusIndicator(),
        ],
      ),
```

注意：需要确认 ShellScreen 当前是否有 AppBar。如果没有，需要在 body 外层包裹一个带 AppBar 的结构。查看当前 ShellScreen —— 它使用 `navigationShell` 作为 body，没有 AppBar。需要将结构改为：

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Tester'),
        actions: const [
          SyncStatusIndicator(),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        // ... existing code
      ),
    );
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/mobile/shell_screen.dart
git commit -m "feat: add sync status indicator to app bar"
```

---

### Task P3-D4: 启动时自动同步

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: 在 main.dart 中注册 auto-sync**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/supabase_config.dart';
import 'data/datasources/local/local_database.dart';
import 'data/datasources/local/sync_queue_datasource.dart';
import 'presentation/providers/sync_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  await LocalDatabase.init();
  await SyncQueueDataSource.init();

  runApp(const ProviderScope(child: ApiTesterApp()));
}
```

注意：`autoSyncProvider` 在 `sync_provider.dart` 中已定义，会在用户登录后自动触发同步。不需要在 main.dart 中手动调用，因为 Riverpod 会在 Provider 被读取时自动初始化。

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize sync queue on startup"
```

---

## 模块 P3-E：构建验证

### Task P3-E1: 全部验证

- [ ] **Step 1: Run analysis**

```bash
cd G:/ApiTester && flutter analyze
```

Expected: No errors (info-level warnings acceptable).

- [ ] **Step 2: Run tests**

```bash
cd G:/ApiTester && flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Commit any remaining changes**

```bash
git add -A
git commit -m "chore: finalize Phase 3 build"
```

---

### Task P3-E2: 手动验证清单

**认证 (P3-A):**
- [ ] 应用启动后未登录时跳转到登录页
- [ ] 可以用邮箱+密码注册新账号
- [ ] 可以用邮箱+密码登录
- [ ] 可以用 Google OAuth 登录
- [ ] 可以用 GitHub OAuth 登录
- [ ] 登录后跳转到请求页面
- [ ] Profile 页显示用户邮箱和 Sign Out 按钮
- [ ] Sign Out 后返回登录页

**数据同步 (P3-B/C):**
- [ ] 登录后本地集合自动同步到云端
- [ ] 登录后本地环境变量自动同步到云端
- [ ] 在另一设备登录同一账号，能看到同步的集合
- [ ] 修改集合后同步到云端
- [ ] 断网时操作不报错
- [ ] 恢复网络后自动同步
- [ ] AppBar 显示同步状态图标

**离线队列 (P3-C):**
- [ ] 断网时创建的集合在恢复网络后自动同步
- [ ] 断网时修改的请求在恢复网络后自动同步

---

## 实现顺序

1. **P3-A1**: 添加 supabase_flutter 依赖
2. **P3-A2**: 创建 Supabase 配置常量
3. **P3-A3**: 初始化 Supabase
4. **P3-A4**: 创建 AuthService
5. **P3-A5**: 创建 Auth Provider
6. **P3-A6**: 创建登录/注册页面
7. **P3-A7**: 更新 Profile 页显示认证状态
8. **P3-B1**: 扩展本地模型添加同步字段
9. **P3-B2**: 创建云端数据源
10. **P3-C1**: 创建 SyncEngine
11. **P3-C2**: 创建 SyncProvider
12. **P3-C3**: 创建离线队列
13. **P3-D1**: 更新路由添加认证流程
14. **P3-D2**: 同步状态指示器组件
15. **P3-D3**: 在 ShellScreen 添加同步状态
16. **P3-D4**: 启动时自动同步
17. **P3-E1**: 自动化验证
18. **P3-E2**: 手动验证清单
