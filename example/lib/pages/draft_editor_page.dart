import 'package:material_ui/material_ui.dart';

import 'draft_editor_page_state.dart';

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
  State<DraftEditorPage> createState() => DraftEditorPageState();
}
