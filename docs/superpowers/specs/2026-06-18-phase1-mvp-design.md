# API Tester - Phase 1 MVP 设计文档

**日期**: 2026-06-18
**版本**: 1.0
**状态**: 已确认

---

## 1. 概述

实现 API Tester Phase 1 MVP，覆盖 HTTP 请求编辑器、响应展示、集合管理（基础）、环境变量、历史记录和 Android 平台适配。所有数据本地存储在 Hive 中。Supabase 相关功能暂不实现，但保留数据模型扩展点。

## 2. 架构

### 2.1 分层架构

```
UI Layer         → screens/ + widgets/        (Flutter Widget)
Presentation     → providers/                 (Riverpod)
Domain           → repositories/ (抽象接口)    (抽象类)
Data             → datasources/local/          (Hive 实现)
Services         → http_engine.dart            (Dio)
```

### 2.2 数据流

```
用户编辑请求 → Provider 管理状态
     ↓
用户点击发送 → Provider 调 HttpEngine.send()
     ↓
HttpEngine 通过 Dio 发送 HTTP 请求 → 返回 ApiResponse
     ↓
Provider 更新响应状态 → UI 渲染响应
     ↓
同时写入 History Hive box（自动保存）
```

## 3. Phase 1 实现范围

| 模块         | 功能点                                                                             |
|------------|---------------------------------------------------------------------------------|
| HTTP 引擎    | GET/POST/PUT/DELETE/PATCH/HEAD/OPTIONS, Dio 封装, 超时配置, 取消请求                      |
| 请求编辑器      | 方法选择器(颜色编码), URL 输入, Headers KV, Query Params KV, JSON Body 编辑器, Form Data Body |
| 响应展示       | 状态码(2xx绿/3xx蓝/4xx橙/5xx红), 响应时间(ms), Body 大小, JSON 格式化/Pretty/Raw, 响应 Headers 列表 |
| 集合管理       | 创建/编辑/删除文件夹, 创建/编辑/删除请求, 单层文件夹嵌套, 保存请求到集合, 从集合加载请求                              |
| 环境变量       | 多环境管理(开发/测试/生产), 变量 KV 编辑, `{{variable}}` 语法替换, 一键切换当前环境                        |
| 历史记录       | 每次请求自动保存, 按时间倒序列表, 显示方法+URL+状态码, 一键重发, 清空历史                                     |
| 本地存储       | Hive boxes: requests, collections, environments, history, settings              |
| Android 适配 | 底部导航 4 Tab(请求/集合/环境/我的), 竖屏为主                                                   |

## 4. 项目结构

```
lib/
├── main.dart                              # 入口，初始化 Hive + ProviderScope
├── app.dart                               # MaterialApp + 主题 + 路由
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                # 主题色/方法色/状态码色
│   │   ├── app_strings.dart               # 字符串常量
│   │   └── http_methods.dart              # HTTP 方法枚举和元数据
│   ├── theme/
│   │   └── app_theme.dart                 # 亮色/暗色主题定义
│   └── utils/
│       ├── variable_resolver.dart         # {{var}} 变量替换
│       └── json_formatter.dart            # JSON 格式校验
├── data/
│   ├── models/
│   │   ├── api_request.dart               # 请求模型 (HiveType 0)
│   │   ├── api_response.dart              # 响应模型
│   │   ├── collection.dart                # 集合模型 (HiveType 1)
│   │   ├── environment.dart               # 环境模型 (HiveType 2)
│   │   ├── history_entry.dart             # 历史模型 (HiveType 3)
│   │   ├── request_body.dart              # 请求体模型
│   │   └── auth_config.dart               # 认证配置模型
│   ├── datasources/
│   │   └── local/
│   │       ├── local_database.dart        # Hive 初始化 + Box 引用
│   │       ├── request_local_datasource.dart
│   │       ├── collection_local_datasource.dart
│   │       ├── environment_local_datasource.dart
│   │       └── history_local_datasource.dart
│   └── repositories/
│       ├── request_repository_impl.dart
│       ├── collection_repository_impl.dart
│       ├── environment_repository_impl.dart
│       └── history_repository_impl.dart
├── domain/
│   └── repositories/
│       ├── request_repository.dart        # 抽象接口
│       ├── collection_repository.dart
│       ├── environment_repository.dart
│       └── history_repository.dart
├── presentation/
│   ├── providers/
│   │   ├── request_provider.dart          # 当前请求 + 发送请求
│   │   ├── collection_provider.dart       # 集合树
│   │   ├── environment_provider.dart      # 环境列表 + 激活环境
│   │   └── history_provider.dart          # 历史列表
│   ├── screens/
│   │   └── mobile/
│   │       ├── shell_screen.dart          # 底部 Tab 导航壳
│   │       ├── request_screen.dart        # Tab 1: 请求编辑器 + 响应
│   │       ├── collection_screen.dart     # Tab 2: 集合列表 + 文件夹
│   │       ├── environment_screen.dart    # Tab 3: 环境管理
│   │       └── profile_screen.dart        # Tab 4: 我的/设置
│   └── widgets/
│       ├── method_selector.dart           # 方法下拉选择器(颜色编码)
│       ├── kv_editor.dart                 # 键值对编辑器(Headers/Params)
│       ├── json_editor_widget.dart         # JSON 编辑器(语法高亮)
│       ├── response_viewer.dart           # 响应查看器(状态码/Body/Headers)
│       ├── status_badge.dart              # 状态码标签(颜色标记)
│       ├── empty_state.dart               # 空状态占位
│       └── loading_indicator.dart         # 加载指示器
├── services/
│   └── http_engine.dart                   # Dio HTTP 引擎
└── router/
    └── mobile_router.dart                 # GoRouter 路由配置
```

