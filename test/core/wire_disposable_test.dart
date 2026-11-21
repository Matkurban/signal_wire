import 'package:flutter_test/flutter_test.dart';
import 'package:signal_wire/signal_wire.dart';

import '../helpers/test_disposable.dart';
import '../helpers/throwing_close_disposable.dart';

/// `WireDisposable` 生命周期防重与自动内存回收单元测试。
///
/// Unit tests for [WireDisposable] idempotent lifecycle hooks and automatic
/// resource disposal.
void main() {
  tearDown(() {
    Wire.reset(clearPermanent: true);
  });

  group('WireDisposable 生命周期与自动回收 / Lifecycle & Auto-Disposal', () {
    test('onInit 与 onClose 仅触发一次且具备防重复保护 / idempotent init and close', () {
      final TestDisposable disposable = Wire.put<TestDisposable>(
        TestDisposable(),
      );

      expect(disposable.isInitialized, isTrue);
      expect(disposable.isClosed, isFalse);
      expect(disposable.initCount, 1);
      expect(disposable.closeCount, 0);

      // 重复调用 internalInit 不应再次触发 onInit。
      // ignore: invalid_use_of_internal_member
      disposable.internalInit();
      expect(disposable.initCount, 1);

      expect(Wire.delete<TestDisposable>(), isTrue);
      expect(disposable.isClosed, isTrue);
      expect(disposable.closeCount, 1);

      // 重复调用 internalClose 不应再次触发 onClose。
      // ignore: invalid_use_of_internal_member
      disposable.internalClose();
      expect(disposable.closeCount, 1);
    });

    test(
      'onClose 自动释放 createSignal、createComputed、createEffect 与 autoDispose (LIFO)',
      () {
        final TestDisposable disposable = Wire.put<TestDisposable>(
          TestDisposable(),
        );

        expect(disposable.count.value, 0);
        expect(disposable.doubled.value, 0);
        expect(disposable.effectLog, <int>[0]);

        disposable.count.value = 3;
        expect(disposable.doubled.value, 6);
        expect(disposable.effectLog, <int>[0, 3]);

        Wire.delete<TestDisposable>();

        // 信号与计算信号应已标记为 disposed。
        expect(disposable.count.disposed, isTrue);
        expect(disposable.doubled.disposed, isTrue);

        // 自定义清理回调应在 onClose 之后按 LIFO 逆序执行。
        expect(disposable.cleanupOrder, <String>[
          'onClose',
          'second',
          'first',
        ]);
      },
    );

    test('提前手动停止 createEffect 后，onClose 再次清理安全无异常 / idempotent early effect cleanup', () {
      final TestDisposable disposable = Wire.put<TestDisposable>(
        TestDisposable(),
      );

      disposable.count.value = 1;
      expect(disposable.effectLog, <int>[0, 1]);

      // 手动提前停止副作用。
      disposable.disposeEffect();
      disposable.count.value = 2;
      expect(disposable.effectLog, <int>[0, 1]);

      // 卸载销毁时再次执行清理不应抛出异常。
      expect(() => Wire.delete<TestDisposable>(), returnsNormally);
      expect(disposable.isClosed, isTrue);
    });

    test('实例已关闭后再次调用 autoDispose 应立即执行清理回调 / autoDispose after close runs immediately', () {
      final TestDisposable disposable = Wire.put<TestDisposable>(
        TestDisposable(),
      );
      Wire.delete<TestDisposable>();

      disposable.registerCustomCleanup('late_cleanup');
      expect(disposable.cleanupOrder.last, 'late_cleanup');
    });

    test('子类 onClose 抛异常时仍应完整释放 autoDispose 资源 / cleans up even if onClose throws', () {
      final ThrowingCloseDisposable disposable =
          Wire.put<ThrowingCloseDisposable>(ThrowingCloseDisposable());

      expect(
        () => Wire.delete<ThrowingCloseDisposable>(),
        throwsA(isA<StateError>()),
      );
      expect(disposable.isClosed, isTrue);
      expect(disposable.cleaned, isTrue);
    });
  });
}
