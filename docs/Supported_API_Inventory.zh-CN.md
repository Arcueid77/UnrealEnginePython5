[English](Supported_API_Inventory.md) | [简体中文](Supported_API_Inventory.zh-CN.md)

<a id="supported-api-inventory-for-100"></a>

# 1.0.0 受支持 API 清单

本版本冻结以下 API 范围，目标环境为 UE5.8.1、CPython3.11 和 Win64。各配置的验证结果与产物来源见[发布说明](Release_1.0.0.zh-CN.md)。下列主要契约规定了允许的输入、所有权及生命周期行为。

| API 范围 | 支持内容与边界 | 主要契约 |
| --- | --- | --- |
| 解释器 | 引擎 CPython 3.11，共享编辑器解释器或独立解释器，仅终结由 UEP 自己拥有的解释器 | Lifecycle_Threading_API.md |
| UObject 反射 | 已测试的标量、数学类型、结构体、枚举、对象及 array/map/set 属性，函数输入、返回值与原生 out 参数 | uobject_API.md, core_validation.py |
| 延迟软类输入 | 空值/null、已加载的 UClass 或经过验证的 Unicode 对象路径，拒绝非法路径及 NUL，解析过程中不加载类。此项未增加软引用 getter 契约 | soft_class_path_validation.py, open_menu_mixin.py |
| 动态类型 | 临时生成 UClass/FProperty/UFunction，名称在进程生命周期中唯一，类型或签名替换通过重启完成 | Subclassing_API.md, Lifecycle_Threading_API.md |
| 生产 Mixin | 保留 BP 类，按实例选择命名 Profile，Interface/CDO 声明，原函数回退与组合，以及清理和恢复 | Mixin_API.md, Mixin_Call_Lifecycle_Matrix.md |
| 委托与 Enhanced Input 生命周期 | 精确移除对应 callable/handle，在游戏线程显式清理 | EnhancedInput_API.md, Lifecycle_Threading_API.md |
| 运行时订阅作用域 | 原生委托，可选 Gameplay Message 信号，以及调用方提供已验证 VM payload reader 后的类型化消息。显式关闭，按规定的消息桥接契约交付 | Runtime_Subscriptions_API.md |
| Actor、World 与退出 | 原生生成和销毁、已观测的权威及复制行为、request_exit 有序退出，均遵循游戏线程约束 | Level_API.md, Lifecycle_Threading_API.md |
| World 查询辅助接口 | `get_world()` 支持 `UWorld`、`AActor` 和 `UActorComponent`，其他 UObject 类型会被拒绝。StateTree 节点的反射 world-context 操作遵循自身入口契约 | `ue_get_uworld` 位于 UEPyModule.cpp，另有 Explorer follow-map 反例夹具 |
| 编辑器、资产与 Slate 辅助接口 | 编辑器专属 API 遵循构建配置边界，并有资产及 Slate 所有权专项测试 | ManagingAssets.md, Slate_API.md, editor_validation.py |
| 构造图提取工具 | 编辑器中提取零参数 Actor 构造逻辑，并通过虚函数 helper 转发。调用方显式编译及保存，支持范围限于该构造适配流程 | Mixin_API.md, mixin_construction_forwarder_validation.py |
| 实验性 Blueprint 函数体脚本 | 独立 API，只有 int/bool out 地址夹具，遵循独立实验契约，生产 Mixin 与 RC 稳定性承诺覆盖清单中明确的生产接口 | blueprint_script_body_validation.py |

<a id="migration-rules"></a>

## 迁移规则

Blueprint 的 `KismetSystemLibrary.CollectGarbage` 通过 `GEngine->ForceGarbageCollection(true)` 请求 GC。检查旧包装对象前，需要跨过一个引擎帧，并记录请求帧和检查帧，以完成实际回收后的生命周期判定。

观察 Boolean Blueprint 网关时，必须返回原调用结果。回退 Profile 中的 `True` 可能使观察者返回后继续执行原图。应在后续控制帧检查完整输出，并让观察步骤遵循该返回时序。

UEP 的 `FRotator` 位置参数构造器采用 Roll/Pitch/Yaw 顺序，UE C++ 使用 Pitch/Yaw/Roll 顺序。测试及游戏逻辑宜显式设置 `.pitch`、`.yaw`、`.roll`，并核对原生返回的各轴，以确认 Pawn 的实际朝向。

既有 `register_mixin` 和 `@mixin` 保持兼容的单 Profile 形式。一个类需要多种行为时，可使用命名 Profile 或 Mixin Set。对象保有其 BP 生成的 Unreal 类型，其他代码在已测试的调用入口范围内正常解析反射方法。Python 成功或异常后的原函数调用遵循显式组合契约。

受控模块重载或 BP 资产编辑前，关闭订阅并注销路由。恢复时保留原 UFunction 身份。需要重新触发原生生命周期事件时，显式重建 Widget。生成类型及反射签名的变更通过重启进程应用。

Mixin 注册拒绝 RPC、delegate 和 latent 签名。直接 C++ 拦截及无限制热重载超出已发布契约。普通反射调用可以使用原生能力。原生通配符 CustomThunk 需要专门的绑定支持，读取必须经过专用 VM 入口。

1.0.0 发布版保留现有公开入口。1.x 期间的弃用说明会列出受影响 API、替代方案、迁移示例和计划移除版本，并在规定的弃用期提供兼容入口。实验性 API 遵循上表中的独立契约。

引擎及通用插件 C++ 系统承担原生职责。Examples 管理 Lyra 专属表现、业务及资产。ABP/动画、编辑器及测试工具、接口声明、组件及默认数据壳、UMG 布局沿用各自明确的迁移处置。已确认的游戏项目 C++ 迁移在 Examples 完成索引中单独验收。
