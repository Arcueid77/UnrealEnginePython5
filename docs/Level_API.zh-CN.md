[English](Level_API.md) | [简体中文](Level_API.zh-CN.md)

<a id="the-level-api"></a>

# 等级API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

<a id="ulevel-vs-uworld"></a>

## ULevel 与 UWorld

在处理 Level api 之前，我们需要关注关卡和世界之间的细微差别。

粗略地说，问题是在执行层面。

UWorld是演员的容器，但为了允许诸如“关卡流”之类的功能（在开放世界游戏中很常见，您无法完全加载一个巨大的关卡，而是只加载其当前相关的部分），UWorld可以映射到一个或多个“关卡”。

更清楚地说：当您创建一个新关卡（或某些命名约定中的新“地图”）时，您实际上是在创建一个新的 UWorld 资产（它甚至有一个工厂！）：

```python
from unreal_engine.classes import WorldFactory

factory = WorldFactory()
new_world = factory.factory_create_new('/Game/Maps/FooLevel')
```

new_world对象实际上是一个UWorld。每当您从编辑器创建关卡时，您都在创建一个世界（是的，这听起来很奇怪......）

现在，有时（就像之前的开放世界示例一样），您希望这个世界的多个在同一视口中同时处于活动状态。但是视口映射到单个世界，因此需要额外的抽象（ULevel）。

因此，默认情况下，对于每个 UWorld，您都有一个 ULevel 对象来表示它，但您可以加载其他 UWorld 并将它们与“主”对象“组合”。

让我们尝试用另一个例子来澄清事情（仔细阅读评论）：


```python
import unreal_engine as ue
from unreal_engine.classes import WorldFactory, Actor, PlayerStart

factory = WorldFactory()

# create a world (it will be the main one, the one you load into the editor by double clicking it)
main_world = factory.factory_create_new('/Game/MapsTest/MainWorld001')
# spawn actors in the world
actor0 = main_world.actor_spawn(PlayerStart)

# create another world
child_world1 = factory.factory_create_new('/Game/MapsTest/ChildWorld001')
# spawn actors in the world
actor1 = child_world1.actor_spawn(Actor)
actor2 = child_world1.actor_spawn(Actor)
actor3 = child_world1.actor_spawn(Actor)

# create another world
child_world2 = factory.factory_create_new('/Game/MapsTest/ChildWorld002')
# spawn actors in the world
actor4 = child_world2.actor_spawn(Actor)

# now the important part, each UWorld, has a ULevel mapped to it (the PersistentLevel):
main_level = main_world.PersistentLevel
child_level1 = child_world1.PersistentLevel
child_level2 = child_world2.PersistentLevel

# open main world in the editor
ue.open_editor_for_asset(main_world)
```

<a id="joining-levels-to-a-single-world"></a>

## 将关卡连接到一个世界

所以我们现在知道每个世界资产都有其对应的关卡，这个关卡是一个世界可以用来附加到另一个世界以实现组合（如果多个开发人员在场景的不同区域工作时很有用）或流的“联合”。

要将关卡附加到世界，您可以使用以下函数：

```python
import unreal_engine as ue

# note we pass the name of the asset instead of the uobject !
# returns a ULevelStreaming, if you want to retrieve a ULevel from ULevelStreaming, use the 'LoadedLevel' property
added_streaming_level = ue.add_level_to_world(main_world, child_world1.get_path_name()[, always_loaded])
```

请记住，您需要传递要附加的世界的资产路径！

always_loaded可选布尔参数，如果设置，将添加一个持久级别而不是流级别（这意味着每当您加载main_world甚至child_world1也将被启用）

<a id="the-currentlevel-concept"></a>

# “CurrentLevel”概念

每个世界都有“当前等级”的概念。例如，当您在世界上调用 actor_spawn() 时，演员将在标记为当前级别的世界中有效生成：

```python
# get a reference to the current level
current_level = ue.get_editor_world().get_current_level()

# change the current level
ue.get_editor_world().set_current_level(child_level1)

# spawn an actor in editor world, but effectively it will be spawned
# in a child level
actor001 = ue.get_editor_world().actor_spawn(actor001)

# back to the original level
ue.get_editor_world().set_current_level(current_level)
```
