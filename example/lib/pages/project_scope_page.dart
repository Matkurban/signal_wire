import 'package:material_ui/material_ui.dart';

import 'project_scope_page_state.dart';

/// 模式 C（[WireScope]）演示页：动态切换多房间 `tag` 与 `Wire.put(force: true)` 强替换演示。
///
/// Mode C ([WireScope]) demo page showcasing dynamic room `tag` switching and
/// safe `Wire.put(..., force: true)` controller replacement.
class ProjectScopePage extends StatefulWidget {
  /// 创建模式 C 协作房间演示页。
  ///
  /// Creates a [ProjectScopePage].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  const ProjectScopePage({super.key});

  @override
  State<ProjectScopePage> createState() => ProjectScopePageState();
}
