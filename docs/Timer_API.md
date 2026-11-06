[English](Timer_API.md) | [简体中文](Timer_API.zh-CN.md)

# The Timer API

> API examples and upstream reference. The [1.0.0 supported API inventory](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.md) defines the release contract. Individual examples record their original environment.

A custom python class is exposed (unreal_engine.FTimerHandler) to support UE4 timers:

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
