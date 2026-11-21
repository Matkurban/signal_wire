import 'package:flutter/widgets.dart';

import '../core/wire_controller.dart';
import '../di/wire.dart';
import '../log/wire_log_category.dart';
import '../log/wire_logger.dart';

/// 模式 B：面向 [StatefulWidget] 的控制器生命周期混入。
///
/// Mode B: State mixin binding a [WireController] lifecycle to a [State].
///
/// 专为需要使用 [StatefulWidget] 的页面设计（例如需要同时混入 `SignalsMixin`、
/// `TickerProviderStateMixin`、`AutomaticKeepAliveClientMixin` 或配合
/// `SignalStatefulWidget` 使用）。泛型 [T] 严格约束为 [WireController]。
///
/// Designed for [StatefulWidget] pages that also mix in `SignalsMixin`,
/// `TickerProviderStateMixin`, `AutomaticKeepAliveClientMixin`, or extend
/// `SignalStatefulWidget`. Type [T] is strictly constrained to [WireController].
mixin WireStateMixin<W extends StatefulWidget, T extends WireController>
    on State<W> {
  /// 缓存的当前控制器实例引用。
  ///
  /// Cached reference to the bound controller instance.
  T? _controller;

  /// 当前 [State] 是否拥有所绑定控制器的销毁权。
  ///
  /// Whether this [State] owns disposal of the bound controller.
  bool _ownsController = false;

  /// 当前 [State] 实际创建的控制器实例引用，防止误删被外部 `force: true` 替换的新实例。
  ///
  /// Reference to the instance created by this [State] to avoid deleting a
  /// newer instance installed via `Wire.put(..., force: true)`.
  T? _createdController;

  /// 绑定时记录的控制器标签。
  ///
  /// Tag recorded when the controller was bound.
  String? _boundTag;

  /// 可选的控制器实例标签，用于区分同类型多实例。
  ///
  /// Optional tag distinguishing multiple instances of the same controller
  /// type [T].
  String? get tag => null;

  /// 可选的控制器创建方法。
  ///
  /// Optional factory method to create a controller owned by this [State].
  T? wire() => null;

  /// 获取当前 [State] 绑定的控制器实例。
  ///
  /// Returns the controller instance bound to this [State].
  ///
  /// 若外部曾通过 `Wire.put(..., force: true)` 强制替换了同键控制器导致缓存的旧实例已关闭，
  /// 此属性会自动同步为容器中的最新活跃实例，确保界面不出现已销毁信号读取异常。
  T get controller {
    final T? cached = _controller;
    if (cached != null && !cached.isClosed) {
      return cached;
    }

    final String? effectiveTag = _boundTag ?? tag;
    WireLogger.info(
      WireLogCategory.widget,
      'WireStateMixin refreshed controller reference after external replacement.',
      type: T,
      tag: effectiveTag,
    );
    final T refreshed = Wire.find<T>(tag: effectiveTag);
    _controller = refreshed;
    return refreshed;
  }

  @override
  void initState() {
    super.initState();
    _boundTag = tag;

    final T? created = wire();
    if (created != null) {
      final T active = Wire.put<T>(created, tag: _boundTag);
      final bool isOwner = identical(active, created);
      _controller = active;
      _ownsController = isOwner;
      _createdController = isOwner ? active : null;
      WireLogger.debug(
        WireLogCategory.widget,
        'WireStateMixin initialized and bound controller (ownsDisposal=$isOwner).',
        type: T,
        tag: _boundTag,
      );
    } else {
      _controller = Wire.find<T>(tag: _boundTag);
      _ownsController = false;
      _createdController = null;
      WireLogger.debug(
        WireLogCategory.widget,
        'WireStateMixin initialized and attached to external controller.',
        type: T,
        tag: _boundTag,
      );
    }
  }

  @override
  void dispose() {
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
            'WireStateMixin disposing owned controller.',
            type: T,
            tag: tagToDelete,
          );
          Wire.delete<T>(tag: tagToDelete);
        } else {
          WireLogger.info(
            WireLogCategory.widget,
            'WireStateMixin skipped delete because controller was replaced externally.',
            type: T,
            tag: tagToDelete,
          );
        }
      }
    }

    _controller = null;
    _boundTag = null;
    super.dispose();
  }
}
