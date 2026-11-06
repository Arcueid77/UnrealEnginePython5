[English](UnrealEngineModule.md) | [简体中文](UnrealEngineModule.zh-CN.md)

<a id="the-unreal_engine-module"></a>

unreal_engine模块
------------------------

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

这是一个通用模块，公开与特定“World”无关的函数（见下文）。

您可以从 actor、pawn、组件或直接从模块使用这些函数。

只需记住导入它：

```py
import unreal_engine
```

或（作为示例）

```py
import unreal_engine as ue
```


---
```py
uclass = unreal_engine.find_class('name')
```

此函数在引擎中搜索具有指定名称的类并返回其“uobject”（内部是一个 c++ UClass 对象）。您可以使用此 uobject 来搜索该类型的对象或生成新的 actor（以及更多的东西）

---
```py
uclass = unreal_engine.find_object('name')
```

这是 find_class 的更通用（且速度更慢）的变体，它搜索每个 UObject。例如，您可以使用它来获取资源的引用（例如材质、网格......）

---
```py
unreal_engine.log('message')
```

将字符串记录到编辑器输出日志中（在LogPythoncategory/class下）


---
```py
unreal_engine.log_warning('message')
```

将警告字符串（黄色）记录到编辑器输出日志中（在LogPythoncategory/class下）


---
```py
unreal_engine.log_error('message')
```

将错误字符串（红色）记录到编辑器输出日志中（在LogPythoncategory/class下）


---
```py
unreal_engine.add_on_screen_debug_message(key, timeout, 'message')
```

蓝图“打印字符串”函数的低级等效项。它在“超时”秒后消失，并且可以获得数字键（使用 -1 禁用按键功能）

TODO：支持颜色


---
```py
unreal_engine.print_string('message')
```

python 相当于蓝图“打印字符串”函数。它会在 2 秒后消失，并以青色书写。


---
```py
editor = unreal_engine.get_editor_world()
```

（仅在编辑器中可用）它允许获取对编辑器世界的引用。这将允许在不久的将来直接在编辑器中生成UObjects（用于自动化任务或编写编辑器本身的脚本）
