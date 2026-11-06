[English](Runtime_Subscriptions_API.md) | [简体中文](Runtime_Subscriptions_API.zh-CN.md)

<a id="runtime-subscriptions"></a>

# 运行时订阅

`uep_runtime.SubscriptionScope` 管理游戏线程上的订阅。UEP 将其 Python 源码作为 NonUFS 松散文件暂存，在编辑器和打包游戏中搜索已启用插件的 Content/Scripts 目录。项目自身的 Content/Scripts 优先进入项目搜索路径。

```python
from uep_runtime import SubscriptionScope

def on_quickbar_changed(channel):
    # Query this presenter's own controller. The message channel alone does
    # not identify a local player or transfer authority to Python.
    refresh_from_native_inventory()

scope = SubscriptionScope()
scope.bind_event(controller, "OnPossessedPawnChanged", on_pawn_changed)
scope.listen_gameplay_signal(controller, "Lyra.QuickBar.Message.ActiveIndexChanged", on_quickbar_changed)

# From Destruct/EndPlay and the Mixin teardown hook:
scope.close()
```

`bind_event` 转发委托参数，并保留用于精确解绑的原 bound callable。`listen_gameplay_signal` 使用可选 GameplayMessageRouter 插件的原生异步代理，先绑定再激活，检查激活结果，并在关闭时取消。该信号接口仅交付通道，通配符 CustomThunk GetPayload 通过专用的类型化 VM 入口读取。

调用方提供经过显式验证的适配器后，`listen_gameplay_message(context, channel, payload_type, payload_reader, callback)` 支持类型化交付。payload_type 是有效的 UScriptStruct UObject。`payload_reader(proxy)` 必须在原生交付**期间**拷贝 payload，提取失败时报告失败。回调接收 `(actual_channel, payload)`。关闭、禁用回调、精确解绑与原生取消遵循同一作用域规则。

GetPayload 的 C++ 签名只是通配符占位，读取需使用专用 VM 入口。Examples 中的 `BP_UEPGameplayMessages` 提供已编译的类型化 ReadUI/ReadVerb 函数，使用局部结构体临时值，返回自有 payload 副本及成功状态。该 Blueprint 桥接仅负责通配符转换，订阅者业务在 Python 中实现。Core 与 GameplayMessageRouter 采用可选运行时集成，payload 布局由显式类型和 reader 决定。错误的 reader/type 会失败。原生代理的 payload 存储在回调结束后失效。副本中的 UObject 成员仍遵循原生 World/GC 生命周期，后续 World 中的 Actor 引用需按该生命周期处理。

原生专项夹具 `transport01` 验证用户定义的 ADS 结构及 LyraVerbMessage、对象身份、嵌套广播及副本隔离、错误 reader 和交付期外访问的拒绝、既有信号兼容性，以及幂等关闭后的零回调。该项只证明消息传输契约，真实 ADS/击杀玩法和打包后的类型化消息需要各自的验收记录。

关闭操作是幂等的。它先禁用回调，再执行原生解绑及取消，尝试所有清理项并报告失败。`closed` 和 `count` 提供自有状态查询，也支持 context manager 用法。UObject 操作在游戏线程执行，终结器和解释器退出钩子按对象有效期处理清理。

Gameplay Message 的范围覆盖整个 GameInstance。适配器需按自己的 player/World 过滤，以隔离各玩家数据。原生异步代理需要有效的 World/GameInstance 和可选插件，缺少依赖会明确失败。该集成采用可选插件契约，UEP Core 的 C++ 链接依赖保持独立。

<a id="lyra-weapon-adapter"></a>

## Lyra 武器适配器

Examples 管理 `uep_lyra_hud.weapon_observer`。原生 QuickBar slot/index 及 Pawn 信号会触发即时刷新。Lyra StatTags FastArray 缺少公开的弹药变化委托，因此适配器使用共享的只读逐帧采样器，缓存当前样本中的 controller/item 读取，只在数值或所有权发生变化时发送更新。报告使用 `read-only-frame-sampler` 标识来源。

最后一个订阅者退出时，释放采样器及按 controller 引用计数的作用域。原生物品栏、装备、GAS、输入、复制和权威逻辑继续由 Lyra 管理。Widget Tick 会抑制原 BP 轮询，实时 Profile 切换后只进行一次观察重建，普通帧使用共享采样器。

受控重载依次移除 Widget、注销路由、关闭旧观察者、重载模块、重新注册及创建新的 Widget。原生生命周期事件和任意 Python 状态需由重载流程显式重建或迁移。

Core 宿主测试覆盖委托身份、取消及禁用、激活失败、GC 后失效的包装对象、可选插件缺失及清理失败。真实 UE 测试覆盖原生消息取消、实时 Profile 切换、3 次 reload/GC、3 次 PIE 和多人切图及所有权。打包与实际运行时导入具有各自独立的验收记录。
