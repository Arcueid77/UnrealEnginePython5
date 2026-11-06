[English](Animation_API.md) | [简体中文](Animation_API.zh-CN.md)


<a id="the-animation-api"></a>

# 动画API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

您可以轻松控制动画蓝图变量和事件：

```py

from unreal_engine.classes import SkeletalMeshComponent

# get a reference to the skeletal mesh
skeletal = self.uobject.get_component_by_type(SkeletalMeshComponent)
# get a reference to the animation class
animation = skeletal.get_anim_instance()

# set a variable
animation.set_property('Speed', 17.0)

# trigger a custom event
animation.call('AttackWithSword')
```
