# signal_wire

[English](README.md) | 简体中文

`signal_wire` 是一个纯 Dart 编写的轻量级 Flutter 插件，将 `signals_flutter` 的细粒度响应式状态管理与极简依赖注入（Service Locator）、生命周期自动回收有机结合。

## 核心设计边界

- **绝对不包含路由功能**：无需自定义 `MaterialApp`，不接管 `Navigator`，完全兼容原生路由、`go_router`、`auto_route` 等任意路由方案。
- **拒绝全家桶冗余**：不包含国际化、主题切换、Snackbar/Dialog、HTTP 请求等无关功能。
- **100% 基于 `signals_flutter`**：不重复造响应式轮子，直接复用并完整导出 `signals_flutter`（`signal`、`computed`、`effect`、`SignalBuilder`、`SignalStatefulWidget`、`SignalsMixin` 等）。
- **纯 Dart 全平台通用**：原生支持 Android、iOS、macOS、Windows、Linux 与 Web。

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  signal_wire: ^1.0.0
```

只需引入唯一入口（已自动 re-export `signals_flutter`）：

```dart
import 'package:signal_wire/signal_wire.dart';
```

## 1. 三层生命周期与全家族 Signals 自动回收

### `WireDisposable`（底层基类）
提供具备防重复初始化与防重复销毁保护的 `onInit()` / `onClose()` 钩子，并自动收集内部创建的所有响应式资源与清理回调。`onClose()` 触发时按后进先出（LIFO）顺序安全释放全部资源，彻底杜绝内存泄漏。

内置全家族托管工厂方法（均直接透传 `signals_flutter` 标准 `options`）：
- **核心原语**：`createSignal`、`createLazySignal`、`createReadonlySignal`、`createComputed`、`createEffect`
- **响应式集合**：`createListSignal`、`createSetSignal`、`createMapSignal`、`createIterableSignal`、`createQueueSignal`
- **历史与追踪**：`createChangeStackSignal`（撤销/重做 Undo/Redo）、`createTrackedSignal`（追踪初始值与上一次值）
- **异步与流**：`createAsyncSignal`、`createFutureSignal`、`createStreamSignal`、`createComputedAsync`、`createComputedFrom`、`createTimerSignal`、`createConnect`
- **通用托管**：`trackSignal`（一键托管 `LinkedSignal`、`PersistedSignal`、`TickerSignal` 等任意信号）与 `autoDispose(VoidCallback)`

### `WireController extends WireDisposable`（页面/局部控制器）
面向 UI 视图层，额外提供 `onReady()` 钩子，通过 `WidgetsBinding.instance.addPostFrameCallback` 在首帧渲染完成后触发（若在首帧前已被销毁则自动跳过）。默认随所属页面或作用域卸载而自动销毁。

### `WireService extends WireDisposable`（全局常驻服务）
面向全局常驻能力（用户鉴权、IM 长连接、本地存储等），脱离 UI 渲染周期（无 `onReady()`）。注册进容器时默认开启 `permanent: true` 常驻保护，防止被普通 `Wire.delete()` 误删（仅当显式传入 `force: true` 时销毁）。

```dart
class AuthService extends WireService {
  late final FlutterSignal<String?> username;
  late final FlutterComputed<bool> isSignedIn;

  @override
  void onInit() {
    super.onInit();
    username = createSignal<String?>(
      null,
      options: const SignalOptions<String?>(name: 'auth_username'),
    );
    isSignedIn = createComputed<bool>(
      () => username.value != null,
      options: const ComputedOptions<bool>(name: 'auth_is_signed_in'),
    );
  }

  void signIn(String name) => username.value = name;
  void signOut() => username.value = null;
}
```

## 2. 极简依赖注入容器（`Wire`）

所有 API 均支持通过 `tag` 区分同类型多实例：

```dart
// 立即注册（WireService 自动开启 permanent: true）
final auth = Wire.put<AuthService>(AuthService());

// 同键重复 put 默认返回已有实例并输出 WARNING 日志；
// 传入 force: true 时先原子初始化替换再帧安全销毁旧实例，保证界面零异常。
final freshCtrl = Wire.put<TaskController>(TaskController(), force: true);

// 异步初始化并注册（适合 runApp 前初始化 WireService，内置并发去重）
await Wire.putAsync<AuthService>(() async => AuthService());

// 懒加载注册（fenix: true 时销毁后再次 find 自动重建全新实例）
Wire.lazyPut<SearchController>(
  () => SearchController(),
  tag: 'global_search',
  fenix: true,
);

