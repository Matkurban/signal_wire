import 'wire_disposable.dart';

/// 页面与局部视图控制器基类。
///
/// Base class for page-scoped and widget-scoped controllers.
///
/// 继承自 [WireDisposable]，默认随所属页面（`WireView`、`WireStateMixin` 或
/// `WireScope`）卸载而自动销毁并回收全部托管信号与副作用。
///
/// Extends [WireDisposable] and is automatically disposed together with all
/// managed signals and effects when its owning view or scope unmounts.
///
/// **零冗余首帧监听 / Zero overhead by default**：
/// 普通 [WireController] 不会自动注册 `WidgetsBinding.addPostFrameCallback`。
/// 如需在首帧渲染完成后执行逻辑，请按需混入 `WireReadyMixin`：
///
/// Plain [WireController] subclasses do not schedule post-frame callbacks.
/// Mix in `WireReadyMixin` on demand if you need an `onReady()` hook:
///
/// ```dart
/// class DetailController extends WireController with WireReadyMixin {
///   @override
///   void onReady() {
///     super.onReady();
///   }
/// }
/// ```
abstract class WireController extends WireDisposable {}
