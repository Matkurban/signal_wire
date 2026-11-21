import 'package:flutter/widgets.dart';
import 'package:signal_wire/signal_wire.dart';

import 'test_controller.dart';
import 'wire_first_mixin_page.dart';

/// [WireFirstMixinPage] 对应的状态类，验证反转 Mixin 顺序时局部与控制器信号均独立响应。
///
/// State class for [WireFirstMixinPage] verifying reversed mixin ordering
/// updates both local and controller signals independently.
class WireFirstMixinPageState extends State<WireFirstMixinPage>
    with
        WireStateMixin<WireFirstMixinPage, TestController>,
        // ignore: deprecated_member_use
        SignalsMixin {
  /// 页面级局部响应式信号。
  ///
  /// Page-local reactive signal.
  late final FlutterSignal<String> localTag = createSignal<String>('alpha');

  @override
  TestController wire() => TestController(label: 'wire_first');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SignalBuilder(
        builder: (BuildContext context) {
          return Text('tag:${localTag.value}|ctrl:${controller.count.value}');
        },
      ),
    );
  }
}
