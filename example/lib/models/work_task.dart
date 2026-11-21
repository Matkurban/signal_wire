import 'package:flutter/foundation.dart';

/// 协作工作台中的不可变任务数据模型。
///
/// Immutable task entity model used in the WireDesk example application.
@immutable
class WorkTask {
  /// 创建一个任务实体。
  ///
  /// Creates a [WorkTask].
  ///
  /// - [id]：任务唯一编号。 / Unique task identifier.
  /// - [title]：任务标题。 / Task title.
  /// - [tag]：任务分类标签（例如 `UI`、`API`、`Test`）。 / Category tag.
  /// - [completed]：是否已完成，默认为 `false`。 / Completion status.
  const WorkTask({
    required this.id,
    required this.title,
    required this.tag,
    this.completed = false,
  });

  /// 任务唯一编号。
  ///
  /// Unique identifier of this task.
  final String id;

  /// 任务标题。
  ///
  /// Display title of this task.
  final String title;

  /// 任务分类标签。
  ///
  /// Category tag (e.g. `UI`, `API`, `Test`).
  final String tag;

  /// 是否已完成。
  ///
  /// Whether this task has been completed.
  final bool completed;

  /// 复制并修改指定字段生成新的 [WorkTask] 实例。
  ///
  /// Returns a copy of this [WorkTask] with the specified fields replaced.
  WorkTask copyWith({String? title, String? tag, bool? completed}) {
    return WorkTask(
      id: id,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      completed: completed ?? this.completed,
    );
  }
}
