/// `signal_wire` 日志输出级别枚举。
///
/// Log verbosity levels for `signal_wire`.
///
/// 级别按严重程度从低到高排序：[verbose] < [debug] < [info] < [warning] <
/// [error] < [none]。当配置 `WireLogger.minLevel` 时，仅会输出大于或等于该级别的日志。
///
/// Ordered from lowest to highest severity: [verbose] < [debug] < [info] <
/// [warning] < [error] < [none]. Only records with severity greater than or
/// equal to `WireLogger.minLevel` are emitted.
enum WireLogLevel {
  /// 极详细追踪日志（例如单个资源释放、跳过帧回调等）。
  ///
  /// Very detailed trace logs (e.g., individual resource disposals or skipped
  /// post-frame scheduling).
  verbose(0, 'VERBOSE'),

  /// 常规调试日志（例如 `put`、`find`、`delete`、`onInit`、`onReady`、`onClose`、视图挂载/卸载）。
  ///
  /// Routine debug logs (e.g., `put`, `find`, `delete`, lifecycle hooks, and
  /// widget mount/unmount events).
  debug(1, 'DEBUG'),

  /// 重要状态变更日志（例如常驻服务注册、`force: true` 替换、`fenix` 重建、`reset`）。
  ///
  /// Significant state transitions (e.g., permanent service registration,
  /// `force: true` replacements, `fenix` recreations, and container resets).
  info(2, 'INFO'),

  /// 警告日志（例如重复 `put` 返回已有实例、`delete` 被常驻保护拦截、`lazyPut` 被忽略）。
  ///
  /// Warning logs (e.g., duplicate `put` returning an existing instance,
  /// `delete` blocked by `permanent`, or ignored `lazyPut`).
  warning(3, 'WARNING'),

  /// 错误日志（例如未找到依赖抛出 `WireNotFoundException`、`onClose` 或清理回调异常）。
  ///
  /// Error logs (e.g., `WireNotFoundException` lookups, or exceptions thrown
  /// during `onClose`, auto-dispose, or `putAsync`).
  error(4, 'ERROR'),

  /// 完全关闭日志输出。
  ///
  /// Disables all log output.
  none(5, 'NONE');

  /// 创建一个日志级别枚举值。
  ///
  /// Creates a [WireLogLevel] enum value.
  ///
  /// - [priority]：用于级别比较的数值权重。 / Numeric severity priority.
  /// - [label]：格式化输出时显示的大写标签。 / Uppercase label for formatting.
  const WireLogLevel(this.priority, this.label);

  /// 日志严重程度权重（数值越大级别越高）。
  ///
  /// Numeric severity weight (higher means more severe).
  final int priority;

  /// 日志级别的大写文本标签。
  ///
  /// Uppercase display label for formatted logs.
  final String label;
}
