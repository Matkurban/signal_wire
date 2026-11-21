import 'package:flutter/scheduler.dart';

import '../core/wire_controller.dart';
import '../core/wire_disposable.dart';
import '../core/wire_service.dart';
import '../log/wire_log_category.dart';
import '../log/wire_logger.dart';
import 'wire_entry.dart';
import 'wire_key.dart';
import 'wire_not_found_exception.dart';

/// 极简静态依赖注入（Service Locator）容器。
///
/// Minimal static Dependency Injection (Service Locator) container.
///
/// 支持按类型与可选 `tag` 管理实例的注册、异步初始化、懒加载（含 `fenix` 自动重建）、
/// 查找与生命周期自动回收：
/// - 注册 [WireDisposable] 时自动调用 `onInit()`。
/// - 注册 [WireController] 时额外排程首帧 `onReady()`。
/// - 注册 [WireService] 时默认开启 `permanent: true` 常驻保护。
/// - 所有关键操作均通过 `WireLogger` 输出结构化分级日志。
///
/// Supports registering, async initialization, lazy instantiation (with
/// `fenix` recreation), lookup, and automatic lifecycle disposal keyed by
/// type and optional `tag`, with structured logging via `WireLogger`.
abstract final class Wire {
  /// 所有已注册依赖条目的存储表。
  ///
  /// Registry map storing all active and lazy dependency entries.
  static final Map<WireKey, WireEntry<Object?>> _entries =
      <WireKey, WireEntry<Object?>>{};

  /// 正在进行中的异步注册任务表，用于并发去重。
  ///
  /// In-flight async registration futures used to deduplicate concurrent
  /// [putAsync] calls for the same key.
  static final Map<WireKey, Future<Object?>> _pendingAsync =
      <WireKey, Future<Object?>>{};

  /// 立即注册一个类型为 [T] 的实例并返回最终生效的实例。
  ///
  /// Registers an instance of type [T] immediately and returns the active
  /// instance.
  ///
  /// 重复注册策略 / Duplicate registration behavior:
  /// - 当同 `(T, tag)` 已存在活跃实例且 [force] 为 `false`（默认）时：
  ///   保留并返回已有实例，同时输出 `WireLogLevel.warning` 警告日志，不会初始化或替换新传入的 [instance]。
  /// - 当 [force] 为 `true` 时：
  ///   先完成新实例的初始化并原子替换容器中的条目，再安全销毁旧实例（触发旧实例 `onClose()`），
  ///   确保替换瞬间界面或回调中访问 [find] 始终拿到有效的新实例，避免界面异常。
  ///
  /// - [instance]：待注册的实例对象。 / Instance to register.
  /// - [tag]：可选标签，用于区分同类型多实例。 / Optional tag for multiple
  ///   instances of the same type.
  /// - [permanent]：是否常驻保护；未传时若 [instance] 为 [WireService] 则
  ///   默认为 `true`，否则为 `false`。 / Whether to protect from non-forced
  ///   deletion; defaults to `true` for [WireService] and `false` otherwise.
  /// - [force]：当已存在同键实例时是否强制销毁旧实例并替换为新实例。
  ///   Whether to forcibly replace and dispose an existing instance for the
  ///   same key.
  static T put<T>(
    T instance, {
    String? tag,
    bool? permanent,
    bool force = false,
  }) {
    final WireKey key = WireKey(T, tag);
    final WireEntry<Object?>? existing = _entries[key];
    final bool effectivePermanent = permanent ?? (instance is WireService);

    if (existing != null && existing.hasInstance) {
      final T existingInstance = existing.instance as T;
      if (identical(existingInstance, instance)) {
        WireLogger.verbose(
          WireLogCategory.di,
          'put() ignored because the exact same instance is already registered.',
          type: T,
          tag: tag,
        );
        return existingInstance;
      }

      if (!force) {
        WireLogger.warning(
          WireLogCategory.di,
          'Already registered. Returning existing instance; pass `force: true` to replace and dispose the old instance.',
          type: T,
          tag: tag,
        );
        return existingInstance;
      }

      // 先初始化并原子替换容器条目，再安全销毁旧实例，避免界面在替换间隙读到空条目或抛出异常。
      // Initialize and atomically swap in the new instance before closing the
      // old one so active widgets/callbacks never observe a missing entry.
      _entries[key] = WireEntry<Object?>(
        instance: instance,
        permanent: effectivePermanent,
        fenix: false,
      );
      WireLogger.info(
        WireLogCategory.di,
        'Forcibly replaced existing instance (permanent=$effectivePermanent).',
        type: T,
        tag: tag,
      );
      _initializeLifecycle(instance);

      if (existingInstance is WireDisposable) {
        _safeCloseReplaced(existingInstance, type: T, tag: tag);
      }
      return instance;
    }

    _entries[key] = WireEntry<Object?>(
      instance: instance,
      permanent: effectivePermanent,
      fenix: false,
    );
    if (effectivePermanent) {
      WireLogger.info(
        WireLogCategory.di,
        'Registered permanent instance.',
        type: T,
        tag: tag,
      );
    } else {
      WireLogger.debug(
        WireLogCategory.di,
        'Registered instance.',
        type: T,
        tag: tag,
      );
    }
    _initializeLifecycle(instance);
    return instance;
  }

