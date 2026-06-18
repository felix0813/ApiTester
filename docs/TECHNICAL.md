# API Tester - 技术文档

## 1. 技术选型

### 1.1 核心框架

| 层级       | 技术                          | 版本   | 说明                        |
| -------- | --------------------------- | ---- | ------------------------- |
| UI 框架    | Flutter                     | 3.x  | 跨平台 UI                    |
| 状态管理     | Riverpod                    | 2.x  | 响应式状态管理，支持代码生成            |
| 路由       | GoRouter                    | 14.x | 声明式路由，支持深链接               |
| HTTP 客户端 | Dio                         | 5.x  | 拦截器、取消请求、进度回调             |
| 本地存储     | Hive                        | 2.x  | 高性能 NoSQL，支持加密            |
| 云数据库     | Supabase (PostgreSQL)       | 2.x  | 国内可用，实时订阅，可自部署            |
| 认证       | Supabase Auth               | -    | 邮箱 + OAuth（Google/GitHub） |
| 代码生成     | Freezed + json_serializable | -    | 不可变数据模型                   |

### 1.2 平台特定

| 平台      | 技术                            |
| ------- | ----------------------------- |
| Android | Kotlin 原生桥接（文件选择、分享）          |
| Windows | Win32 API 桥接（托盘、自更新）          |
| 文件选择    | `file_picker`                 |
| 本地通知    | `flutter_local_notifications` |

---

## 2. 架构设计

### 2.1 分层架构

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                       │
│   Screens (mobile/desktop)  +  Widgets          │
├─────────────────────────────────────────────────┤
│               Presentation Layer                │
│   Riverpod Providers (StateNotifier/AsyncNotifier)│
├─────────────────────────────────────────────────┤
│                 Domain Layer                    │
│   Use Cases  +  Repository Interfaces           │
├─────────────────────────────────────────────────┤
│                  Data Layer                     │
│   LocalDataSource  +  RemoteDataSource          │
│   (Hive/Supabase)   (Supabase REST/Realtime)   │
└─────────────────────────────────────────────────┘
```

### 2.2 数据流

```
用户操作
    │
    ▼
Screen (Flutter Widget)
    │
    ▼
Provider (触发 Action)
    │
    ▼
Repository (协调数据源)
    ├──────────────────┐
    ▼                  ▼
LocalDataSource    RemoteDataSource
    │                  │
    ▼                  ▼
  Hive            Supabase
```

### 2.3 平台适配策略

```
lib/
├── screens/
│   ├── shared/          # 共享页面逻辑
│   ├── mobile/          # Android 专属 Widget
│   └── desktop/         # Windows 专属 Widget
├── widgets/
│   ├── common/          # 通用组件
│   ├── mobile/          # 移动端组件
│   └── desktop/         # 桌面端组件
└── router/
    ├── mobile_router.dart
    └── desktop_router.dart
