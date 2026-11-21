import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../log/wire_log_category.dart';
import '../log/wire_logger.dart';

/// 生命周期与自动资源回收基类。
///
/// Base class for lifecycle management and automatic resource disposal.
///
/// 提供防重复触发的 [onInit] 与 [onClose] 生命周期钩子，并完整覆盖
/// `signals_flutter` 全家族信号的自动生命周期托管（核心信号、集合信号、
/// 历史/追踪信号、异步信号、流连接与通用清理回调）。当 [onClose] 触发时，
/// 所有已登记的资源将按后进先出（LIFO）顺序自动释放，彻底杜绝内存泄漏。
///
/// Provides idempotent [onInit] and [onClose] lifecycle hooks along with
/// full automatic disposal helpers for the entire `signals_flutter` signal
/// family (core primitives, reactive collections, history/tracked signals,
/// async signals, stream connections, and generic cleanup callbacks).
abstract class WireDisposable {
  /// 标记当前实例是否已完成初始化。
  ///
  /// Whether this instance has already been initialized.
  bool _isInitialized = false;

  /// 标记当前实例是否已被关闭销毁。
  ///
  /// Whether this instance has already been closed and disposed.
  bool _isClosed = false;

  /// 已收集的自动清理回调队列。
  ///
  /// Queue of collected automatic disposal callbacks.
  final List<VoidCallback> _disposers = <VoidCallback>[];

  /// 当前实例是否已完成初始化。
  ///
  /// Returns `true` if [onInit] has already been invoked.
  bool get isInitialized => _isInitialized;

  /// 当前实例是否已被销毁。
  ///
  /// Returns `true` if [onClose] has already been invoked.
  bool get isClosed => _isClosed;

  /// 初始化生命周期钩子，在实例注册进容器后自动调用一次。
  ///
  /// Lifecycle hook called automatically once after the instance is
  /// registered in the container.
  @protected
  @mustCallSuper
  void onInit() {}

  /// 销毁生命周期钩子，在实例从容器移除时自动调用一次。
  ///
  /// Lifecycle hook called automatically once when the instance is
  /// removed from the container.
  ///
  /// 子类重写时请调用 `super.onClose()`。即使此方法抛出异常，
  /// 已通过 [autoDispose] 收集的资源仍会被安全释放。
  ///
  /// Subclasses should call `super.onClose()`. Even if this method throws,
  /// all resources collected via [autoDispose] are still safely released.
  @protected
  @mustCallSuper
  void onClose() {}

  // ---------------------------------------------------------------------------
  // 核心响应式原语 / Core Reactive Primitives
  // ---------------------------------------------------------------------------

  /// 创建一个受当前实例生命周期托管的可变信号（[FlutterSignal]）。
  ///
  /// Creates a mutable [FlutterSignal] bound to this instance's lifecycle.
  ///
  /// - [value]：信号初始值。 / Initial signal value.
  /// - [options]：可选信号配置项（包含名称、监听回调等）。 / Optional
  ///   [SignalOptions] (supports `name`, lifecycle hooks, etc.).
  @protected
  FlutterSignal<T> createSignal<T>(T value, {SignalOptions<T>? options}) {
    final FlutterSignal<T> created = signal<T>(value, options: options);
    return trackSignal<FlutterSignal<T>>(created);
  }

  /// 创建一个受当前实例生命周期托管的延迟初始化可变信号（[lazySignal]）。
  ///
  /// Creates a lazily initialized mutable [FlutterSignal] bound to this
  /// instance's lifecycle whose value can be assigned later.
  ///
  /// - [options]：可选信号配置项。 / Optional [SignalOptions].
  @protected
  FlutterSignal<T> createLazySignal<T>({SignalOptions<T>? options}) {
    final FlutterSignal<T> created = lazySignal<T>(options: options);
    return trackSignal<FlutterSignal<T>>(created);
  }

