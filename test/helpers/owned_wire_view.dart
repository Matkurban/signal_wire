import 'package:flutter/widgets.dart';
import 'package:signal_wire/signal_wire.dart';

import 'test_controller.dart';

/// 重写了 `wire()` 的 [WireView] 测试组件，用于验证“谁创建、谁销毁”与响应式刷新。
///
/// Test [WireView] overriding `wire()` to verify automatic creation,
/// reactive updates, and disposal on unmount.
class OwnedWireView extends WireView<TestController> {
  /// 创建一个自行创建控制器的测试视图。
  ///
  /// Creates an [OwnedWireView].
  ///
  /// - [key]：可选组件键。 / Optional widget key.
  /// - [viewTag]：可选控制器标签。 / Optional controller tag.
  /// - [onCreate]：控制器创建时触发的回调（用于统计 `wire()` 调用次数）。
  ///   Optional callback invoked when `wire()` creates a controller.
  /// - [headerText]：外部传入的动态标题，用于测试父组件重建场景。 / External
  ///   header string used to test parent rebuilds.
  const OwnedWireView({
    super.key,
    this.viewTag,
    this.onCreate,
    this.headerText = 'owned',
  });

  /// 控制器实例标签。
  ///
  /// Controller instance tag.
  final String? viewTag;

  /// 创建控制器时的钩子回调。
  ///
  /// Callback fired whenever `wire()` creates a controller.
  final void Function(TestController controller)? onCreate;

  /// 外部标题文本。
  ///
  /// External header text.
  final String headerText;

  @override
  String? get tag => viewTag;

  @override
  TestController wire() {
    final TestController created = TestController(label: viewTag ?? 'owned');
    onCreate?.call(created);
    return created;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: <Widget>[
          Text(headerText),
          SignalBuilder(
            builder: (BuildContext context) {
              return Text('count:${controller.count.value}');
            },
          ),
        ],
      ),
    );
  }
}
