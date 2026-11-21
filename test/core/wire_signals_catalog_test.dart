import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/full_signals_controller.dart';

/// `WireDisposable` 全家族 Signals 自动托管与生命周期释放单元测试。
///
/// Unit tests verifying creation, reactive behavior, and automatic disposal
/// for every signal family supported by [WireDisposable].
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('WireDisposable 全家族 Signals / Full Signals Catalog', () {
    test('核心、集合、历史栈、追踪、异步与流连接信号均正常工作并在 onClose 时自动释放', () async {
      final FullSignalsController ctrl = Wire.put<FullSignalsController>(
        FullSignalsController(),
      );

      // 1. 核心信号 / Core signals
      expect(ctrl.tripled.value, 3);
      ctrl.counter.value = 4;
      expect(ctrl.tripled.value, 12);

      ctrl.lazyNote.value = 'initialized_later';
      expect(ctrl.lazyNote.value, 'initialized_later');
      expect(ctrl.version.value, 'v1.0.0');

      // 2. 集合信号 / Collection signals
      ctrl.items.add('b');
      expect(ctrl.items, <String>['a', 'b']);

      ctrl.selectedTags.add('ui');
      expect(ctrl.selectedTags, <String>{'core', 'ui'});

      ctrl.inventory['banana'] = 5;
      expect(ctrl.inventory['banana'], 5);

      ctrl.numbers.value = <int>[30, 40, 50];
      expect(ctrl.numbers.length, 3);

      ctrl.jobQueue.addLast('job2');
      expect(ctrl.jobQueue.removeFirst(), 'job1');
      expect(ctrl.jobQueue.first, 'job2');

      // 3. 撤销重做栈与追踪信号 / ChangeStack & Tracked signals
      ctrl.draft.value = 'v2';
      ctrl.draft.value = 'v3';
      expect(ctrl.draft.canUndo, isTrue);
      ctrl.draft.undo();
      expect(ctrl.draft.value, 'v2');
      expect(ctrl.draft.canRedo, isTrue);
      ctrl.draft.redo();
      expect(ctrl.draft.value, 'v3');

      ctrl.trackedScore.value = 150;
      expect(ctrl.trackedScore.initialValue, 100);
      expect(ctrl.trackedScore.previousValue, 100);
      expect(ctrl.trackedScore.value, 150);

      // 4. 异步与流信号 / Async, Future, Stream & Connect signals
      expect(ctrl.manualAsync.value.value, 'ready');
      expect(await ctrl.fetchedProfile.future, 'profile_ok');
      expect(await ctrl.asyncLabel.future, 'label_4');
      expect(await ctrl.asyncSum.future, 14);

      // 首次读取触发 StreamSignal 懒订阅，再向 broadcast 流发送事件。
      expect(ctrl.liveTicks.value.isLoading, isTrue);
      ctrl.tickStreamController.add(77);
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.liveTicks.value.value, 77);

      ctrl.statusStreamController.add('online');
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.connectedStatus.value, 'online');

      ctrl.externalFlag.value = true;
      expect(ctrl.externalFlag.value, isTrue);

      // 5. 销毁控制器，验证全家族信号全部自动 disposed
      expect(Wire.delete<FullSignalsController>(), isTrue);
      expect(ctrl.isClosed, isTrue);
      expect(ctrl.counter.disposed, isTrue);
      expect(ctrl.lazyNote.disposed, isTrue);
      expect(ctrl.tripled.disposed, isTrue);
      expect(ctrl.items.disposed, isTrue);
      expect(ctrl.selectedTags.disposed, isTrue);
      expect(ctrl.inventory.disposed, isTrue);
      expect(ctrl.numbers.disposed, isTrue);
      expect(ctrl.jobQueue.disposed, isTrue);
      expect(ctrl.draft.disposed, isTrue);
      expect(ctrl.trackedScore.disposed, isTrue);
      expect(ctrl.manualAsync.disposed, isTrue);
      expect(ctrl.fetchedProfile.disposed, isTrue);
      expect(ctrl.liveTicks.disposed, isTrue);
      expect(ctrl.asyncLabel.disposed, isTrue);
      expect(ctrl.asyncSum.disposed, isTrue);
      expect(ctrl.connectedStatus.disposed, isTrue);
      expect(ctrl.externalFlag.disposed, isTrue);
    });
  });
}
