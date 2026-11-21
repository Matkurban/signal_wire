import 'package:signal_wire/signal_wire.dart';

/// 未混入 [WireReadyMixin] 的轻量测试控制器，用于验证零首帧回调开销。
///
/// Lightweight test [WireController] without [WireReadyMixin] used to verify
/// that no post-frame `onReady` callback is scheduled by default.
class PlainController extends WireController {
  /// 记录 `onInit()` 被触发的次数。
  ///
  /// Number of times `onInit()` has been invoked.
  int initCount = 0;

  /// 记录 `onClose()` 被触发的次数。
  ///
  /// Number of times `onClose()` has been invoked.
  int closeCount = 0;

  @override
  void onInit() {
    super.onInit();
    initCount++;
  }

  @override
  void onClose() {
    closeCount++;
    super.onClose();
  }
}
