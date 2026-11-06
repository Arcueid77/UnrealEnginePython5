[English](Fracturing_API.md) | [简体中文](Fracturing_API.zh-CN.md)

# The Fracturing API

> API examples and upstream reference. The [1.0.0 supported API inventory](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.md) defines the release contract. Individual examples record their original environment.

Fracturing is one of the best features you get for free in unreal engine.

You can apply damage to destructible objects directly from python (more kind of damages will be added soon)

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

you can now call the 'explode' method via blueprints using the 'Call Python Component Method' node

Another approach (way more easier) would be adding a RadialForceComponent and fire it when you want to destroy something:

```py
# get a reference to the RadialForceComponent
self.radial_force = self.uobject.get_owner().get_actor_component_by_type(ue.find_class('RadialForceComponent'))

# fire it !
self.radial_force.call('FireImpulse')
```