// 查找实例（未注册时抛出包含明确 Type 与 tag 的 WireNotFoundException）
final search = Wire.find<SearchController>(tag: 'global_search');

// 检查与销毁
if (Wire.isRegistered<SearchController>(tag: 'global_search')) {
  Wire.delete<SearchController>(tag: 'global_search');
}

// 强制销毁常驻服务
Wire.delete<AuthService>(force: true);

// 批量重置容器（适合退出登录或单元测试 tearDown）
Wire.reset(clearPermanent: true);
```

## 3. 视图层与页面逻辑绑定的三种模式

三种模式在泛型上均严格约束为 `T extends WireController`（编译期禁止将全局 `WireService` 误绑到页面生命周期），并遵循**“谁创建、谁销毁”**原则。

### 模式 A：`WireView<T extends WireController>`（自定义 `ComponentElement`）

直接继承 `Widget`（无 `StatefulWidget` 样板代码）。重写 `wire()` 时自动在挂载期注册、卸载期回收；不重写 `wire()` 时默认通过 `Wire.find` 复用外部已注入实例且卸载不销毁。

```dart
class TaskBoardPage extends WireView<TaskBoardController> {
  const TaskBoardPage({super.key});

  @override
  TaskBoardController wire() => TaskBoardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务看板')),
      body: SignalBuilder(
        builder: (context) => Text('任务总数: ${controller.tasks.length}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.addQuickTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 模式 B：`WireStateMixin<W, T extends WireController>`（`StatefulWidget` 混入）

专为需要使用 `StatefulWidget` 的页面设计，可与 `SignalsMixin`、`TickerProviderStateMixin`、`AutomaticKeepAliveClientMixin` 或 `SignalStatefulWidget` 无缝混用。

```dart
class DraftEditorPage extends StatefulWidget {
  const DraftEditorPage({super.key});

  @override
  State<DraftEditorPage> createState() => _DraftEditorPageState();
}

class _DraftEditorPageState extends State<DraftEditorPage>
    with SignalsMixin, WireStateMixin<DraftEditorPage, DraftEditorController> {
  late final localStep = createSignal<int>(5);

  @override
  DraftEditorController wire() => DraftEditorController();

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) => Column(
        children: [
          Text('当前积分: ${controller.score.value}'),
          Text('局部步长: ${localStep.value}'),
          FilledButton(
            onPressed: () => controller.addScore(localStep.value),
            child: const Text('增加积分'),
          ),
        ],
      ),
    );
  }
}
```

### 模式 C：`WireScope<T extends WireController>`（作用域包裹）

可包裹任意组件（`StatelessWidget`、`StatefulWidget` 或第三方组件），将控制器的创建与销毁严格绑定到 `WireScope` 子树生命周期，支持 `builder` / `child` 与动态切换 `tag`。

```dart
WireScope<ProjectScopeController>(
  tag: activeRoomTag,
  create: () => ProjectScopeController(roomName: activeRoomTag),
  builder: (context, controller) {
    return SignalBuilder(
      builder: (context) => Text(
        '房间 ${controller.roomName}: ${controller.onlineCount.value} 人在线',
      ),
    );
  },
)
```

## 4. 结构化日志系统（`WireLogger`）

`WireLogger` 默认在 Debug 模式开启、Release 模式静默，支持按 `WireLogLevel` 过滤、按 `WireLogCategory` 分类，并可通过自定义 `handler` 接入任意第三方日志框架或应用内调试面板（内置防重入保护）：

```dart
WireLogger.configure(
  enabled: true,
  minLevel: WireLogLevel.info,
  handler: (WireLogRecord record) {
    debugPrint(record.format());
  },
);
```

## 示例应用（WireDesk）

完整的正式应用场景示例位于 [`example/lib/main.dart`](example/lib/main.dart)，演示了：
- 全局常驻 `AuthService` 与接入 `WireLogger` 的实时日志流面板（`WorkspaceLogService`）
- 模式 A（`WireView`）：任务看板（`ListSignal` + `SetSignal` + `FutureSignal` + `Computed` + `Effect`）
- 模式 B（`SignalsMixin` + `WireStateMixin`）：追踪积分（`TrackedSignal`）与撤销/重做草稿编辑器（`ChangeStackSignal`）
- 模式 C（`WireScope`）：多房间动态 `tag` 切换（`MapSignal` + `QueueSignal`）与界面零异常的 `Wire.put(..., force: true)` 强替换

## 开源协议

MIT License — 详见 [LICENSE](LICENSE)。
