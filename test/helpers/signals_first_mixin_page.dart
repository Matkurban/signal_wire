import 'package:flutter/widgets.dart';

import 'signals_first_mixin_page_state.dart';

/// 用于测试 `SignalsMixin` 在前、`WireStateMixin` 在后的混合使用场景。
///
/// Test [StatefulWidget] combining `SignalsMixin` followed by `WireStateMixin`.
class SignalsFirstMixinPage extends StatefulWidget {
  /// 创建混合顺序测试页（`SignalsMixin` 在前）。
  ///
  /// Creates a [SignalsFirstMixinPage].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  const SignalsFirstMixinPage({super.key});

  @override
  State<SignalsFirstMixinPage> createState() => SignalsFirstMixinPageState();
}
