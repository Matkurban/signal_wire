# signal_wire

English | [简体中文](README_ZH.md)

`signal_wire` is a lightweight, pure-Dart Flutter package that combines the fine-grained reactivity of `signals_flutter` with minimal dependency injection (Service Locator) and automatic lifecycle disposal.

## Strict Boundaries & Philosophy

- **Zero Routing Lock-In**: No custom `MaterialApp`, no `Navigator` hijack — works seamlessly with Flutter's native `Navigator`, `go_router`, `auto_route`, or any router of your choice.
- **No All-in-One Bloat**: No i18n, theme wrappers, Snackbars/Dialogs, or HTTP clients.
- **100% Powered by `signals_flutter`**: Re-exports the entire `signals_flutter` library (`signal`, `computed`, `effect`, `SignalBuilder`, `SignalStatefulWidget`, `SignalsMixin`, etc.) without reinventing reactive primitives.
- **Pure Dart, All Platforms**: Works out of the box on Android, iOS, macOS, Windows, Linux, and Web.

## Installation

Add `signal_wire` to your `pubspec.yaml`:

```yaml
dependencies:
  signal_wire: ^1.0.0
```

Import a single entry point (automatically re-exports `signals_flutter`):

```dart
import 'package:signal_wire/signal_wire.dart';
```

## 1. Three-Tier Lifecycle & Full Signals Auto-Disposal

### `WireDisposable` (Base Class)
Provides idempotent `onInit()` and `onClose()` hooks and automatically tracks every reactive primitive and custom cleanup callback. When `onClose()` fires, all tracked resources are disposed in LIFO order — even if a subclass throws inside `onClose()`.

Supported lifecycle-managed factories (all accept standard `signals_flutter` `options`):
- **Core**: `createSignal`, `createLazySignal`, `createReadonlySignal`, `createComputed`, `createEffect`
- **Collections**: `createListSignal`, `createSetSignal`, `createMapSignal`, `createIterableSignal`, `createQueueSignal`
- **History & Tracking**: `createChangeStackSignal` (Undo / Redo), `createTrackedSignal` (`initialValue` / `previousValue`)
- **Async & Streams**: `createAsyncSignal`, `createFutureSignal`, `createStreamSignal`, `createComputedAsync`, `createComputedFrom`, `createTimerSignal`, `createConnect`
- **Generic**: `trackSignal` (for `LinkedSignal`, `PersistedSignal`, `TickerSignal`, etc.) and `autoDispose(VoidCallback)`

### `WireController extends WireDisposable`
Designed for page-scoped or widget-scoped logic. Adds `onReady()` invoked automatically after the first rendered frame via `WidgetsBinding.instance.addPostFrameCallback` (automatically skipped if the controller closes before the frame completes).

### `WireService extends WireDisposable`
Designed for globally persistent services (auth, IM socket, local storage). Decoupled from UI frames (no `onReady()`) and automatically registered with `permanent: true` so regular `Wire.delete()` cannot accidentally remove it (requires `force: true`).

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

## 2. Minimal Dependency Injection Container (`Wire`)

All methods support an optional `tag` to isolate multiple instances of the same type:

```dart
// Immediate registration (WireService defaults to permanent: true)
final auth = Wire.put<AuthService>(AuthService());

// Duplicate put returns existing instance and logs a WARNING;
// pass `force: true` to atomically swap in the new instance and dispose the old one safely.
final freshCtrl = Wire.put<TaskController>(TaskController(), force: true);

// Async initialization before runApp (with concurrent deduplication)
await Wire.putAsync<AuthService>(() async => AuthService());

// Lazy factory (fenix: true recreates automatically on next find after delete)
Wire.lazyPut<SearchController>(
  () => SearchController(),
  tag: 'global_search',
  fenix: true,
);

// Lookup (throws WireNotFoundException with exact Type & tag if missing)
final search = Wire.find<SearchController>(tag: 'global_search');

// Check & delete
if (Wire.isRegistered<SearchController>(tag: 'global_search')) {
  Wire.delete<SearchController>(tag: 'global_search');
}

// Force delete permanent service
Wire.delete<AuthService>(force: true);

// Reset container (great for logout or test tearDown)
Wire.reset(clearPermanent: true);
```

## 3. Three View-Binding Modes

All three modes strictly enforce `T extends WireController` (preventing `WireService` from being tied to a page lifecycle at compile time) and follow **"whoever creates, disposes"**.

### Mode A: `WireView<T extends WireController>` (Custom `ComponentElement`)

Directly extends `Widget` (no `StatefulWidget` boilerplate). Override `wire()` to own controller creation/disposal, or omit `wire()` to consume an externally registered instance without disposing it on unmount.

```dart
class TaskBoardPage extends WireView<TaskBoardController> {
  const TaskBoardPage({super.key});

  @override
  TaskBoardController wire() => TaskBoardController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Board')),
      body: SignalBuilder(
        builder: (context) => Text('Tasks: ${controller.tasks.length}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.addQuickTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Mode B: `WireStateMixin<W, T extends WireController>` (`StatefulWidget` Mixin)

Built for pages that already need a `StatefulWidget` (e.g., alongside `SignalsMixin`, `TickerProviderStateMixin`, `AutomaticKeepAliveClientMixin`, or `SignalStatefulWidget`).

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
          Text('Score: ${controller.score.value}'),
          Text('Step: ${localStep.value}'),
          FilledButton(
            onPressed: () => controller.addScore(localStep.value),
            child: const Text('Add Score'),
          ),
        ],
      ),
    );
  }
}
```

### Mode C: `WireScope<T extends WireController>` (Scope Wrapper)

Wraps any widget (`StatelessWidget`, `StatefulWidget`, or third-party widget) and binds the controller strictly to the scope's lifecycle — including automatic rebinding when `tag` changes dynamically.

```dart
WireScope<ProjectScopeController>(
  tag: activeRoomTag,
  create: () => ProjectScopeController(roomName: activeRoomTag),
  builder: (context, controller) {
    return SignalBuilder(
      builder: (context) => Text(
        'Room ${controller.roomName}: ${controller.onlineCount.value} online',
      ),
    );
  },
)
```

## 4. Structured Logging (`WireLogger`)

`WireLogger` is enabled in debug mode and silent in release mode by default. You can filter by `WireLogLevel`, inspect `WireLogCategory`, or plug in your own log sink (crash reporting, file logger, or in-app console):

```dart
WireLogger.configure(
  enabled: true,
  minLevel: WireLogLevel.info,
  handler: (WireLogRecord record) {
    debugPrint(record.format());
  },
);
```

## Example App (WireDesk)

See the complete **WireDesk** sample application in [`example/lib/main.dart`](example/lib/main.dart), demonstrating:
- Global `AuthService` & live `WireLogger` stream (`WorkspaceLogService`)
- Mode A (`WireView`): Task board using `ListSignal`, `SetSignal`, `FutureSignal`, `Computed`, and `Effect`
- Mode B (`SignalsMixin` + `WireStateMixin`): Tracked score (`TrackedSignal`) & Undo/Redo draft (`ChangeStackSignal`)
- Mode C (`WireScope`): Dynamic `tag` room switching (`MapSignal`, `QueueSignal`) & UI-safe `Wire.put(..., force: true)` replacement

## License

MIT License — see [LICENSE](LICENSE) for details.
