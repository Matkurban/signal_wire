import 'package:meta/meta.dart';

/// 依赖注入容器内部条目模型，封装实例引用、懒加载构造器及生命周期策略。
///
/// Internal registry entry model storing an active instance, optional lazy
/// builder factory, and lifecycle flags (`permanent` and `fenix`).
@internal
final class WireEntry<T> {
  /// 创建一个容器注册条目。
  ///
  /// Creates a registry entry.
  ///
  /// - [instance]：当前已创建的实例；若为尚未实例化的懒加载条目则为 `null`。
  ///   Active instance, or `null` if lazily registered and not yet created.
  /// - [builder]：懒加载或 `fenix` 重建使用的工厂函数。 / Factory function
  ///   used for lazy instantiation and `fenix` recreation.
  /// - [permanent]：是否受常驻保护（普通 `delete` 无法删除）。 / Whether
  ///   this entry is protected from non-forced deletion.
  /// - [fenix]：销毁实例后是否保留 [builder] 以便下次 `find` 自动重建。
  ///   Whether to retain [builder] after disposal for automatic recreation
  ///   on the next `find`.
  WireEntry({
    this.instance,
    this.builder,
    required this.permanent,
    required this.fenix,
  });

  /// 当前已实例化的对象引用。
  ///
  /// Currently active instance, or `null` if not yet instantiated.
  T? instance;

  /// 用于懒加载或涅槃重建（[fenix]）的工厂函数。
  ///
  /// Factory callback for lazy instantiation or [fenix] recreation.
  final T Function()? builder;

  /// 是否启用常驻保护。
  ///
  /// Whether this entry is protected against non-forced deletion.
  bool permanent;

  /// 销毁后再次查找时是否自动重建。
  ///
  /// Whether to recreate the instance on subsequent lookups after deletion.
  final bool fenix;

  /// 是否已持有活跃实例。
  ///
  /// Returns `true` if an active [instance] has already been created.
  bool get hasInstance => instance != null;
}