  /// 创建一个受当前实例生命周期托管的只读信号（[ReadonlySignal]）。
  ///
  /// Creates a [ReadonlySignal] bound to this instance's lifecycle.
  ///
  /// - [value]：只读信号值。 / Initial read-only value.
  /// - [options]：可选信号配置项。 / Optional [SignalOptions].
  @protected
  ReadonlySignal<T> createReadonlySignal<T>(
    T value, {
    SignalOptions<T>? options,
  }) {
    final ReadonlySignal<T> created = readonly<T>(value, options: options);
    return trackSignal<ReadonlySignal<T>>(created);
  }

  /// 创建一个受当前实例生命周期托管的派生计算信号（[FlutterComputed]）。
  ///
  /// Creates a derived [FlutterComputed] signal bound to this instance's
  /// lifecycle.
  ///
  /// - [compute]：纯计算回调，内部读取的信号会被自动追踪为依赖。 / Pure
  ///   computation callback whose read signals are tracked automatically.
  /// - [options]：可选计算配置项。 / Optional [ComputedOptions].
  @protected
  FlutterComputed<T> createComputed<T>(
    T Function() compute, {
    ComputedOptions<T>? options,
  }) {
    final FlutterComputed<T> created = computed<T>(compute, options: options);
    return trackSignal<FlutterComputed<T>>(created);
  }

  /// 创建一个受当前实例生命周期托管的副作用（[effect]）。
  ///
  /// Creates a reactive side [effect] bound to this instance's lifecycle.
  ///
  /// 返回幂等清理函数 [EffectCleanup]，可提前手动停止或交由 [onClose] 自动释放。
  /// Returns an idempotent [EffectCleanup] callback safe to invoke early or
  /// leave for automatic disposal in [onClose].
  ///
  /// - [compute]：副作用回调。 / Side-effect callback.
  /// - [options]：可选副作用配置项。 / Optional [EffectOptions].
  @protected
  EffectCleanup createEffect(Function() compute, {EffectOptions? options}) {
    final EffectCleanup rawCleanup = effect(compute, options: options);
    bool cleaned = false;
    void safeCleanup() {
      if (cleaned) {
        return;
      }
      cleaned = true;
      rawCleanup();
    }

    autoDispose(safeCleanup);
    return safeCleanup;
  }

  // ---------------------------------------------------------------------------
  // 响应式集合信号 / Reactive Collection Signals
  // ---------------------------------------------------------------------------

  /// 创建一个受生命周期托管的响应式列表信号（[ListSignal]）。
  ///
  /// Creates a reactive [ListSignal] bound to this instance's lifecycle.
  ///
  /// - [value]：初始列表。 / Initial list elements.
  /// - [options]：可选列表信号配置项。 / Optional [ListSignalOptions].
  @protected
  ListSignal<T> createListSignal<T>(
    List<T> value, {
    ListSignalOptions<T>? options,
  }) {
    final ListSignal<T> created = listSignal<T>(value, options: options);
    return trackSignal<ListSignal<T>>(created);
  }

  /// 创建一个受生命周期托管的响应式集合信号（[SetSignal]）。
  ///
  /// Creates a reactive [SetSignal] bound to this instance's lifecycle.
  ///
  /// - [value]：初始集合。 / Initial set elements.
  /// - [options]：可选集合信号配置项。 / Optional [SetSignalOptions].
  @protected
  SetSignal<T> createSetSignal<T>(
    Set<T> value, {
    SetSignalOptions<T>? options,
  }) {
    final SetSignal<T> created = setSignal<T>(value, options: options);
    return trackSignal<SetSignal<T>>(created);
  }

  /// 创建一个受生命周期托管的响应式映射表信号（[MapSignal]）。
  ///
  /// Creates a reactive [MapSignal] bound to this instance's lifecycle.
  ///
  /// - [value]：初始键值对映射。 / Initial map entries.
  /// - [options]：可选映射表信号配置项。 / Optional [MapSignalOptions].
  @protected
  MapSignal<K, V> createMapSignal<K, V>(
    Map<K, V> value, {
    MapSignalOptions<K, V>? options,
  }) {
    final MapSignal<K, V> created = mapSignal<K, V>(value, options: options);
    return trackSignal<MapSignal<K, V>>(created);
  }

