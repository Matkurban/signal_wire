import 'package:material_ui/material_ui.dart';
import 'package:signal_wire/signal_wire.dart';

import '../controllers/draft_editor_controller.dart';

/// 模式 B（`SignalsMixin` + `WireStateMixin`）演示页：积分追踪与撤销/重做草稿编辑器。
///
/// Mode B (`SignalsMixin` + `WireStateMixin`) demo page: tracked score &
/// undo/redo draft editor.
class DraftEditorPage extends StatefulWidget {
  /// 创建模式 B 编辑器演示页。
  ///
  /// Creates a [DraftEditorPage].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  const DraftEditorPage({super.key});

  @override
  State<DraftEditorPage> createState() => _DraftEditorPageState();
}

/// [DraftEditorPage] 对应的状态类，演示 `SignalsMixin` 局部信号与 `WireStateMixin` 控制器信号协同。
///
/// State for [DraftEditorPage] demonstrating `SignalsMixin` local UI signals
/// working alongside `WireStateMixin` controller signals (`TrackedSignal` and
/// `ChangeStackSignal`), wrapped in [SignalBuilder] for surgical UI updates.
class _DraftEditorPageState extends State<DraftEditorPage>
    with
        // ignore: deprecated_member_use
        SignalsMixin,
        WireStateMixin<DraftEditorPage, DraftEditorController> {
  /// 页面级局部 UI 信号：每次点击增加的积分步长（由 `SignalsMixin` 自动释放）。
  ///
  /// Page-local UI signal holding the score step (auto-disposed by
  /// `SignalsMixin`).
  late final FlutterSignal<int> localStep = createSignal<int>(5);

  /// 页面级局部 UI 信号：是否展示详细追踪历史。
  ///
  /// Page-local UI toggle controlling whether detailed tracked metrics show.
  late final FlutterSignal<bool> showTrackingDetails = createSignal<bool>(true);

  @override
  DraftEditorController wire() => DraftEditorController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode B · SignalsMixin + WireState')),
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
                    'TrackedSignal Score + Local Step Signal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SignalBuilder(
                    builder: (BuildContext context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Controller Score: ${controller.score.value}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (showTrackingDetails.value)
                            Text(
                              'Initial: ${controller.score.initialValue} · '
                              'Previous: ${controller.score.previousValue ?? '-'}',
                            ),
                          const SizedBox(height: 4),
                          Text('Local Step Signal: ${localStep.value}'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      OutlinedButton(
                        key: const Key('btn_toggle_step'),
                        onPressed: () {
                          localStep.value = localStep.value == 5 ? 10 : 5;
                        },
                        child: const Text('Toggle Step (5 / 10)'),
                      ),
                      FilledButton(
                        key: const Key('btn_add_score'),
                        onPressed: () => controller.addScore(localStep.value),
                        child: const Text('Add Score'),
                      ),
                      TextButton(
                        key: const Key('btn_toggle_details'),
                        onPressed: () {
                          showTrackingDetails.value =
                              !showTrackingDetails.value;
                        },
                        child: const Text('Toggle Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'ChangeStackSignal · Undo / Redo Draft',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SignalBuilder(
                    builder: (BuildContext context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Draft: ${controller.draft.value}'),
                          const SizedBox(height: 4),
                          Text('Length: ${controller.charCount.value} chars'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: <Widget>[
                              FilledButton(
                                key: const Key('btn_append_draft'),
                                onPressed: controller.appendDraftSnapshot,
                                child: const Text('Append Snapshot'),
                              ),
                              OutlinedButton(
                                key: const Key('btn_undo_draft'),
                                onPressed: controller.draft.canUndo
                                    ? controller.undoDraft
                                    : null,
                                child: const Text('Undo'),
                              ),
                              OutlinedButton(
                                key: const Key('btn_redo_draft'),
                                onPressed: controller.draft.canRedo
                                    ? controller.redoDraft
                                    : null,
                                child: const Text('Redo'),
                              ),
                            ],
                          ),
                        ],
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
