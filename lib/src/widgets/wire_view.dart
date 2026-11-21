import 'package:flutter/widgets.dart';

import '../core/wire_controller.dart';
import '../di/wire.dart';
import 'wire_view_element.dart';

/// 模式 A：极简视图基类，直接继承 [Widget] 并由自定义 [ComponentElement] 托管控制器生命周期。
///
/// Mode A: Minimal reactive view base class extending [Widget] directly with
/// a custom [ComponentElement] managing controller lifecycle.
///
/// 泛型 [T] 严格约束为 [WireController]，在编译期防止误将全局常驻服务
/// `WireService` 绑定到页面生命周期中。
///
/// Type parameter [T] is strictly constrained to [WireController] so that
/// global `WireService` instances cannot be accidentally bound to a page
/// lifecycle at compile time.
///
/// 遵循“谁创建、谁销毁”原则 / Ownership rule ("whoever creates, disposes"):
/// - **重写了 [wire]**：在挂载（`mount`）时自动调用 `Wire.put` 注册控制器，
///   在卸载（`unmount`）时自动调用 `Wire.delete` 回收。
/// - **未重写 [wire]**（返回 `null`）：在挂载时通过 `Wire.find` 获取外部已注入实例，
///   卸载时不会销毁该实例。
///
/// - **Overriding [wire]**: automatically calls `Wire.put` on `mount` and
///   `Wire.delete` on `unmount`.
/// - **Not overriding [wire]** (returns `null`): resolves an externally
///   registered instance via `Wire.find` and does not dispose it on `unmount`.
abstract class WireView<T extends WireController> extends Widget {
  /// 创建一个极简视图组件。
  ///
  /// Creates a [WireView] widget.
  ///
  /// - [key]：可选的 Flutter [Key]。 / Optional Flutter widget key.
  const WireView({super.key});

  /// 可选的控制器实例标签，用于区分同类型多实例。
  ///
  /// Optional tag used to distinguish multiple instances of the same
  /// controller type [T].
  String? get tag => null;

  /// 可选的控制器创建方法。
  ///
  /// Optional factory method to create and bind a controller to this view's
  /// lifecycle.
  ///
  /// - 返回非空实例：由当前 [WireView] 负责注册并在卸载时自动回收。
  /// - 返回 `null`（默认）：从 `Wire` 容器中查找外部已注册的实例，卸载时不销毁。
  ///
  /// - Returning a non-null instance makes this [WireView] own its
  ///   registration and automatic disposal on unmount.
  /// - Returning `null` (default) resolves an externally registered instance
  ///   without disposing it on unmount.
  T? wire() => null;

  /// 获取当前视图绑定的控制器实例。
  ///
  /// Returns the controller instance bound to this view.
  ///
  /// 由于 [WireViewElement] 在首次 [build] 前即完成控制器注册，因此在 [build]
  /// 方法及其回调中访问 [controller] 始终安全可用，且在外部通过
  /// `Wire.put(..., force: true)` 强制替换后也能自动指向最新实例。
  ///
  /// Safe to access inside [build] and its event callbacks because
  /// [WireViewElement] binds the controller before the first [build]. Always
  /// resolves to the active instance even after a forced replacement.
  T get controller => Wire.find<T>(tag: tag);

  /// 构建当前视图的用户界面。
  ///
  /// Describes the part of the user interface represented by this view.
  ///
  /// - [context]：当前构建上下文。 / The build context for this widget.
  Widget build(BuildContext context);

  @override
  Element createElement() => WireViewElement<T>(this);
}
