# API Tester Phase 2 - 核心增强 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phase 2 增强 — 深色模式切换、Auth 认证 UI（Bearer/Basic/API Key）、集合拖拽排序、Windows 桌面端侧边栏布局、历史记录回放

**Architecture:** 5 个独立模块并行推进。深色模式通过 Riverpod provider 管理主题状态，AppTheme 新增 darkTheme。Auth UI 在请求编辑器中新增第 4 个 Tab。集合排序通过 Hive `sortOrder` 字段持久化 + ReorderableListView。桌面端新增 desktop_router + ShellScreen + 响应式布局。历史记录支持从列表点击回放到请求编辑器。

**Tech Stack:** Flutter 3.x, Riverpod 2.x, GoRouter 14.x, Hive 2.x

---

## 模块 P2-A：深色模式

### Task P2-A1: 添加 darkTheme 到 AppTheme

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: 添加 darkTheme getter**

在 `AppTheme` 类中，`lightTheme` getter 之后添加：

```dart
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        surface: AppColors.bgSurfaceDark,
        error: AppColors.errorDark,
      ),
      scaffoldBackgroundColor: AppColors.bgBaseDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: const TextStyle(fontSize: 14, color: Color(0xFFE2E8F0)),
        bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFFE2E8F0)),
        bodySmall: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        labelLarge: const TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          color: Color(0xFFD4D4D4),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.bgSurfaceDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        filled: true,
        fillColor: AppColors.bgSurfaceDark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: Colors.grey,
        backgroundColor: AppColors.bgSurfaceDark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
```

注意：需要在 `textTheme` 的 `copyWith` 前将 `ThemeData.dark()` 的 text theme 作为 base。实际代码改为：

```dart
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
```

- [ ] **Step 2: 验证编译**

```bash
cd G:/ApiTester && flutter analyze lib/core/theme/
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: add dark theme to AppTheme"
```

---

### Task P2-A2: 创建 theme provider

**Files:**
- Create: `lib/presentation/providers/settings_provider.dart`

- [ ] **Step 1: 创建 settings_provider.dart**

注意：直接使用 Flutter 内置的 `ThemeMode`（来自 `package:flutter/material.dart`），不自定义枚举，避免命名冲突。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/datasources/local/local_database.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final box = LocalDatabase.settings;
    final saved = box.get('themeMode', defaultValue: 'light') ?? 'light';
    state = ThemeMode.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await LocalDatabase.settings.put('themeMode', mode.name);
  }
}
```

注意：`LocalDatabase` 需要新增一个 `settings` box。如果还没有，需要在 `local_database.dart` 中添加：

在 `local_database.dart` 中添加 `settings` box：
```dart
  static const String settingsBox = 'settings';

  // 在 init() 方法中打开
  await Hive.openBox(settingsBox);

  static Box get settings => Hive.box(settingsBox);
```

这个修改放在 Task P2-A2 中一起完成。

- [ ] **Step 2: 修改 local_database.dart 添加 settings box**

在 `lib/data/datasources/local/local_database.dart`:
- 添加常量 `static const String settingsBox = 'settings';`
- 在 `init()` 中添加 `await Hive.openBox(settingsBox);`
- 添加 getter `static Box get settings => Hive.box(settingsBox);`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/providers/settings_provider.dart lib/data/datasources/local/local_database.dart
git commit -m "feat: add theme mode provider and settings Hive box"
```

---

### Task P2-A3: 更新 app.dart 使用动态主题 + 平台路由选择

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: 更新 app.dart**

当前 `app.dart` 中 `ApiTesterApp` 内部包裹了 `ProviderScope`，需要移除（改为在 `main.dart` 中统一包裹）。同时将类从 `StatelessWidget` 改为 `ConsumerWidget` 以支持 `ref.watch`。

```dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'router/mobile_router.dart';
import 'router/desktop_router.dart';

class ApiTesterApp extends ConsumerWidget {
  const ApiTesterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final routerConfig = Platform.isAndroid ? mobileRouter : desktopRouter;

    return MaterialApp.router(
      title: 'API Tester',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: routerConfig,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

关键改动：
1. `StatelessWidget` → `ConsumerWidget`
2. 移除内部 `ProviderScope` 包裹（`MaterialApp.router` 直接返回）
3. `themeMode` 直接传入 Flutter 的 `ThemeMode`，无需手动映射（因为 `settings_provider.dart` 已使用 Flutter 内置 `ThemeMode`）

- [ ] **Step 2: 更新 main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/datasources/local/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.init();
  runApp(const ProviderScope(child: ApiTesterApp()));
}
```

注意：`ProviderScope` 仅在 `main.dart` 中出现一次，`app.dart` 中不再包含。

- [ ] **Step 3: Commit**

```bash
git add lib/app.dart lib/main.dart
git commit -m "feat: dynamic theme mode + platform-based router selection"
```

---

### Task P2-A4: 在 Profile 页添加主题切换 UI

**Files:**
- Modify: `lib/presentation/screens/mobile/profile_screen.dart`

- [ ] **Step 1: 在 profile_screen.dart 的 Account Card 下方添加 Settings card**

在 `ProfileScreen` 的 `Column` children 中，Account Card 和 History Section 之间插入：

```dart
          // Settings section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Theme'),
                    subtitle: _buildThemeSubtitle(themeMode),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (mode) {
                        ref.read(themeModeProvider.notifier).setTheme(mode);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
```

需要导入 `settings_provider.dart`：
```dart
import '../../providers/settings_provider.dart';
```

并在 build 方法开头读取：
```dart
    final themeMode = ref.watch(themeModeProvider);
```

添加辅助方法：
```dart
  Widget _buildThemeSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return const Text('Light', style: TextStyle(fontSize: 12));
      case ThemeMode.dark:
        return const Text('Dark', style: TextStyle(fontSize: 12));
      case ThemeMode.system:
        return const Text('Follow system', style: TextStyle(fontSize: 12));
    }
  }
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/mobile/profile_screen.dart
git commit -m "feat: add theme switcher to profile screen"
```

---

## 模块 P2-B：Auth 认证 UI

### Task P2-B1: 创建 Auth 配置 Widget

**Files:**
- Create: `lib/presentation/widgets/auth_config_widget.dart`

- [ ] **Step 1: 创建 auth_config_widget.dart**

```dart
import 'package:flutter/material.dart';
import '../../data/models/auth_config.dart';

class AuthConfigWidget extends StatelessWidget {
  final AuthConfig config;
  final ValueChanged<AuthConfig> onChanged;

  const AuthConfigWidget({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auth type selector
          SegmentedButton<AuthType>(
            segments: const [
              ButtonSegment(value: AuthType.none, label: Text('None')),
              ButtonSegment(value: AuthType.bearer, label: Text('Bearer')),
              ButtonSegment(value: AuthType.basic, label: Text('Basic')),
              ButtonSegment(value: AuthType.apiKey, label: Text('API Key')),
            ],
            selected: {config.type},
            onSelectionChanged: (type) {
              onChanged(config.copyWith(type: type));
            },
          ),
          const SizedBox(height: 16),

          // Bearer token
          if (config.type == AuthType.bearer)
            TextField(
              controller: TextEditingController(text: config.token)
                ..selection = TextSelection.collapsed(offset: config.token.length),
              onChanged: (v) => onChanged(config.copyWith(token: v)),
              decoration: const InputDecoration(
                labelText: 'Token',
                hintText: 'eyJhbGci...',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),

          // Basic Auth
          if (config.type == AuthType.basic) ...[
            TextField(
              controller: TextEditingController(text: config.username)
                ..selection = TextSelection.collapsed(offset: config.username.length),
              onChanged: (v) => onChanged(config.copyWith(username: v)),
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: config.password)
                ..selection = TextSelection.collapsed(offset: config.password.length),
              onChanged: (v) => onChanged(config.copyWith(password: v)),
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],

          // API Key
          if (config.type == AuthType.apiKey) ...[
            TextField(
              controller: TextEditingController(text: config.apiKeyHeader)
                ..selection = TextSelection.collapsed(offset: config.apiKeyHeader.length),
              onChanged: (v) => onChanged(config.copyWith(apiKeyHeader: v)),
              decoration: const InputDecoration(
                labelText: 'Header Name',
                hintText: 'X-API-Key',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: config.apiKey)
                ..selection = TextSelection.collapsed(offset: config.apiKey.length),
              onChanged: (v) => onChanged(config.copyWith(apiKey: v)),
              decoration: const InputDecoration(labelText: 'API Key'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/auth_config_widget.dart
git commit -m "feat: add AuthConfigWidget (Bearer/Basic/API Key)"
```