  /// 异步构造并注册一个类型为 [T] 的实例（适合 `WireService` 在 `runApp` 前初始化）。
  ///
  /// Asynchronously constructs and registers an instance of type [T] (ideal
  /// for initializing [WireService] dependencies before `runApp`).
  ///
  /// 若同 `(T, tag)` 已存在活跃实例且 [force] 为 `false`，直接返回已有实例并输出警告；
  /// 若同 `(T, tag)` 正有未完成的异步注册任务且 [force] 为 `false`，将复用该并发任务避免重复构造。
  ///
  /// - [builder]：异步实例构造函数。 / Async factory creating the instance.
  /// - [tag]：可选实例标签。 / Optional tag distinguishing same-type instances.
  /// - [permanent]：是否常驻保护；未传时对 [WireService] 自动为 `true`。
  ///   Optional permanent flag; defaults to `true` for [WireService].
  /// - [force]：是否强制替换已有实例。 / Whether to forcibly replace an
  ///   existing instance.
  static Future<T> putAsync<T>(
    Future<T> Function() builder, {
    String? tag,
    bool? permanent,
    bool force = false,
  }) {
    final WireKey key = WireKey(T, tag);
    final WireEntry<Object?>? existing = _entries[key];

    if (!force && existing != null && existing.hasInstance) {
      WireLogger.warning(
        WireLogCategory.di,
        'putAsync() skipped because instance is already registered; returning existing instance.',
        type: T,
        tag: tag,
      );
      return Future<T>.value(existing.instance as T);
    }

    if (!force && _pendingAsync.containsKey(key)) {
      WireLogger.debug(
        WireLogCategory.di,
        'Reusing in-flight putAsync() task.',
        type: T,
        tag: tag,
      );
      return _pendingAsync[key]!.then((Object? value) => value as T);
    }

    WireLogger.debug(
      WireLogCategory.di,
      'Starting putAsync() initialization (force=$force).',
      type: T,
      tag: tag,
    );

    late final Future<T> task;
    task = () async {
      try {
        final T instance = await builder();
        return put<T>(instance, tag: tag, permanent: permanent, force: force);
      } catch (error, stackTrace) {
        WireLogger.error(
          WireLogCategory.di,
          'putAsync() builder failed.',
          type: T,
          tag: tag,
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      } finally {
        if (identical(_pendingAsync[key], task)) {
          _pendingAsync.remove(key);
        }
      }
    }();

    _pendingAsync[key] = task;
    return task;
  }

  /// 注册一个懒加载依赖工厂，仅在首次调用 [find] 时才实例化。
  ///
  /// Registers a lazy factory that is instantiated on the first [find] call.
  ///
  /// - [builder]：用于创建实例的同步工厂函数。 / Synchronous factory callback
  ///   producing the instance.
  /// - [tag]：可选实例标签。 / Optional tag distinguishing same-type instances.
  /// - [fenix]：若为 `true`，实例被普通 [delete] 销毁后仍保留工厂函数，下次 [find]
  ///   会自动重建新实例；仅在 `delete(force: true)` 时彻底移除。 / If `true`,
  ///   retains [builder] after normal [delete] so the next [find] recreates a
  ///   fresh instance; removed permanently only by `delete(force: true)`.
  /// - [permanent]：是否常驻保护；若未指定且构建出的实例为 [WireService]，
  ///   首次实例化时也会自动视为常驻。 / Optional permanent flag; also
  ///   defaults to `true` when the built instance is a [WireService].
  static void lazyPut<T>(
    T Function() builder, {
    String? tag,
    bool fenix = false,
    bool? permanent,
  }) {
    final WireKey key = WireKey(T, tag);
    final WireEntry<Object?>? existing = _entries[key];
    if (existing != null && existing.hasInstance) {
      WireLogger.warning(
        WireLogCategory.di,
        'lazyPut() ignored because an active instance is already registered.',
        type: T,
        tag: tag,
      );
      return;
    }

    _entries[key] = WireEntry<Object?>(
      builder: () => builder(),
      permanent: permanent ?? false,
      fenix: fenix,
    );
    WireLogger.debug(
      WireLogCategory.di,
      'Registered lazy factory (fenix=$fenix, permanent=${permanent ?? false}).',
      type: T,
      tag: tag,
    );
  }

  /// 查找并返回已注册的类型为 [T] 的实例。
  ///
  /// Finds and returns the registered instance of type [T].
  ///
  /// 若该条目通过 [lazyPut] 注册且尚未实例化，将在本次调用中同步构建并自动触发
  /// 生命周期钩子；若未注册，则记录错误日志并抛出包含具体类型与 [tag] 的 [WireNotFoundException]。
  ///
  /// - [tag]：可选实例标签。 / Optional tag matching the registered instance.
  static T find<T>({String? tag}) {
    final WireKey key = WireKey(T, tag);
    final WireEntry<Object?>? entry = _entries[key];
    if (entry == null) {
      final WireNotFoundException exception = WireNotFoundException(
        type: T,
        tag: tag,
      );
      WireLogger.error(
        WireLogCategory.di,
        'Lookup failed: dependency not registered.',
        type: T,
        tag: tag,
        error: exception,
      );
      throw exception;
    }

    if (entry.hasInstance) {
      WireLogger.verbose(
        WireLogCategory.di,
        'Resolved active instance.',
        type: T,
        tag: tag,
      );
      return entry.instance as T;
    }

    final Object? Function()? builder = entry.builder;
    if (builder == null) {
      final WireNotFoundException exception = WireNotFoundException(
        type: T,
        tag: tag,
      );
      WireLogger.error(
        WireLogCategory.di,
        'Lookup failed: missing lazy builder.',
        type: T,
        tag: tag,
        error: exception,
      );
      throw exception;
    }

    final T created = builder() as T;
    entry.instance = created;
    if (created is WireService) {
      entry.permanent = true;
    }
    if (entry.fenix) {
      WireLogger.info(
        WireLogCategory.di,
        'Instantiated lazy/fenix dependency.',
        type: T,
        tag: tag,
      );
    } else {
      WireLogger.debug(
        WireLogCategory.di,
        'Instantiated lazy dependency.',
        type: T,
        tag: tag,
      );
    }
    _initializeLifecycle(created);
    return created;
  }

  /// 销毁并移除已注册的类型为 [T] 的实例，若为 [WireDisposable] 则触发 `onClose()`。
  ///
  /// Deletes and disposes the registered instance of type [T], invoking
  /// `onClose()` if it is a [WireDisposable].
  ///
  /// - [tag]：可选实例标签。 / Optional tag matching the registered instance.
  /// - [force]：是否强制删除受 `permanent` 保护的实例或清除 `fenix` 工厂。
  ///   Whether to bypass `permanent` protection and also clear `fenix`
  ///   factories.
  static bool delete<T>({String? tag, bool force = false}) {
    final WireKey key = WireKey(T, tag);
    final WireEntry<Object?>? entry = _entries[key];
    if (entry == null) {
      WireLogger.verbose(
        WireLogCategory.di,
        'delete() skipped: dependency not registered.',
        type: T,
        tag: tag,
      );
      return false;
    }

    if (entry.permanent && !force) {
      WireLogger.warning(
        WireLogCategory.di,
        'delete() blocked because instance is permanent. Pass `force: true` to dispose.',
        type: T,
        tag: tag,
      );
      return false;
    }

    final Object? instance = entry.instance;
    if (entry.fenix && !force) {
      entry.instance = null;
      WireLogger.info(
        WireLogCategory.di,
        'Disposed fenix instance while retaining factory for recreation.',
        type: T,
        tag: tag,
      );
    } else {
      _entries.remove(key);
      WireLogger.debug(
        WireLogCategory.di,
        'Deleted instance (force=$force).',
        type: T,
        tag: tag,
      );
    }

    if (instance is WireDisposable) {
      instance.internalClose();
    }
    return true;
  }

  /// 检查类型为 [T]（及可选 [tag]）的依赖是否已在容器中注册。
  ///
  /// Returns `true` if a dependency of type [T] (and optional [tag]) is
  /// registered in the container (either instantiated or lazily registered).
  ///
  /// - [tag]：可选实例标签。 / Optional tag to check.
  static bool isRegistered<T>({String? tag}) {
    final WireKey key = WireKey(T, tag);
    return _entries.containsKey(key);
  }

  /// 检查类型为 [T]（及可选 [tag]）的依赖是否已通过 [lazyPut] 预备但尚未实例化。
  ///
  /// Returns `true` if a dependency of type [T] (and optional [tag]) has been
  /// lazily registered via [lazyPut] and has not yet been instantiated.
  ///
  /// - [tag]：可选实例标签。 / Optional tag to check.
  static bool isPrepared<T>({String? tag}) {
    final WireKey key = WireKey(T, tag);
    final WireEntry<Object?>? entry = _entries[key];
    return entry != null && !entry.hasInstance && entry.builder != null;
  }

  /// 清空容器中的依赖（常用于单元测试 `tearDown` 或退出登录时的全局状态重置）。
  ///
  /// Resets the container by disposing registered entries (commonly used in
  /// unit test `tearDown` or full session logout).
  ///
  /// - [clearPermanent]：为 `false`（默认）时仅清理非常驻依赖；为 `true` 时
  ///   强制销毁并清空包括 [WireService] 在内的全部依赖。 / When `false`
  ///   (default), preserves `permanent` entries; when `true`, forcibly
  ///   disposes and clears all entries including [WireService].
  static void reset({bool clearPermanent = false}) {
    final List<MapEntry<WireKey, WireEntry<Object?>>> snapshot = _entries
        .entries
        .toList(growable: false);

    final List<WireDisposable> toClose = <WireDisposable>[];
    int removedCount = 0;

    for (final MapEntry<WireKey, WireEntry<Object?>> item in snapshot) {
      if (item.value.permanent && !clearPermanent) {
        continue;
      }
      _entries.remove(item.key);
      removedCount++;
      final Object? instance = item.value.instance;
      if (instance is WireDisposable) {
        toClose.add(instance);
      }
    }

    if (clearPermanent) {
      _pendingAsync.clear();
    }

    if (removedCount > 0) {
      WireLogger.info(
        WireLogCategory.di,
        'Container reset removed $removedCount entry(ies) (clearPermanent=$clearPermanent).',
      );
    }

    for (final WireDisposable disposable in toClose) {
      disposable.internalClose();
    }
  }

  /// 触发已注册实例的生命周期初始化钩子。
  ///
  /// Triggers lifecycle initialization hooks for a newly registered instance.
  static void _initializeLifecycle(Object? instance) {
    if (instance is WireDisposable) {
      instance.internalInit();
    }
    if (instance is WireController) {
      instance.internalReady();
    }
  }

  /// 安全销毁被 `put(force: true)` 替换下来的旧实例。
  ///
  /// Safely closes a previous instance replaced by `put(force: true)`.
  static void _safeCloseReplaced(
    WireDisposable oldInstance, {
    required Type type,
    String? tag,
  }) {
    SchedulerBinding? scheduler;
    try {
      scheduler = SchedulerBinding.instance;
    } catch (_) {
      scheduler = null;
    }

    if (scheduler != null &&
        scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WireLogger.debug(
        WireLogCategory.di,
        'Deferring old instance disposal to post-frame callback during active build.',
        type: type,
        tag: tag,
      );
      scheduler.addPostFrameCallback((_) {
        oldInstance.internalClose();
      });
      return;
    }

    oldInstance.internalClose();
  }
}