  /// 创建一个受生命周期托管的响应式可迭代集合信号（[IterableSignal]）。
  ///
  /// Creates a reactive [IterableSignal] bound to this instance's lifecycle.
  ///
  /// - [value]：初始可迭代对象。 / Initial iterable elements.
  /// - [options]：可选配置项。 / Optional [IterableSignalOptions].
  @protected
  IterableSignal<T> createIterableSignal<T>(
    Iterable<T> value, {
    IterableSignalOptions<T>? options,
  }) {
    final IterableSignal<T> created = iterableSignal<T>(
      value,
      options: options,
    );
    return trackSignal<IterableSignal<T>>(created);
  }

  /// 创建一个受生命周期托管的响应式队列信号（[QueueSignal]）。
  ///
  /// Creates a reactive [QueueSignal] bound to this instance's lifecycle.
  ///
  /// - [value]：初始队列。 / Initial [Queue] elements.
  /// - [options]：可选队列信号配置项。 / Optional [QueueSignalOptions].
  @protected
  QueueSignal<T> createQueueSignal<T>(
    Queue<T> value, {
    QueueSignalOptions<T>? options,
  }) {
    final QueueSignal<T> created = queueSignal<T>(value, options: options);
    return trackSignal<QueueSignal<T>>(created);
  }

  // ---------------------------------------------------------------------------
  // 历史记录与值追踪信号 / History & Tracked Signals
  // ---------------------------------------------------------------------------

  /// 创建一个支持撤销/重做（Undo / Redo）历史栈的信号（[ChangeStackSignal]）。
  ///
  /// Creates a [ChangeStackSignal] with undo/redo history bound to this
  /// instance's lifecycle.
  ///
  /// - [value]：初始值。 / Initial value.
  /// - [limit]：可选最大历史记录条数限制。 / Optional max history stack size.
  /// - [options]：可选变更栈信号配置项。 / Optional [ChangeSignalOptions].
  @protected
  ChangeStackSignal<T> createChangeStackSignal<T>(
    T value, {
    int? limit,
    ChangeSignalOptions<T>? options,
  }) {
    final ChangeStackSignal<T> created = changeStack<T>(
      value,
      limit: limit,
      options: options,
    );
    return trackSignal<ChangeStackSignal<T>>(created);
  }

  /// 创建一个自动记录初始值与上一次值的追踪信号（[TrackedSignal]）。
  ///
  /// Creates a [TrackedSignal] that remembers its initial and previous values,
  /// bound to this instance's lifecycle.
  ///
  /// - [value]：初始值。 / Initial value.
  /// - [options]：可选追踪信号配置项。 / Optional [TrackedSignalOptions].
  @protected
  TrackedSignal<T> createTrackedSignal<T>(
    T value, {
    TrackedSignalOptions<T>? options,
  }) {
    final TrackedSignal<T> created = trackedSignal<T>(value, options: options);
    return trackSignal<TrackedSignal<T>>(created);
  }

  // ---------------------------------------------------------------------------
  // 异步与流信号 / Async & Stream Signals
  // ---------------------------------------------------------------------------

  /// 创建一个受生命周期托管的异步状态信号（[AsyncSignal]）。
  ///
  /// Creates an [AsyncSignal] initialized with [AsyncState], bound to this
  /// instance's lifecycle.
  ///
  /// - [value]：初始异步状态（如 `AsyncState.loading()`）。 / Initial [AsyncState].
  /// - [options]：可选异步信号配置项。 / Optional [AsyncSignalOptions].
  @protected
  AsyncSignal<T> createAsyncSignal<T>(
    AsyncState<T> value, {
    AsyncSignalOptions<T>? options,
  }) {
    final AsyncSignal<T> created = asyncSignal<T>(value, options: options);
    return trackSignal<AsyncSignal<T>>(created);
  }

  /// 创建一个受生命周期托管的 Future 异步信号（[FutureSignal]）。
  ///
  /// Creates a [FutureSignal] wrapping an asynchronous callback, bound to this
  /// instance's lifecycle.
  ///
  /// - [compute]：返回 [Future] 的异步计算函数。 / Async computation callback.
  /// - [options]：可选异步信号配置项（支持显式 `dependencies` 与 `initialValue`）。
  ///   Optional [AsyncSignalOptions] (supports `dependencies` & `initialValue`).
  @protected
  FutureSignal<T> createFutureSignal<T>(
    Future<T> Function() compute, {
    AsyncSignalOptions<T>? options,
  }) {
    final FutureSignal<T> created = futureSignal<T>(compute, options: options);
    return trackSignal<FutureSignal<T>>(created);
  }