---

### Task P2-B2: 在请求编辑器中接入 Auth Tab

**Files:**
- Modify: `lib/presentation/screens/mobile/request_screen.dart`

- [ ] **Step 1: 修改 request_screen.dart 添加 Auth tab**

改动：
1. TabController length 从 3 改为 4：`TabController(length: 4, vsync: this);`
2. TabBar 添加第 4 个 tab：`const Tab(text: 'Auth'),`
3. TabBarView 添加第 4 个 child：`_buildAuthTab(request),`
4. 添加 `_buildAuthTab` 方法

```dart
  Widget _buildAuthTab(request) {
    final auth = request.auth ?? const AuthConfig();
    return AuthConfigWidget(
      config: auth,
      onChanged: (updated) {
        ref.read(currentRequestProvider.notifier).updateRequest(
              (r) => r.copyWith(auth: updated),
            );
      },
    );
  }
```

添加导入：
```dart
import '../../../data/models/auth_config.dart';
import '../../widgets/auth_config_widget.dart';
```

- [ ] **Step 2: 验证编译**

```bash
cd G:/ApiTester && flutter analyze
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/mobile/request_screen.dart
git commit -m "feat: add Auth tab to request editor"
```

---

### Task P2-B3: 在 HttpEngine 中注入 Auth 配置

**Files:**
- Modify: `lib/services/http_engine.dart`

- [ ] **Step 1: 修改 sendRequest 方法，在发送前注入 Auth headers**

在 `sendRequest` 方法中，resolve headers 之后、发送请求之前添加：

```dart
    // Inject auth headers
    if (request.auth != null && request.auth!.type != AuthType.none) {
      final auth = request.auth!;
      switch (auth.type) {
        case AuthType.bearer:
          resolvedHeaders['Authorization'] = 'Bearer ${auth.token}';
          break;
        case AuthType.basic:
          final credentials =
              '${auth.username}:${auth.password}';
          final encoded = base64Encode(utf8.encode(credentials));
          resolvedHeaders['Authorization'] = 'Basic $encoded';
          break;
        case AuthType.apiKey:
          resolvedHeaders[auth.apiKeyHeader] = auth.apiKey;
          break;
        case AuthType.none:
          break;
      }
    }
```

添加导入（文件顶部）：
```dart
import 'dart:convert';  // for base64Encode, utf8
import '../data/models/auth_config.dart';  // for AuthType
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/http_engine.dart
git commit -m "feat: inject auth headers in HttpEngine"
```

---

## 模块 P2-C：集合拖拽排序

排序方案：在 `CollectionItem` 模型上添加 `sortOrder` int 字段（HiveField 8），通过持久化顺序值实现拖拽排序。现有数据中该字段默认为 0，首次启动时按创建时间自动迁移排序。

### Task P2-C1: CollectionItem 添加 sortOrder + DataSource 排序

**Files:**
- Modify: `lib/data/models/collection.dart`
- Modify: `lib/data/datasources/local/collection_local_datasource.dart`

- [ ] **Step 1: 修改 collection.dart 添加 sortOrder 字段**

在 `CollectionItem` 类中，在 `@HiveField(7) DateTime updatedAt;` 之后添加：

```dart
  @HiveField(8)
  int sortOrder;
```

构造函数中添加默认值：`this.sortOrder = 0`

`copyWith` 方法添加参数：
```dart
  CollectionItem copyWith({
    String? name,
    String? parentId,
    List<String>? childIds,
    CollectionType? type,
    String? requestId,
    bool clearRequestId = false,
    int? sortOrder,
  }) {
    return CollectionItem(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? List<String>.from(this.childIds),
      type: type ?? this.type,
      requestId: clearRequestId ? null : (requestId ?? this.requestId),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
```

