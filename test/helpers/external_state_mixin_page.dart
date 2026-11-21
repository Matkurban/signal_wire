import 'package:flutter/widgets.dart';

import 'external_state_mixin_page_state.dart';

/// 未重写 `wire()` 的 [WireStateMixin] 测试用 [StatefulWidget]。
///
/// Test [StatefulWidget] whose state mixes in `WireStateMixin` without
/// overriding `wire()`.
class ExternalStateMixinPage extends StatefulWidget {
  /// 创建消费外部控制器的混入测试页。
  ///
  /// Creates an [ExternalStateMixinPage].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  /// - [controllerTag]：可选控制器标签。 / Optional controller tag.
  const ExternalStateMixinPage({super.key, this.controllerTag});

  /// 可选控制器标签。
  ///
  /// Optional controller tag.
  final String? controllerTag;

  @override
  State<ExternalStateMixinPage> createState() => ExternalStateMixinPageState();
}
