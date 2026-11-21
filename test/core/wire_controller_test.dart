import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/test_controller.dart';

/// `WireController` 生命周期及首帧 `onReady` 钩子测试。
///
/// Unit and widget tests for [WireController] lifecycle and post-frame
/// `onReady()` behavior.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('WireController 生命周期 / Lifecycle & onReady', () {
    testWidgets(
      '首帧渲染完成后自动触发 onReady 且仅触发一次 / onReady fires once after first frame',
      (WidgetTester tester) async {
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
      },
    );

    testWidgets(
      '在首帧回调执行前即销毁控制器，onReady 不应被误触发 / skips onReady if closed before frame',
      (WidgetTester tester) async {
        final TestController controller = Wire.put<TestController>(
          TestController(label: 'early_close'),
        );

        // 首帧前直接删除控制器。
        Wire.delete<TestController>();
        expect(controller.isClosed, isTrue);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(controller.isReady, isFalse);
        expect(controller.readyCount, 0);
        expect(controller.events, <String>['onInit', 'onClose']);
      },
    );
  });
}
