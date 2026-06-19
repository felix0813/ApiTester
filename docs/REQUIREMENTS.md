# API Tester - 需求文档

## 1. 项目概述

**项目名称**：API Tester  
**技术栈**：Flutter (Dart)  
**目标平台**：Android、Windows 11  
**设计目标**：提供简洁高效的 HTTP 端点测试工具，支持云同步，移动端操作优先

---

## 2. 核心功能模块

### 2.1 HTTP 请求编辑器

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 请求方法 | 支持 GET、POST、PUT、DELETE、PATCH、HEAD、OPTIONS | P0 |
| URL 输入 | 自动补全历史 URL，支持环境变量替换 `{{baseUrl}}` | P0 |
| Headers | 键值对编辑，支持常用 Header 快捷插入 | P0 |
| Query Params | 可视化键值对编辑，自动生成 URL 查询字符串 | P0 |
| Body - JSON | JSON 编辑器，带语法高亮和格式校验 | P0 |
| Body - Form Data | 表单键值对，支持文件上传（移动端适配） | P0 |
| Body - Raw | 纯文本/XML/HTML 等原始内容编辑 | P1 |
| Body - Binary | 二进制文件发送 | P2 |
| Auth | Bearer Token / Basic Auth / API Key | P0 |

### 2.2 响应展示

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 状态码 | 颜色标记（2xx 绿、3xx 蓝、4xx 橙、5xx 红） | P0 |
| 响应时间 | 毫秒级显示 | P0 |
| 响应大小 | 自动计算并显示 | P0 |
| Body 查看 | JSON 格式化、原始文本、Pretty Print | P0 |
| Headers 查看 | 响应头键值对列表 | P0 |
| 搜索 | 在响应内容中搜索关键词 | P1 |

### 2.3 集合管理

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 文件夹 | 支持多层文件夹嵌套组织请求 | P0 |
| 请求保存 | 保存完整请求配置到集合 | P0 |
| 拖拽排序 | 集合内请求/文件夹可拖拽排序 | P1 |
| 批量操作 | 批量删除、批量移动 | P2 |
| 导入/导出 | 支持 Postman Collection v2.1、OpenAPI 3.0、cURL 导入 | P1 |

### 2.4 环境变量

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 环境管理 | 支持多环境（开发/测试/生产） | P0 |
| 变量定义 | 全局变量 + 环境级变量 | P0 |
| 变量引用 | `{{variableName}}` 语法 | P0 |
| 环境切换 | 一键切换当前激活环境 | P0 |

### 2.5 测试脚本

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 前置脚本 (Pre-request) | 请求发送前执行 JavaScript/Dart 脚本 | P1 |
| 后置脚本 (Tests) | 响应返回后断言校验 | P1 |
| 内置断言 | status code、response body、header 校验 | P1 |
| 变量操作 | 脚本中读写环境变量 | P1 |

### 2.6 历史记录

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 自动保存 | 每次请求自动记录到历史 | P0 |
| 历史列表 | 按时间倒序，显示方法+URL+状态码 | P0 |
| 快速重发 | 从历史一键重发请求 | P0 |
| 清空历史 | 手动清空或设置自动清理天数 | P1 |

---

## 3. 云同步功能

### 3.1 同步架构

```
┌─────────────┐         ┌─────────────────┐         ┌─────────────┐
│  Android    │◄───────►│   Supabase      │◄───────►│  Windows    │
│  Flutter    │  sync   │   (PostgreSQL)  │  sync   │  Flutter    │
└─────────────┘         └─────────────────┘         └─────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │   PostgreSQL    │
                     │  (Collections,  │
                     │   Environments, │
                     │   Requests)     │
                     └─────────────────┘
```

### 3.2 同步策略

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 账号系统 | 邮箱注册/登录，支持 OAuth（Google、GitHub） | P0 |
| 实时同步 | 数据变更后自动推送到云端 | P0 |
| 冲突解决 | 最后写入优先（Last Write Wins） | P0 |
| 离线支持 | 离线操作本地缓存，联网后自动同步 | P0 |
| 同步状态 | 显示同步状态图标（同步中/已同步/冲突） | P1 |
| 手动同步 | 提供手动触发同步按钮 | P1 |

### 3.3 同步数据范围

| 数据类型 | 同步 | 说明 |
|----------|------|------|
| 集合 (Collections) | ✅ | 请求配置、文件夹结构 |
| 环境变量 (Environments) | ✅ | 多环境配置 |
| 历史记录 (History) | ❌ | 仅本地存储，可选同步 |
| 请求标签页 | ❌ | 仅本地会话状态 |

---

## 4. 平台适配

### 4.1 Android 端

| 要求 | 描述 |
|------|------|
| 最低版本 | Android 8.0 (API 26) |
| 目标版本 | Android 14 (API 34) |
| 屏幕适配 | 手机竖屏为主，支持平板横屏 |
| 底部导航 | 请求 | 集合 | 环境 | 我的 |
| 手势操作 | 左滑删除、下拉刷新、长按拖拽排序 |
| 文件选择 | 调用系统文件选择器上传 Body 文件 |
| 分享功能 | 支持分享 cURL 命令到其他应用 |
| 深色模式 | 跟随系统或手动切换 |

### 4.2 Windows 端

| 要求 | 描述 |
|------|------|
| 最低版本 | Windows 10 |
| 推荐版本 | Windows 11 |
| 窗口管理 | 支持多窗口、窗口吸附、自由缩放 |
| 侧边栏 | 左侧集合树 + 右侧请求编辑区 |
| 快捷键 | Ctrl+N 新建、Ctrl+S 保存、Ctrl+Enter 发送 |
| 托盘通知 | 后台运行时最小化到系统托盘 |
| 自动更新 | 检测新版本并提示更新 |

