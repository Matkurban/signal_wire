import 'package:flutter/widgets.dart';

import 'wire_first_mixin_page_state.dart';

/// 用于测试 `WireStateMixin` 在前、`SignalsMixin` 在后的混合使用场景。
///
/// Test [StatefulWidget] combining `WireStateMixin` followed by `SignalsMixin`.
class WireFirstMixinPage extends StatefulWidget {
  /// 创建混合顺序测试页（`WireStateMixin` 在前）。
  ///
  /// Creates a [WireFirstMixinPage].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  const WireFirstMixinPage({super.key});

  @override
  State<WireFirstMixinPage> createState() => WireFirstMixinPageState();
}
