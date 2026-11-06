[English](ManagingAssets.md) | [简体中文](ManagingAssets.zh-CN.md)

<a id="managing-your-assets-with-python"></a>

使用Python管理您的资产
=

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

<a id="naming-conventions"></a>

命名约定
-

在开始之前，您应该熟悉有关资产的不真实的命名约定：

* UObject，是绝大多数 Unreal C++ 类的根。材质、纹理、蓝图，全部继承自UObject
* 资产是一个以某种形式序列化的UObject。您可以在内容浏览器中看到资产
* 包是包含一个或多个资源的文件。受祝福的虚幻模式是每个包拥有一个资产，但您可以在一个包中拥有多个资产。包存储在 Content 目录中的 .uasset 文件中。


<a id="referencing-assets"></a>

参考资产
-

对于 load/reference 资产，您需要使用特殊的命名约定：

```
PackagePath.AssetName
```

例如，封装在“/Game/Materials/Mat001”中的名为“FooBar”的材质可以引用为：

```
/Game/Materials/Mat001.Foobar
```

（这意味着Mat001.uasset将在项目文件系统的/Content/Materials目录中可用）


要从 python 获取对资源的引用，您可以使用：

```python
import unreal_engine as ue
# get the Mat001.Foobar asset
material = ue.get_asset('/Game/Materials/Mat001.Foobar')
# print material repr
ue.log(material)
# print material properties
ue.log(material.properties())
```

要获取特定路径下的所有资产的列表：

```python
materials = ue.get_assets('/Game/Materials')
```

默认情况下，调用不会是递归的（读：它不会扫描子目录），要启用递归模式，只需传递 True 作为第二个参数：

```python
materials = ue.get_assets('/Game/Materials', True)
```

您可以获得继承指定类的所有资产的列表（作为字符串传递！）。如get_assets()，第二个参数指定递归。

```python
# get all assets of the class Material
materials = ue.get_assets_by_class('Material')
```

<a id="movingrenaming-assets"></a>

Moving/Renaming资产
-

rename_asset() 函数允许您更改资产的名称：

```python
ue.rename_asset('/Game/Materials/Mat001.Foobar', 'FooBarUpdated')
```

这将产生/Game/Materials/FooBarUpdated.FooBarUpdated资产。请注意，由于虚幻编辑器保留了所谓的“重定向器对象”，它基本上是对原始对象的引用，因此在重新加载编辑器之前，您将无法重新使用旧名称。

如果您指定完整路径作为目的地，则可以“移动”资产：

```python
ue.rename_asset('/Game/Materials/Mat001.Foobar', '/Game/Ops/FooBarUpdated')
```

将产生/Game/Ops/FooBarUpdated.FooBarUpdated资产

<a id="duplicating-assets"></a>

重复资产
-

类似于重命名：

```python
ue.duplicate_asset('/Game/Materials/Mat001.Foobar', '/Game/NewMaterials/Mat001', 'FooBarUpdated')
```

这将导致/Game/NewMaterials/Mat001.FooBarUpdated成为原始资产的副本而不破坏它

<a id="deleting-assets"></a>

删除资产
-

```python
ue.delete_asset('/Game/NewMaterials/Mat001.FooBarUpdated')
```

将删除/Game/NewMaterials/Mat001.FooBarUpdated资产


<a id="importing-assets"></a>

导入资产
-

这可能是任务自动化最重要的功能。它允许您将外部资源（如纹理、网格、动画...）导入到编辑器中。

要导入资产文件夹中的文件：

```python
asset = ue.import_asset('/Users/FooBar/Desktop/texture001.png', '/Game/Textures')
```

这将在/Game/Textures文件夹中生成texture001资源

您甚至可以在一轮中导入多个资产：

```python
files_to_import = ['/Users/FooBar/Desktop/texture001.png', '/Users/FooBar/Desktop/texture002.png', '/Users/FooBar/Desktop/texture001.png', '/Users/FooBar/Desktop/texture003,png']
assets = ue.import_asset(files_to_import,  '/Game/Textures')
```

