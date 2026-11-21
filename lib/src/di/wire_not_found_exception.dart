/// 在 `Wire` 容器中查找未注册依赖时抛出的异常。
///
/// Exception thrown when looking up an unregistered dependency in `Wire`.
///
/// 异常信息会明确包含未找到的目标类型 [type] 以及可选 [tag]，
/// 方便快速定位漏注册或已被回收的依赖问题。
///
/// Includes the exact missing [type] and optional [tag] in its message to
/// simplify diagnosing missing registrations or prematurely disposed
/// dependencies.
final class WireNotFoundException implements Exception {
  /// 创建一个依赖未找到异常。
  ///
  /// Creates a [WireNotFoundException] for the missing [type] and optional
  /// [tag].
  ///
  /// - [type]：未找到的目标类型。 / The dependency type that was not found.
  /// - [tag]：查找时使用的可选标签。 / Optional tag used during lookup.
  const WireNotFoundException({required this.type, this.tag});

  /// 未找到的目标依赖类型。
  ///
  /// The missing dependency type.
  final Type type;

  /// 查找时使用的可选标签。
  ///
  /// The optional tag used in the failed lookup.
  final String? tag;

  @override
  String toString() {
    final String tagSegment = tag == null ? '' : ' with tag "$tag"';
    return 'WireNotFoundException: "$type"$tagSegment is not registered in Wire. '
        'Call Wire.put<$type>(...) or Wire.lazyPut<$type>(...) before calling Wire.find<$type>().';
  }
}
