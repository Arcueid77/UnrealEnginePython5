[English](Timer_API.md) | [简体中文](Timer_API.zh-CN.md)

<a id="the-timer-api"></a>

# 计时器API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

公开了一个自定义Python类（unreal_engine.FTimerHandler）来支持UE4计时器：

```py
# create a timer
timer = self.uobject.set_timer(frequency, callable[, loop, initial])
# clear a timer
timer.clear()
# pause a timer
timer.pause()
# unpause a timer
timer.unpause()
```
