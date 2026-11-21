import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/external_state_mixin_page.dart';
import '../helpers/owned_state_mixin_page.dart';
import '../helpers/signals_first_mixin_page.dart';
import '../helpers/signals_first_mixin_page_state.dart';
import '../helpers/test_controller.dart';
import '../helpers/wire_first_mixin_page.dart';
import '../helpers/wire_first_mixin_page_state.dart';

/// 模式 B：`WireStateMixin` 生命周期及与 `SignalsMixin` 兼容共存 Widget 测试。
///
/// Widget tests for Mode B ([WireStateMixin]) verifying owned/external
/// lifecycles, independent reactivity of controller vs. local signals on user
/// tap, and full compatibility with `SignalsMixin` in either order.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('模式 B：WireStateMixin / Mode B: WireStateMixin', () {
    testWidgets('重写 wire() 时在 initState 自动注册，dispose 时自动回收', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const OwnedStateMixinPage(controllerTag: 'm1'));
      await tester.pump();

      expect(Wire.isRegistered<TestController>(tag: 'm1'), isTrue);
      final TestController ctrl = Wire.find<TestController>(tag: 'm1');
      expect(ctrl.isInitialized, isTrue);
      expect(ctrl.isReady, isTrue);
      expect(find.text('mixin:0'), findsOneWidget);

      ctrl.increment(4);
      await tester.pump();
      expect(find.text('mixin:4'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(Wire.isRegistered<TestController>(tag: 'm1'), isFalse);
      expect(ctrl.isClosed, isTrue);
    });

    testWidgets('未重写 wire() 时复用外部实例，页面 dispose 不销毁外部实例', (
      WidgetTester tester,
    ) async {
      final TestController external = Wire.put<TestController>(
        TestController(label: 'ext_mixin', initialCount: 12),
        tag: 'ext',
      );

      await tester.pumpWidget(
        const ExternalStateMixinPage(controllerTag: 'ext'),
      );
      expect(find.text('ext-mixin:12'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(external.isClosed, isFalse);
      expect(Wire.isRegistered<TestController>(tag: 'ext'), isTrue);
    });

    testWidgets(
      '同时混入 SignalsMixin + WireStateMixin：单独点击更新 controller 信号或局部信号均即时刷新，卸载均回收',
      (WidgetTester tester) async {
        await tester.pumpWidget(const SignalsFirstMixinPage());
        await tester.pump();

        final SignalsFirstMixinPageState state = tester.state(
          find.byType(SignalsFirstMixinPage),
        );
        final TestController ctrl = state.controller;

        expect(find.text('local:10|ctrl:0'), findsOneWidget);

        // 仅点击更新 controller 信号（不修改 localStep），验证 UI 确实立即刷新。
        await tester.tap(find.byKey(const Key('btn_add_ctrl')));
        await tester.pump();
        expect(find.text('local:10|ctrl:10'), findsOneWidget);

        // 仅点击更新局部信号（不修改 controller），验证 UI 独立刷新。
        await tester.tap(find.byKey(const Key('btn_toggle_local')));
        await tester.pump();
        expect(find.text('local:25|ctrl:10'), findsOneWidget);

        // 再次点击使用新步长 25 更新 controller。
        await tester.tap(find.byKey(const Key('btn_add_ctrl')));
        await tester.pump();
        expect(find.text('local:25|ctrl:35'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        expect(ctrl.isClosed, isTrue);
        expect(state.localStep.disposed, isTrue);
      },
    );

    testWidgets('反转混入顺序（WireStateMixin + SignalsMixin）同样独立响应且完全兼容', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const WireFirstMixinPage());
      await tester.pump();

      final WireFirstMixinPageState state = tester.state(
        find.byType(WireFirstMixinPage),
      );
      final TestController ctrl = state.controller;

      expect(find.text('tag:alpha|ctrl:0'), findsOneWidget);

      // 单独修改 controller 信号。
      ctrl.increment(9);
      await tester.pump();
      expect(find.text('tag:alpha|ctrl:9'), findsOneWidget);

      // 单独修改局部信号。
      state.localTag.value = 'beta';
      await tester.pump();
      expect(find.text('tag:beta|ctrl:9'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(ctrl.isClosed, isTrue);
      expect(state.localTag.disposed, isTrue);
    });
  });
}
