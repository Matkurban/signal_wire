/// 用于验证 `Wire` 支持注册普通非 `WireDisposable` 对象的测试类。
///
/// Plain Dart dependency class (non-[WireDisposable]) used to verify generic
/// DI container registration.
class PlainDependency {
  /// 创建一个普通依赖实例。
  ///
  /// Creates a [PlainDependency] holding [id].
  ///
  /// - [id]：依赖标识。 / Dependency identifier.
  const PlainDependency(this.id);

  /// 依赖标识字符串。
  ///
  /// Identifier string for this dependency.
  final String id;
}
