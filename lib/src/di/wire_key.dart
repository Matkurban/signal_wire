import 'package:meta/meta.dart';

/// 依赖注入容器内部复合键，由泛型类型 [type] 与可选 [tag] 共同组成。
///
/// Internal composite lookup key for the DI container combining a runtime
/// [type] and an optional [tag].
@immutable
@internal
final class WireKey {
  /// 创建一个由 [type] 和可选 [tag] 组成的复合键。
  ///
  /// Creates a composite key from [type] and an optional [tag].
  ///
  /// - [type]：注册依赖的 Dart 静态类型。 / Static Dart type of the dependency.
  /// - [tag]：用于区分同类型多实例的可选标签。 / Optional tag distinguishing
  ///   multiple instances of the same type.
  const WireKey(this.type, this.tag);

  /// 注册依赖的静态类型。
  ///
  /// The static Dart type of the registered dependency.
  final Type type;

  /// 可选实例标签。
  ///
  /// Optional tag differentiating instances of the same [type].
  final String? tag;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WireKey && other.type == type && other.tag == tag;
  }

  @override
  int get hashCode => Object.hash(type, tag);

  @override
  String toString() {
    if (tag == null) {
      return '$type';
    }
    return '$type(tag: "$tag")';
  }
}
