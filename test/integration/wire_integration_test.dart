import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/owned_wire_view.dart';
import '../helpers/service_consumer_controller.dart';
import '../helpers/test_controller.dart';
import '../helpers/test_service.dart';

/// 综合集成测试：验证全局 `WireService` 与页面控制器联动以及 `put(force: true)` UI 替换安全性。
///
/// Integration tests verifying global [WireService] + page controller
/// interaction and UI stability during `Wire.put(..., force: true)` swaps.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('综合集成与 UI 安全 / Integration & UI Safety', () {
    testWidgets('页面卸载后其监听全局 WireService 信号的 effect 彻底断开，服务继续存活', (
      WidgetTester tester,
    ) async {
      final TestService authService = Wire.put<TestService>(TestService());
      ServiceConsumerController? pageController;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WireScope<ServiceConsumerController>(
            create: () {
              pageController = ServiceConsumerController();
              return pageController!;
            },
            builder: (BuildContext context, ServiceConsumerController ctrl) {
              return SignalBuilder(
                builder: (BuildContext context) {
                  return Text('user:${authService.currentUser.value}');
                },
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('user:guest'), findsOneWidget);
      expect(pageController!.observedUsers, <String>['guest']);

      authService.signIn('alice');
      await tester.pump();
      expect(find.text('user:alice'), findsOneWidget);
      expect(pageController!.observedUsers, <String>['guest', 'alice']);

      // 卸载页面后，页面控制器销毁，effect 不再响应全局服务的后续变更。
      await tester.pumpWidget(const SizedBox.shrink());
      expect(pageController!.isClosed, isTrue);
      expect(authService.isClosed, isFalse);

      authService.signIn('bob');
      expect(pageController!.observedUsers, <String>['guest', 'alice']);
      expect(Wire.find<TestService>().currentUser.value, 'bob');
    });

    testWidgets('界面挂载期间外部调用 Wire.put(..., force: true) 替换控制器时界面无异常且切换为新实例', (
      WidgetTester tester,
    ) async {
      TestController? first;

      await tester.pumpWidget(
        OwnedWireView(
          headerText: 'live_v1',
          onCreate: (TestController ctrl) {
            first = ctrl;
          },
        ),
      );
      await tester.pump();
      expect(find.text('count:0'), findsOneWidget);

      // 在界面处于活跃挂载状态时，通过 force: true 强行替换同类型控制器。
      final TestController replacement = Wire.put<TestController>(
        TestController(label: 'replaced', initialCount: 100),
        force: true,
      );

      expect(first!.isClosed, isTrue);
      expect(replacement.isInitialized, isTrue);

      // 触发界面重建，验证界面无缝读取新控制器且无任何异常。
      await tester.pumpWidget(const OwnedWireView(headerText: 'live_v2'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('live_v2'), findsOneWidget);
      expect(find.text('count:100'), findsOneWidget);

      // 卸载旧 OwnedWireView 时，由于容器里已是外部 force 替换的新实例，不应误删 replacement。
      await tester.pumpWidget(const SizedBox.shrink());
      expect(replacement.isClosed, isFalse);
      expect(Wire.isRegistered<TestController>(), isTrue);
    });
  });
}
