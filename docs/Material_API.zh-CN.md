[English](Material_API.md) | [简体中文](Material_API.zh-CN.md)

<a id="the-material-api"></a>

材料API
----------------

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

Unreal 有 3“种”材质：

* 材质 - 这是以下两种类型的基础，这是您定义材质节点和属性的地方，必须对其进行编译以生成所需的着色器。

* 材质实例 - 当您想要修改材质的参数时，您不需要创建全新的材质，但可以创建它的“实例”。该实例共享父材质的逻辑，但更改特定属性（如纹理）。

* 动态材质实例 - 有时您可能希望在运行时更改材质实例的属性，在这种情况下，您需要生成一个特殊的材质实例，在游戏运行时映射到特定对象。

<a id="assigning-a-material-to-a-primitive-component"></a>

将材质分配给原始组件
---------------------------------------------

一旦您的材质（实例化或非实例化、常量或动态）准备就绪，您需要将其分配给 PrimitiveComponent：


```python
component = self.uobject.get_actor_component('Mesh')
material = ue.load_object(Material, '/Game/Materials/Iron')
component.set_material(index, material);
```

<a id="creating-a-material-editor-only"></a>

创建材质（仅限编辑器）
---------------------------------

这是创建材质的“原始”方式

```python
from unreal_engine.classes import Material
new_material = Material()
new_material.set_name('New Funny Material')
new_material.save_package('/Game/Materials/NewFunnyMaterial')
```

更好的是，您可以使用 MaterialFactoryNew 类

```python
from unreal_engine.classes import MaterialFactoryNew
import unreal_engine as ue

factory = MaterialFactoryNew()
new_material = factory.factory_create_new('/Game/Materials/NewFunnyMaterial')

# destroy the asset
ue.delete_asset(new_material.get_path_name())
```

<a id="creating-a-material-instance-editor-only"></a>

创建材质实例（仅限编辑器）
------------------------------------------

您有两种方法来创建实例材质：

（new_material 是对之前的created/loaded 材料的引用）

```python
from unreal_engine.classes import MaterialInstanceConstant

material_instance = MaterialInstanceConstant()
material_instance.set_name('New Funny Material Instance')
material_instance.set_material_parent(new_material)
material_instance.save_package('/Game/Materials/instanced')
```

或快捷方式：

```python
import unreal_engine as ue
# the material instance will get the name of the parent with the _inst suffix
material_instance = ue.create_material_instance(new_material)
```

```python
import unreal_engine as ue
# you can also specify a path and a name to the new material instance.
material_instance = ue.create_material_instance(new_material, '/Game/Materials/', 'New Funny Material Instance')
```


或者工厂方式：

```python
from unreal_engine.classes import Material, MaterialInstanceConstantFactoryNew

factory = MaterialInstanceConstantFactoryNew()

# get a reference to a parent material
parent_material = ue.load_object(Material, '/Game/MainMaterial')

factory.InitialParent = parent_material

child_material = factory.factory_create_new('/Game/ChildMaterial')
```

<a id="creating-a-material-instance-dynamic"></a>

创建动态材质实例
------------------------------------

您可以从材质（或材质实例）创建 MID（动态材质实例）：

```python
mid = self.uobject.create_material_instance_dynamic(material_instance)
```


<a id="listing-getting-and-changing-available-material-properties"></a>

列出、获取和更改可用材料属性
-----------------------------------------------------------

要修改材质的属性，您需要知道其名称。

您无法从材质实例访问属性列表，您需要从父级获取它：

```python
parent_material = material_instance.Parent

for expression in parent_material.Expressions:
    parameter_name = expression.ParameterName
    parameter_group = expression.Group
```


一旦你有了属性名称，你就可以get/set参数值

```py
# retuns a float
material_instance.get_material_scalar_parameter('Parameter name')
# returns a FVector
material_instance.get_material_vector_parameter('Parameter name')
# returns a Texture
material_instance.get_material_texture_parameter('Parameter name')

material_instance.set_material_scalar_parameter('Parameter name', float)
material_instance.set_material_vector_parameter('Parameter name', FVector)
material_instance.set_material_texture_parameter('Parameter name', Texture)
```
