import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../core/wire_controller.dart';
import '../di/wire.dart';
import '../log/wire_log_category.dart';
import '../log/wire_logger.dart';
import 'wire_view.dart';

/// [WireView] 对应的自定义 [ComponentElement]，负责在挂载与卸载阶段自动管理控制器生命周期。
///
/// Custom [ComponentElement] backing [WireView] that binds and disposes the
/// controller during [mount], [update], and [unmount].
@internal
final class WireViewElement<T extends WireController> extends ComponentElement {
  /// 为指定 [WireView] 创建对应的自定义元素节点。
  ///
  /// Creates a [WireViewElement] for the given [WireView] widget.
  ///
  /// - [widget]：关联的 [WireView] 实例。 / The associated [WireView].
  WireViewElement(WireView<T> super.widget);

  /// 当前元素是否拥有所绑定控制器的销毁权（即由 `widget.wire()` 创建）。
  ///
  /// Whether this element owns disposal of the bound controller (created via
  /// `widget.wire()`).
  bool _ownsController = false;

  /// 当前元素实际创建并注册的控制器引用，用于卸载时避免误删被外部 `force: true` 替换的新实例。
  ///
  /// Reference to the controller instance created by this element so unmount
  /// will not accidentally delete a newer instance replaced via `force: true`.
  T? _createdController;

  /// 当前元素绑定时所使用的标签。
  ///
  /// Tag active when the controller was bound.
  String? _boundTag;

  @override
  WireView<T> get widget => super.widget as WireView<T>;

  @override
  void mount(Element? parent, Object? newSlot) {
    _bindController(widget);
    super.mount(parent, newSlot);
  }

  @override
  void update(covariant WireView<T> newWidget) {
    final String? previousTag = _boundTag;
    final String? nextTag = newWidget.tag;
    super.update(newWidget);

    if (previousTag != nextTag) {
      WireLogger.debug(
        WireLogCategory.widget,
        'WireView tag changed from "$previousTag" to "$nextTag"; rebinding controller.',
        type: T,
        tag: nextTag,
      );
      _unbindController();
      _bindController(newWidget);
    }

    rebuild(force: true);
  }

  @override
  void unmount() {
    _unbindController();
    super.unmount();
  }

  @override
  Widget build() => widget.build(this);

  /// 根据 [targetWidget] 的 `wire()` 与 `tag` 执行控制器注册或查找。
  ///
  /// Registers or resolves the controller according to [targetWidget]'s
  /// `wire()` factory and `tag`.
  void _bindController(WireView<T> targetWidget) {
    final String? currentTag = targetWidget.tag;
    _boundTag = currentTag;

    final T? created = targetWidget.wire();
    if (created != null) {
      final T active = Wire.put<T>(created, tag: currentTag);
      final bool isOwner = identical(active, created);
      _ownsController = isOwner;
      _createdController = isOwner ? active : null;
      WireLogger.debug(
        WireLogCategory.widget,
        'WireView mounted and bound controller (ownsDisposal=$isOwner).',
        type: T,
        tag: currentTag,
      );
    } else {
      Wire.find<T>(tag: currentTag);
      _ownsController = false;
      _createdController = null;
      WireLogger.debug(
        WireLogCategory.widget,
        'WireView mounted and attached to external controller.',
        type: T,
        tag: currentTag,
      );
    }
  }

  /// 按“谁创建、谁销毁”原则安全解绑并回收由当前元素创建的控制器。
  ///
  /// Safely disposes the controller if and only if this element created it
  /// and it is still the active instance in `Wire`.
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
            'WireView unmounting; disposing owned controller.',
            type: T,
            tag: tagToDelete,
          );
          Wire.delete<T>(tag: tagToDelete);
        } else {
          WireLogger.info(
            WireLogCategory.widget,
            'WireView unmounting; skipped delete because controller was replaced externally.',
            type: T,
            tag: tagToDelete,
          );
        }
      }
    }
    _boundTag = null;
  }
}
