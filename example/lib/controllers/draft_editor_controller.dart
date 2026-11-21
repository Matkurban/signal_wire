import 'package:signal_wire/signal_wire.dart';

/// 页面 2（模式 B：`SignalsMixin` + `WireStateMixin`）对应的积分与草稿编辑器控制器。
///
/// Controller for Page 2 (Mode B: `SignalsMixin` + `WireStateMixin`)
/// managing tracked scores and undo/redo draft history.
///
/// 演示 [createTrackedSignal]（追踪初始值与上一次值）与
/// [createChangeStackSignal]（支持 Undo / Redo 历史栈）。
class DraftEditorController extends WireController {
  /// 业务积分追踪信号，自动记住 `initialValue` 与 `previousValue`。
  ///
  /// Tracked score signal retaining `initialValue` and `previousValue`.
  late final TrackedSignal<int> score;

  /// 支持撤销与重做的文档草稿历史栈信号。
  ///
  /// Undo/redo change-stack signal holding the active draft text.
  late final ChangeStackSignal<String> draft;

  /// 派生计算信号：当前草稿字符数。
  ///
  /// Computed character length of [draft].
  late final FlutterComputed<int> charCount;

  /// 草稿修订序号。
  ///
  /// Revision counter appended when adding draft snapshots.
  int _revision = 1;

  @override
  void onInit() {
    super.onInit();
    score = createTrackedSignal<int>(
      10,
      options: const TrackedSignalOptions<int>(name: 'editor_tracked_score'),
    );
    draft = createChangeStackSignal<String>(
      'Initial spec v1',
      limit: 20,
      options: const ChangeSignalOptions<String>(name: 'editor_draft_stack'),
    );
    charCount = createComputed<int>(
      () => draft.value.length,
      options: const ComputedOptions<int>(name: 'editor_char_count'),
    );
  }

  /// 按步长 [delta] 增加业务积分。
  ///
  /// Adds [delta] to [score].
  ///
  /// - [delta]：本次增加的分值。 / Score delta to add.
  void addScore(int delta) {
    score.value = score.value + delta;
  }

  /// 追加一条新的草稿修订快照以演示撤销/重做能力。
  ///
  /// Appends a new draft revision snapshot onto the undo/redo stack.
  void appendDraftSnapshot() {
    _revision++;
    draft.value = '${draft.value} -> rev$_revision';
  }

  /// 撤销上一次草稿修改。
  ///
  /// Undoes the latest draft change if available.
  void undoDraft() {
    if (draft.canUndo) {
      draft.undo();
    }
  }

  /// 重做已撤销的草稿修改。
  ///
  /// Redoes the previously undone draft change if available.
  void redoDraft() {
    if (draft.canRedo) {
      draft.redo();
    }
  }
}
