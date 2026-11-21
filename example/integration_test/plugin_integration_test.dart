import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:signal_wire/signal_wire.dart';
import 'package:signal_wire_example/app.dart';
import 'package:signal_wire_example/services/auth_service.dart';
import 'package:signal_wire_example/services/workspace_log_service.dart';

/// WireDesk 示例应用端到端集成测试。
///
/// End-to-end integration test for the WireDesk example app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    WireLogger.reset();
    Wire.reset(clearPermanent: true);
  });

  testWidgets('示例应用集成测试：全局 AuthService 与 WorkspaceLogService 协同正常', (
    WidgetTester tester,
  ) async {
    final WorkspaceLogService logService = Wire.put<WorkspaceLogService>(
      WorkspaceLogService(),
    );
    WireLogger.configure(
      enabled: true,
      minLevel: WireLogLevel.debug,
      handler: logService.append,
    );
    final AuthService auth = Wire.put<AuthService>(AuthService());
    await tester.pumpWidget(const SignalWireExampleApp());

    expect(find.text('WireDesk · signal_wire'), findsOneWidget);
    auth.toggleAuth(fallbackName: 'IntegrationUser');
    await tester.pumpAndSettle();
    expect(find.text('Signed in as IntegrationUser'), findsOneWidget);
  });
}
