import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../log/wire_log_category.dart';
import '../log/wire_logger.dart';
import 'wire_disposable.dart';

/// 页面与局部视图控制器基类。
///
/// Base class for page-scoped and widget-scoped controllers.
///
/// 继承自 [WireDisposable]，在 [onInit] 与 [onClose] 的基础上增加
/// [onReady] 生命周期钩子，会在首帧渲染完成后自动触发。
/// 默认随所属页面（`WireView`、`WireStateMixin` 或 `WireScope`）卸载而自动销毁。
///
/// Extends [WireDisposable] with an [onReady] lifecycle hook invoked after
/// the first frame is rendered. By default, instances are automatically
/// disposed when their owning view or scope unmounts.
abstract class WireController extends WireDisposable {
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
  /// 适合在界面就绪后执行依赖渲染尺寸、滚动定位或非阻塞数据加载等逻辑。
  /// 若控制器在首帧回调执行前已被销毁，此方法不会被触发。
  ///
  /// Suitable for work that runs once the UI frame is ready, such as reading
  /// render metrics, scrolling, or starting non-blocking data loads. Will not
  /// run if the controller is closed before the post-frame callback fires.
  @protected
  @mustCallSuper
  void onReady() {}

  /// 内部首帧就绪调度方法，供容器在 [internalInit] 后调用。
  ///
  /// Internal scheduler invoked by the DI container right after
  /// [internalInit] to trigger [onReady] on the next post-frame callback.
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
