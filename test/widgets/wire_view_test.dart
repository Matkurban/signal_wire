import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/external_wire_view.dart';
import '../helpers/owned_wire_view.dart';
import '../helpers/test_controller.dart';

/// 模式 A：`WireView` 自定义 `ComponentElement` 生命周期与响应性 Widget 测试。
///
/// Widget tests for Mode A ([WireView]) covering owned creation/disposal,
/// external controller lookup, parent rebuild stability, and dynamic tags.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('模式 A：WireView / Mode A: WireView', () {
    testWidgets('重写 wire() 时挂载自动注册、触发 onInit/onReady、响应更新并在卸载时自动回收', (
      WidgetTester tester,
    ) async {
      TestController? created;

      await tester.pumpWidget(
        OwnedWireView(
          onCreate: (TestController ctrl) {
            created = ctrl;
          },
        ),
      );
      await tester.pump();

      expect(created, isNotNull);
      expect(created!.isInitialized, isTrue);
      expect(created!.isReady, isTrue);
      expect(Wire.isRegistered<TestController>(), isTrue);
      expect(find.text('count:0'), findsOneWidget);

      // 信号变更触发局部 UI 更新与内部 effect。
      created!.increment(3);
      await tester.pump();
      expect(find.text('count:3'), findsOneWidget);
      expect(created!.effectValues, <int>[0, 3]);

      // 卸载 WireView 自动销毁控制器并释放信号与副作用。
      await tester.pumpWidget(const SizedBox.shrink());
      expect(Wire.isRegistered<TestController>(), isFalse);
      expect(created!.isClosed, isTrue);
      expect(created!.count.disposed, isTrue);
    });

    testWidgets('未重写 wire() 时复用外部已注入实例，卸载后不销毁该外部实例', (
      WidgetTester tester,
    ) async {
      final TestController external = Wire.put<TestController>(
        TestController(label: 'shared', initialCount: 7),
      );

      await tester.pumpWidget(const ExternalWireView());
      expect(find.text('external:shared:7'), findsOneWidget);

      external.increment();
      await tester.pump();
      expect(find.text('external:shared:8'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(external.isClosed, isFalse);
      expect(Wire.isRegistered<TestController>(), isTrue);
    });

    testWidgets('父组件 rebuild 不重复调用 wire()；动态切换 tag 时销毁旧控制器并创建新控制器', (
      WidgetTester tester,
    ) async {
      int createCalls = 0;
      final List<TestController> createdList = <TestController>[];

      await tester.pumpWidget(
        OwnedWireView(
          viewTag: 'tab_a',
          headerText: 'v1',
          onCreate: (TestController ctrl) {
            createCalls++;
            createdList.add(ctrl);
          },
        ),
      );

      expect(createCalls, 1);
      expect(find.text('v1'), findsOneWidget);

      // 同 tag 下父组件重建，不应重复创建控制器。
      await tester.pumpWidget(
        OwnedWireView(
          viewTag: 'tab_a',
          headerText: 'v2',
          onCreate: (TestController ctrl) {
            createCalls++;
            createdList.add(ctrl);
          },
        ),
      );

      expect(createCalls, 1);
      expect(find.text('v2'), findsOneWidget);
      expect(createdList.first.isClosed, isFalse);

      // 动态切换 tag，应自动销毁 tab_a 并创建 tab_b。
      await tester.pumpWidget(
        OwnedWireView(
          viewTag: 'tab_b',
          headerText: 'v3',
          onCreate: (TestController ctrl) {
            createCalls++;
            createdList.add(ctrl);
          },
        ),
      );

      expect(createCalls, 2);
      expect(createdList[0].isClosed, isTrue);
      expect(Wire.isRegistered<TestController>(tag: 'tab_a'), isFalse);
      expect(createdList[1].isClosed, isFalse);
      expect(Wire.isRegistered<TestController>(tag: 'tab_b'), isTrue);
    });
  });
}