- [ ] **Step 2: 运行代码生成**

```bash
cd G:/ApiTester && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: 更新 CollectionLocalDataSource 按 sortOrder 排序**

修改 `collection_local_datasource.dart` 中的 `getByParentId()` 方法：

```dart
  Future<List<CollectionItem>> getByParentId(String? parentId) async {
    final items = LocalDatabase.collections.values
        .where((c) => c.parentId == parentId)
        .toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }
```

- [ ] **Step 4: 数据迁移 — 现有数据 sortOrder 初始化**

在 `local_database.dart` 的 `init()` 方法末尾添加一次性迁移逻辑，为现有数据按创建时间赋 sortOrder：

```dart
    // Migrate: assign sortOrder to existing items by createdAt
    final collections = Hive.box<CollectionItem>(collectionsBox);
    bool needsSort = collections.values.any((c) => c.sortOrder == 0 && collections.values.length > 1);
    if (needsSort) {
      final all = collections.values.toList();
      // Group by parentId
      final groups = <String?, List<CollectionItem>>{};
      for (final item in all) {
        groups.putIfAbsent(item.parentId, () => []).add(item);
      }
      for (final entry in groups.entries) {
        final sorted = entry.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        for (int i = 0; i < sorted.length; i++) {
          sorted[i].sortOrder = i;
          await sorted[i].save();
        }
      }
    }
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/collection.dart lib/data/models/collection.g.dart lib/data/datasources/local/collection_local_datasource.dart lib/data/datasources/local/local_database.dart
git commit -m "feat: add sortOrder field to CollectionItem with migration"
```

---

### Task P2-C2: Provider 添加 reorder 方法 + CollectionScreen 拖拽 UI

**Files:**
- Modify: `lib/presentation/providers/collection_provider.dart`
- Modify: `lib/presentation/screens/mobile/collection_screen.dart`

- [ ] **Step 1: 在 collection_provider.dart 添加 reorder 方法**

在 `CollectionTreeNotifier` 类中添加：

```dart
  /// Reorder root-level items (parentId == null)
  Future<void> reorderRootItems(int oldIndex, int newIndex) async {
    final items = getRootItems();
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex < 0 || newIndex > items.length) return;

    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, movedItem);

    for (int i = 0; i < items.length; i++) {
      await _repo.save(items[i].copyWith(sortOrder: i));
    }
  }

  /// Reorder child items within a parent folder
  Future<void> reorderChildren(String parentId, int oldIndex, int newIndex) async {
    final children = getChildren(parentId);
    if (oldIndex < 0 || oldIndex >= children.length) return;
    if (newIndex < 0 || newIndex > children.length) return;

    final movedItem = children.removeAt(oldIndex);
    children.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, movedItem);

    for (int i = 0; i < children.length; i++) {
      await _repo.save(children[i].copyWith(sortOrder: i));
    }
  }