前面的函数触发UFactory的自动发现（工厂描述如何加载文件，每种支持的文件格式都有工厂）。如果自动发现正确的工厂失败，您可以指定它

```python
from unreal_engine.classes import TextureFactory, FbxFactory
asset001 = ue.import_asset('/Users/FooBar/Desktop/texture001.png', '/Game/Textures', TextureFactory)
asset002 = ue.import_asset('/Users/FooBar/Desktop/warrior001.fbx', '/Game/Meshes', FbxFactory)
```

请注意，FbxFactory是fbx的默认导入器，但它会触发一个对话框。对于自动化任务，将包括更好的工厂PyFbxFactory

```python
from unreal_engine.classes import PyFbxFactory
asset002 = ue.import_asset('/Users/FooBar/Desktop/warrior001.fbx', '/Game/Meshes', PyFbxFactory)
```

如果工厂支持选项，则可以在使用前实例化工厂：

```python
from unreal_engine.classes import PyFbxFactory

factory = PyFbxFactory()
factory.ImportUI.bImportAsSkeletal = True

asset002 = factory.factory_import_object('/Users/FooBar/Desktop/warrior001.fbx', '/Game/Meshes')
```

<a id="reimporting-assets"></a>

重新导入资产
-

有些资源可能需要重新导入（例如，当您有新的纹理图像或 fbx 时）。在这种情况下你可以这样做：

```python
asset002.asset_reimport()
```

在重新导入之前，您可以检查资产是否支持：

```python
if asset002.asset_can_reimport():
   asset002.asset_reimport()
```

asset_reimport()的签名如下：

```python
success = asset_reimport(open_file_dialog, report_dialog, filename_to_import)
```

如果对象没有映射到它的文件，open_file_dialog将触发一个打开文件小部件来选择要导入的文件。

report_dialog 将显示报告操作状态的通知小部件

filename_to_import 允许您指定为资产导入哪个文件

该函数返回一个布尔值

您可以通过以下方式以编程方式更改分配给资产的文件名：

```python
mesh.asset_import_data_set_sources('D:/sword.fbx')
```


<a id="creating-assets"></a>

创建资产
-

您可以手动或通过工厂创建新资产（如果需要）：

```python
from unreal_engine.classes import ParticleSystem, Material

particle_system = ParticleSystem()
particle_system.set_name('ParticleSystemForDummies')

# special form of the constructor taking the object name
material = Material('FunnyMaterial')

# this will save particle_system into /Game/Particles.ParticleSystemForDummies
particle_system.save_package('/Game/Particles')

# this will save material into /Game/FunnyMaterials.FunnyMaterial
material.save_package('/Game/FunnyMaterials')
```

前一种方法是幸运的，其中每个资产都存储在不同的包中。

如果您想在同一个包中存储多个资源，您只需在 save_package 中传递相同的名称即可

```python
# this will save particle_system into /Game/Funny.ParticleSystemForDummies
particle_system.save_package('/Game/Funny')

# this will save material into /Game/Funny.FunnyMaterial
material.save_package('/Game/Funny')
```

请考虑到，如果您对瞬态对象（读取：标记为不可存储到磁盘的对象）调用save_package()，则对象标志将被覆盖以包含RF_Public|RF_Standalone，而RF_Transient将被删除

使用工厂可以创建空资产：

```python
from unreal_engine.classes import AnimBlueprintFactory

# get a reference to a skeleton asset (required for anim blueprint)
skeleton = ue.get_asset('/Game/Skeleton.Skeleton001')
anim_blueprint_factory = AnimBlueprintFactory()

anim_blueprint_factory.TargetSkeleton = skeleton

# create the asset
anim_blueprint = anim_blueprint_factory.factory_create_new('/Game/anim001')
```

<a id="asset-dependenciesreferencers"></a>

资产dependencies/referencers
-

每个资产都有一个引用它的其他资产（引用者）和它所依赖的资产（依赖项）的列表。

您可以通过以下方式访问这些列表：

```python
list_of_referencers = ue.get_asset_referencers('/Game/FooBar')
list_of_dependencies = ue.get_asset_dependencies('/Game/FooBar')
```
