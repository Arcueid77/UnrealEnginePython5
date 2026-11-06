[English](Navigation_API.md) | [简体中文](Navigation_API.zh-CN.md)

<a id="the-navigation-api"></a>

# 导航API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

唯一公开的与导航相关的方法是“simple_move_to_location”。它需要一个带有运动组件（如角色）的Pawn

```py
class MoveToTargetComponent:

    def begin_play(self):
        # get a 'target point' reference from a pawn public property
        target = self.uobject.get_owner().get_property('target')
        self.uobject.get_owner().simple_move_to_location(target.get_actor_location())
        
    def tick(self, delta_time):
        pass
```

另一个类似暗黑破坏神动作的例子（点击移动，将此组件添加到角色上）

```py
class Walker:
    def begin_play(self):
        self.uobject.show_mouse_cursor()
    def tick(self, delta_time):
        if not self.uobject.is_input_key_down('LeftMouseButton'):
            return
        hit = self.uobject.get_hit_result_under_cursor(ue.COLLISION_CHANNEL_VISIBILITY)
        if not hit:
            return
        # hit is a unreal_engine.FHitResult object
        self.uobject.simple_move_to_location(hit.impact_point)
```
