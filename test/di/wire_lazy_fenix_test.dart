import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/test_controller.dart';
import '../helpers/test_service.dart';

/// `Wire.lazyPut` 懒加载与 `fenix: true` 涅槃重建单元测试。
///
/// Unit tests for [Wire.lazyPut] lazy instantiation and `fenix: true`
/// automatic recreation after disposal.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('Wire.lazyPut 与 fenix / Lazy Instantiation & Fenix', () {
    test('lazyPut 注册时不立即构造，首次 find 才实例化并触发 onInit', () {
      int buildCount = 0;
      Wire.lazyPut<TestController>(() {
        buildCount++;
        return TestController(label: 'lazy_$buildCount');
      });

      expect(Wire.isRegistered<TestController>(), isTrue);
      expect(Wire.isPrepared<TestController>(), isTrue);
      expect(buildCount, 0);

      final TestController first = Wire.find<TestController>();
      expect(buildCount, 1);
      expect(first.isInitialized, isTrue);
      expect(Wire.isPrepared<TestController>(), isFalse);

      // 再次 find 返回同一实例，不再重新构造。
      final TestController second = Wire.find<TestController>();
      expect(identical(first, second), isTrue);
      expect(buildCount, 1);
    });

    test('fenix: false 时 delete 彻底移除，再次 find 抛出 WireNotFoundException', () {
      Wire.lazyPut<TestController>(() => TestController(label: 'non_fenix'));

      final TestController ctrl = Wire.find<TestController>();
      expect(Wire.delete<TestController>(), isTrue);
      expect(ctrl.isClosed, isTrue);
      expect(Wire.isRegistered<TestController>(), isFalse);
      expect(() => Wire.find<TestController>(), throwsA(isA<WireNotFoundException>()));
    });

    test('fenix: true 时普通 delete 销毁旧实例并保留工厂，再次 find 自动重建全新实例', () {
      int buildCount = 0;
      Wire.lazyPut<TestController>(() {
        buildCount++;
        return TestController(label: 'fenix_$buildCount');
      }, fenix: true);

      final TestController first = Wire.find<TestController>();
      first.increment(5);
      expect(first.count.value, 5);

      expect(Wire.delete<TestController>(), isTrue);
      expect(first.isClosed, isTrue);
      expect(Wire.isRegistered<TestController>(), isTrue);
      expect(Wire.isPrepared<TestController>(), isTrue);

      final TestController rebuilt = Wire.find<TestController>();
      expect(identical(rebuilt, first), isFalse);
      expect(buildCount, 2);
      expect(rebuilt.isInitialized, isTrue);
      expect(rebuilt.count.value, 0);

      // delete(force: true) 应彻底清除 fenix 工厂。
      expect(Wire.delete<TestController>(force: true), isTrue);
      expect(rebuilt.isClosed, isTrue);
      expect(Wire.isRegistered<TestController>(), isFalse);
    });

    test('lazyPut 构造出 WireService 时首次实例化后自动启用 permanent 保护', () {
      Wire.lazyPut<TestService>(() => TestService(serviceName: 'lazy_svc'));

      final TestService svc = Wire.find<TestService>();
      expect(svc.isInitialized, isTrue);
      expect(Wire.delete<TestService>(), isFalse);
      expect(Wire.delete<TestService>(force: true), isTrue);
      expect(svc.isClosed, isTrue);
    });
  });
}
