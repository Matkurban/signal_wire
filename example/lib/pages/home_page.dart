import 'package:material_ui/material_ui.dart';
import 'package:signal_wire/signal_wire.dart';

import '../services/auth_service.dart';
import '../services/workspace_log_service.dart';
import 'draft_editor_page.dart';
import 'project_scope_page.dart';
import 'task_board_page.dart';

/// WireDesk 工作台首页，展示全局认证状态、三大模式入口及实时 [WireLogger] 日志流。
///
/// Home dashboard of WireDesk displaying global [AuthService] state,
/// navigation entries to the three binding modes, and a live [WireLogger]
/// event feed.
class HomePage extends StatelessWidget {
  /// 创建 WireDesk 工作台首页。
  ///
  /// Creates a [HomePage].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = Wire.find<AuthService>();
    final WorkspaceLogService logService = Wire.find<WorkspaceLogService>();

    return Scaffold(
      appBar: AppBar(title: const Text('WireDesk · signal_wire')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Global WireService · AuthService',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SignalBuilder(
                    builder: (BuildContext context) {
                      final String status = auth.isSignedIn.value
                          ? 'Signed in as ${auth.username.value}'
                          : 'Guest mode (signed out)';
                      return Text(status);
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('btn_toggle_auth'),
                    onPressed: auth.toggleAuth,
                    child: const Text('Toggle Sign-In Status'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('nav_mode_a'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TaskBoardPage()),
              );
            },
            child: const Text(
              'Mode A · WireView (Task Board: List/Set/Future/Effect)',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            key: const Key('nav_mode_b'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DraftEditorPage(),
                ),
              );
            },
            child: const Text(
              'Mode B · SignalsMixin + WireStateMixin (Tracked + Undo/Redo)',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            key: const Key('nav_mode_c'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProjectScopePage(),
                ),
              );
            },
            child: const Text(
              'Mode C · WireScope (Dynamic Tag Rooms + Force Swap)',
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Live WireLogger Stream',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: logService.clear,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SignalBuilder(
                    builder: (BuildContext context) {
                      final List<WireLogRecord> items = logService.records
                          .take(8)
                          .toList(growable: false);
                      if (items.isEmpty) {
                        return const Text('No logs recorded yet.');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items
                            .map(
                              (WireLogRecord rec) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  rec.format(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