```

- [ ] **Step 2: 修改 collection_screen.dart 使用 ReorderableListView**

将 `build` 方法中的 `ListView.builder` 替换为 `ReorderableListView.builder`：

```dart
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rootItems.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(collectionTreeProvider.notifier)
                  .reorderRootItems(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 2,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final item = rootItems[index];
              return _CollectionTreeTile(
                key: ValueKey(item.id),
                item: item,
                allItems: items,
                onTap: () {
                  if (item.isRequest && item.requestId != null) {
                    _loadRequest(item.requestId!);
                  }
                },
                onDelete: (id) {
                  ref.read(collectionTreeProvider.notifier).delete(id);
                },
                onCreateChild: (parentId) =>
                    _showCreateDialog(parentId: parentId),
              );
            },
          );
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/providers/collection_provider.dart lib/presentation/screens/mobile/collection_screen.dart
git commit -m "feat: add drag-and-drop reorder to collection screen"
```

---

## 模块 P2-D：Windows 桌面布局

桌面布局设计：
- **DesktopShellScreen**：全窗口壳，包含左侧集合树侧边栏 + 顶部 URL 工具栏 + 中间内容区
- **DesktopRequestScreen**：左右分栏——左侧请求编辑 tabs（Params/Headers/Body/Auth），右侧响应面板
- 环境管理和设置页面复用移动端页面，在桌面窗口中以全宽内容区展示

### Task P2-D1: 创建桌面 Shell Screen

**Files:**
- Create: `lib/presentation/screens/desktop/desktop_shell_screen.dart`

- [ ] **Step 1: 创建 desktop_shell_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/collection_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/environment_provider.dart';
import '../../widgets/method_selector.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/collection.dart';

class DesktopShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const DesktopShellScreen({super.key, required this.child});

  @override
  ConsumerState<DesktopShellScreen> createState() => _DesktopShellScreenState();
}

class _DesktopShellScreenState extends ConsumerState<DesktopShellScreen> {
  String _selectedRequestId = '';

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionTreeProvider);
    final request = ref.watch(currentRequestProvider);
    final activeEnv = ref.watch(activeEnvironmentProvider);

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar — collection tree
          SizedBox(
            width: 260,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text('API Tester',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search collections...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Collection tree
                  Expanded(
                    child: collectionsAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, _) => Center(child: Text('Error')),
                      data: (items) {
                        final roots = items.where((c) => c.parentId == null).toList();
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: roots.length,
                          itemBuilder: (ctx, i) =>
                              _buildTreeItem(roots[i], items),
                        );
                      },
                    ),
                  ),
                  // Bottom actions
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: 'New',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20),
                          tooltip: 'Settings',
                          onPressed: () => context.go('/profile'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1),

          // Right content area
          Expanded(
            child: Column(
              children: [
                // Top URL toolbar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: const Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      MethodSelector(
                        selectedMethod: request.method,
                        onChanged: (m) =>
                            ref.read(currentRequestProvider.notifier).setMethod(m),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Enter URL...',
                            isDense: true,
                          ),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 14),
                          controller: TextEditingController(text: request.url)
                            ..selection = TextSelection.collapsed(
                                offset: request.url.length),
                          onChanged: (v) =>
                              ref.read(currentRequestProvider.notifier).setUrl(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => ref
                            .read(responseProvider.notifier)
                            .sendRequest(activeEnv?.variables),
                        child: const Text('Send'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => context.go('/environments'),
                        child: const Text('Environments'),
                      ),
                    ],
                  ),
                ),
                // Main content (child router page)
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeItem(CollectionItem item, List<CollectionItem> allItems) {
    final children = allItems.where((c) => c.parentId == item.id).toList();

    if (item.isFolder) {
      return ExpansionTile(
        leading: const Icon(Icons.folder_outlined, size: 20),
        title: Text(item.name, style: const TextStyle(fontSize: 13)),
        initiallyExpanded: true,
        children: children.map((c) => _buildTreeItem(c, allItems)).toList(),
      );
    }

    return ListTile(
      leading: Text(item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.forMethod('GET'),
          )),
      title: Text(item.name, style: const TextStyle(fontSize: 13)),
      dense: true,
      selected: item.requestId == _selectedRequestId,
      onTap: () {
        setState(() => _selectedRequestId = item.requestId ?? '');
        if (item.requestId != null) {
          _loadRequest(item.requestId!);
        }
      },
    );
  }

  void _loadRequest(String id) {
    ref.read(requestRepositoryProvider).getById(id).then((req) {
      if (req != null) {
        ref.read(currentRequestProvider.notifier).loadRequest(req);
      }
    });
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/desktop/desktop_shell_screen.dart
git commit -m "feat: add Windows desktop shell with sidebar + URL toolbar"
```

---

### Task P2-D2: 创建桌面请求编辑器（左右分栏）

**Files:**
- Create: `lib/presentation/screens/desktop/desktop_request_screen.dart`

- [ ] **Step 1: 创建 desktop_request_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/request_provider.dart';
import '../../providers/environment_provider.dart';
import '../../../data/models/request_body.dart';
import '../../../data/models/auth_config.dart';
import '../../widgets/kv_editor.dart';
import '../../widgets/json_editor_widget.dart';
import '../../widgets/response_viewer.dart';
import '../../widgets/auth_config_widget.dart';

