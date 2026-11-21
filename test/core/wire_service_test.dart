import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/test_service.dart';

/// `WireService` 天然常驻保护与强制销毁测试。
///
/// Unit tests verifying [WireService] automatic `permanent: true` protection
/// and explicit forced disposal.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('WireService 常驻保护 / Permanent Protection', () {
    test('注册 WireService 时自动视为 permanent: true，普通 delete 无法销毁', () {
      final TestService service = Wire.put<TestService>(TestService());

      expect(service.isInitialized, isTrue);
      expect(service.initCount, 1);

      // 普通 delete 应被常驻保护拦截。
      expect(Wire.delete<TestService>(), isFalse);
      expect(Wire.isRegistered<TestService>(), isTrue);
      expect(service.isClosed, isFalse);

      // 普通 reset() 也应保留常驻服务。
      Wire.reset();
      expect(Wire.isRegistered<TestService>(), isTrue);
      expect(service.isClosed, isFalse);

      // 显式传入 force: true 才销毁并触发 onClose。
      expect(Wire.delete<TestService>(force: true), isTrue);
      expect(Wire.isRegistered<TestService>(), isFalse);
      expect(service.isClosed, isTrue);
      expect(service.closeCount, 1);
    });

    test('支持显式传入 permanent: false 覆盖 WireService 默认常驻策略', () {
      final TestService service = Wire.put<TestService>(
        TestService(serviceName: 'temp_service'),
        permanent: false,
      );

      expect(Wire.delete<TestService>(), isTrue);
      expect(service.isClosed, isTrue);
    });
  });
}
