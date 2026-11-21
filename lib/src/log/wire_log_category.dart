/// `signal_wire` 日志事件分类枚举。
///
/// Functional categories for `signal_wire` log records.
///
/// 便于在控制台或外部日志系统中按模块筛选依赖注入、生命周期、视图绑定或信号托管事件。
/// Allows filtering logs by subsystem across DI, lifecycle, widgets, and
/// managed signals.
enum WireLogCategory {
  /// 依赖注入容器相关事件（注册、查找、懒加载、强制替换、删除、重置）。
  ///
  /// Dependency injection container events (put, find, lazyPut, force swap,
  /// delete, reset).
  di('di'),

  /// 生命周期与资源自动回收事件（`onInit`、`onReady`、`onClose`、`autoDispose`）。
  ///
  /// Lifecycle and automatic disposal events (`onInit`, `onReady`, `onClose`,
  /// `autoDispose`).
  lifecycle('lifecycle'),

  /// 视图层绑定事件（`WireView`、`WireStateMixin`、`WireScope` 挂载/更新/卸载）。
  ///
  /// View binding events (`WireView`, `WireStateMixin`, `WireScope` mount,
  /// update, and unmount).
  widget('widget'),

  /// 托管信号创建与清理事件。
  ///
  /// Managed signal creation and disposal events.
  signal('signal');

  /// 创建一个日志分类枚举值。
  ///
  /// Creates a [WireLogCategory] enum value.
  ///
  /// - [label]：格式化输出时使用的模块短名称。 / Short subsystem label.
  const WireLogCategory(this.label);

  /// 格式化输出时使用的分类标签。
  ///
  /// Short label emitted in formatted log lines.
  final String label;
}
