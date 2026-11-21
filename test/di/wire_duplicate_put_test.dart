import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/test_controller.dart';
import '../helpers/test_service.dart';

/// `Wire.put` 重复注册警告与 `force: true` 强制替换策略单元测试。
///
/// Unit tests verifying duplicate [Wire.put] warning behavior via [WireLogger]
/// and `force: true` replacement with old-instance disposal.
void main() {
  late List<WireLogRecord> records;

  setUp(() {
    records = <WireLogRecord>[];
    WireLogger.configure(
      enabled: true,
      minLevel: WireLogLevel.verbose,
      handler: records.add,
    );
  });

  tearDown(() {
    WireLogger.reset();
    Wire.reset(clearPermanent: true);
  });

  group('Wire.put 重复注册与 force 替换 / Duplicate Put & Force Replacement', () {
    test('同类型同 tag 重复 put 默认返回已有实例并输出 WARNING 日志，新实例不被初始化', () {
      final TestController first = Wire.put<TestController>(
        TestController(label: 'first', initialCount: 5),
      );
      final TestController candidate = TestController(
        label: 'second',
        initialCount: 99,
      );

      final TestController result = Wire.put<TestController>(candidate);

      expect(identical(result, first), isTrue);
      expect(first.isClosed, isFalse);
      expect(first.count.value, 5);
      expect(candidate.isInitialized, isFalse);

      final List<WireLogRecord> warnings = records
          .where((WireLogRecord r) => r.level == WireLogLevel.warning)
          .toList();
      expect(warnings, hasLength(1));
      expect(warnings.first.category, WireLogCategory.di);
      expect(warnings.first.type, TestController);
      expect(warnings.first.format(), contains('WARNING'));
      expect(warnings.first.format(), contains('TestController'));
    });

    test('传入完全相同的实例引用时幂等返回且不输出 WARNING 日志', () {
      final TestController controller = Wire.put<TestController>(
        TestController(label: 'same'),
      );

      final TestController result = Wire.put<TestController>(controller);

      expect(identical(result, controller), isTrue);
      expect(controller.initCount, 1);
      expect(
        records.where((WireLogRecord r) => r.level == WireLogLevel.warning),
        isEmpty,
      );
    });

    test('传入 force: true 时销毁旧实例、初始化并返回新实例，并记录 INFO 替换日志', () {
      final TestController oldCtrl = Wire.put<TestController>(
        TestController(label: 'old', initialCount: 1),
      );
      final TestController newCtrl = TestController(
        label: 'new',
        initialCount: 42,
      );

      final TestController result = Wire.put<TestController>(
        newCtrl,
        force: true,
      );

      expect(identical(result, newCtrl), isTrue);
      expect(identical(Wire.find<TestController>(), newCtrl), isTrue);
      expect(newCtrl.isInitialized, isTrue);
      expect(newCtrl.count.value, 42);
      expect(oldCtrl.isClosed, isTrue);
      expect(oldCtrl.count.disposed, isTrue);
      expect(
        records.where((WireLogRecord r) => r.level == WireLogLevel.warning),
        isEmpty,
      );
      expect(
        records.any(
          (WireLogRecord r) =>
              r.level == WireLogLevel.info &&
              r.category == WireLogCategory.di &&
              r.message.contains('Forcibly replaced'),
        ),
        isTrue,
      );
    });

    test('force: true 同样支持强制替换常驻的 WireService', () {
      final TestService oldService = Wire.put<TestService>(
        TestService(serviceName: 'v1'),
      );
      final TestService newService = Wire.put<TestService>(
        TestService(serviceName: 'v2'),
        force: true,
      );

      expect(oldService.isClosed, isTrue);
      expect(newService.isInitialized, isTrue);
      expect(Wire.find<TestService>().serviceName, 'v2');
      expect(Wire.delete<TestService>(), isFalse);
    });
  });
}
