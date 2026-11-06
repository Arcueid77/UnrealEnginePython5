[English](Physics_API.md) | [简体中文](Physics_API.zh-CN.md)

# The Physics API

> API examples and upstream reference. The [1.0.0 supported API inventory](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.md) defines the release contract. Individual examples record their original environment.

The 'set_simulate_physics' method is exposed for enabling physic on PrimitiveComponent.

Remember that you cannot enable physics withotu setting the collision presetes accordingly:

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

TODO: expose more physics functions, expecially the one for applying forces
