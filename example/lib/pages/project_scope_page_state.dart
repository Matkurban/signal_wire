import 'package:material_ui/material_ui.dart';
import 'package:signal_wire/signal_wire.dart';

import '../controllers/project_scope_controller.dart';
import 'project_room_panel.dart';
import 'project_scope_page.dart';

/// [ProjectScopePage] 对应的状态类，使用局部信号动态切换 `WireScope` 的 `tag` 与重建版本。
///
/// State for [ProjectScopePage] switching the active [WireScope] `tag` and
/// demonstrating UI-safe `Wire.put(..., force: true)` replacement.
class ProjectScopePageState extends State<ProjectScopePage>
    with
        // ignore: deprecated_member_use
        SignalsMixin {
  /// 当前选中的项目房间标签信号。
  ///
  /// Active room tag signal (`project_alpha` or `project_beta`).
  late final FlutterSignal<String> activeRoom = createSignal<String>(
    'project_alpha',
  );

  /// 强制替换次数信号，用于在 `force: true` 替换后通知子树重新绑定最新控制器。
  ///
  /// Revision signal incremented after `Wire.put(..., force: true)` swaps.
  late final FlutterSignal<int> swapVersion = createSignal<int>(0);

  /// 使用 `Wire.put(..., force: true)` 强制销毁并重建当前房间的控制器。
  ///
  /// Replaces the current room's controller via `Wire.put(..., force: true)`
  /// without causing UI exceptions.
  void forceResetCurrentRoom() {
    final String room = activeRoom.value;
    Wire.put<ProjectScopeController>(
      ProjectScopeController(roomName: '$room#reset${swapVersion.value + 1}'),
      tag: room,
      force: true,
    );
    swapVersion.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode C · WireScope Rooms')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SignalBuilder(
              builder: (BuildContext context) {
                final String current = activeRoom.value;
                return Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      key: const Key('room_alpha'),
                      label: const Text('project_alpha'),
                      selected: current == 'project_alpha',
                      onSelected: (_) => activeRoom.value = 'project_alpha',
                    ),
                    ChoiceChip(
                      key: const Key('room_beta'),
                      label: const Text('project_beta'),
                      selected: current == 'project_beta',
                      onSelected: (_) => activeRoom.value = 'project_beta',
                    ),
                    OutlinedButton(
                      key: const Key('btn_force_swap'),
                      onPressed: forceResetCurrentRoom,
                      child: const Text('Force Reset (force: true)'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SignalBuilder(
                builder: (BuildContext context) {
                  final String room = activeRoom.value;
                  // 订阅 swapVersion 确保 force: true 强替换后 builder 拿到最新控制器。
                  final int version = swapVersion.value;
                  return WireScope<ProjectScopeController>(
                    tag: room,
                    create: () => ProjectScopeController(roomName: room),
                    builder:
                        (
                          BuildContext context,
                          ProjectScopeController controller,
                        ) {
                          return ProjectRoomPanel(
                            key: ValueKey<String>('$room-$version'),
                            controller: controller,
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
