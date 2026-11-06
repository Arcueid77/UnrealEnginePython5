[English](Physics_API.md) | [简体中文](Physics_API.zh-CN.md)

<a id="the-physics-api"></a>

# 物理API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

公开了“set_simulate_physics”方法，用于在PrimitiveComponent上启用物理。

请记住，如果不相应地设置碰撞预设，则无法启用物理：

```py

# PyActor with a staticmeshcomponent (a sphere)
# when overlapped it became a physic object
class Ball:

    def begin_play(self):
        self.sphere = self.uobject.get_actor_component_by_type(ue.find_class('StaticMeshComponent'))
        
    def tick(self, delta_time):
        pass
    
    def on_actor_begin_overlap(self, me, other_actor):
        # change collision profile
        self.sphere.call('SetCollisionProfileName BlockAll')
        # enable physics
        self.sphere.set_simulate_physics()
        
    # once the object became a physics one, hit event will start arriving
    def on_actor_hit(self, me, other, *args):
        ue.print_string('HIT with ' + other.get_name())
```

TODO：公开更多物理函数，特别是施加力的函数
