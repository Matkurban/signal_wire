import 'package:flutter/scheduler.dart';
import 'package:signal_wire/signal_wire.dart';

/// 全局常驻日志收集服务，接入 [WireLogger.handler] 实时展示插件运行日志。
///
/// Globally persistent log collector service wired into [WireLogger.handler]
/// to display live `signal_wire` runtime logs inside the example app.
class WorkspaceLogService extends WireService {
  /// 内存中保留的最大日志条数。
  ///
  /// Maximum number of recent log records retained in memory.
  static const int maxRecords = 50;

  /// 实时日志记录列表信号（最新日志排在最前）。
  ///
  /// Reactive list signal of recent log records (newest first).
  late final ListSignal<WireLogRecord> records;

  /// 构建帧期间暂存的待刷入日志队列，避免在 `build` 阶段直接修改 UI 监听的信号。
  ///
  /// Buffer holding records emitted during an active Flutter build phase so
  /// reactive UI updates are flushed safely after the frame completes.
  final List<WireLogRecord> _pendingBuffer = <WireLogRecord>[];

  /// 标记是否已排程帧末刷入回调。
  ///
  /// Whether a post-frame flush callback has already been scheduled.
  bool _flushScheduled = false;

  @override
  void onInit() {
    super.onInit();
    records = createListSignal<WireLogRecord>(
      <WireLogRecord>[],
      options: const ListSignalOptions<WireLogRecord>(
        name: 'workspace_log_records',
      ),
    );
  }

  /// 追加一条新的结构化日志记录。
  ///
  /// Prepends a new [WireLogRecord] to [records], deferring mutation until
  /// post-frame if invoked during Flutter's build phase to avoid triggering
  /// `markNeedsBuild` mid-build.
  ///
  /// - [record]：由 [WireLogger] 派发的结构化日志对象。 / Record emitted by
  ///   [WireLogger].
  void append(WireLogRecord record) {
    if (isClosed) {
      return;
    }

    if (_isInBuildPhase()) {
      _pendingBuffer.add(record);
      if (!_flushScheduled) {
        _flushScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _flushScheduled = false;
          _flushPending();
        });
      }
      return;
    }

    _insertRecord(record);
  }

  /// 清空当前已收集的日志记录。
  ///
  /// Clears all collected log records.
  void clear() {
    _pendingBuffer.clear();
    records.clear();
  }

  /// 批量将构建帧期间暂存的日志刷入响应式列表。
  ///
  /// Flushes buffered records into [records] once the frame build completes.
  void _flushPending() {
    if (isClosed || _pendingBuffer.isEmpty) {
      _pendingBuffer.clear();
      return;
    }
    final List<WireLogRecord> batch = List<WireLogRecord>.of(_pendingBuffer);
    _pendingBuffer.clear();
    for (final WireLogRecord item in batch) {
      _insertRecord(item);
    }
  }

  /// 将单条日志插入列表头部并维持最大条数限制。
  ///
  /// Inserts a single record at the front of [records] and enforces
  /// [maxRecords].
  void _insertRecord(WireLogRecord record) {
    records.insert(0, record);
    if (records.length > maxRecords) {
      records.removeRange(maxRecords, records.length);
    }
  }

  /// 判断当前是否处于 Flutter 渲染帧构建阶段。
  ///
  /// Returns `true` when Flutter is currently executing persistent frame
  /// callbacks (build/layout/paint).
  bool _isInBuildPhase() {
    try {
      return SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks;
    } catch (_) {
      return false;
    }
  }
}