  /// 创建一个受生命周期托管的 Stream 流信号（[StreamSignal]）。
  ///
  /// Creates a [StreamSignal] wrapping a reactive [Stream], automatically
  /// cancelled and disposed when [onClose] runs.
  ///
  /// - [compute]：返回 [Stream] 的流工厂函数。 / Stream factory callback.
  /// - [options]：可选异步信号配置项。 / Optional [AsyncSignalOptions].
  @protected
  StreamSignal<T> createStreamSignal<T>(
    Stream<T> Function() compute, {
    AsyncSignalOptions<T>? options,
  }) {
    final StreamSignal<T> created = streamSignal<T>(compute, options: options);
    return trackSignal<StreamSignal<T>>(created);
  }

  /// 创建一个隐式追踪同步依赖的异步计算信号（[computedAsync]）。
  ///
  /// Creates an asynchronous computed signal ([computedAsync]) with implicit
  /// dependency tracking, bound to this instance's lifecycle.
  ///
  /// - [compute]：异步计算函数。 / Async computation callback.
  /// - [options]：可选异步信号配置项。 / Optional [AsyncSignalOptions].
  @protected
  FutureSignal<T> createComputedAsync<T>(
    Future<T> Function() compute, {
    AsyncSignalOptions<T>? options,
  }) {
    final FutureSignal<T> created = computedAsync<T>(compute, options: options);
    return trackSignal<FutureSignal<T>>(created);
  }

  /// 创建一个显式声明依赖列表的异步计算信号（[computedFrom]），彻底规避异步间隙依赖丢失问题。
  ///
  /// Creates an asynchronous computed signal ([computedFrom]) with explicitly
  /// declared [signals] dependencies, immune to the async-gap tracking issue.
  ///
  /// - [signals]：显式依赖的只读信号列表。 / Explicit dependency signal list.
  /// - [compute]：接收解析后依赖值列表的异步计算函数。 / Async computation callback.
  /// - [options]：可选异步信号配置项。 / Optional [AsyncSignalOptions].
  @protected
  FutureSignal<T> createComputedFrom<T, A>(
    List<ReadonlySignal<A>> signals,
    Future<T> Function(List<A> args) compute, {
    AsyncSignalOptions<T>? options,
  }) {
    final FutureSignal<T> created = computedFrom<T, A>(
      signals,
      compute,
      options: options,
    );
    return trackSignal<FutureSignal<T>>(created);
  }

  /// 创建一个受生命周期托管的周期定时信号（[TimerSignal]）。
  ///
  /// Creates a recurring [TimerSignal] bound to this instance's lifecycle.
  ///
  /// - [every]：周期触发间隔。 / Interval duration between timer ticks.
  /// - [cancelOnError]：发生错误时是否取消定时流。 / Whether to cancel on error.
  /// - [options]：可选异步信号配置项。 / Optional [AsyncSignalOptions].
  @protected
  TimerSignal createTimerSignal(
    Duration every, {
    bool? cancelOnError,
    AsyncSignalOptions<TimerSignalEvent>? options,
  }) {
    final TimerSignal created = timerSignal(
      every,
      cancelOnError: cancelOnError,
      options: options,
    );
    return trackSignal<TimerSignal>(created);
  }

  /// 创建一个受生命周期托管的流连接桥接器（[Connect]），在 [onClose] 时自动断开所有流订阅。
  ///
  /// Creates a [Connect] bridge connecting one or more [Stream]s into [target]
  /// and automatically disposes all stream subscriptions in [onClose].
  ///
  /// - [target]：接收流数据的目标信号。 / Target signal receiving stream events.
  @protected
  Connect<T, S> createConnect<T, S extends T>(Signal<T> target) {
    final Connect<T, S> bridge = connect<T, S>(target);
    autoDispose(bridge.dispose);
    return bridge;
  }