class DesktopRequestScreen extends ConsumerStatefulWidget {
  const DesktopRequestScreen({super.key});

  @override
  ConsumerState<DesktopRequestScreen> createState() =>
      _DesktopRequestScreenState();
}

class _DesktopRequestScreenState extends ConsumerState<DesktopRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(currentRequestProvider);
    final responseState = ref.watch(responseProvider);

    return Row(
      children: [
        // Left: Request config tabs
        Expanded(
          flex: 1,
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Params'),
                  Tab(text: 'Headers'),
                  Tab(text: 'Body'),
                  Tab(text: 'Auth'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildParamsTab(),
                    _buildHeadersTab(),
                    _buildBodyTab(),
                    _buildAuthTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: Response viewer
        Expanded(
          flex: 1,
          child: ResponseViewer(
            response: responseState.response,
            isLoading: responseState.isLoading,
            error: responseState.error,
          ),
        ),
      ],
    );
  }

  // --- Tab builders (same logic as mobile RequestScreen) ---

  Widget _buildParamsTab() {
    final request = ref.read(currentRequestProvider);
    final params = Map<String, String>.from(request.queryParams ?? {});
    final entries = params.entries
        .map((e) => KvEntry(key: e.key, value: e.value))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: KvEditor(
        entries: entries,
        addButtonLabel: 'Add Param',
        onChanged: (updated) {
          final map = <String, String>{};
          for (final e in updated) {
            if (e.key.isNotEmpty) map[e.key] = e.value;
          }
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(queryParams: map),
              );
        },
      ),
    );
  }

  Widget _buildHeadersTab() {
    final request = ref.read(currentRequestProvider);
    final headers = Map<String, String>.from(request.headers ?? {});
    final entries = headers.entries
        .map((e) => KvEntry(key: e.key, value: e.value))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: KvEditor(
        entries: entries,
        addButtonLabel: 'Add Header',
        onChanged: (updated) {
          final map = <String, String>{};
          for (final e in updated) {
            if (e.key.isNotEmpty) map[e.key] = e.value;
          }
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(headers: map),
              );
        },
      ),
    );
  }

  Widget _buildBodyTab() {
    final request = ref.read(currentRequestProvider);
    final body = request.body ?? const RequestBody();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _BodyTypeChip(
                label: 'JSON',
                selected: body.type == BodyType.json,
                onTap: () {
                  ref.read(currentRequestProvider.notifier).updateRequest(
                        (r) => r.copyWith(
                          body: (r.body ?? const RequestBody())
                              .copyWith(type: BodyType.json),
                        ),
                      );
                },
              ),
              const SizedBox(width: 8),
              _BodyTypeChip(
                label: 'Form Data',
                selected: body.type == BodyType.formData,
                onTap: () {
                  ref.read(currentRequestProvider.notifier).updateRequest(
                        (r) => r.copyWith(
                          body: (r.body ?? const RequestBody())
                              .copyWith(type: BodyType.formData),
                        ),
                      );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: body.type == BodyType.json
              ? JsonEditorWidget(
                  content: body.jsonContent,
                  onChanged: (v) {
                    ref.read(currentRequestProvider.notifier).updateRequest(
                          (r) => r.copyWith(
                            body: (r.body ?? const RequestBody())
                                .copyWith(jsonContent: v),
                          ),
                        );
                  },
                )
              : _buildFormDataEditor(body),
        ),
      ],
    );
  }

  Widget _buildFormDataEditor(RequestBody body) {
    final entries = body.formFields
        .map((f) => KvEntry(key: f.key, value: f.value, enabled: f.enabled))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: KvEditor(
        entries: entries,
        addButtonLabel: 'Add Form Field',
        onChanged: (updated) {
          ref.read(currentRequestProvider.notifier).updateRequest(
                (r) => r.copyWith(
                  body: (r.body ?? const RequestBody()).copyWith(
                    type: BodyType.formData,
                    formFields: updated
                        .map((e) => KeyValuePair(
                              key: e.key, value: e.value, enabled: e.enabled))
                        .toList(),
                  ),
                ),
              );
        },
      ),
    );
  }

  Widget _buildAuthTab() {
    final request = ref.read(currentRequestProvider);
    final auth = request.auth ?? const AuthConfig();
    return AuthConfigWidget(
      config: auth,
      onChanged: (updated) {
        ref.read(currentRequestProvider.notifier).updateRequest(
              (r) => r.copyWith(auth: updated),
            );
      },
    );
  }
}

