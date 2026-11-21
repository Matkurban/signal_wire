import 'package:flutter/widgets.dart';

import '../core/wire_controller.dart';
import '../di/wire.dart';
import '../log/wire_log_category.dart';
import '../log/wire_logger.dart';

/// 模式 C：作用域包裹组件，将 [WireController] 的注册与销毁严格绑定到当前子树生命周期。
///
/// Mode C: Scope wrapper widget that strictly binds a [WireController]'s
/// registration and disposal to its subtree lifecycle.
///
/// 允许包裹任意 Flutter 组件（包括 `StatelessWidget`、`StatefulWidget`、
/// `SignalStatefulWidget` 或第三方组件）。泛型 [T] 严格约束为 [WireController]。
///
/// Can wrap any Flutter widget (`StatelessWidget`, `StatefulWidget`,
/// `SignalStatefulWidget`, or third-party widgets). Type [T] is strictly
/// constrained to [WireController].
class WireScope<T extends WireController> extends StatefulWidget {
  /// 创建一个控制器作用域包裹组件。
  ///
  /// Creates a [WireScope] widget.
  ///
  /// [builder] 与 [child] 必须至少提供一个。若两者同时提供，优先调用 [builder]。
  /// At least one of [builder] or [child] must be provided. If both are
  /// provided, [builder] takes precedence.
  ///
  /// - [key]：可选的 Flutter [Key]。 / Optional Flutter widget key.
  /// - [create]：创建控制器实例的工厂函数。 / Factory creating the controller.
  /// - [tag]：可选的实例标签，用于区分同类型多实例。 / Optional tag for
  ///   distinguishing multiple instances of type [T].
  /// - [builder]：直接接收 `BuildContext` 与控制器实例的构建回调。 / Builder
  ///   callback receiving both `BuildContext` and the active controller.
  /// - [child]：静态子组件（内部可通过 `Wire.find<T>(tag: ...)` 访问控制器）。
  ///   Static child widget (can look up the controller via `Wire.find`).
  const WireScope({
    super.key,
    required this.create,
    this.tag,
    this.builder,
    this.child,
  }) : assert(
         builder != null || child != null,
         'WireScope requires either a `builder` or a `child`.',
       );

  /// 控制器工厂函数，在 [WireScope] 初始化（或 [tag] 变更）时调用。
  ///
  /// Factory callback creating the controller when [WireScope] initializes
  /// or when [tag] changes.
  final T Function() create;

  /// 可选的控制器实例标签。
  ///
  /// Optional tag distinguishing multiple instances of [T].
  final String? tag;

  /// 接收当前控制器实例的子树构建器。
  ///
  /// Optional builder callback receiving the current [BuildContext] and
  /// active controller [T].
  final Widget Function(BuildContext context, T controller)? builder;

  /// 可选的静态子组件。
  ///
  /// Optional static child widget rendered when [builder] is omitted.
  final Widget? child;

  @override
  State<WireScope<T>> createState() => _WireScopeState<T>();
}

/// [WireScope] 对应的私有状态类，按 Flutter 标准与组件定义在同一文件中。
///
/// Private [State] class backing [WireScope], managing controller registration,
/// dynamic tag switching, and automatic disposal.
final class _WireScopeState<T extends WireController>
    extends State<WireScope<T>> {
  /// 当前绑定的控制器实例。
  ///
  /// Currently bound controller instance.
  T? _controller;

  /// 当前状态是否拥有控制器销毁权。
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
