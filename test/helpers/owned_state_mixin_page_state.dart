import 'package:flutter/widgets.dart';
import 'package:signal_wire/signal_wire.dart';

import 'owned_state_mixin_page.dart';
import 'test_controller.dart';

/// [OwnedStateMixinPage] 对应的状态类，验证 `WireStateMixin` 自动创建与卸载销毁。
///
/// State class for [OwnedStateMixinPage] verifying `WireStateMixin` owned
/// lifecycle creation and disposal.
class OwnedStateMixinPageState extends State<OwnedStateMixinPage>
    with WireStateMixin<OwnedStateMixinPage, TestController> {
  @override
  String? get tag => widget.controllerTag;

  @override
  TestController wire() =>
      TestController(label: widget.controllerTag ?? 'mixin');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SignalBuilder(
        builder: (BuildContext context) {
          return Text('mixin:${controller.count.value}');
        },
      ),
    );
  }
}
