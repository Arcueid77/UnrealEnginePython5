[English](Landscape_API.md) | [简体中文](Landscape_API.zh-CN.md)

<a id="the-landscapeterrain-api"></a>

# Landscape/Terrain API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

UE4 中的地形是基于“高度图”概念构建的特殊角色。

每个地形都是一个组件网格 (ULandscapeComponent)。每个组件都映射到保存高度数据的纹理。

景观组件概念非常重要，因为它影响结果的性能和质量。组件是地形的最小渲染单元（因此它是可以从渲染和碰撞角度剔除的最小几何体）。

关于景观组件的简要说明可以在这里找到：https://docs.unrealengine.com/latest/INT/Engine/Landscape/TechnicalGuide/#componentsections

要构建新地形（或UE4中的景观），您需要获取高度图。根据此高度图，UE4 api 将生成映射到组件的纹理。

高度图是无符号 16 位值的简单数组（0 到 65535，其中 32768 值被视为“海平面”）。

在 Python 中（出于性能原因，并简化与 numpy 的集成）高度图表示为字节数组（因此您最终需要重新转换它们）。

<a id="creating-a-new-landscape"></a>

# 创造新景观

我们首先创建一个具有随机值的高度图：

```python
import unreal_engine as ue
import struct
import random

width = 1024
height = 1024
heightmap = []

# fill the heightmap with random values
for y in range(0, height):
    for x in range(0, width):
        heightmap.append(random.randint(0, 65535))

data = struct.pack('{0}H'.format(width * height), *heightmap)
```

现在“数据”是我们可以用于景观 api 的东西

在填充景观之前，我们需要生成它：

```python
from unreal_engine.classes import Landscape

new_landscape = ue.get_editor_world().actor_spawn(Landscape)
```

注意：不要运行前面的脚本，因为编辑器不喜欢未初始化的地形。 （阅读：它将残酷地崩溃）

现在是时候用我们之前创建的高度图数据填充地形了。我们需要选择需要多少个组件（网格分辨率）以及每个组件需要多少个四边形（每个组件几何体由简单的四边形基元形成）。

一旦我们知道地形有多大，我们就可以使用特殊的 UE4 api 函数相应地expand/adapt高度图：

```
unreal_engine.heightmap_expand(data, original_width, original_height, terrain_width, terrain_height)
```

该函数将生成一个具有景观最佳尺寸的新高度图。


```python
import unreal_engine as ue
import struct
import random
from unreal_engine.classes import Landscape

width = 1024
height = 1024
heightmap = []

for y in range(0, height):
    for x in range(0, width):
        heightmap.append(random.randint(0, 65535))

data = struct.pack('{0}H'.format(width * height), *heightmap)

quads_per_section = 63
number_of_sections = 1
components_x = 8
components_y = 8

fixed_data = ue.heightmap_expand(data, width, height, quads_per_section * number_of_sections * components_x + 1, quads_per_section * number_of_sections * components_y + 1)

landscape = ue.get_editor_world().actor_spawn(Landscape)
landscape.landscape_import(quads_per_section, number_of_sections, components_x, components_y, fixed_data)
landscape.set_actor_scale(1,1,1)
```

您应该已经注意到，我们没有指定每个组件的四边形，而是使用“部分”概念。

事实上，UE4 允许另一个级别的细分，以便更好地控制优化（LOD、mipmapping...）。更多详细信息请参见此处：

https://docs.unrealengine.com/latest/INT/Engine/Landscape/TechnicalGuide/#componentsections

您可以有 1 部分（1x1 四边形）或 2（2x2 四边形）。不支持其他值。

即使四边形的数量也与纹理大小有关，因此有效值为：7x7、15x15、31x31、63x63、127x127、255x255（请注意相差一的奇怪之处，因为所有地形工具都使用最大值而不是大小）

请注意，您需要仔细选择地形的大小以及高度图：

https://docs.unrealengine.com/latest/INT/Engine/Landscape/TechnicalGuide/index.html#calculatingheightmapdimensions


<a id="gettingcreating-ulandscapeinfo"></a>

## Getting/Creating ULandscapeInfo

有关Landscape/Terrain的信息存储在一个名为ULandscapeInfo的特殊uobject中。

要检索它（或者如果您进行奇怪的操作，最终创建一个新的），您有以下两个函数：

```python
landscape_info = landscape.get_landscape_info()

# create a new ULandscapeInfo, required if you do not import an heightmap in a manually spawned landscape
landscape_info = landscape.create_landscape_info()
```

<a id="retrieving-ulandscapecomponents-textures"></a>

## 检索ULandscapeComponent的纹理

如果您想访问地形的高度值，您需要从每个组件中检索它们：

```python
import unreal_engine as ue

for component in landscape.LandscapeComponents:
    heightmap_texture = component.HeightmapTexture
    print('{0}x{1} -> {2}'.format(heightmap_texture.texture_get_width(), heightmap_texture.texture_get_height(), len(heightmap_texture.texture_get_source_data())))
```

这将打印每个景观组件的纹理宽度、高度和数据大小。

<a id="exporting-the-terrain-to-a-frawmesh"></a>

## 将地形导出到FRawMesh

FRawMesh是代表网格的特殊结构。您可以使用它在UE4中生成新的StaticMesh。

更多信息可以在这里检索：

https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes.md

您可以使用以下函数从景观中生成新的FRawMesh：


```python
# lod is optional, by default it is 0
raw_mesh = landscape.landscape_export_to_raw_mesh([lod])
```

请记住，地形通常很大:)

<a id="the-heightmap-api"></a>

## 高度图 API

公开高度图高级 API 以简化高度图操作

```python
# expand the heightmap to fit the new size
expanded_data = ue.heightmap_expand(data, data_width, data_height, new_width, new_height)
```

```python
# import a heightmap file (r16 or grayscale 16bit png) and returns a bytearray
data = ue.heightmap_import(filename[,width, height])
```

如果未指定宽度和高度，系统将尝试从文件中检索它们