## 5. 数据模型

### 5.1 ApiRequest（请求定义）
```dart
class ApiRequest {
  String id;              // UUID
  String name;            // 请求名称
  String method;          // GET/POST/PUT/DELETE/PATCH/HEAD/OPTIONS
  String url;             // 完整 URL（含变量替换后）
  Map<String, String> headers;
  Map<String, String> queryParams;
  RequestBody? body;      // type + content/formData
  AuthConfig? auth;       // type + credentials
  String? collectionId;   // 所属集合
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 5.2 ApiResponse（响应结果）
```dart
class ApiResponse {
  int statusCode;
  Map<String, String> headers;
  String body;
  int durationMs;
  int bodySize;
}
```

### 5.3 Collection（集合）
```dart
class Collection {
  String id;
  String name;
  String? parentId;           // 父文件夹 ID
  List<String> childIds;      // 子文件夹/请求 ID
  CollectionType type;        // folder / request
  String? requestId;          // 如果是请求节点，指向请求
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 5.4 Environment（环境）
```dart
class Environment {
  String id;
  String name;
  Map<String, String> variables;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 5.5 HistoryEntry（历史记录）
```dart
class HistoryEntry {
  String id;
  String method;
  String url;
  int? statusCode;
  int durationMs;
  int bodySize;
  DateTime sentAt;
  ApiRequest? originalRequest;  // 用于重发
}
```

## 6. 路由设计（Android）

```
/                        → ShellScreen (BottomNavigationBar)
├── /request             → RequestScreen (Tab 0: 请求编辑器)
├── /collections         → CollectionScreen (Tab 1: 集合)
├── /environments        → EnvironmentScreen (Tab 2: 环境)
└── /profile             → ProfileScreen (Tab 3: 我的)
```

使用 GoRouter 的 `ShellRoute` 实现底部导航持久化。

## 7. 状态管理（Riverpod）

| Provider | 类型 | 职责 |
|----------|------|------|
| `currentRequestProvider` | StateNotifier | 当前编辑的请求状态 |
| `responseStateProvider` | StateNotifier | 响应数据 + 加载状态 |
| `collectionTreeProvider` | StateNotifier | 集合树数据 |
| `environmentListProvider` | StateNotifier | 环境列表 |
| `activeEnvironmentProvider` | StateNotifier | 当前激活的环境 |
| `historyListProvider` | StateNotifier | 历史记录列表 |

## 8. HTTP 引擎

```dart
// Dio 配置
BaseOptions(
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(seconds: 10),
)

// 核心方法
Future<ApiResponse> sendRequest(ApiRequest request, {CancelToken? cancelToken});
void cancelRequest(String requestId);
```

拦截器链：
- LogInterceptor（请求/响应日志）
- 超时重试（可选）

## 9. 主题/UI

### 9.1 颜色系统
- 遵循 UI_DESIGN.md 的亮色/暗色配色方案
- 请求方法颜色编码（GET 绿/POST 橙/PUT 蓝/DELETE 红/PATCH 紫/HEAD 灰/OPTIONS 灰）
- 状态码颜色（2xx 绿/3xx 蓝/4xx 橙/5xx 红）

### 9.2 组件规范
- 间距: 页面 16px, 卡片 12px, 列表项 8px
- 圆角: 卡片 12px, 按钮 8px, 输入框 8px, 标签 4px
- 字体: 标题 20sp Bold, 区块 16sp SemiBold, 正文 14sp, 辅助 12sp, 代码 13sp Mono

## 10. 不在 Phase 1 范围内的

- Supabase 云同步（Phase 3）
- 测试脚本 Pre-request/Tests（Phase 4）
- cURL/Postman/OpenAPI 导入导出（Phase 2/4）
- Windows 桌面端适配（Phase 2）
- Auth 认证支持 Bearer/Basic/API Key 配置（Phase 2）
- 拖拽排序（Phase 2）
- 深色模式（Phase 2）
- 请求体 Raw/Binary 类型（Phase 1 仅 JSON + Form Data）
- 文件上传（Phase 2）

## 11. 依赖清单

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  dio: ^5.4.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  uuid: ^4.3.0
  google_fonts: ^6.1.0
  connectivity_plus: ^6.0.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.0
```
