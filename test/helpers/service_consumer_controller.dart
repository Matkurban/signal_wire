import 'package:signal_wire/signal_wire.dart';

import 'test_service.dart';

/// 订阅全局 [TestService] 信号的页面级测试控制器，用于验证页面卸载后副作用彻底断开。
///
/// Page-level test controller subscribing to a global [TestService] signal
/// to verify its effect stops reacting once the page is unmounted.
class ServiceConsumerController extends WireController {
  /// 记录副作用监听到的全局用户名变更历史。
  ///
  /// History of global username changes observed by this controller's effect.
  final List<String> observedUsers = <String>[];

  @override
  void onInit() {
    super.onInit();
    final TestService service = Wire.find<TestService>();
    createEffect(() {
      observedUsers.add(service.currentUser.value);
    }, debugLabel: 'service_consumer_effect');
  }
}
