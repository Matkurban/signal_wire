import 'package:signal_wire/signal_wire.dart';

/// 用于验证 [WireDisposable] 生命周期与自动回收行为的测试替身类。
///
/// Test double for verifying [WireDisposable] lifecycle hooks and automatic
/// resource disposal.
class TestDisposable extends WireDisposable {
  /// 记录 `onInit()` 被触发的次数。
  ///
  /// Number of times `onInit()` has been invoked.
  int initCount = 0;

  /// 记录 `onClose()` 被触发的次数。
  ///
  /// Number of times `onClose()` has been invoked.
  int closeCount = 0;

  /// 记录自动清理回调的执行顺序。
  ///
  /// Ordered log of executed auto-dispose callbacks.
  final List<String> cleanupOrder = <String>[];

  /// 托管的可变计数器信号。
  ///
  /// Managed mutable counter signal.
  late final FlutterSignal<int> count;

  /// 托管的派生双倍计算信号。
  ///
  /// Managed derived doubled computed signal.
  late final FlutterComputed<int> doubled;

  /// 托管的副作用清理函数。
  ///
  /// Cleanup handle returned by [createEffect].
  late final EffectCleanup disposeEffect;

  /// 记录副作用响应到的历史值列表。
  ///
  /// History of values observed by the managed effect.
  final List<int> effectLog = <int>[];

  @override
  void onInit() {
    super.onInit();
    initCount++;
    count = createSignal<int>(
      0,
      options: const SignalOptions<int>(name: 'test_count'),
    );
    doubled = createComputed<int>(
      () => count.value * 2,
      options: const ComputedOptions<int>(name: 'test_doubled'),
    );
    disposeEffect = createEffect(() {
      effectLog.add(count.value);
    }, options: const EffectOptions(name: 'test_effect'));
    autoDispose(() => cleanupOrder.add('first'));
    autoDispose(() => cleanupOrder.add('second'));
  }

  /// 向外部暴露注册自定义清理回调的辅助方法。
  ///
  /// Exposes [autoDispose] for testing custom cleanup registration.
  ///
  /// - [label]：清理回调执行时写入 [cleanupOrder] 的标识文本。 / Label
  ///   appended to [cleanupOrder] when cleanup runs.
  void registerCustomCleanup(String label) {
    autoDispose(() => cleanupOrder.add(label));
  }

  @override
  void onClose() {
    cleanupOrder.add('onClose');
    closeCount++;
    super.onClose();
  }
}
