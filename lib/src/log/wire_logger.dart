import 'package:flutter/foundation.dart';

import 'wire_log_category.dart';
import 'wire_log_level.dart';
import 'wire_log_record.dart';

/// `signal_wire` 统一日志调度器。
///
/// Centralized logger for `signal_wire`.
///
/// 设计特性 / Design highlights:
/// - **默认 Debug 开启、Release 静默**：[enabled] 默认为 `kDebugMode`，避免生产包无谓刷屏。
/// - **分级过滤**：通过 [minLevel] 精确控制输出粒度（默认 [WireLogLevel.debug]）。
/// - **可插拔外部处理器**：通过 [handler] 对接第三方日志框架（如 `logger`、`talker`、
///   远程监控或应用内日志面板），未设置时默认通过 `debugPrint` 输出。
/// - **防重入保护**：若自定义 [handler] 内部触发了新的 `WireLogger` 调用，自动拦截防死循环。
///
/// - **Debug-on, Release-quiet by default**: [enabled] defaults to `kDebugMode`.
/// - **Level filtering**: filters events by [minLevel] (defaults to
///   [WireLogLevel.debug]).
/// - **Pluggable handler**: set [handler] to forward [WireLogRecord] instances
///   to any external logger or in-app log viewer; defaults to `debugPrint`.
/// - **Re-entrancy safe**: guards against recursive logging inside custom
///   handlers.
abstract final class WireLogger {
  /// 全局日志总开关，默认在 Debug 模式为 `true`，Release 模式为 `false`。
  ///
  /// Global logging toggle; defaults to `kDebugMode`.
  static bool enabled = kDebugMode;

  /// 允许输出的最低日志级别，默认为 [WireLogLevel.debug]。
  ///
  /// Minimum severity level to emit; defaults to [WireLogLevel.debug].
  static WireLogLevel minLevel = WireLogLevel.debug;

  /// 自定义日志回调处理器；为 `null` 时使用 `debugPrint(record.format())`。
  ///
  /// Optional custom log sink; falls back to `debugPrint(record.format())`
  /// when `null`.
  static void Function(WireLogRecord record)? handler;

  /// 重入保护标志，防止自定义处理器内部再次触发日志形成递归死循环。
  ///
  /// Re-entrancy guard preventing infinite recursion when a custom [handler]
  /// triggers another log call.
  static bool _isEmitting = false;

  /// 一次性配置日志系统的开关、最低级别与自定义处理器。
  ///
  /// Convenience method to configure [enabled], [minLevel], and [handler].
  ///
  /// - [enabled]：可选，更新全局日志总开关。 / Optional global enable flag.
  /// - [minLevel]：可选，更新最低日志级别。 / Optional minimum severity level.
  /// - [handler]：可选，设置自定义日志处理器。 / Optional custom log handler.
  /// - [clearHandler]：若为 `true`，将 [handler] 重置为 `null`（恢复默认 `debugPrint`）。
  ///   When `true`, clears [handler] back to `null`.
  static void configure({
    bool? enabled,
    WireLogLevel? minLevel,
    void Function(WireLogRecord record)? handler,
    bool clearHandler = false,
  }) {
    if (enabled != null) {
      WireLogger.enabled = enabled;
    }
    if (minLevel != null) {
      WireLogger.minLevel = minLevel;
    }
    if (clearHandler) {
      WireLogger.handler = null;
    } else if (handler != null) {
      WireLogger.handler = handler;
    }
  }

  /// 将日志系统恢复至默认配置（常用于单元测试 `tearDown`）。
  ///
  /// Resets logger configuration to defaults (useful in test `tearDown`).
  static void reset() {
    enabled = kDebugMode;
    minLevel = WireLogLevel.debug;
    handler = null;
    _isEmitting = false;
  }

  /// 输出 [WireLogLevel.verbose] 级别日志。
  ///
  /// Emits a [WireLogLevel.verbose] log record.
  static void verbose(
    WireLogCategory category,
    String message, {
    Type? type,
    String? tag,
  }) {
    log(
      level: WireLogLevel.verbose,
      category: category,
      message: message,
      type: type,
      tag: tag,
    );
  }

  /// 输出 [WireLogLevel.debug] 级别日志。
  ///
  /// Emits a [WireLogLevel.debug] log record.
  static void debug(
    WireLogCategory category,
    String message, {
    Type? type,
    String? tag,
  }) {
    log(
      level: WireLogLevel.debug,
      category: category,
      message: message,
      type: type,
      tag: tag,
    );
  }

  /// 输出 [WireLogLevel.info] 级别日志。
  ///
  /// Emits a [WireLogLevel.info] log record.
  static void info(
    WireLogCategory category,
    String message, {
    Type? type,
    String? tag,
  }) {
    log(
      level: WireLogLevel.info,
      category: category,
      message: message,
      type: type,
      tag: tag,
    );
  }

  /// 输出 [WireLogLevel.warning] 级别日志。
  ///
  /// Emits a [WireLogLevel.warning] log record.
  static void warning(
    WireLogCategory category,
    String message, {
    Type? type,
    String? tag,
  }) {
    log(
      level: WireLogLevel.warning,
      category: category,
      message: message,
      type: type,
      tag: tag,
    );
  }

  /// 输出 [WireLogLevel.error] 级别日志（可附带异常与堆栈）。
  ///
  /// Emits a [WireLogLevel.error] log record with optional [error] and
  /// [stackTrace].
  static void error(
    WireLogCategory category,
    String message, {
    Type? type,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      level: WireLogLevel.error,
      category: category,
      message: message,
      type: type,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 底层日志分发方法，负责开关检查、级别过滤与防重入安全派发。
  ///
  /// Core log dispatch method applying toggle checks, severity filtering,
  /// and re-entrancy protection.
  ///
  /// - [level]：日志级别。 / Severity level.
  /// - [category]：所属分类。 / Subsystem category.
  /// - [message]：日志正文。 / Message body.
  /// - [type]：可选关联类型。 / Optional target type.
  /// - [tag]：可选关联标签。 / Optional target tag.
  /// - [error]：可选异常对象。 / Optional error object.
  /// - [stackTrace]：可选堆栈信息。 / Optional stack trace.
  static void log({
    required WireLogLevel level,
    required WireLogCategory category,
    required String message,
    Type? type,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled ||
        level == WireLogLevel.none ||
        minLevel == WireLogLevel.none ||
        level.priority < minLevel.priority ||
        _isEmitting) {
      return;
    }

    final WireLogRecord record = WireLogRecord(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      type: type,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );

    _isEmitting = true;
    try {
      final void Function(WireLogRecord record)? customHandler = handler;
      if (customHandler != null) {
        customHandler(record);
      } else {
        debugPrint(record.format());
      }
    } finally {
      _isEmitting = false;
    }
  }
}
