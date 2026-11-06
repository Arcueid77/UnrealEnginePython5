[English](Foliage_API.md) | [简体中文](Foliage_API.zh-CN.md)

<a id="the-foliage-api"></a>

# 树叶API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

每个UWorld都可以有其专用于绘制树叶的AInstancedFoliageActor。

基本上，树叶系统是静态网格物体的大量实例。

UFoliageType 是可以绘制为树叶的 StaticMesh 的表示。

您可以轻松创建UFoliageType：

```python
from unreal_engine.classes import FoliageTypeFactory, StaticMesh
import unreal_engine as ue

factory = FoliageTypeFactory()
foliage_type = factory.factory_create_new('/Game/Foliage/FirstFoliageType')
foliage_type.Mesh = ue.load_object(StaticMesh, '/Game/Mesh/StaticMesh001')
foliage_type.save_package()
```

要将 UFoliageType 添加到 UWorld 只需执行以下操作：

```python

world.add_foliage_asset(foliage_type)
```

最终您可以将 StaticMesh （而不是 FoliageType）直接添加到 AInstancedFoliageActor：

```python
world.add_foliage_asset(ue.load_object(StaticMesh, '/Game/Mesh/StaticMesh001'))
```

注意：遗憾的是，树叶编辑器不会自动更新，只需将编辑器模式手动切换到树叶模式即可更新资源列表。

您可以使用以下方式获取对世界的AInstancedFoliageActor的引用：

```python
foliage_actor = world.get_instanced_foliage_actor_for_current_level()
```

<a id="iterating-instances"></a>

## 迭代实例

您可以获得每个实例的 FFoliageInstance 结构（按 UFoliageType 分组）：

```python
import unreal_engine as ue

foliage_actor = ue.get_editor_world().get_instanced_foliage_actor_for_current_level()

for foliage_type in foliage_actor.get_foliage_types():
   print('Foliage Type: {0}'.format(foliage_type.get_name()))
   for foliage_instance in foliage_actor.get_foliage_instances(foliage_type):
       print(foliage_instance.location)
       print(foliage_instance.draw_scale3d)
       print(foliage_instance.pre_align_rotation)
       print(foliage_instance.rotation)
       print(foliage_instance.flags)
       print(foliage_instance.zoffset)
       print('*' * 20)
```
