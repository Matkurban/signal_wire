import 'package:flutter/widgets.dart';
import 'package:signal_wire/signal_wire.dart';

import 'external_state_mixin_page.dart';
import 'test_controller.dart';

/// [ExternalStateMixinPage] 对应的状态类，验证 `WireStateMixin` 复用外部实例且不销毁。
///
/// State class for [ExternalStateMixinPage] verifying external controller
/// lookup without disposal on unmount.
class ExternalStateMixinPageState extends State<ExternalStateMixinPage>
    with WireStateMixin<ExternalStateMixinPage, TestController> {
  @override
  String? get tag => widget.controllerTag;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SignalBuilder(
        builder: (BuildContext context) {
          return Text('ext-mixin:${controller.count.value}');
        },
      ),
    );
  }
}
