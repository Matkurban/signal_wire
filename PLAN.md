# `signal_wire` 架构设计与编码规范

## 1. 已确认的工程与编码规范

1. **纯 Dart Flutter Package**：
   - 彻底移除插件根目录的 `android/`、`ios/`、`linux/`、`macos/`、`windows/`、`pigeon/` 与旧平台通道代码。
   - 保留 `example/` 示例工程，使用 `package:material_ui/material_ui.dart` 与标准路由演示全部功能。
2. **严格单文件单类原则**：
   - `lib/`、`test/`、`example/lib/` 中每个 `.dart` 文件仅定义一个顶层类型（`class`、`mixin`、`enum`、`extension`），不将多个类或组件堆叠在同一文件中。
   - 自定义 `Element`、`State`、容器内部 Key/Entry 等全部拆分为独立文件。
3. **完整中英双语 Dartdoc 注释**：
   - 每个类、mixin、枚举、构造函数、方法、属性、参数均提供清晰、准确的中英双语 `///` 文档注释。
   - 严格遵循 Sound Null Safety 与 `flutter_lints`，禁止 `print()` 与文件级 `// ignore_for_file:`。
4. **`Wire.put` 重复注册与强制替换策略**：
   - 默认（`force: false`）：同 `(Type, tag)` 已存在活跃实例时，保留并返回已有实例，同时通过 `debugPrint` 输出清晰警告日志。
   - 强制替换（`force: true`）：先完成新实例的初始化并原子替换容器条目，再销毁旧实例（触发旧实例 `onClose()`），确保替换过程中容器始终持有有效实例，避免界面在帧渲染或回调中出现异常。

---

## 2. 目录结构规划

### 核心库 (`lib/`)
```text
lib/
├── signal_wire.dart                        # 公共入口：导出 signal_wire 全部 API + signals_flutter
└── src/
    ├── core/
    │   ├── wire_disposable.dart            # WireDisposable（防重初始化/销毁 + 自动内存回收）
    │   ├── wire_controller.dart            # WireController（扩展 onReady() 首帧回调）
    │   └── wire_service.dart               # WireService（全局常驻，默认 permanent: true）
    ├── di/
    │   ├── wire_key.dart                   # WireKey（不可变 Type + tag 键）
    │   ├── wire_entry.dart                 # WireEntry（容器条目：实例/懒加载工厂/permanent/fenix）
    │   ├── wire_not_found_exception.dart   # WireNotFoundException（清晰的类型与 tag 异常）
    │   └── wire.dart                       # Wire（静态 DI 容器）
    └── widgets/
        ├── wire_view.dart                  # WireView<T>（直接继承 Widget）
        ├── wire_view_element.dart          # WireViewElement<T>（自定义 ComponentElement）
        ├── wire_state_mixin.dart           # WireStateMixin<W, T>（兼容 SignalsMixin 等）
        ├── wire_scope.dart                 # WireScope<T>（作用域包裹组件）
        └── wire_scope_state.dart           # WireScopeState<T>（WireScope 对应的 State）
```

### 分文件测试套件 (`test/`)
```text
test/
├── helpers/
│   ├── test_disposable.dart                # 测试用 WireDisposable 子类
│   ├── throwing_close_disposable.dart      # onClose 抛异常的测试子类
│   ├── test_controller.dart                # 测试用 WireController 子类
│   ├── secondary_controller.dart           # 多类型隔离测试用控制器
│   ├── test_service.dart                   # 测试用 WireService 子类
│   ├── plain_dependency.dart               # 普通非 WireDisposable 依赖类
│   ├── owned_wire_view.dart                # 重写 wire() 的测试 WireView
│   ├── external_wire_view.dart             # 未重写 wire() 的测试 WireView
│   ├── tagged_wire_view.dart               # 支持动态 tag 的测试 WireView
│   ├── owned_state_mixin_page.dart         # 重写 wire() 的 WireStateMixin 测试页
│   ├── owned_state_mixin_page_state.dart   # 对应 State
│   ├── external_state_mixin_page.dart      # 未重写 wire() 的 WireStateMixin 测试页
│   ├── external_state_mixin_page_state.dart
│   ├── signals_first_mixin_page.dart       # SignalsMixin 在前的混合测试页
│   ├── signals_first_mixin_page_state.dart
│   ├── wire_first_mixin_page.dart          # WireStateMixin 在前的混合测试页
│   └── wire_first_mixin_page_state.dart
├── core/
│   ├── wire_disposable_test.dart           # WireDisposable 生命周期与自动回收测试
│   ├── wire_controller_test.dart           # WireController onReady 与首帧前销毁测试
│   └── wire_service_test.dart              # WireService 常驻特性测试
├── di/
│   ├── wire_basic_di_test.dart             # put / find / delete / isRegistered / tag / reset
│   ├── wire_duplicate_put_test.dart        # 重复 put 警告返回已有实例 & force: true 安全替换
│   ├── wire_async_di_test.dart             # putAsync 异步初始化与并发去重
│   └── wire_lazy_fenix_test.dart           # lazyPut 懒加载与 fenix 涅槃重建
├── widgets/
│   ├── wire_view_test.dart                 # 模式 A：WireView 完整生命周期与响应性测试
│   ├── wire_state_mixin_test.dart          # 模式 B：WireStateMixin 与 SignalsMixin 共存测试
│   └── wire_scope_test.dart                # 模式 C：WireScope builder / child / tag 切换测试
└── integration/
    └── wire_integration_test.dart          # 全局 WireService + 页面销毁联动与强替换 UI 安全测试
```

### 示例工程 (`example/lib/`)
```text
example/lib/
├── main.dart                               # 入口：初始化 AuthService 并启动 App
├── app.dart                                # SignalWireExampleApp
├── services/
│   └── auth_service.dart                   # AuthService extends WireService
├── controllers/
│   ├── wire_view_counter_controller.dart   # 页面 1 控制器
│   ├── mixin_demo_controller.dart          # 页面 2 控制器
│   └── scope_demo_controller.dart          # 页面 3 控制器
└── pages/
    ├── home_page.dart                      # 首页导航与全局 AuthService 状态卡片
    ├── wire_view_demo_page.dart            # 页面 1：WireView 极简继承模式
    ├── wire_state_mixin_demo_page.dart     # 页面 2：StatefulWidget 壳
    ├── wire_state_mixin_demo_page_state.dart # 页面 2：SignalsMixin + WireStateMixin
    ├── wire_scope_demo_page.dart           # 页面 3：WireScope 外部包裹模式
    └── wire_scope_inner_card.dart          # 页面 3 内部纯展示组件
```
