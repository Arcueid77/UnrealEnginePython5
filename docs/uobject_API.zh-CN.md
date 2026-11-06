[English](uobject_API.md) | [简体中文](uobject_API.zh-CN.md)

<a id="the-uobject-api"></a>

uobject API
===============

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

这是 uobject api 公开的方法列表。

请记住，我们不需要公开 ue4 中可用的所有方法，而只需公开如果过多使用 C++ 反射可能会影响性能的最常见方法。对于所有其他情况，使用 uobject.call('Function args') 是最好的方法。

---
```py
vector = uobject.get_actor_location()
```

获取当前角色位置（如果需要，自动从组件中检索角色）

---
```py
uobject.set_actor_location(vector)
uobject.set_actor_location(x, y, z)
```

设置当前角色位置（如果需要，自动从组件中检索角色）

---
```py
rotation = uobject.get_actor_rotation()
```

获取当前的 actor 旋转（如果需要，自动从组件中检索 actor）


---
```py
uobject.set_actor_rotation(rotation)
uobject.set_actor_rotation(pitch, yaw, roll)
```
设置当前角色旋转（如果需要，自动从组件中检索角色）

---
```py
vector = uobject.get_actor_forward()
```

获取当前 actor 前向向量（如果需要，自动从组件中检索 actor）

---
```py
vector = uobject.get_actor_right()
```

获取当前演员的右向量（如果需要，自动从组件中检索演员）

---
```py
vector = uobject.get_actor_up()
```

获取当前演员的向上向量（如果需要，自动从组件中检索演员）

---
```py
vector = uobject.get_actor_velocity()
```
获取当前 actor 速度向量（如果需要，自动从组件中检索 actor）


---
```py
value = uobject.get_property('name')
```

获取 uobject 的属性值

注意：当前不支持结构


---
```py
uobject.set_property('name', value)
```

设置 uobject 的属性

注意：当前不支持结构

---
```py
properties_list = uobject.properties()
```

获取可用于 uobject 的属性列表（作为字符串名称列表）

---
```py
uobject.call('function arg0 arg1 argN....')
```

这可能是Unreal Engine反射系统最重要的功能。

它允许您调用由传递参数的 uobject 公开的 method/function。

例如，您有一个映射到 UTextRenderComponent 的 uobject，并且您想要更改文本：

```py
text_render_component.call('SetText Hello')
```

将调用 UTextRenderComponent::SetText(FString value) 方法，并将 'Hello' 作为字符串参数传递

该方法允许您与基本上每个引擎功能进行交互，但显然比直接调用 C++ 方法慢。

使用它来调用蓝图函数，或者在等待 uobject api 中添加新的特定方法时。）

---
```py
ret = uobject.call_function('function', arg0, arg1, argN....')
```

‘召唤’的高级伴侣。这是调用 UFUNCTION 并获取其返回值的更高级方法。

注意：不支持结构体

---
```py
actor = uobject.get_owner()
```

获取对象的所有者（通常由组件调用以获取其参与者）

---
```py
world = uobject.get_world()
```

获取包含对象的世界。 （目前仅用于测试和比较）

---
```py
name = uobject.get_name()
```
获取 uobject 的名称

---
```py
full_name = uobject.get_full_name()
```

获取uobject的全名

---
```py
# really slow !
found_uobject = uobject.find_object('name')
```

在调用者的同一世界中找到一个对象（按名称）（SLOW，除非您知道自己在做什么，否则不要使用它）

---
```py
# really really slow !
found_uobjects = uobject.all_objects()
```

获取调用者同一世界中所有 uobject 的列表（真的SLOW，除非你知道自己在做什么，否则不要使用它）

---
```py
found_actors = uobject.all_actors()
```

获取调用者同一世界中可用的所有参与者的列表。有点慢。

---
```py
uclass = uobject.get_class()
```

这与在 c++ 中调用 ->GetClass() 相同。您可以获得uobject的UClass。

---
```py
uclass = uobject.actor_spawn(uclass[, location, rotation])
```

产生一个演员。 uclass 是您可以通过 get_class() 或 unreal_engine.find_class() 获得的参考

---
```py
uobject.actor_destroy()
```

毁掉一个演员

---
```py
yesno = uobject.actor_has_component_of_type(uclass)
```

如果 actor 具有指定类型的组件，则返回 True

---
```py
component = uobject.get_actor_component_by_type(uclass)
# alias
component = uobject.get_component_by_type(uclass)
```

返回指定类型的第一个组件（演员的）


---
```py
components = uobject.get_actor_components()
```

获取映射到 actor 的所有组件的列表

---
```py
uobject.enable_input()
```

启用对象上的输入系统

---
```py
uobject.bind_input_axis('axis')
```

---
```py
uobject.quit_game()
```

通过第一个本地玩家控制器退出游戏世界。专用服务器没有本地控制器。使用模块级`unreal_engine.request_exit()`进行游戏、commandlet和服务器进程关闭。

---
```py
import unreal_engine as ue

ue.request_exit()
```

请求优雅的引擎循环退出，而不需要世界或玩家控制器。仅当需要强制退出平台时才通过`True`。

---
```py
yesno = uobject.is_input_key_down('key')
```

---
```py
value = uobject.get_input_axis('axis')
```

---
```py
yesno = uobject.actor_has_tag('tagname')
```

检查演员是否带有特定标签

---
```py
location, extents = uobject.get_actor_bounds()
```

获取对象的边界（位置和范围都是向量）

---
```py
hit = uobject.line_trace_single_by_channel(start, end, channel)
```

---
```py
[hit0, hit1, ...] = uobject.line_trace_multi_by_channel(start, end, channel)
```

---
```py
uobject.show_mouse_cursor()
```

---
```py
uobject.enable_click_events()
```

---
```py
uobject.enable_mouse_over_events()
```

---
```py
uobject.destructible_apply_damage(damage, impulse, direction, impulse)
```

请参阅自述文件中的压裂部分

---
```py
uobject.set_view_target(target)
```

更改视图目标。 “目标”参数应该是具有相机组件的演员。

---
```py
uobject.set_simulate_physics()
```

---
```py
new_component = uobject.add_actor_component(uclass, 'name')
```

添加指定uclass（类型）的新组件并设置其名称

---
```py
new_component = uobject.add_actor_root_component(uclass, 'name')
```

添加一个新组件作为指定 uclass（类型）的根组件并设置其名称

---
```py
uobject.simple_move_to_location(vector)
uobject.simple_move_to_location(x, y, z)
```

使用 navmesh 移动到某个位置（请参阅主自述文件中的导航）

---
```py
hit = self.uobject.get_hit_result_under_cursor(channel)
```

获取鼠标光标下的世界点（有关示例用法，请参阅主自述文件中的导航）


---
```py
length = uobject.get_spline_length()
```

获取样条线组件的长度（请参阅主自述文件中的样条线部分）

---
```py
vector = uobject.get_world_location_at_distance_along_spline(distance)
```

根据距离获取样条组件的 a 点（请参阅主自述文件中的样条部分）
