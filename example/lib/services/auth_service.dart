import 'package:signal_wire/signal_wire.dart';

/// 全局常驻认证服务示例，继承自 [WireService]。
///
/// Example globally persistent authentication service extending [WireService].
///
/// 注册到 `Wire` 容器后默认开启 `permanent: true` 保护，
/// 不会因任意业务页面销毁而被回收。
///
/// Automatically protected with `permanent: true` when registered in `Wire`,
/// surviving all page navigations and disposals.
class AuthService extends WireService {
  /// 当前登录用户名信号，`null` 表示游客状态。
  ///
  /// Reactive signal holding the signed-in username, or `null` when signed out.
  late final FlutterSignal<String?> username;

  /// 派生计算属性：当前是否已登录。
  ///
  /// Derived computed signal indicating whether a user is currently signed in.
  late final FlutterComputed<bool> isSignedIn;

  @override
  void onInit() {
    super.onInit();
    username = createSignal<String?>(null, debugLabel: 'auth_username');
    isSignedIn = createComputed<bool>(
      () => username.value != null,
      debugLabel: 'auth_is_signed_in',
    );
  }

  /// 模拟异步恢复本地会话登录态。
  ///
  /// Simulates restoring a persisted user session asynchronously.
  ///
  /// - [initialUser]：恢复后的默认用户名。 / Default username after restore.
  Future<void> restoreSession({String initialUser = 'Alex'}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    username.value = initialUser;
  }

  /// 切换登录/登出状态。
  ///
  /// Toggles between signed-in and guest states.
  ///
  /// - [fallbackName]：从未登录切换为登录时使用的用户名。 / Username applied
  ///   when signing in from guest mode.
  void toggleAuth({String fallbackName = 'Alex'}) {
    if (isSignedIn.value) {
      username.value = null;
    } else {
      username.value = fallbackName;
    }
  }
}
