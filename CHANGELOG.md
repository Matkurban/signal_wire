## 1.0.0

* Initial stable release of `signal_wire`, a pure-Dart Flutter state management, dependency injection, and automatic lifecycle disposal package built on `signals_flutter`.
* **Three-Tier Lifecycle Architecture**:
  * `WireDisposable`: Idempotent `onInit()` / `onClose()` hooks with LIFO exception-safe automatic disposal for the full `signals_flutter` signal family (`createSignal`, `createLazySignal`, `createReadonlySignal`, `createComputed`, `createEffect`, `createListSignal`, `createSetSignal`, `createMapSignal`, `createIterableSignal`, `createQueueSignal`, `createChangeStackSignal`, `createTrackedSignal`, `createAsyncSignal`, `createFutureSignal`, `createStreamSignal`, `createComputedAsync`, `createComputedFrom`, `createTimerSignal`, `createConnect`, `trackSignal`, and `autoDispose`).
  * `WireController`: Page-scoped controller adding post-frame `onReady()` with early-close protection.
  * `WireService`: Globally persistent service automatically registered with `permanent: true`.
* **Minimal Static DI Container (`Wire`)**:
  * Supports `put` (with duplicate-registration warning and frame-safe `force: true` replacement), `putAsync` (with concurrent deduplication), `lazyPut` (with `fenix: true` recreation), `find` (with clear `WireNotFoundException`), `delete`, `isRegistered`, `isPrepared`, and `reset`.
* **Three View Binding Modes (Zero Routing Lock-In)**:
  * Mode A: `WireView<T extends WireController>` backed by a custom `ComponentElement`.
  * Mode B: `WireStateMixin<W, T extends WireController>` compatible with `SignalsMixin`, `TickerProviderStateMixin`, and `SignalStatefulWidget`.
  * Mode C: `WireScope<T extends WireController>` supporting `builder`, `child`, and dynamic `tag` switching.
* **Structured Logging (`WireLogger`)**:
  * Configurable verbosity (`WireLogLevel`), subsystem categories (`WireLogCategory`), immutable `WireLogRecord`, pluggable custom `handler`, and re-entrancy protection.
