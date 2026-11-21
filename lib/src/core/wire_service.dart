import 'wire_disposable.dart';

/// 全局常驻服务基类。
///
/// Base class for globally persistent services.
///
/// 面向全局常驻能力（例如用户鉴权、IM 长连接、本地存储、配置中心等），
/// 脱离 UI 渲染周期，不包含 `onReady()` 钩子。
///
/// Designed for long-lived application services (such as authentication,
/// IM connections, local storage, or configuration) that live outside the UI
/// rendering lifecycle and therefore do not have an `onReady()` hook.
///
/// **天然常驻保护 / Built-in permanent protection**：
/// 注册到 `Wire` 容器时，`permanent` 参数默认自动视为 `true`，
/// 防止被普通 `Wire.delete()` 误删；仅在显式传入 `force: true` 时才会销毁并触发 [onClose]。
///
/// When registered in the `Wire` container, `permanent` defaults to `true`
/// automatically to prevent accidental removal by regular `Wire.delete()`.
/// It is only disposed when `force: true` is explicitly passed.
abstract class WireService extends WireDisposable {}