---

## 5. UI/UX 设计规范

### 5.1 设计原则

- **移动端优先**：手机端操作路径最短，核心操作 2 步内完成
- **一致性**：Android 和 Windows 保持统一的设计语言
- **响应式**：自适应不同屏幕尺寸

### 5.2 配色方案

```
主色：#2563EB (Blue)
成功：#10B981 (Green)
警告：#F59E0B (Amber)
错误：#EF4444 (Red)
背景：#FFFFFF / #0F172A (Dark)
表面：#F8FAFC / #1E293B (Dark)
```

### 5.3 移动端关键交互

```
首页
├── 顶部搜索栏（搜索集合/历史）
├── 快速请求入口（大按钮，点击直接编辑）
├── 最近请求列表（5条）
└── 底部 Tab 导航
    ├── 请求（编辑器）
    ├── 集合（文件夹树）
    ├── 环境（变量管理）
    └── 我的（账号/设置/同步）
```

---

## 6. 技术架构

### 6.1 项目结构

```
api_tester/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── http/           # HTTP 客户端封装
│   │   ├── storage/        # 本地存储（SQLite/Hive）
│   │   ├── sync/           # 云同步引擎
│   │   ├── auth/           # 认证模块
│   │   └── utils/          # 工具函数
│   ├── models/
│   │   ├── request.dart
│   │   ├── response.dart
│   │   ├── collection.dart
│   │   ├── environment.dart
│   │   └── history.dart
│   ├── providers/          # 状态管理
│   ├── screens/
│   │   ├── mobile/         # 移动端页面
│   │   └── desktop/        # 桌面端页面
│   ├── widgets/            # 通用组件
│   └── routes/             # 路由定义
├── android/
├── windows/
├── test/
└── pubspec.yaml
```

### 6.2 核心依赖

| 依赖 | 用途 |
|------|------|
| `dio` | HTTP 客户端 |
| `hive` / `sqflite` | 本地存储 |
| `riverpod` / `bloc` | 状态管理 |
| `go_router` | 路由管理 |
| `google_fonts` | 字体 |
| `flutter_highlight` | JSON 语法高亮 |
| `uuid` | 唯一 ID 生成 |
| `crypto` | 数据加密 |
| `supabase_flutter` | 云端数据库 + 认证 |
| `connectivity_plus` | 网络状态检测 |

### 6.3 数据模型

```dart
class ApiRequest {
  final String id;
  final String name;
  final String method;        // GET, POST, ...
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final RequestBody? body;
  final AuthConfig? auth;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ApiResponse {
  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final int durationMs;
  final int bodySize;
}

class Environment {
  final String id;
  final String name;
  final Map<String, String> variables;
  final bool isActive;
}

class Collection {
  final String id;
  final String name;
  final String? parentId;
  final List<String> requestIds;
  final DateTime updatedAt;
}
```

---

## 7. 非功能需求

### 7.1 性能

| 指标 | 目标 |
|------|------|
| 冷启动时间 | < 2 秒 |
| 请求发送延迟 | < 100ms（不含网络） |
| 大响应体渲染 | 1MB JSON < 500ms |
| 本地存储查询 | < 50ms |

### 7.2 安全

| 要求 | 描述 |
|------|------|
| 数据传输 | HTTPS/TLS 1.3 |
| 本地存储 | 敏感数据加密存储（Hive with encryption） |
| Token 安全 | 不在日志/历史中明文存储 Token |
| 证书校验 | 支持自定义证书信任 |

### 7.3 可靠性

| 要求 | 描述 |
|------|------|
| 崩溃率 | < 0.1% |
| 数据不丢失 | 本地写入使用事务，异常时回滚 |
| 离线可用 | 无网络时核心功能完整可用 |

---

## 8. 开发计划

### Phase 1 - MVP（4 周）

- [x] 项目初始化 & 平台配置
- [x] HTTP 请求编辑器（GET/POST/Headers/Body）
- [x] 响应展示（状态码/Body/Headers/时间）
- [x] 本地存储（集合管理）
- [x] 环境变量基础功能
- [x] Android 基础适配

### Phase 2 - 核心增强（3 周）

- [x] 完整的集合管理（文件夹嵌套、拖拽排序）
- [x] 历史记录
- [x] Auth 认证支持（Bearer/Basic/API Key）
- [ ] cURL 导入
- [x] Windows 端适配
- [x] 深色模式

### Phase 3 - 云同步（3 周）

- [x] 用户注册/登录系统
- [x] 云端数据同步
- [x] 离线队列 & 冲突处理
- [x] 跨设备数据一致性

### Phase 4 - 高级功能（2 周）

- [x] 测试脚本（Pre-request / Tests）
- [x] Postman Collection 导入
- [x] OpenAPI 导入
- [x] 请求组合测试（Runner）
- [x] 性能优化 & 稳定性

---

## 9. 验收标准

### 9.1 功能验收

- [ ] 能发送 GET/POST/PUT/DELETE 请求并正确显示响应
- [ ] 集合可以创建、编辑、删除、嵌套组织
- [ ] 环境变量可以定义并在请求中引用
- [ ] Android 和 Windows 端 UI 自适应正常
- [ ] 云同步可在两端之间同步集合数据
- [ ] 离线操作后联网自动同步

### 9.2 性能验收

- [ ] Android 端冷启动 < 2s
- [ ] Windows 端冷启动 < 3s
- [ ] 1000 条历史记录列表滑动流畅（60fps）

### 9.3 兼容性验收

- [ ] Android 8.0 ~ 14 正常运行
- [ ] Windows 10/11 正常运行
- [ ] 竖屏/横屏布局正确切换
