import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/test_service.dart';

/// `Wire.putAsync` 异步初始化、并发去重与异常日志单元测试。
///
/// Unit tests for [Wire.putAsync] asynchronous registration, concurrent
/// deduplication, error logging, and `WireService` permanent protection.
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

  group('Wire.putAsync 异步注册 / Async Registration', () {
    test('异步构造并注册 WireService，自动触发 onInit 并受 permanent 保护', () async {
      final TestService service = await Wire.putAsync<TestService>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return TestService(serviceName: 'async_auth');
      });

      expect(service.isInitialized, isTrue);
      expect(service.serviceName, 'async_auth');
      expect(identical(Wire.find<TestService>(), service), isTrue);
      expect(Wire.delete<TestService>(), isFalse);
    });

    test('同键并发调用 putAsync 时自动去重，仅执行一次 builder', () async {
      int buildCount = 0;
      final Completer<TestService> completer = Completer<TestService>();

      final Future<TestService> f1 = Wire.putAsync<TestService>(() {
        buildCount++;
        return completer.future;
      });
      final Future<TestService> f2 = Wire.putAsync<TestService>(() {
        buildCount++;
        return Future<TestService>.value(TestService(serviceName: 'duplicate'));
      });

      completer.complete(TestService(serviceName: 'single'));

      final List<TestService> results = await Future.wait<TestService>(
        <Future<TestService>>[f1, f2],
      );

      expect(buildCount, 1);
      expect(identical(results[0], results[1]), isTrue);
      expect(results[0].serviceName, 'single');
    });

    test('已存在实例时再次调用 putAsync 返回已有实例并记录 WARNING；force: true 则替换为新实例', () async {
      final TestService first = await Wire.putAsync<TestService>(
        () async => TestService(serviceName: 'first'),
      );

      final TestService duplicate = await Wire.putAsync<TestService>(
        () async => TestService(serviceName: 'second'),
      );
      expect(identical(duplicate, first), isTrue);
      expect(
        records.where((WireLogRecord r) => r.level == WireLogLevel.warning),
        hasLength(1),
      );

      final TestService replaced = await Wire.putAsync<TestService>(
        () async => TestService(serviceName: 'third'),
        force: true,
      );
      expect(identical(replaced, first), isFalse);
      expect(first.isClosed, isTrue);
      expect(replaced.serviceName, 'third');
    });

    test('putAsync 构造失败时记录 ERROR 日志并清理挂起状态允许重试', () async {
      await expectLater(
        Wire.putAsync<TestService>(() async {
          throw StateError('network offline');
        }),
        throwsA(isA<StateError>()),
      );

      expect(
        records.any(
          (WireLogRecord r) =>
              r.level == WireLogLevel.error && r.category == WireLogCategory.di,
        ),
        isTrue,
      );

      // 重试应当能够成功注册。
      final TestService recovered = await Wire.putAsync<TestService>(
        () async => TestService(serviceName: 'recovered'),
      );
      expect(recovered.serviceName, 'recovered');
    });
  });
}
