import 'package:material_ui/material_ui.dart';
import 'package:signal_wire/signal_wire.dart';

import '../controllers/project_scope_controller.dart';

/// 模式 C 内部纯展示面板，渲染 [ProjectScopeController] 中的成员在线表（`MapSignal`）与通知队列（`QueueSignal`）。
///
/// Presentational panel inside Mode C rendering member presence (`MapSignal`)
/// and notification queue (`QueueSignal`) from [ProjectScopeController].
class ProjectRoomPanel extends StatelessWidget {
  /// 创建协作房间展示面板。
  ///
  /// Creates a [ProjectRoomPanel].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  /// - [controller]：当前作用域托管的房间控制器。 / Active scoped controller.
  const ProjectRoomPanel({super.key, required this.controller});

  /// 外部 `WireScope` 注入的控制器实例。
  ///
  /// Scoped controller provided by `WireScope`.
  final ProjectScopeController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SignalBuilder(
              builder: (BuildContext context) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Room: ${controller.roomName} · '
                      'Online: ${controller.onlineCount.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...controller.memberPresence.entries.map(
                      (MapEntry<String, bool> entry) => SwitchListTile(
                        key: Key('member_${entry.key}'),
                        title: Text(entry.key),
                        value: entry.value,
                        onChanged: (_) => controller.toggleMember(entry.key),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SignalBuilder(
              builder: (BuildContext context) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Notification Queue (${controller.notifications.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        FilledButton(
                          key: const Key('btn_push_notice'),
                          onPressed: controller.pushNotification,
                          child: const Text('Push Notice'),
                        ),
                        OutlinedButton(
                          key: const Key('btn_consume_notice'),
                          onPressed: controller.notifications.isNotEmpty
                              ? controller.consumeNotification
                              : null,
                          child: const Text('Consume First'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...controller.notifications.map(Text.new),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
