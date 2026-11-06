[English](Splines_API.md) | [简体中文](Splines_API.zh-CN.md)

<a id="the-splines-api"></a>

# 样条线API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

样条线是另一个令人惊叹的UE4功能。

以下组件展示了如何在样条路径上移动另一个角色：

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