class _BodyTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BodyTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/desktop/desktop_request_screen.dart
git commit -m "feat: add desktop request screen with split pane layout"
```

---

### Task P2-D3: 创建桌面路由

**Files:**
- Create: `lib/router/desktop_router.dart`

- [ ] **Step 1: 创建 desktop_router.dart**

```dart
import 'package:go_router/go_router.dart';
import '../presentation/screens/desktop/desktop_shell_screen.dart';
import '../presentation/screens/desktop/desktop_request_screen.dart';
import '../presentation/screens/mobile/environment_screen.dart';
import '../presentation/screens/mobile/profile_screen.dart';

final desktopRouter = GoRouter(
  initialLocation: '/request',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return DesktopShellScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/request',
          builder: (context, state) => const DesktopRequestScreen(),
        ),
        GoRoute(
          path: '/environments',
          builder: (context, state) => const EnvironmentScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
```

桌面路由说明：
- `ShellRoute` 始终显示 `DesktopShellScreen`（含侧边栏和 URL 工具栏）
- `/request` 加载 `DesktopRequestScreen`（左右分栏：配置 | 响应）
- `/environments` 和 `/profile` 复用移动端页面，在侧边栏右侧以全宽展示
- 不需要 `/collections` 路由——集合树已在侧边栏中显示

- [ ] **Step 2: Commit**

```bash
git add lib/router/desktop_router.dart
git commit -m "feat: add desktop GoRouter with ShellRoute"
```

---

## 模块 P2-E：历史记录回放

当前 `profile_screen.dart` 中 `_HistoryTile.onTap` 是空的（注释写了 "History replay" 但未实现）。需要完善此功能，让用户点击历史记录可以回放到请求编辑器。

### Task P2-E1: 实现历史记录回放

**Files:**
- Modify: `lib/presentation/screens/mobile/profile_screen.dart`
- Modify: `lib/presentation/providers/history_provider.dart`

- [ ] **Step 1: 给 HistoryEntry 添加可选的完整请求快照**

修改 `history_entry.dart`，添加可选的 `requestSnapshot` 字段用于回放：

```dart
  @HiveField(9)
  final String? requestSnapshot; // JSON 序列化的 ApiRequest
```

在构造函数中添加：`this.requestSnapshot`

重新运行代码生成：
```bash
cd G:/ApiTester && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: 更新 history_provider.dart 添加回放方法**

在 `HistoryListNotifier` 类中添加：

```dart
  /// Get the full request from history entry's snapshot
  ApiRequest? getRequestFromHistory(HistoryEntry entry) {
    if (entry.requestSnapshot == null) return null;
    try {
      final map = jsonDecode(entry.requestSnapshot!) as Map<String, dynamic>;
      return ApiRequest.fromMap(map);
    } catch (_) {
      return null;
    }
  }
```

添加导入：
```dart
import 'dart:convert';
import '../../data/models/api_request.dart';
```

- [ ] **Step 3: 更新 profile_screen.dart 的 _HistoryTile.onTap**

将 `_HistoryTile` 改为 `ConsumerWidget`，在 onTap 中回放请求：

```dart
class _HistoryTile extends ConsumerWidget {
  final HistoryEntry entry;

  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... 保持现有 build 代码不变
  }
}
```

修改 `onTap` 回调：

```dart
        onTap: () {
          final historyNotifier = ref.read(historyListProvider.notifier);
          final request = historyNotifier.getRequestFromHistory(entry);
          if (request != null) {
            ref.read(currentRequestProvider.notifier).loadRequest(request);
            // Navigate to request tab
            // 如果在 ShellScreen 中，可以通过 navigationShell 切换 tab
          }
        },
```

- [ ] **Step 4: 更新 ResponseNotifier.sendRequest 保存完整请求快照**

在 `request_provider.dart` 中 `ResponseNotifier.sendRequest` 保存历史时，附加请求快照：

```dart
      // Save to history with request snapshot
      final historyRepo = _reader(historyRepositoryProvider);
      await historyRepo.save(HistoryEntry(
        method: request.method,
        url: request.url,
        statusCode: response.statusCode,
        durationMs: response.durationMs,
        bodySize: response.bodySize,
        requestSnapshot: jsonEncode(request.toMap()),
      ));
```

添加导入：
```dart
import 'dart:convert';
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/history_entry.dart lib/data/models/history_entry.g.dart lib/presentation/providers/history_provider.dart lib/presentation/providers/request_provider.dart lib/presentation/screens/mobile/profile_screen.dart
git commit -m "feat: implement history replay - tap to load request into editor"
```

---

## 模块 P2-G：构建验证

### Task P2-G1: 自动化验证

- [ ] **Step 1: Run analysis**

```bash
cd G:/ApiTester && flutter analyze
```

Expected: No issues.

- [ ] **Step 2: Run tests**

```bash
cd G:/ApiTester && flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Commit any remaining changes**

```bash
git add -A
git commit -m "chore: finalize Phase 2 build"
```

---

### Task P2-G2: 手动验证清单

逐项验证以下功能，确保所有 Phase 2 功能正常工作：

**深色模式 (P2-A):**
- [ ] Profile 页面可以切换 Light/Dark/Auto 三种主题
- [ ] 切换后应用主题立即生效（无需重启）
- [ ] 深色模式下所有页面（请求编辑器、集合、环境、Profile）颜色正确
- [ ] 退出重进后主题设置被保留

**Auth 认证 (P2-B):**
- [ ] 请求编辑器出现第 4 个 Auth Tab
- [ ] Bearer Token 模式：输入 token 后发送请求，验证 Authorization header 包含 `Bearer xxx`
- [ ] Basic Auth 模式：输入用户名密码后发送请求，验证 Authorization header 包含 Base64 编码
- [ ] API Key 模式：输入 header name 和 key 后发送请求，验证自定义 header 正确注入
- [ ] None 模式：不注入任何认证 header

**集合拖拽排序 (P2-C):**
- [ ] 长按/拖拽集合项可以调整顺序
- [ ] 拖拽排序后退出重进，顺序被保留
- [ ] 文件夹内的子项也可以独立排序
- [ ] 新创建的项目排在末尾

**桌面端 (P2-D):**
- [ ] Windows 端启动后显示左侧边栏 + 右侧内容区布局
- [ ] 侧边栏显示集合树，点击可展开/折叠
- [ ] 点击集合中的请求项，右侧加载该请求
- [ ] URL 工具栏中修改 method/URL 后发送请求正常
- [ ] 左右分栏（Params/Headers/Body/Auth | Response）布局正确
- [ ] 窗口缩放后布局自适应

**历史记录回放 (P2-E):**
- [ ] 发送请求后历史记录中出现新条目
- [ ] 点击历史记录条目，请求被加载到编辑器
- [ ] 回放的请求包含完整的 method/url/headers/body/auth 配置

---

## 实现顺序

1. **P2-A1**: 添加 darkTheme 到 AppTheme
2. **P2-A2**: 创建 theme provider + settings box
3. **P2-A3**: 更新 app.dart + main.dart（移除重复 ProviderScope）
4. **P2-A4**: Profile 页主题切换 UI
5. **P2-B1**: 创建 AuthConfigWidget
6. **P2-B2**: 在请求编辑器接入 Auth Tab
7. **P2-B3**: HttpEngine 注入 Auth headers
8. **P2-C1**: CollectionItem sortOrder + DataSource 排序 + 数据迁移
9. **P2-C2**: CollectionScreen ReorderableListView + provider reorder 方法
10. **P2-D1**: Desktop Shell Screen
11. **P2-D2**: Desktop Request Screen
12. **P2-D3**: Desktop Router
13. **P2-E1**: 历史记录回放（HistoryEntry 快照 + 回放逻辑）
14. **P2-G1**: 自动化验证（flutter analyze + flutter test）
15. **P2-G2**: 手动验证清单
