import 'package:flutter/widgets.dart';

import 'owned_state_mixin_page_state.dart';

/// 重写 `wire()` 的 [WireStateMixin] 测试用 [StatefulWidget]。
///
/// Test [StatefulWidget] whose state mixes in `WireStateMixin` and overrides
/// `wire()`.
class OwnedStateMixinPage extends StatefulWidget {
  /// 创建重写 `wire()` 的混入测试页。
  ///
  /// Creates an [OwnedStateMixinPage].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  /// - [controllerTag]：可选控制器标签。 / Optional controller tag.
  const OwnedStateMixinPage({super.key, this.controllerTag});

  /// 可选控制器标签。
  ///
  /// Optional controller tag.
  final String? controllerTag;

  @override
  State<OwnedStateMixinPage> createState() => OwnedStateMixinPageState();
}
