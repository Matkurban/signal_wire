import 'package:flutter/widgets.dart';
import 'package:signal_wire/signal_wire.dart';

import 'signals_first_mixin_page.dart';
import 'test_controller.dart';

/// [SignalsFirstMixinPage] 对应的状态类，演示局部信号与 `controller` 信号独立细粒度刷新。
///
/// State class for [SignalsFirstMixinPage] demonstrating independent
/// fine-grained reactivity for both local signals (`SignalsMixin`) and
/// controller signals (`WireStateMixin`).
class SignalsFirstMixinPageState extends State<SignalsFirstMixinPage>
    with
        // ignore: deprecated_member_use
        SignalsMixin,
        WireStateMixin<SignalsFirstMixinPage, TestController> {
  /// 页面级局部响应式信号，由 `SignalsMixin` 托管。
  ///
  /// Page-local reactive signal managed by `SignalsMixin`.
  late final FlutterSignal<int> localStep = createSignal<int>(10);

  @override
  TestController wire() => TestController(label: 'signals_first');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: <Widget>[
          SignalBuilder(
            builder: (BuildContext context) {
              return Text(
                'local:${localStep.value}|ctrl:${controller.count.value}',
              );
            },
          ),
          GestureDetector(
            key: const Key('btn_add_ctrl'),
            onTap: () => controller.increment(localStep.value),
            child: const Text('Add Ctrl'),
          ),
          GestureDetector(
            key: const Key('btn_toggle_local'),
            onTap: () {
              localStep.value = localStep.value == 10 ? 25 : 10;
            },
            child: const Text('Toggle Local'),
          ),
        ],
      ),
    );
  }
}
