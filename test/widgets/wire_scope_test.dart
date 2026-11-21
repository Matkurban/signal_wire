import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/external_wire_view.dart';
import '../helpers/test_controller.dart';

/// 模式 C：`WireScope` 作用域包裹组件（`builder` / `child` / 动态 `tag`）测试。
///
/// Widget tests for Mode C ([WireScope]) covering `builder` mode, `child`
/// mode, dynamic tag switching, and automatic disposal on unmount.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('模式 C：WireScope / Mode C: WireScope', () {
    testWidgets('builder 模式下挂载创建、响应式更新并在卸载时自动回收', (WidgetTester tester) async {
      TestController? scopedCtrl;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: WireScope<TestController>(
            create: () {
              scopedCtrl = TestController(label: 'scope_builder');
              return scopedCtrl!;
            },
            builder: (BuildContext context, TestController controller) {
              return SignalBuilder(
                builder: (BuildContext context) {
                  return Text('scope:${controller.count.value}');
                },
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(scopedCtrl, isNotNull);
      expect(scopedCtrl!.isInitialized, isTrue);
      expect(scopedCtrl!.isReady, isTrue);
      expect(find.text('scope:0'), findsOneWidget);

      scopedCtrl!.increment(6);
      await tester.pump();
      expect(find.text('scope:6'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(scopedCtrl!.isClosed, isTrue);
      expect(Wire.isRegistered<TestController>(), isFalse);
    });

    testWidgets('child 模式下子组件可通过 Wire.find 获取并在 WireScope 卸载时自动回收', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        WireScope<TestController>(
          tag: 'child_scope',
          create: () => TestController(label: 'child_mode', initialCount: 3),
          child: const ExternalWireView(viewTag: 'child_scope'),
        ),
      );
      await tester.pump();

      expect(find.text('external:child_mode:3'), findsOneWidget);
      final TestController ctrl = Wire.find<TestController>(tag: 'child_scope');

      await tester.pumpWidget(const SizedBox.shrink());
      expect(ctrl.isClosed, isTrue);
      expect(Wire.isRegistered<TestController>(tag: 'child_scope'), isFalse);
    });

    testWidgets('WireScope 动态切换 tag 时销毁旧作用域控制器并创建新控制器', (
      WidgetTester tester,
    ) async {
      final List<TestController> instances = <TestController>[];

      Widget buildScope(String activeTag) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: WireScope<TestController>(
            tag: activeTag,
            create: () {
              final TestController ctrl = TestController(label: activeTag);
              instances.add(ctrl);
              return ctrl;
            },
            builder: (BuildContext context, TestController controller) {
              return Text('active:${controller.label}');
            },
          ),
        );
      }

      await tester.pumpWidget(buildScope('room_1'));
      expect(find.text('active:room_1'), findsOneWidget);
      expect(instances, hasLength(1));

      await tester.pumpWidget(buildScope('room_2'));
      expect(find.text('active:room_2'), findsOneWidget);
      expect(instances, hasLength(2));
      expect(instances[0].isClosed, isTrue);
      expect(Wire.isRegistered<TestController>(tag: 'room_1'), isFalse);
      expect(instances[1].isClosed, isFalse);
      expect(Wire.isRegistered<TestController>(tag: 'room_2'), isTrue);
    });
  });
}
