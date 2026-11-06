[English](Animation_API.md) | [简体中文](Animation_API.zh-CN.md)


# The Animation API

> API examples and upstream reference. The [1.0.0 supported API inventory](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.md) defines the release contract. Individual examples record their original environment.

You can control animation blueprints variables and events easily:

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
