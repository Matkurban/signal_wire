import 'package:signal_wire/signal_wire.dart';

/// 用于验证 [WireController] 与 [WireReadyMixin] 完整生命周期与信号响应性的测试控制器。
///
/// Test controller mixing in [WireReadyMixin] for verifying lifecycle hooks
/// and signal reactivity.
class TestController extends WireController with WireReadyMixin {
  /// 创建一个带有可选标识名称与初始计数的测试控制器。
  ///
  /// Creates a [TestController] with an optional [label] and [initialCount].
  ///
  /// - [label]：控制器实例标识名称。 / Identifier label for this instance.
  /// - [initialCount]：初始计数值，默认为 `0`。 / Initial counter value.
  TestController({this.label = 'default', this.initialCount = 0});

  /// 实例标识名称。
  ///
  /// Instance identifier label.
  final String label;

  /// 初始计数值。
  ///
  /// Initial counter value.
  final int initialCount;

  /// `onInit` 被触发的次数。
  ///
  /// Number of times `onInit` was called.
  int initCount = 0;

  /// `onReady` 被触发的次数。
  ///
  /// Number of times `onReady` was called.
  int readyCount = 0;

  /// `onClose` 被触发的次数。
  ///
  /// Number of times `onClose` was called.
  int closeCount = 0;

  /// 按调用顺序记录生命周期事件名称。
  ///
  /// Chronological log of lifecycle events.
  final List<String> events = <String>[];

  /// 副作用捕获到的计数变更记录。
  ///
  /// Log of counter values observed by the internal effect.
  final List<int> effectValues = <int>[];

  /// 受托管的响应式计数器信号。
  ///
  /// Managed reactive counter signal.
  late final FlutterSignal<int> count;

  /// 受托管的派生计算信号。
  ///
  /// Managed derived computed signal.
  late final FlutterComputed<String> summary;

  @override
  void onInit() {
    super.onInit();
    initCount++;
    events.add('onInit');
    count = createSignal<int>(
      initialCount,
      options: SignalOptions<int>(name: 'ctrl_count_$label'),
    );
    summary = createComputed<String>(
      () => '$label:${count.value}',
      options: ComputedOptions<String>(name: 'ctrl_summary_$label'),
    );
    createEffect(() {
      effectValues.add(count.value);
    }, options: EffectOptions(name: 'ctrl_effect_$label'));
  }

  @override
  void onReady() {
    super.onReady();
    readyCount++;
    events.add('onReady');
  }

  /// 将计数器递增指定步长（默认加 1）。
  ///
  /// Increments [count] by [step] (defaults to `1`).
  ///
  /// - [step]：递增步长。 / Increment step.
  void increment([int step = 1]) {
    count.value += step;
  }

  @override
  void onClose() {
    closeCount++;
    events.add('onClose');
    super.onClose();
  }
}
