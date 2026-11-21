import 'package:flutter/widgets.dart';

import '../core/wire_controller.dart';
import 'wire_scope_state.dart';

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
  State<WireScope<T>> createState() => WireScopeState<T>();
}
