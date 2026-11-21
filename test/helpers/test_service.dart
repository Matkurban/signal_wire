import 'package:signal_wire/signal_wire.dart';

/// 用于验证多类型隔离与全局服务联动的辅助测试服务类。
///
/// Test [WireService] implementation for verifying permanent protection and
/// cross-controller reactive integration.
class TestService extends WireService {
  /// 创建一个测试服务实例。
  ///
  /// Creates a [TestService] with an optional [serviceName].
  ///
  /// - [serviceName]：服务名称标识。 / Identifier name for this service.
  TestService({this.serviceName = 'auth'});

  /// 服务名称标识。
  ///
  /// Identifier name for this service.
  final String serviceName;

  /// `onInit` 调用次数。
  ///
  /// Number of times `onInit` was called.
  int initCount = 0;

  /// `onClose` 调用次数。
  ///
  /// Number of times `onClose` was called.
  int closeCount = 0;

  /// 全局用户状态信号。
  ///
  /// Global reactive username signal.
  late final FlutterSignal<String> currentUser;

  @override
  void onInit() {
    super.onInit();
    initCount++;
    currentUser = createSignal<String>('guest', debugLabel: 'service_user');
  }

  /// 更新当前登录用户名称。
  ///
  /// Updates [currentUser] with [username].
  ///
  /// - [username]：新的用户名。 / New username value.
  void signIn(String username) {
    currentUser.value = username;
  }

  @override
  void onClose() {
    closeCount++;
    super.onClose();
  }
}
