[English](EnhancedInput_API.md) | [简体中文](EnhancedInput_API.zh-CN.md)

<a id="enhanced-input-api"></a>

# 增强输入API

UnrealEnginePython 0.3.0 公开运行时Python 游戏所需的UE5 增强输入操作。这些方法可在兼容的包装UObjects上使用，并使用本地玩家的`UEnhancedInputLocalPlayerSubsystem`或player/possessed pawn拥有的`UEnhancedInputComponent`。

<a id="trigger-events"></a>

## 触发事件

`bind_enhanced_action` 接受一个 Unreal `ETriggerEvent` 成员的整数值：

| 名称 | 价值 |
| --- | ---: |
| `Triggered` | 1 |
| `Started` | 2 |
| `Ongoing` | 4 |
| `Canceled` | 8 |
| `Completed` | 16 |

<a id="binding-actions"></a>

## 绑定动作

```python
TRIGGERED = 1
STARTED = 2
COMPLETED = 16

move_handle = pawn.bind_enhanced_action(IA_MOVE, TRIGGERED, on_move)
jump_start_handle = pawn.bind_enhanced_action(IA_JUMP, STARTED, on_jump)
jump_end_handle = pawn.bind_enhanced_action(IA_JUMP, COMPLETED, on_stop_jump)

count = pawn.get_enhanced_action_binding_count()
removed = pawn.remove_enhanced_action_binding(move_handle)
```

该绑定拥有对其回调的强 Python 引用。成功删除会立即清除该引用。保留数字句柄并在拥有对象的清理过程中将其删除。第二次删除同一句柄将返回`False`。

`bind_enhanced_action(action, trigger_event, callback)` 返回绑定的无符号句柄。回调接收一个从输入操作的配置值类型派生的 Python 值：

| 输入动作值类型 | Python回调值 |
| --- | --- |
| 布尔值 | `bool` |
| 轴 1D | `float` |
| 二维轴 | `unreal_engine.FVector2D` |
| 轴3D | `unreal_engine.FVector` |

绑定可能会在 pawn 构造期间或早期BeginPlay 失败，因为占有尚未创建其输入组件。当该挂钩可用时从设置输入时间绑定，或者像演示一样从稍后的游戏线程回调中重试。

<a id="mapping-contexts"></a>

## 映射上下文

```python
controller.add_enhanced_input_mapping_context(IMC_DEFAULT, 0)
ready = controller.has_enhanced_input_mapping_context(IMC_DEFAULT)
controller.remove_enhanced_input_mapping_context(IMC_DEFAULT)
```

- `add_enhanced_input_mapping_context(context, priority=0)` 添加上下文。
- 激活时，`has_enhanced_input_mapping_context(context)` 返回`True`。
- `remove_enhanced_input_mapping_context(context)` 将其删除。

这些方法需要本地玩家。它们不是服务器端复制API，并且在一个客户端上添加映射上下文不会配置另一个客户端。

<a id="deterministic-injection"></a>

## 确定性注入

测试和本地工具可以提供与游戏玩法相同的动作路径：

```python
controller.inject_enhanced_input_for_action(IA_JUMP, True)
controller.inject_enhanced_input_for_action(IA_MOVE, FVector2D(0.0, 1.0))
```

`inject_enhanced_input_for_action(action, value)` 根据操作的配置值类型验证 Python 值。它需要本地增强输入子系统，并且必须在虚幻的游戏线程上调用。

请参阅 `Demos/UEPPythonThirdPerson/Overlay/Content/Scripts/uep_third_person/character.py` 和 `controller.py`，了解在可打包示例中映射所有权、故障安全绑定、移动、查看和跳转。旧的 `uep_python_third_person.py` 路径仍然是兼容性导入。
