import 'package:signal_wire/signal_wire.dart';

import '../models/work_task.dart';

/// 页面 1（模式 A：`WireView`）对应的任务看板控制器。
///
/// Controller for Page 1 (Mode A: `WireView`) managing a reactive task board.
///
/// 演示在单个控制器中组合使用 [createListSignal]、[createSetSignal]、
/// [createFutureSignal]、[createComputed] 与 [createEffect]，
/// 并在页面退出时由 `WireView` 自动回收全部资源。
class TaskBoardController extends WireController with WireReadyMixin {
  /// 全部任务列表信号。
  ///
  /// Reactive list of all tasks on the board.
  late final ListSignal<WorkTask> tasks;

  /// 当前激活的标签筛选集合信号（空集合表示展示全部）。
  ///
  /// Reactive set of active filter tags (empty means show all).
  late final SetSignal<String> activeTags;

  /// 异步云端同步状态信号。
  ///
  /// Future signal representing the latest simulated remote sync status.
  late final FutureSignal<String> syncStatus;

  /// 派生计算信号：按 [activeTags] 实时过滤后的任务列表。
  ///
  /// Computed list of tasks filtered by [activeTags].
  late final FlutterComputed<List<WorkTask>> filteredTasks;

  /// 派生计算信号：已完成任务数量。
  ///
  /// Computed count of completed tasks.
  late final FlutterComputed<int> completedCount;

  /// 最近一次副作用生成的进度摘要文本信号。
  ///
  /// Signal updated by an internal effect summarizing completion progress.
  late final FlutterSignal<String> progressNote;

  /// 自增任务序号。
  ///
  /// Monotonic counter for newly added task IDs.
  int _nextTaskNumber = 4;

  @override
  void onInit() {
    super.onInit();
    tasks = createListSignal<WorkTask>(<WorkTask>[
      const WorkTask(
        id: 'T-1',
        title: 'Design WireLogger pipeline',
        tag: 'API',
      ),
      const WorkTask(
        id: 'T-2',
        title: 'Build TaskBoard WireView UI',
        tag: 'UI',
        completed: true,
      ),
      const WorkTask(
        id: 'T-3',
        title: 'Write end-to-end widget tests',
        tag: 'Test',
      ),
    ], options: const ListSignalOptions<WorkTask>(name: 'board_tasks'));

    activeTags = createSetSignal<String>(
      <String>{},
      options: const SetSignalOptions<String>(name: 'board_tags'),
    );

    syncStatus = createFutureSignal<String>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 60));
      return 'Synced ${tasks.length} tasks';
    }, options: const AsyncSignalOptions<String>(name: 'board_sync'));

    filteredTasks = createComputed<List<WorkTask>>(() {
      final Set<String> selected = activeTags.value;
      if (selected.isEmpty) {
        return List<WorkTask>.of(tasks.value);
      }
      return tasks.value
          .where((WorkTask item) => selected.contains(item.tag))
          .toList(growable: false);
    }, options: const ComputedOptions<List<WorkTask>>(name: 'board_filtered'));

    completedCount = createComputed<int>(
      () => tasks.value.where((WorkTask item) => item.completed).length,
      options: const ComputedOptions<int>(name: 'board_completed_count'),
    );

    progressNote = createSignal<String>(
      '',
      options: const SignalOptions<String>(name: 'board_progress_note'),
    );

    createEffect(() {
      progressNote.value =
          'Completed ${completedCount.value} of ${tasks.value.length} tasks';
    }, options: const EffectOptions(name: 'board_progress_effect'));
  }

  /// 切换指定标签的筛选选中状态。
  ///
  /// Toggles whether [tag] is included in [activeTags].
  ///
  /// - [tag]：标签名称（`UI`、`API` 或 `Test`）。 / Tag name to toggle.
  void toggleTagFilter(String tag) {
    if (activeTags.contains(tag)) {
      activeTags.remove(tag);
    } else {
      activeTags.add(tag);
    }
  }

  /// 切换指定任务的完成状态。
  ///
  /// Toggles the completion flag of the task matching [taskId].
  ///
  /// - [taskId]：目标任务编号。 / Identifier of the task to toggle.
  void toggleTask(String taskId) {
    final int index = tasks.indexWhere((WorkTask t) => t.id == taskId);
    if (index == -1) {
      return;
    }
    final WorkTask current = tasks[index];
    tasks[index] = current.copyWith(completed: !current.completed);
  }

  /// 新增一条默认任务到看板。
  ///
  /// Appends a new task to [tasks].
  ///
  /// - [tag]：新任务所属分类标签，默认为 `UI`。 / Category tag for the new task.
  void addQuickTask({String tag = 'UI'}) {
    final int num = _nextTaskNumber++;
    tasks.add(WorkTask(id: 'T-$num', title: 'Sprint item #$num', tag: tag));
  }

  /// 触发异步同步信号重新拉取最新状态。
  ///
  /// Reloads [syncStatus] to simulate a fresh remote synchronization.
  Future<void> refreshSync() => syncStatus.reload();
}
