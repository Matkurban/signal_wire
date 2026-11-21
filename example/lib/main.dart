import 'package:material_ui/material_ui.dart';
import 'package:signal_wire/signal_wire.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/workspace_log_service.dart';

/// WireDesk 示例应用入口。
///
/// Entry point for the WireDesk example application.
///
/// 初始化全局常驻日志服务 [WorkspaceLogService]（接入 [WireLogger.handler]）
/// 与全局认证服务 [AuthService]（通过 `Wire.putAsync` 异步初始化），随后启动应用。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注册全局实时日志服务并接入 WireLogger。
  // Register global log collector and wire it into WireLogger.
  final WorkspaceLogService logService = Wire.put<WorkspaceLogService>(
    WorkspaceLogService(),
  );
  WireLogger.configure(
    enabled: true,
    minLevel: WireLogLevel.debug,
    handler: (WireLogRecord record) {
      debugPrint(record.format());
      logService.append(record);
    },
  );

  // 异步初始化全局常驻认证服务。
  // Asynchronously initialize globally permanent AuthService.
  await Wire.putAsync<AuthService>(() async => AuthService());
  await Wire.find<AuthService>().restoreSession();

  runApp(const SignalWireExampleApp());
}
