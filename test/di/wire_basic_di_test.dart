import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/plain_dependency.dart';
import '../helpers/test_controller.dart';
import '../helpers/test_service.dart';

/// `Wire` 基础依赖注入 API（`put` / `find` / `delete` / `isRegistered` / `tag` / `reset`）测试。
///
/// Unit tests for core [Wire] DI operations including `put`, `find`, `delete`,
/// `isRegistered`, multi-tag isolation, and `reset`.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('Wire 基础 DI 容器 / Basic DI Container', () {
    test('支持注册普通对象与 WireController 并按 tag 严格隔离多实例', () {
      const PlainDependency depA = PlainDependency('A');
      const PlainDependency depB = PlainDependency('B');

      Wire.put<PlainDependency>(depA, tag: 'a');
      Wire.put<PlainDependency>(depB, tag: 'b');

      expect(Wire.isRegistered<PlainDependency>(), isFalse);
      expect(Wire.isRegistered<PlainDependency>(tag: 'a'), isTrue);
      expect(Wire.isRegistered<PlainDependency>(tag: 'b'), isTrue);

      expect(Wire.find<PlainDependency>(tag: 'a').id, 'A');
      expect(Wire.find<PlainDependency>(tag: 'b').id, 'B');

      // 删除 tag 'a' 不应影响 tag 'b'。
      expect(Wire.delete<PlainDependency>(tag: 'a'), isTrue);
      expect(Wire.isRegistered<PlainDependency>(tag: 'a'), isFalse);
      expect(Wire.find<PlainDependency>(tag: 'b').id, 'B');
    });

    test('查找未注册类型或未注册 tag 时抛出包含清晰类型与 tag 的 WireNotFoundException', () {
      expect(
        () => Wire.find<TestController>(),
        throwsA(
          isA<WireNotFoundException>()
              .having(
                (WireNotFoundException e) => e.type,
                'type',
                TestController,
              )
              .having((WireNotFoundException e) => e.tag, 'tag', isNull)
              .having(
                (WireNotFoundException e) => e.toString(),
                'toString',
                contains('TestController'),
              ),
        ),
      );

      expect(
        () => Wire.find<TestController>(tag: 'profile'),
        throwsA(
          isA<WireNotFoundException>()
              .having((WireNotFoundException e) => e.tag, 'tag', 'profile')
              .having(
                (WireNotFoundException e) => e.toString(),
                'toString',
                allOf(contains('TestController'), contains('profile')),
              ),
        ),
      );
    });

    test('删除未注册项返回 false；显式 permanent: true 需 force: true 才能删除', () {
      expect(Wire.delete<TestController>(), isFalse);

      final TestController controller = Wire.put<TestController>(
        TestController(label: 'perm'),
        permanent: true,
      );

      expect(Wire.delete<TestController>(), isFalse);
      expect(controller.isClosed, isFalse);

      expect(Wire.delete<TestController>(force: true), isTrue);
      expect(controller.isClosed, isTrue);
    });

    test('Wire.reset() 保留常驻服务，Wire.reset(clearPermanent: true) 全部销毁', () {
      final TestService service = Wire.put<TestService>(TestService());
      final TestController controller = Wire.put<TestController>(
        TestController(),
      );

      Wire.reset();
      expect(controller.isClosed, isTrue);
      expect(Wire.isRegistered<TestController>(), isFalse);
      expect(service.isClosed, isFalse);
      expect(Wire.isRegistered<TestService>(), isTrue);

      Wire.reset(clearPermanent: true);
      expect(service.isClosed, isTrue);
      expect(Wire.isRegistered<TestService>(), isFalse);
    });
  });
}
