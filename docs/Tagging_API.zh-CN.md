[English](Tagging_API.md) | [简体中文](Tagging_API.zh-CN.md)

<a id="the-tagging-api"></a>

# 标签API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

您可以“标记”参与者和组件。

标签是一个分配给参与者和组件的字符串（好吧，内部是一个FName）。他们每个人都可以有多个标签。

<a id="tagging-actors"></a>

## 标记Actors

“标签”属性允许您标记演员：

```python
your_actor.Tags = ['foo', 'Bar', tEsT']
```

您最终可以快速检查参与者是否有标签：

```python
if your_actor.actor_has_tag('foo'):
    ue.log('Success')
```

不幸的是，查找带有标签的所有参与者是一个缓慢的操作（在 C++、Blueprint 中，显然还有 Python）：

```python
import unreal_engine as ue

def find_all_actors_with_tag(world, tag):
    for actor in world.all_actors():
        if actor.actor_has_tag(tag):
            yield actor


world = ue.get_editor_world()

for actor in find_all_actors_with_tag(world, 'foo'):
    print(actor)
```

最终你可以使用蓝图API：

```python
import unreal_engine as ue
from unreal_engine.classes import GameplayStatics

world = ue.get_editor_world()

# blueprint ufunctions returns a tuple (as UFunctions can returns multiple values)
actors, = GameplayStatics.GetAllActorsWithTag(world, 'one')
for actor in actors:
    print(actor)
```

<a id="tagging-components"></a>

## 标记组件

您也可以使用属性“ComponentTags”来标记组件：

```python
your_component.ComponentTags = ['one', 'two', 'three']
```

可以使用 component_has_tag() 函数快速检查标签可用性：

```python
if your_component.component_has_tag('one'):
    print('yes')
```

虽然您可以获得标有特定值的参与者组件列表：

```python
component_list = your_actor.get_components_by_tag('two')
```

该函数可以采用可选参数来指定必须考虑哪些 ActorComponent 类：

```python
from unreal_engine.classes import SceneComponent
# search all the components children of the class SceneComponent and tagged with 'two'
component_list = your_actor.get_components_by_tag('two', SceneComponent)
```
