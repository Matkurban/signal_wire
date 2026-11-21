import 'package:material_ui/material_ui.dart';
import 'package:signal_wire/signal_wire.dart';

import '../controllers/task_board_controller.dart';
import '../models/work_task.dart';
import '../services/auth_service.dart';

/// 模式 A（[WireView]）演示页：协作任务看板。
///
/// Mode A ([WireView]) demo page: reactive Sprint Task Board.
///
/// 重写 [wire] 自动创建并注册 [TaskBoardController]，页面退出时自动回收所有
/// `ListSignal`、`SetSignal`、`FutureSignal`、`Computed` 与 `Effect`。
class TaskBoardPage extends WireView<TaskBoardController> {
  /// 创建任务看板页面。
  ///
  /// Creates a [TaskBoardPage].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  const TaskBoardPage({super.key});

  @override
  TaskBoardController wire() => TaskBoardController();

  @override
  Widget build(BuildContext context) {
    final AuthService auth = Wire.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode A · Task Board'),
        actions: <Widget>[
          IconButton(
            key: const Key('btn_refresh_sync'),
            onPressed: controller.refreshSync,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab_add_task'),
        onPressed: controller.addQuickTask,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SignalBuilder(
              builder: (BuildContext context) {
                final String owner = auth.username.value ?? 'Guest';
                final String syncText = controller.syncStatus.value.map(
                  data: (String value) => value,
                  error: (Object err, StackTrace? _) => 'Error: $err',
                  loading: () => 'Syncing...',
                );
                return Text(
                  'Owner: $owner · $syncText\n${controller.progressNote.value}',
                );
              },
            ),
            const SizedBox(height: 12),
            SignalBuilder(
              builder: (BuildContext context) {
                return Wrap(
                  spacing: 8,
                  children: <String>['UI', 'API', 'Test']
                      .map((String tagName) {
                        final bool selected = controller.activeTags.contains(
                          tagName,
                        );
                        return FilterChip(
                          key: Key('chip_$tagName'),
                          label: Text(tagName),
                          selected: selected,
                          onSelected: (_) =>
                              controller.toggleTagFilter(tagName),
                        );
                      })
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SignalBuilder(
                builder: (BuildContext context) {
                  final List<WorkTask> visible = controller.filteredTasks.value;
                  return ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (BuildContext context, int index) {
                      final WorkTask task = visible[index];
                      return CheckboxListTile(
                        key: Key('task_${task.id}'),
                        value: task.completed,
                        onChanged: (_) => controller.toggleTask(task.id),
                        title: Text(task.title),
                        subtitle: Text('${task.id} · ${task.tag}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
