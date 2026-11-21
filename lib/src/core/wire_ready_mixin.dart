import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../log/wire_log_category.dart';
import '../log/wire_logger.dart';
import 'wire_controller.dart';

/// 可选的首帧就绪生命周期混入，仅在需要 `onReady()` 时按需混入 [WireController]。
///
/// Optional post-frame readiness mixin for [WireController].
///
/// 未混入此 Mixin 的普通 [WireController] **完全不会**注册
/// `WidgetsBinding.instance.addPostFrameCallback`，避免不必要的首帧回调开销与日志。
/// 仅当控制器确实需要在首帧渲染完成后执行逻辑（如读取布局尺寸、滚动定位或首帧后拉取数据）
/// 时按需混入：
///
/// Plain [WireController] subclasses that do not mix in [WireReadyMixin]
/// register **zero** post-frame callbacks. Mix this in only when a controller
/// genuinely needs work to run after the first rendered frame:
///
/// ```dart
/// class HomeController extends WireController with WireReadyMixin {
///   @override
///   void onReady() {
///     super.onReady();
///     // Runs once after the first frame completes.
///   }
/// }
/// ```
mixin WireReadyMixin on WireController {
  /// 标记 [onReady] 是否已触发。
  ///
  /// Whether [onReady] has already been invoked.
  bool _isReady = false;

  /// 标记首帧回调是否已经排程，防止重复注册帧回调。
  ///
  /// Whether the post-frame callback for [onReady] has already been scheduled.
  bool _readyScheduled = false;

  /// 当前控制器是否已完成 [onReady] 回调。
  ///
  /// Returns `true` if [onReady] has already been executed.
  bool get isReady => _isReady;

  /// 首帧渲染完成后自动触发的生命周期钩子。
  ///
  /// Lifecycle hook invoked automatically after the first frame finishes
  /// rendering.
  ///
  /// 若控制器在首帧回调执行前已被销毁，此方法不会被触发。
  /// Will not run if the controller is closed before the post-frame callback
  /// fires.
  @protected
  @mustCallSuper
  void onReady() {}

  /// 内部首帧就绪调度方法，供容器在 `internalInit()` 后按需调用。
  ///
  /// Internal scheduler invoked by the DI container right after
  /// `internalInit()` to trigger [onReady] on the next post-frame callback.
  ///
  /// 若当前运行在未初始化 [WidgetsBinding] 的纯 Dart 单元测试环境中，
  /// 会记录 verbose 日志并安全跳过帧回调排程。
  ///
  /// Logs a verbose note and safely skips scheduling when running without an
  /// initialized [WidgetsBinding].
  @internal
  void internalReady() {
    if (_isReady || _readyScheduled || isClosed) {
      return;
    }

    final WidgetsBinding? binding = _tryGetWidgetsBinding();
    if (binding == null) {
      WireLogger.verbose(
        WireLogCategory.lifecycle,
        'WidgetsBinding is not initialized; skipped scheduling onReady().',
        type: runtimeType,
      );
      return;
    }

    _readyScheduled = true;
    binding.addPostFrameCallback((_) {
      if (isClosed || _isReady) {
        WireLogger.verbose(
          WireLogCategory.lifecycle,
          'Skipped onReady() because controller was closed before post-frame callback.',
          type: runtimeType,
        );
        return;
      }
      _isReady = true;
      WireLogger.debug(
        WireLogCategory.lifecycle,
        'onReady()',
        type: runtimeType,
      );
      onReady();
    });
  }

  /// 安全获取当前 [WidgetsBinding] 实例，未初始化时返回 `null`。
  ///
  /// Safely retrieves the active [WidgetsBinding] instance, returning `null`
  /// if the binding has not been initialized.
  WidgetsBinding? _tryGetWidgetsBinding() {
    try {
      return WidgetsBinding.instance;
    } catch (_) {
      return null;
    }
  }
}
