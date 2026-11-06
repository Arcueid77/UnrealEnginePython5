[English](Fracturing_API.md) | [简体中文](Fracturing_API.zh-CN.md)

<a id="the-fracturing-api"></a>

# 断裂API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

断裂是您在虚幻引擎中免费获得的最佳功能之一。

您可以直接从Python对可破坏的物体施加伤害（很快就会添加更多种类的伤害）

```py
class DestroyMeComponent:

    def begin_play(self):
        # get a reference to a destructible component in the actor
        self.destructible = self.uobject.get_actor_component_by_type(ue.find_class('DestructibleComponent'))
        
    def tick(self, delta_time):
        pass
        
    def explode(self):
        # damage amount
        amount = 1000
        strength = 20000
        position = self.uobject.get_owner().get_actor_location()
        up = self.uobject.get_owner().get_actor_up()
        self.destructible.destructible_apply_damage(amount, strength, position, up)
    
```

您现在可以使用“Call Python Component Method”节点通过蓝图调用“explode”方法

另一种方法（更简单）是添加一个 RadialForceComponent 并在你想要销毁某些东西时触发它：

```py
# get a reference to the RadialForceComponent
self.radial_force = self.uobject.get_owner().get_actor_component_by_type(ue.find_class('RadialForceComponent'))

# fire it !
self.radial_force.call('FireImpulse')
```
