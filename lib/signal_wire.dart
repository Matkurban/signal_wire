/// `signal_wire` 公共入口库。
///
/// Public entry library for `signal_wire`.
///
/// 结合 `signals_flutter` 的细粒度响应式状态管理与极简依赖注入、生命周期自动回收
/// 及结构化日志系统。完整导出 `signals_flutter`，开发者仅需引入
/// `package:signal_wire/signal_wire.dart` 即可使用全套响应式与依赖托管能力。
///
/// Combines `signals_flutter` fine-grained reactivity with minimal dependency
/// injection, automatic lifecycle disposal, and structured logging. Re-exports
/// `signals_flutter` so consumers only need to import
/// `package:signal_wire/signal_wire.dart`.
library;

export 'package:signals_flutter/signals_flutter.dart';

export 'src/core/wire_controller.dart';
export 'src/core/wire_disposable.dart';
export 'src/core/wire_ready_mixin.dart';
export 'src/core/wire_service.dart';
export 'src/di/wire.dart';
export 'src/di/wire_not_found_exception.dart';
export 'src/log/wire_log_category.dart';
export 'src/log/wire_log_level.dart';
export 'src/log/wire_log_record.dart';
export 'src/log/wire_logger.dart';
export 'src/widgets/wire_scope.dart';
export 'src/widgets/wire_state_mixin.dart';
export 'src/widgets/wire_view.dart';
