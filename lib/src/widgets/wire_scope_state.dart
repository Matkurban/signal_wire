import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../core/wire_controller.dart';
import '../di/wire.dart';
import '../log/wire_log_category.dart';
import '../log/wire_logger.dart';
import 'wire_scope.dart';

/// [WireScope] 对应的状态管理类，负责在挂载、更新与销毁阶段维护控制器生命周期。
///
/// [State] implementation for [WireScope] managing controller registration,
/// dynamic tag switching, and automatic disposal.
@internal
final class WireScopeState<T extends WireController>
    extends State<WireScope<T>> {
  /// 当前绑定的控制器实例。
  ///
  /// Currently bound controller instance.
  T? _controller;

  /// 当前 [WireScopeState] 是否拥有控制器销毁权。
  ///
  /// Whether this state owns disposal of the bound controller.
  bool _ownsController = false;

  /// 当前状态实际创建的控制器引用，防止卸载时误删被外部 `force: true` 替换的新实例。
  ///
  /// Reference to the controller instance created by this state to avoid
  /// deleting a newer instance installed via `Wire.put(..., force: true)`.
  T? _createdController;

  /// 绑定时记录的控制器标签。
  ///
  /// Tag recorded when the controller was bound.
  String? _boundTag;

  @override
  void initState() {
    super.initState();
    _bindController(widget);
  }

  @override
  void didUpdateWidget(covariant WireScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) {
      WireLogger.debug(
        WireLogCategory.widget,
        'WireScope tag changed from "${oldWidget.tag}" to "${widget.tag}"; rebinding controller.',
        type: T,
        tag: widget.tag,
      );
      _unbindController();
      _bindController(widget);
    }
  }

  @override
  void dispose() {
    _unbindController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget Function(BuildContext context, T controller)? builder =
        widget.builder;
    if (builder != null) {
      return builder(context, _resolveActiveController());
    }
    return widget.child!;
  }

  /// 获取当前有效的控制器实例；若旧实例被外部 `force: true` 替换则自动切换至新实例。
  ///
  /// Resolves the active controller, transparently refreshing if the previous
  /// instance was closed by an external `Wire.put(..., force: true)` call.
  T _resolveActiveController() {
    final T? cached = _controller;
    if (cached != null && !cached.isClosed) {
      return cached;
    }
    final String? effectiveTag = _boundTag ?? widget.tag;
    WireLogger.info(
      WireLogCategory.widget,
      'WireScope refreshed controller reference after external replacement.',
      type: T,
      tag: effectiveTag,
    );
    final T refreshed = Wire.find<T>(tag: effectiveTag);
    _controller = refreshed;
    return refreshed;
  }

  /// 创建并注册控制器到 `Wire` 容器。
  ///
  /// Creates and registers the controller in `Wire`.
  void _bindController(WireScope<T> targetWidget) {
    _boundTag = targetWidget.tag;
    final T created = targetWidget.create();
    final T active = Wire.put<T>(created, tag: _boundTag);
    final bool isOwner = identical(active, created);
    _controller = active;
    _ownsController = isOwner;
    _createdController = isOwner ? active : null;
    WireLogger.debug(
      WireLogCategory.widget,
      'WireScope mounted and bound controller (ownsDisposal=$isOwner).',
      type: T,
      tag: _boundTag,
    );
  }

  /// 按“谁创建、谁销毁”原则解绑并回收控制器。
  ///
  /// Safely disposes the controller if owned by this state and still active.
  void _unbindController() {
    if (_ownsController) {
      final String? tagToDelete = _boundTag;
      final T? ownedInstance = _createdController;
      _ownsController = false;
      _createdController = null;

      if (Wire.isRegistered<T>(tag: tagToDelete)) {
        final T current = Wire.find<T>(tag: tagToDelete);
        if (ownedInstance == null || identical(current, ownedInstance)) {
          WireLogger.debug(
            WireLogCategory.widget,
            'WireScope disposing owned controller.',
            type: T,
            tag: tagToDelete,
          );
          Wire.delete<T>(tag: tagToDelete);
        } else {
          WireLogger.info(
            WireLogCategory.widget,
            'WireScope skipped delete because controller was replaced externally.',
            type: T,
            tag: tagToDelete,
          );
        }
      }
    }
    _controller = null;
    _boundTag = null;
  }
}