```

判断平台：

```dart
// 统一入口，根据平台加载不同路由
final router = Platform.isAndroid ? mobileRouter : desktopRouter;
```

---

## 3. 数据库设计

### 3.1 本地存储 (Hive)

#### requests箱

```dart
@HiveType(typeId: 0)
class RequestHive {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String method;
  @HiveField(3) String url;
  @HiveField(4) Map<String, String> headers;
  @HiveField(5) Map<String, String> queryParams;
  @HiveField(6) RequestBodyHive? body;
  @HiveField(7) AuthConfigHive? auth;
  @HiveField(8) String? collectionId;
  @HiveField(9) DateTime createdAt;
  @HiveField(10) DateTime updatedAt;
  @HiveField(11) DateTime? syncAt;       // 最后同步时间
  @HiveField(12) bool isDeleted;         // 软删除标记
}
```

#### collections箱

```dart
@HiveType(typeId: 1)
class CollectionHive {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String? parentId;
  @HiveField(3) List<String> childIds;
  @HiveField(4) DateTime createdAt;
  @HiveField(5) DateTime updatedAt;
  @HiveField(6) DateTime? syncAt;
  @HiveField(7) bool isDeleted;
}
```

#### environments箱

```dart
@HiveType(typeId: 2)
class EnvironmentHive {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) Map<String, String> variables;
  @HiveField(3) bool isActive;
  @HiveField(4) DateTime createdAt;
  @HiveField(5) DateTime updatedAt;
  @HiveField(6) DateTime? syncAt;
  @HiveField(7) bool isDeleted;
}
```

#### history箱

```dart
@HiveType(typeId: 3)
class HistoryHive {
  @HiveField(0) String id;
  @HiveField(1) String requestId;
  @HiveField(2) String method;
  @HiveField(3) String url;
  @HiveField(4) int? statusCode;
  @HiveField(5) int durationMs;
  @HiveField(6) int bodySize;
  @HiveField(7) DateTime sentAt;
  @HiveField(8) bool syncToCloud;        // 是否已同步
}
```

### 3.2 云端数据模型 (Supabase / PostgreSQL)

#### 表结构

```sql
-- 用户表（Supabase Auth 自动管理 auth.users，此表扩展 profile 信息）
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 集合表
CREATE TABLE collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  parent_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 请求表
CREATE TABLE requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  collection_id UUID REFERENCES collections(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  method TEXT NOT NULL DEFAULT 'GET',
  url TEXT NOT NULL DEFAULT '',
  headers JSONB DEFAULT '{}',
  query_params JSONB DEFAULT '{}',
  body JSONB,
  auth JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 环境变量表
CREATE TABLE environments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  variables JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 同步日志表（用于增量同步）
CREATE TABLE sync_log (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  action TEXT NOT NULL,  -- 'INSERT' | 'UPDATE' | 'DELETE'
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 索引
CREATE INDEX idx_collections_user ON collections(user_id);
CREATE INDEX idx_collections_parent ON collections(parent_id);
CREATE INDEX idx_requests_user ON requests(user_id);
CREATE INDEX idx_requests_collection ON requests(collection_id);
CREATE INDEX idx_environments_user ON environments(user_id);
CREATE INDEX idx_sync_log_user_time ON sync_log(user_id, created_at);

-- RLS（Row Level Security）策略
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE environments ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "用户只能操作自己的数据" ON collections
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "用户只能操作自己的数据" ON requests
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "用户只能操作自己的数据" ON environments
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "用户只能操作自己的数据" ON sync_log
  FOR ALL USING (auth.uid() = user_id);

-- updated_at 自动更新触发器
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_collections_updated
  BEFORE UPDATE ON collections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_requests_updated
  BEFORE UPDATE ON requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_environments_updated
  BEFORE UPDATE ON environments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

#### Supabase Flutter 集成

```dart
// 初始化
final supabase = Supabase.instance.client;

// 认证
await supabase.auth.signUp(email: email, password: password);
await supabase.auth.signInWithPassword(email: email, password: password);

// 数据操作
final requests = await supabase
    .from('requests')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);

// 实时订阅（变更推送）
supabase
    .from('requests')
    .stream(primaryKey: ['id'])
    .eq('user_id', userId)
    .listen((data) {
      // 处理实时变更
    });

// 插入
await supabase.from('requests').insert({
  'user_id': userId,
  'name': 'My Request',
  'method': 'GET',
  'url': 'https://api.example.com',
});

// 更新
await supabase
    .from('requests')
    .update({'name': 'Updated'})
    .eq('id', requestId);

// 删除
await supabase.from('requests').delete().eq('id', requestId);
```

---

## 4. 同步协议

### 4.1 同步流程

```
          App 启动 / 恢复前台
               │
               ▼
      ┌─── 获取上次同步时间戳 ───┐
      │                          │
      ▼                          ▼
  拉取云端变更               推送本地变更
  (SELECT from sync_log     (INSERT into sync_log
   WHERE created_at > last)  + 操作数据表)
      │                          │
      ▼                          ▼
  合并到本地 Hive          更新本地 syncAt
```

#### 增量同步实现

```dart
class SupabaseSyncEngine {
  final SupabaseClient _client;
  final HiveSyncQueue _queue;

  // 拉取云端增量变更
  Future<List<SyncAction>> pullChanges(DateTime since) async {
    final logs = await _client
        .from('sync_log')
        .select()
        .eq('user_id', currentUser.id)
        .gt('created_at', since.toIso8601String())
        .order('created_at');

    return logs.map((log) => SyncAction(
      table: log['table_name'],
      recordId: log['record_id'],
      action: log['action'],
      timestamp: DateTime.parse(log['created_at']),
    )).toList();
  }

  // 推送本地变更到云端
  Future<void> pushChanges(List<SyncAction> localChanges) async {
    for (final action in localChanges) {
      await _client.from('sync_log').insert({
        'user_id': currentUser.id,
        'table_name': action.table,
        'record_id': action.recordId,
        'action': action.action,
      });
    }
  }

  // 全量同步（首次登录或冲突严重时）
  Future<void> fullSync() async {
    final localData = await _localStore.getAll();
    final remoteData = await _fetchAllFromCloud();

    final merged = _mergeData(localData, remoteData);
    await _localStore.saveAll(merged);
    await _pushAllToCloud(merged);
  }
}
```

### 4.2 冲突解决

- **策略**：Last Write Wins（以 `updatedAt` 较新的为准）
- **标记**：冲突数据在 UI 上显示黄色提示，用户可手动选择版本
- **实现**：

```dart
// 冲突检测
if (local.updatedAt.isAfter(remote.updatedAt)) {
  // 本地优先，推送覆盖
  await pushToCloud(local);
} else if (remote.updatedAt.isAfter(local.updatedAt)) {
  // 云端优先，覆盖本地
  await saveToLocal(remote);
} else {
  // 时间戳相同，保留本地（极少发生）
}
```

### 4.3 离线队列

```dart
class SyncQueue {
  // 本地维护操作队列
  // 格式: [{ action: 'create'|'update'|'delete', type: 'request'|'collection', data: {...}, timestamp }]

  Future<void> enqueue(SyncAction action);
  Future<List<SyncAction>> getPendingActions();
  Future<void> markSynced(String actionId);
  Future<void> clearSynced();
}
```

---

## 5. HTTP 引擎

### 5.1 Dio 配置

```dart
final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(seconds: 10),
));

// 拦截器链
dio.interceptors.addAll([
  AuthInterceptor(),        // 注入 Token
  LogInterceptor(),         // 请求/响应日志
  RetryInterceptor(),       // 失败重试
  CacheInterceptor(),       // 响应缓存
]);
```

### 5.2 请求取消

```dart
// 支持用户手动取消进行中的请求
final cancelToken = CancelToken();
dio.get(url, cancelToken: cancelToken);

// 用户点击取消
onCancelPressed: () => cancelToken.cancel('User cancelled');
```

### 5.3 进度监听

```dart
dio.post(
  url,
  data: formData,
  onSendProgress: (sent, total) {
    // 更新发送进度条
    progressNotifier.update(sent / total);
  },
  onReceiveProgress: (received, total) {
    // 更新接收进度条
  },
);
```

---

## 6. 路由设计

### 6.1 Android 路由结构

```
/                        → 底部导航壳
├── /requests            → 快速请求（Tab 1）
├── /collections         → 集合列表（Tab 2）
│   └── /collections/:id → 集合详情/编辑
├── /environments        → 环境管理（Tab 3）
│   └── /environments/:id → 环境编辑
└── /profile             → 我的（Tab 4）
    ├── /profile/settings
    ├── /profile/sync
    └── /profile/about
```

### 6.2 Windows 路由结构

```
/                        → 侧边栏 + 内容区壳
├── /request/new         → 新建请求
├── /request/:id         → 编辑请求
├── /collections         → 集合树
├── /environments        → 环境管理
├── /settings            → 设置
└── /sync                → 同步状态
```

---

## 7. 关键接口

### 7.1 Repository 接口

```dart
abstract class RequestRepository {
  Future<List<ApiRequest>> getAll();
  Future<ApiRequest?> getById(String id);
  Future<void> save(ApiRequest request);
  Future<void> delete(String id);
  Stream<List<ApiRequest>> watchAll();  // 实时监听变更
}

abstract class CollectionRepository {
  Future<List<Collection>> getRootCollections();
  Future<List<Collection>> getChildren(String parentId);
  Future<void> save(Collection collection);
  Future<void> delete(String id);
}

abstract class SyncRepository {
  Future<SyncStatus> getStatus();
  Future<void> syncNow();
  Stream<SyncStatus> watchStatus();
}

enum SyncStatus { idle, syncing, error, conflict }
```

### 7.2 网络层接口

```dart
abstract class HttpEngine {
  Future<HttpResponse> send(ApiRequest request, {CancelToken? cancelToken});
  Stream<double> watchProgress();
}

class HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final Duration duration;
  final int bodySize;
}
```

---

## 8. 安全方案

### 8.1 数据加密

| 数据         | 加密方式                                                 |
| ---------- | ---------------------------------------------------- |
| 本地请求数据     | Hive AEAD 加密（AES-256-GCM）                            |
| Auth Token | 系统 Keychain (Android) / Credential Manager (Windows) |
| 云端传输       | TLS 1.3 (Supabase 内置)                                |

### 8.2 Token 存储

```
Android: EncryptedSharedPreferences / Android Keystore
Windows: DPAPI (Data Protection API)
```

### 8.3 敏感信息处理

- 历史记录中 Body 包含 Token 时，仅存储 hash，不存储明文
- 导出集合时，可选是否包含敏感 Header
- 日志输出中自动脱敏 Authorization Header

---

## 9. 状态管理结构

```
providers/
├── request_providers.dart
│   ├── currentRequestProvider    → StateNotifier<ApiRequest?>
│   ├── requestListProvider       → AsyncNotifier<List<ApiRequest>>
│   └── sendRequestProvider      → FutureProvider<HttpResponse>
├── collection_providers.dart
│   ├── collectionTreeProvider    → AsyncNotifier<List<Collection>>
│   └── currentCollectionProvider → StateNotifier<Collection?>
├── environment_providers.dart
│   ├── environmentListProvider   → AsyncNotifier<List<Environment>>
│   └── activeEnvironmentProvider → StateNotifier<Environment?>
├── sync_providers.dart
│   ├── syncStatusProvider        → StreamProvider<SyncStatus>
│   └── syncTriggerProvider      → StateNotifier<bool>
└── history_providers.dart
    └── historyListProvider       → AsyncNotifier<List<History>>
```

---

## 10. 目录结构总览

```
api_tester/
├── lib/
│   ├── main.dart                    # 入口
│   ├── app.dart                     # MaterialApp 配置
│   ├── core/
│   │   ├── constants/               # 常量定义
│   │   ├── di/                      # 依赖注入（Riverpod modules）
│   │   ├── theme/                   # 主题配置
│   │   ├── utils/                   # 工具类
│   │   └── extensions/              # Dart 扩展方法
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/               # Hive 数据源
│   │   │   └── remote/              # Supabase 数据源
│   │   ├── models/                  # 数据模型（Freezed 生成）
│   │   └── repositories/            # Repository 实现
│   ├── domain/
│   │   ├── entities/                # 业务实体
│   │   ├── repositories/            # Repository 接口
│   │   └── usecases/                # 用例
│   ├── presentation/
│   │   ├── providers/               # Riverpod Providers
│   │   ├── screens/
│   │   │   ├── mobile/              # Android 页面
│   │   │   └── desktop/             # Windows 页面
│   │   └── widgets/                 # UI 组件
│   ├── services/
│   │   ├── http_engine.dart         # HTTP 请求引擎
│   │   ├── sync_engine.dart         # 同步引擎
│   │   └── auth_service.dart        # 认证服务
│   └── router/
│       ├── mobile_router.dart
│       └── desktop_router.dart
├── android/
├── windows/
├── test/
└── pubspec.yaml
```
