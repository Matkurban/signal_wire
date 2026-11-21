import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signal_wire/signal_wire.dart';
import 'package:signal_wire_example/app.dart';
import 'package:signal_wire_example/controllers/draft_editor_controller.dart';
import 'package:signal_wire_example/controllers/project_scope_controller.dart';
import 'package:signal_wire_example/controllers/task_board_controller.dart';
import 'package:signal_wire_example/services/auth_service.dart';
import 'package:signal_wire_example/services/workspace_log_service.dart';

/// WireDesk 完整正式应用场景端到端交互 Widget 测试。
///
/// Full end-to-end interactive widget test suite for the WireDesk example app
/// covering Mode A (`WireView`), Mode B (`SignalsMixin` + `WireStateMixin`),
/// Mode C (`WireScope` dynamic tags + `force: true` replacement), and live
/// `WireLogger` integration.
void main() {
  setUp(() {
    final WorkspaceLogService logService = Wire.put<WorkspaceLogService>(
      WorkspaceLogService(),
    );
    WireLogger.configure(
      enabled: true,
      minLevel: WireLogLevel.debug,
      handler: logService.append,
    );
    Wire.put<AuthService>(AuthService());
  });

  tearDown(() {
    WireLogger.reset();
    Wire.reset(clearPermanent: true);
  });

  testWidgets('端到端验证 Mode A (WireView 任务看板) 筛选、新增、勾选及返回自动回收', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SignalWireExampleApp());
    expect(find.text('Guest mode (signed out)'), findsOneWidget);

    // 切换全局 AuthService 登录状态。
    await tester.tap(find.byKey(const Key('btn_toggle_auth')));
    await tester.pump();
    expect(find.text('Signed in as Alex'), findsOneWidget);

    // 导航进入 Mode A 任务看板。
    await tester.tap(find.byKey(const Key('nav_mode_a')));
    await tester.pumpAndSettle();

    expect(Wire.isRegistered<TaskBoardController>(), isTrue);
    expect(find.text('Design WireLogger pipeline'), findsOneWidget);

    // 新增任务并勾选筛选。
    await tester.tap(find.byKey(const Key('fab_add_task')));
    await tester.pump();
    expect(find.text('Sprint item #4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chip_API')));
    await tester.pump();
    expect(find.text('Design WireLogger pipeline'), findsOneWidget);
    expect(find.text('Sprint item #4'), findsNothing);

    // 返回首页后，TaskBoardController 应自动销毁，全局 AuthService 依然存活。
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(Wire.isRegistered<TaskBoardController>(), isFalse);
    expect(Wire.isRegistered<AuthService>(), isTrue);
  });

  testWidgets('端到端验证 Mode B (SignalsMixin + WireStateMixin) 点击 Add Score 与撤销重做即时响应', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SignalWireExampleApp());

    await tester.tap(find.byKey(const Key('nav_mode_b')));
    await tester.pumpAndSettle();

    expect(Wire.isRegistered<DraftEditorController>(), isTrue);
    expect(find.text('Controller Score: 10'), findsOneWidget);
    expect(find.text('Local Step Signal: 5'), findsOneWidget);

    // 点击 Add Score（默认步长 5）应立即更新为 15。
    await tester.tap(find.byKey(const Key('btn_add_score')));
    await tester.pump();
    expect(find.text('Controller Score: 15'), findsOneWidget);

    // 切换局部步长为 10，再次点击 Add Score 应立即更新为 25。
    await tester.tap(find.byKey(const Key('btn_toggle_step')));
    await tester.pump();
    expect(find.text('Local Step Signal: 10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_add_score')));
    await tester.pump();
    expect(find.text('Controller Score: 25'), findsOneWidget);

    // 测试 ChangeStackSignal 追加快照、Undo 与 Redo。
    await tester.tap(find.byKey(const Key('btn_append_draft')));
    await tester.pump();
    expect(find.text('Draft: Initial spec v1 -> rev2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_undo_draft')));
    await tester.pump();
    expect(find.text('Draft: Initial spec v1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_redo_draft')));
    await tester.pump();
    expect(find.text('Draft: Initial spec v1 -> rev2'), findsOneWidget);

    // 返回首页自动释放控制器。
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(Wire.isRegistered<DraftEditorController>(), isFalse);
  });

  testWidgets('端到端验证 Mode C (WireScope) 动态切换房间 tag 与 force: true 强替换界面零异常', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SignalWireExampleApp());

    await tester.tap(find.byKey(const Key('nav_mode_c')));
    await tester.pumpAndSettle();

    expect(
      Wire.isRegistered<ProjectScopeController>(tag: 'project_alpha'),
      isTrue,
    );
    expect(find.text('Room: project_alpha · Online: 2'), findsOneWidget);

    // 点击推送通知队列。
    await tester.tap(find.byKey(const Key('btn_push_notice')));
    await tester.pump();
    expect(find.text('[project_alpha] Event #1'), findsOneWidget);

    // 触发 force: true 强替换当前房间控制器，界面应无缝切换且无异常。
    await tester.tap(find.byKey(const Key('btn_force_swap')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Room: project_alpha#reset1 · Online: 2'), findsOneWidget);

    // 切换至 project_beta 房间。
    await tester.tap(find.byKey(const Key('room_beta')));
    await tester.pump();
    expect(
      Wire.isRegistered<ProjectScopeController>(tag: 'project_beta'),
      isTrue,
    );
    expect(find.text('Room: project_beta · Online: 2'), findsOneWidget);

    // 返回首页自动清理当前房间控制器。
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      Wire.isRegistered<ProjectScopeController>(tag: 'project_beta'),
      isFalse,
    );
  });
}
