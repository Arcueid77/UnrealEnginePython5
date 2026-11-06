[English](Lifecycle_Threading_API.md) | [简体中文](Lifecycle_Threading_API.zh-CN.md)

<a id="lifecycle-reload-exceptions-and-threading"></a>

# 生命周期、重载、异常与线程

本文规定 UnrealEnginePython 1.0.0 在 UE 5.8.1、引擎自带 CPython 3.11.8 及 Win64 上的运行时契约。

<a id="interpreter-ownership"></a>

## 解释器所有权

UEP 验证了两种进程模式。

- 共享模式。Epic 的 `PythonScriptPlugin` 初始化 CPython，UEP 接入该解释器。
- 独立模式。`-DisablePython` 禁用 Epic 插件，由 UEP 初始化引擎自带的 CPython 3.11 运行时。

游戏代码应遵循既有解释器的所有权。UEP 只负责终结自己创建的解释器。

<a id="game-thread-rule"></a>

## 游戏线程规则

反射、UObject 创建与销毁、属性、函数、委托、World 访问和编辑器 API 均属于 Unreal 游戏线程。Python 工作线程可以执行纯 Python 计算或阻塞 I/O，涉及 UObject 的结果处理需交回游戏线程。

```python
import unreal_engine as ue

if not ue.is_in_game_thread():
    raise RuntimeError("UObject access must be dispatched to the game thread")
```

`is_in_game_thread()` 可从 Python 工作线程安全调用，用于诊断当前线程。其他 UObject 操作仍需遵循游戏线程规则。常见做法是由工作线程把普通 Python 数据放入队列，再由游戏线程代码或游戏回调读取。

<a id="headless-process-exit-040"></a>

## 无界面进程退出（0.4.0 引入）

`UObject.quit_game()` 需要所在 World 具有本地 `PlayerController`。专用服务器和 commandlet 可使用模块级退出请求。

```python
import unreal_engine as ue

ue.request_exit()
```

默认请求引擎主循环有序退出，使 UEP 完成对象子系统和自有解释器的清理。`ue.request_exit(True)` 请求平台强制退出，适用于已经无法恢复的进程。

<a id="delegate-and-input-lifetime"></a>

## 委托与输入生命周期

绑定会持有 Python callable。自 0.3.0 起，显式调用 `unbind_event(...)` 和 `remove_enhanced_action_binding(handle)` 会立即释放 callable 引用，并解除桥接代理的 GC root。所有者销毁后，HouseKeeper 清理过程也会处理跟踪到的 callable。

保存 Enhanced Input 返回的句柄，在所属游戏对象清理时移除。重复移除同一个句柄会返回 `False`。

需要成组管理游戏线程绑定时，`uep_runtime.SubscriptionScope` 持有对应的委托回调及可选原生 Gameplay Message 通道订阅。在 Destruct/EndPlay、Mixin 清理和模块重载前调用 `close()`。[运行时订阅](Runtime_Subscriptions_API.zh-CN.md)

<a id="dynamic-class-reload-contract"></a>

## 动态类重载契约

生成的类是临时类型，但 Unreal 类名在进程生命周期中需要唯一。重复定义同名动态类会抛出 `RuntimeError`，原类继续可用。新的类型定义通过重启编辑器或游戏进程加载。

代理式 `PyActor`/`PythonComponent` 代码的 Python 模块重载同样遵循动态 `UClass` 的类型规则。

<a id="exception-boundary"></a>

## 异常边界

反射 Python `UFunction` 中逃逸的异常会写入 Unreal 日志。原生调用记录错误后返回，并丢弃本次未完成转换的值，后续调用仍可继续。UE commandlet 会把 traceback 日志计为错误，因此验证使用独立进程，并只放行预期的 traceback 行。

回调异常应按真实玩法失败处理。在 Python 内捕获可恢复情况，并使反射回调保持简洁。

<a id="non-trivial-values-and-stress"></a>

## 非平凡类型与压力检查

动态调用帧通过 UE 反射初始化和销毁。`FString` 等返回值使用属性的拷贝操作。必验测试在两种解释器所有权模式下反复调用整数及变长字符串函数，检查生命周期和析构回归。
