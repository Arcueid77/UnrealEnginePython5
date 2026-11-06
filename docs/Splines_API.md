[English](Splines_API.md) | [简体中文](Splines_API.zh-CN.md)

# The Splines API

> API examples and upstream reference. The [1.0.0 supported API inventory](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.md) defines the release contract. Individual examples record their original environment.

Splines are another amazing UE4 feature.

The following component shows how to move another actor over a spline path:

```py
class Spline:
    def begin_play(self):
        # get a reference to a spline component
        self.spline = self.uobject.get_owner().get_actor_component_by_type(ue.find_class('SplineComponent'))
        # find the length of the spline
        self.max_distance = self.spline.get_spline_length()
        self.distance = 0.0
        # get a reference to the actor to move (as a blueprint property)
        self.actor_to_move = self.uobject.get_owner().get_property('ObjectToMove')

    def tick(self, delta_time):
        if self.distance >= self.max_distance:
            return
        # find the next point on the spline
        next_point = self.spline.get_world_location_at_distance_along_spline(self.distance)
        self.actor_to_move.set_actor_location(next_point)
        self.distance += 100 * delta_time
```
