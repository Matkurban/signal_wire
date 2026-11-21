import 'package:signal_wire/signal_wire.dart';

/// 用于验证 `onClose()` 抛出异常时 `autoDispose` 队列仍会完整释放的测试替身类。
///
/// Test double verifying that registered `autoDispose` callbacks still run
/// even when `onClose()` throws an exception.
class ThrowingCloseDisposable extends WireDisposable {
  /// 标记自定义清理回调是否已成功执行。
  ///
  /// Whether the registered cleanup callback was executed.
  bool cleaned = false;

  @override
  void onInit() {
    super.onInit();
    autoDispose(() {
      cleaned = true;
    });
  }

  @override
  void onClose() {
    super.onClose();
    throw StateError('Simulated error in onClose');
  }
}