  // ---------------------------------------------------------------------------
  // 通用信号与资源托管 / Generic Signal & Resource Tracking
  // ---------------------------------------------------------------------------

  /// 将任意 [ReadonlySignal]（如 `LinkedSignal`、`PersistedSignal`、`TickerSignal` 或外部转换的信号）
  /// 纳入当前实例的生命周期自动销毁队列。
  ///
  /// Registers any [ReadonlySignal] (including `LinkedSignal`,
  /// `PersistedSignal`, `TickerSignal`, or converted `ValueNotifier` signals)
  /// for automatic disposal in [onClose].
  ///
  /// - [target]：待托管的信号实例。 / Signal instance to track and dispose.
  @protected
  S trackSignal<S extends ReadonlySignal<Object?>>(S target) {
    autoDispose(target.dispose);
    WireLogger.verbose(
      WireLogCategory.signal,
      'Tracked ${target.runtimeType} for auto-disposal.',
      type: runtimeType,
    );
    return target;
  }

  /// 注册一个通用资源清理回调，在 [onClose] 时自动执行。
  ///
  /// Registers a generic cleanup callback to be executed automatically when
  /// [onClose] runs.
  ///
  /// 若调用此方法时当前实例已经处于 [isClosed] 状态，将输出警告并立即执行 [cleanup] 防止泄漏。
  /// If this instance is already closed ([isClosed] is `true`), logs a warning
  /// and invokes [cleanup] immediately to prevent resource leaks.
  ///
  /// - [cleanup]：待执行的资源释放回调。 / Cleanup callback to run on disposal.
  @protected
  void autoDispose(VoidCallback cleanup) {
    if (_isClosed) {
      WireLogger.warning(
        WireLogCategory.lifecycle,
        'autoDispose() called on an already closed instance; executing cleanup immediately.',
        type: runtimeType,
      );
      cleanup();
      return;
    }
    _disposers.add(cleanup);
  }

  /// 内部初始化调度方法，供容器调用，具备防重复初始化保护。
  ///
  /// Internal initialization entry point invoked by the DI container with
  /// duplicate-init protection.
  @internal
  void internalInit() {
    if (_isInitialized || _isClosed) {
      WireLogger.verbose(
        WireLogCategory.lifecycle,
        'Skipped duplicate internalInit() (initialized=$_isInitialized, closed=$_isClosed).',
        type: runtimeType,
      );
      return;
    }
    _isInitialized = true;
    WireLogger.debug(WireLogCategory.lifecycle, 'onInit()', type: runtimeType);
    onInit();
  }

  /// 内部销毁调度方法，供容器调用，具备防重复销毁与异常隔离保护。
  ///
  /// Internal disposal entry point invoked by the DI container with
  /// duplicate-close protection and exception safety.
  @internal
  void internalClose() {
    if (_isClosed) {
      WireLogger.verbose(
        WireLogCategory.lifecycle,
        'Skipped duplicate internalClose().',
        type: runtimeType,
      );
      return;
    }
    _isClosed = true;
    WireLogger.debug(
      WireLogCategory.lifecycle,
      'onClose() with ${_disposers.length} auto-disposer(s).',
      type: runtimeType,
    );

    Object? capturedError;
    StackTrace? capturedStackTrace;

    try {
      onClose();
    } catch (error, stackTrace) {
      capturedError = error;
      capturedStackTrace = stackTrace;
      WireLogger.error(
        WireLogCategory.lifecycle,
        'Exception thrown inside onClose().',
        type: runtimeType,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      final List<VoidCallback> disposersSnapshot = List<VoidCallback>.of(
        _disposers,
      );
      _disposers.clear();

      for (int i = disposersSnapshot.length - 1; i >= 0; i--) {
        try {
          disposersSnapshot[i]();
        } catch (error, stackTrace) {
          capturedError ??= error;
          capturedStackTrace ??= stackTrace;
          WireLogger.error(
            WireLogCategory.lifecycle,
            'Exception thrown while running autoDispose callback #$i.',
            type: runtimeType,
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }

    if (capturedError != null && capturedStackTrace != null) {
      Error.throwWithStackTrace(capturedError, capturedStackTrace);
    }
  }
}
