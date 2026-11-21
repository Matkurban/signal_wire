import 'dart:async';
import 'dart:collection';

import 'package:signal_wire/signal_wire.dart';

/// 覆盖 `WireDisposable` 全家族信号工厂方法的测试控制器。
///
/// Test controller exercising the entire family of managed signal factories
/// provided by [WireDisposable].
class FullSignalsController extends WireController {
  /// 基础可变信号。 / Mutable signal.
  late final FlutterSignal<int> counter;

  /// 延迟初始化信号。 / Lazy signal.
  late final FlutterSignal<String> lazyNote;

  /// 只读信号。 / Read-only signal.
  late final ReadonlySignal<String> version;

  /// 派生计算信号。 / Computed signal.
  late final FlutterComputed<int> tripled;

  /// 列表信号。 / Reactive list signal.
  late final ListSignal<String> items;

  /// 集合信号。 / Reactive set signal.
  late final SetSignal<String> selectedTags;

  /// 映射表信号。 / Reactive map signal.
  late final MapSignal<String, int> inventory;

  /// 可迭代集合信号。 / Reactive iterable signal.
  late final IterableSignal<int> numbers;

  /// 队列信号。 / Reactive queue signal.
  late final QueueSignal<String> jobQueue;

  /// 支持撤销/重做的历史栈信号。 / Undo/redo change stack signal.
  late final ChangeStackSignal<String> draft;

  /// 追踪初始值与上一次值的信号。 / Tracked signal.
  late final TrackedSignal<int> trackedScore;

  /// 手动异步状态信号。 / Manual async state signal.
  late final AsyncSignal<String> manualAsync;

  /// Future 异步信号。 / Future signal.
  late final FutureSignal<String> fetchedProfile;

  /// Stream 流信号。 / Stream signal.
  late final StreamSignal<int> liveTicks;

  /// 隐式依赖异步计算信号。 / Implicit async computed signal.
  late final FutureSignal<String> asyncLabel;

  /// 显式依赖异步计算信号。 / Explicit-dependency async computed signal.
  late final FutureSignal<int> asyncSum;

  /// 外部流连接目标信号。 / Target signal connected to an external stream.
  late final FlutterSignal<String> connectedStatus;

  /// 流连接桥接器。 / Connect bridge.
  late final Connect<String, String> statusConnect;

  /// 外部手动创建并通过 `trackSignal` 托管的信号。 / Externally created tracked signal.
  late final FlutterSignal<bool> externalFlag;

  /// 内部流控制器（用于测试 `StreamSignal` 与 `Connect`）。
  ///
  /// Internal stream controller backing `StreamSignal` and `Connect` tests.
  final StreamController<int> tickStreamController =
      StreamController<int>.broadcast();

  /// 内部状态流控制器。 / Internal status stream controller.
  final StreamController<String> statusStreamController =
      StreamController<String>.broadcast();

  @override
  void onInit() {
    super.onInit();
    counter = createSignal<int>(1, debugLabel: 'full_counter');
    lazyNote = createLazySignal<String>(debugLabel: 'full_lazy');
    version = createReadonlySignal<String>('v1.0.0', debugLabel: 'full_ver');
    tripled = createComputed<int>(
      () => counter.value * 3,
      debugLabel: 'full_tripled',
    );
    items = createListSignal<String>(<String>['a'], debugLabel: 'full_items');
    selectedTags = createSetSignal<String>(
      <String>{'core'},
      debugLabel: 'full_tags',
    );
    inventory = createMapSignal<String, int>(
      <String, int>{'apple': 2},
      debugLabel: 'full_inventory',
    );
    numbers = createIterableSignal<int>(
      <int>[10, 20],
      debugLabel: 'full_numbers',
    );
    jobQueue = createQueueSignal<String>(
      Queue<String>.from(<String>['job1']),
      debugLabel: 'full_queue',
    );
    draft = createChangeStackSignal<String>(
      'v1',
      limit: 5,
      debugLabel: 'full_draft',
    );
    trackedScore = createTrackedSignal<int>(100, debugLabel: 'full_tracked');
    manualAsync = createAsyncSignal<String>(
      const AsyncData<String>('ready'),
      debugLabel: 'full_manual_async',
    );
    fetchedProfile = createFutureSignal<String>(
      () async => 'profile_ok',
      debugLabel: 'full_future',
    );
    liveTicks = createStreamSignal<int>(
      () => tickStreamController.stream,
      debugLabel: 'full_stream',
    );
    asyncLabel = createComputedAsync<String>(() async {
      final int current = counter.value;
      return 'label_$current';
    }, debugLabel: 'full_computed_async');
    asyncSum = createComputedFrom<int, int>(
      <ReadonlySignal<int>>[counter],
      (List<int> args) async => args.first + 10,
      debugLabel: 'full_computed_from',
    );
    connectedStatus = createSignal<String>(
      'idle',
      debugLabel: 'full_connected',
    );
    statusConnect = createConnect<String, String>(connectedStatus);
    statusConnect.from(statusStreamController.stream);
    externalFlag = trackSignal<FlutterSignal<bool>>(
      signal<bool>(false, options: const SignalOptions<bool>(name: 'ext_flag')),
    );

    autoDispose(() {
      tickStreamController.close();
      statusStreamController.close();
    });
  }
}
