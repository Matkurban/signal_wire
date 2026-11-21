import 'dart:collection';

import 'package:signal_wire/signal_wire.dart';

/// 页面 3（模式 C：`WireScope`）对应的项目协作房间控制器。
///
/// Controller for Page 3 (Mode C: `WireScope`) managing a tagged project room
/// with reactive member presence and notification queues.
class ProjectScopeController extends WireController {
  /// 创建一个指定房间标识的协作控制器。
  ///
  /// Creates a [ProjectScopeController] for [roomName].
  ///
  /// - [roomName]：当前项目房间名称。 / Name of the project room.
  ProjectScopeController({required this.roomName});

  /// 当前项目房间名称。
  ///
  /// Display name of this project room.
  final String roomName;

  /// 成员在线状态映射表信号（`MapSignal`）。
  ///
  /// Reactive map of member names to online presence booleans.
  late final MapSignal<String, bool> memberPresence;

  /// 待处理通知队列信号（`QueueSignal`）。
  ///
  /// Reactive FIFO queue of pending room notifications.
  late final QueueSignal<String> notifications;

  /// 派生计算信号：当前在线成员数量。
  ///
  /// Computed count of currently online members.
  late final FlutterComputed<int> onlineCount;

  /// 通知序号计数器。
  ///
  /// Monotonic counter for generated notifications.
  int _noticeSeq = 1;

  @override
  void onInit() {
    super.onInit();
    memberPresence = createMapSignal<String, bool>(<String, bool>{
      'Alice': true,
      'Bob': false,
      'Charlie': true,
    }, debugLabel: 'room_${roomName}_presence');

    notifications = createQueueSignal<String>(
      Queue<String>.from(<String>['Welcome to $roomName']),
      debugLabel: 'room_${roomName}_queue',
    );

    onlineCount = createComputed<int>(
      () => memberPresence.values.where((bool online) => online).length,
      debugLabel: 'room_${roomName}_online',
    );
  }

  /// 切换指定成员的在线状态。
  ///
  /// Toggles online status for [member].
  ///
  /// - [member]：成员名称。 / Member display name.
  void toggleMember(String member) {
    final bool current = memberPresence[member] ?? false;
    memberPresence[member] = !current;
  }

  /// 向队列末尾压入一条新通知。
  ///
  /// Enqueues a new notification into [notifications].
  void pushNotification() {
    final int id = _noticeSeq++;
    notifications.addLast('[$roomName] Event #$id');
  }

  /// 消费队首通知。
  ///
  /// Dequeues the oldest notification if the queue is non-empty.
  void consumeNotification() {
    if (notifications.isNotEmpty) {
      notifications.removeFirst();
    }
  }
}
