import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/plain_controller.dart';
import '../helpers/test_controller.dart';

/// `WireController` 与按需混入 `WireReadyMixin` 首帧 `onReady` 生命周期测试。
///
/// Unit and widget tests for [WireController] and opt-in [WireReadyMixin]
/// post-frame `onReady()` behavior.
void main() {
  tearDown(() {
    WireLogger.reset();
    Wire.reset(clearPermanent: true);
  });

  group('WireController 与 WireReadyMixin / Lifecycle & Opt-In onReady', () {
    testWidgets('混入 WireReadyMixin 时首帧渲染完成后自动触发 onReady 且仅触发一次', (
      WidgetTester tester,
    ) async {
      final TestController controller = Wire.put<TestController>(
        TestController(label: 'ready_case'),
      );

      expect(controller.isInitialized, isTrue);
      expect(controller.isReady, isFalse);
      expect(controller.events, <String>['onInit']);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(controller.isReady, isTrue);
      expect(controller.readyCount, 1);
      expect(controller.events, <String>['onInit', 'onReady']);

      // 再次刷新帧不应重复触发 onReady。
      await tester.pump();
      expect(controller.readyCount, 1);
    });

    testWidgets('混入 WireReadyMixin 但在首帧回调前即销毁，onReady 不应被误触发', (
      WidgetTester tester,
    ) async {
      final TestController controller = Wire.put<TestController>(
        TestController(label: 'early_close'),
      );

      Wire.delete<TestController>();
      expect(controller.isClosed, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(controller.isReady, isFalse);
      expect(controller.readyCount, 0);
      expect(controller.events, <String>['onInit', 'onClose']);
    });

    testWidgets('未混入 WireReadyMixin 的普通 WireController 零首帧回调且不产生 onReady 日志', (
      WidgetTester tester,
    ) async {
      final List<WireLogRecord> records = <WireLogRecord>[];
      WireLogger.configure(
        enabled: true,
        minLevel: WireLogLevel.verbose,
        handler: records.add,
      );

      final PlainController controller = Wire.put<PlainController>(
        PlainController(),
      );
      expect(controller.initCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(
        records.any((WireLogRecord r) => r.message.contains('onReady')),
        isFalse,
      );

      Wire.delete<PlainController>();
      expect(controller.closeCount, 1);
    });
  });
}
