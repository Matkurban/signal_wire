import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/test_controller.dart';
import '../helpers/test_service.dart';

/// `WireLogger` 结构化日志系统的级别过滤、开关、防重入与全链路接入测试。
///
/// Unit tests for [WireLogger] level filtering, toggles, re-entrancy safety,
/// and structured log emission across DI and lifecycle events.
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

  group('WireLogger 结构化日志系统 / Structured Logging', () {
    test('支持按 minLevel 过滤日志以及通过 enabled / WireLogLevel.none 关闭日志', () {
      WireLogger.configure(minLevel: WireLogLevel.warning);

      WireLogger.verbose(WireLogCategory.di, 'v');
      WireLogger.debug(WireLogCategory.di, 'd');
      WireLogger.info(WireLogCategory.di, 'i');
      WireLogger.warning(WireLogCategory.di, 'w');
      WireLogger.error(WireLogCategory.di, 'e');

      expect(records.map((WireLogRecord r) => r.level).toList(), <WireLogLevel>[
        WireLogLevel.warning,
        WireLogLevel.error,
      ]);

      records.clear();
      WireLogger.configure(enabled: false);
      WireLogger.error(WireLogCategory.di, 'blocked');
      expect(records, isEmpty);

      WireLogger.configure(enabled: true, minLevel: WireLogLevel.none);
      WireLogger.error(WireLogCategory.di, 'blocked_by_none');
      expect(records, isEmpty);
    });

    test('自定义 handler 内部再次调用 WireLogger 时触发防重入保护，不会栈溢出', () {
      int calls = 0;
      WireLogger.configure(
        handler: (WireLogRecord record) {
          calls++;
          records.add(record);
          // 模拟 handler 内部误触发日志，应被防重入拦截。
          WireLogger.warning(WireLogCategory.di, 'nested_recursive_log');
        },
      );

      WireLogger.info(WireLogCategory.di, 'outer_log');

      expect(calls, 1);
      expect(records, hasLength(1));
      expect(records.first.message, 'outer_log');
    });

    test('DI 常驻删除拦截、未找到异常与生命周期钩子均产出正确分类与级别的日志', () {
      Wire.put<TestService>(TestService(), tag: 'auth');
      expect(Wire.delete<TestService>(tag: 'auth'), isFalse);

      expect(
        () => Wire.find<TestController>(tag: 'missing'),
        throwsA(isA<WireNotFoundException>()),
      );

      expect(
        records.any(
          (WireLogRecord r) =>
              r.level == WireLogLevel.info &&
              r.category == WireLogCategory.di &&
              r.type == TestService &&
              r.tag == 'auth',
        ),
        isTrue,
      );
      expect(
        records.any(
          (WireLogRecord r) =>
              r.level == WireLogLevel.warning &&
              r.category == WireLogCategory.di &&
              r.message.contains('permanent'),
        ),
        isTrue,
      );
      expect(
        records.any(
          (WireLogRecord r) =>
              r.level == WireLogLevel.error &&
              r.category == WireLogCategory.di &&
              r.error is WireNotFoundException &&
              r.tag == 'missing',
        ),
        isTrue,
      );
      expect(
        records.any(
          (WireLogRecord r) =>
              r.level == WireLogLevel.debug &&
              r.category == WireLogCategory.lifecycle &&
              r.message == 'onInit()',
        ),
        isTrue,
      );
    });
  });
}
