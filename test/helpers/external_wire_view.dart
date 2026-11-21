import 'package:flutter/widgets.dart';
import 'package:signal_wire/signal_wire.dart';

import 'test_controller.dart';

/// 未重写 `wire()` 的 [WireView] 测试组件，用于验证复用外部实例且卸载时不销毁。
///
/// Test [WireView] that does not override `wire()`, verifying lookup of an
/// externally registered controller without disposing it on unmount.
class ExternalWireView extends WireView<TestController> {
  /// 创建一个消费外部控制器的测试视图。
  ///
  /// Creates an [ExternalWireView].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  /// - [viewTag]：可选控制器标签。 / Optional controller tag.
  const ExternalWireView({super.key, this.viewTag});

  /// 控制器实例标签。
  ///
  /// Controller instance tag.
  final String? viewTag;

  @override
  String? get tag => viewTag;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SignalBuilder(
        builder: (BuildContext context) {
          return Text('external:${controller.summary.value}');
        },
      ),
    );
  }
}
