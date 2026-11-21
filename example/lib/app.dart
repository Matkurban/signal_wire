import 'package:material_ui/material_ui.dart';

import 'pages/home_page.dart';

/// `signal_wire` 示例应用根组件。
///
/// Root application widget for the `signal_wire` example app.
///
/// 使用标准 [MaterialApp] 与原生 [Navigator]，验证 `signal_wire`
/// 完全不侵入或接管路由系统。
///
/// Uses a standard [MaterialApp] and native [Navigator] to demonstrate
/// zero routing lock-in.
class SignalWireExampleApp extends StatelessWidget {
  /// 创建示例应用根组件。
  ///
  /// Creates a [SignalWireExampleApp].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  const SignalWireExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'signal_wire Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}
