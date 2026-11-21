import 'package:meta/meta.dart';

import 'wire_log_category.dart';
import 'wire_log_level.dart';

/// 结构化日志记录对象，包含时间戳、级别、分类、消息、关联类型与异常信息。
///
/// Immutable structured log record carrying timestamp, severity level,
/// category, message, optional dependency metadata, and error details.
@immutable
final class WireLogRecord {
  /// 创建一条结构化日志记录。
  ///
  /// Creates a [WireLogRecord].
  ///
  /// - [timestamp]：日志产生时间。 / Timestamp when the log was created.
  /// - [level]：日志严重级别。 / Severity level of the record.
  /// - [category]：所属功能分类。 / Functional subsystem category.
  /// - [message]：可读日志正文。 / Human-readable log message.
  /// - [type]：可选关联的依赖或组件类型。 / Optional associated dependency or
  ///   widget type.
  /// - [tag]：可选关联的实例标签。 / Optional associated instance tag.
  /// - [error]：可选异常对象。 / Optional error object.
  /// - [stackTrace]：可选堆栈跟踪信息。 / Optional stack trace.
  const WireLogRecord({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.type,
    this.tag,
    this.error,
    this.stackTrace,
  });

  /// 日志产生的时间戳。
  ///
  /// Timestamp when this record was emitted.
  final DateTime timestamp;

  /// 日志级别。
  ///
  /// Severity level of this record.
  final WireLogLevel level;

  /// 日志所属分类。
  ///
  /// Subsystem category of this record.
  final WireLogCategory category;

  /// 日志正文内容。
  ///
  /// Human-readable description of the event.
  final String message;

  /// 可选关联的目标类型。
  ///
  /// Optional target [Type] related to this event.
  final Type? type;

  /// 可选关联的实例标签。
  ///
  /// Optional instance tag related to this event.
  final String? tag;

  /// 可选捕获的异常对象。
  ///
  /// Optional captured error object.
  final Object? error;

  /// 可选捕获的堆栈跟踪。
  ///
  /// Optional stack trace accompanying [error].
  final StackTrace? stackTrace;

  /// 将日志记录格式化为统一、易读的单行或多行字符串。
  ///
  /// Formats this record into a consistent human-readable string.
  String format() {
    final StringBuffer buffer = StringBuffer()
      ..write('[signal_wire][')
      ..write(level.label)
      ..write('][')
      ..write(category.label)
      ..write(']');

    if (type != null) {
      buffer
        ..write(' ')
        ..write(type);
      if (tag != null) {
        buffer
          ..write('(tag: "')
          ..write(tag)
          ..write('")');
      }
      buffer.write(':');
    } else if (tag != null) {
      buffer
        ..write(' (tag: "')
        ..write(tag)
        ..write('"):');
    }

    buffer
      ..write(' ')
      ..write(message);

    if (error != null) {
      buffer
        ..write(' | error: ')
        ..write(error);
    }

    return buffer.toString();
  }

  @override
  String toString() => format();
}
