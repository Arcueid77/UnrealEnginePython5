[English](WritingAColladaFactoryWithPython.md) | [简体中文](WritingAColladaFactoryWithPython.zh-CN.md)

<a id="writing-a-collada-staticmesh-importerfactory-with-python"></a>

# 使用 Python 编写 Collada StaticMesh importer/factory

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

在本教程中，我们将了解如何使用 Unreal Engine 4 Python 插件中提供的高级子类化 api，以及如何构建 Slate GUI

本教程已使用 Unreal Engine 4.16 和 Python 3.6 进行了测试，并假设您已经熟悉将插件安装到引擎中并编辑 Python 脚本。

如果这是您第一次体验 Unreal Engine Python 插件，此链接是一个很好的起点：https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython.md#installing-the-python-plugin


目标是通过构建新工厂来指示编辑器将 .dae (collada) 文件导入为静态网格物体。工厂是Unreal Engine4中的一个特殊类，允许创建和导入资产。有 fbx、wav、图像和 UE4 支持的所有媒体文件的工厂。

通常，您可以通过在 C++ 中子类化 UFactory 类来创建新工厂，但在本教程中，我们将了解如何在纯 Python 中子类化 UE4 C++ 类。



<a id="subclassing-ufactory-pyfactory"></a>

## 子类化UFactory：PyFactory

子类化 API 允许开发人员对任何 UClass 进行子类化（暴露给 UE4 反射系统的类）。不幸的是，UFactory类没有向反射系统公开其方法，因此Python插件公开了一个名为“UPyFactory”的方便类（它是UFactory的简单子类）：

```python
from unreal_engine.classes import PyFactory

import unreal_engine as ue

class ColladaFactory(PyFactory):

    def __init__(self):
        ue.log_error('Hello World, i am a useless factory')
```

将文件作为 collada_factory.py 保存到 /Content/Scripts 目录中，并从 Unreal Engine Python 控制台运行它：

![类原型](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/class_prototype.png)

请注意，每当您重新运行脚本时，内部 Unreal Engine 反射系统都会更新，因此在更改脚本代码时无需重新启动编辑器（或启动缓慢编译）：

![多次运行](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/multiple_runs.png)

从屏幕截图中可以看到，UClass及其对应的Python UObject的地址保持不变，而`__init__`调用已更新。请记住，每当您从 python 创建新的 UClass 时，`__init__` 方法都会由 ClassDefaultObject 自动调用（此信息仅在您了解虚幻引擎内部结构时才有用，否则您可以简单地忽略它。）。

请记住：只有以大写字母开头的函数才会暴露给 unreal，其他函数只能在 python 中使用。

<a id="parse-dae-files-with-pycollada"></a>

## 使用 pycollada 解析 .dae 文件

collada 格式基于 XML，因此我们可以轻松地从 python 中解析它，但我们可以使用令人惊叹的 pycollada 模块（https://github.com/pycollada/pycollada），而不是手动完成艰苦的工作。只需 pip 安装它并更新您的类即可导入和使用它：

```python
from unreal_engine.classes import PyFactory, StaticMesh, Object, Class

import unreal_engine as ue

from collada import Collada

class ColladaFactory(PyFactory):

    def __init__(self):
        # inform the editor that this class is able to import assets
        self.bEditorImport = True
        # register the .dae extension as supported
        self.Formats = ['dae;Collada']
        # set the UClass this UFactory will generate
        self.SupportedClass = StaticMesh

    def PyFactoryCreateFile(self, uclass: Class, parent: Object, name: str, filename: str) -> Object:
        # load the collada file
        dae = Collada(filename)
        ue.log_warning(dae)
        # create a new UStaticMesh with the specified name and parent
        static_mesh = StaticMesh(name, parent)
        return static_mesh
```

运行这个新脚本将显示ColladaFactory有一个新方法：


![添加了 pycollada](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/added_pycollada.png)


PyFactoryCreateFile，是由UPyFactory公开的虚拟C++方法，我们通过python覆盖它。请注意，我们需要使用 python3 注释来通知虚幻引擎（显然是强类型的）函数的类型。每当我们尝试使用 ColladaFactory 导入文件时，编辑器都会调用 PyFactoryCreateFile

现在从此处下载示例 .dae 文件：

https://github.com/20tab/UnrealEnginePython/raw/master/tutorials/WritingAColladaFactoryWithPython_Assets/duck_triangles.dae

（这是一只简单的鸭子）

重新运行 collada_factory.py 脚本后，您将能够在 Countent 浏览器中单击“导入”，现在“dae”扩展将显示在受支持的扩展列表中。选择duck文件，只需查看python控制台：

![首次导入](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/first_import.png)

显然我们还没有添加数据到我们的StaticMesh，所以在我们的内容浏览器中会出现一个空的静态网格物体：

![空网格](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/empty_mesh.png)

<a id="building-the-new-mesh"></a>

## 构建新的网格

以下部分有点复杂，需要对UE4内部结构有深入的了解。

只需阅读代码注释，我们现在需要提取dae文件中的数据（顶点、uv和法线）并为StaticMesh构建LOD（细节级别）（一个StaticMesh可以有多个LOD，每个都是不同的网格）。

在本例中，我们使用单个 LOD (LOD0)。注意FixMeshData()中的数据操作（使用numpy）。 collada 格式对于 UE4 有不同的约定。我们垂直翻转 UVs 并交换轴以使 Z 位于顶部（而不是 y）

```python
from unreal_engine.classes import PyFactory, StaticMesh, Object, Class

import unreal_engine as ue

from collada import Collada

from unreal_engine.structs import StaticMeshSourceModel, MeshBuildSettings
from unreal_engine import FRawMesh
import numpy

class ColladaFactory(PyFactory):

    def __init__(self):
        # inform the editor that this class is able to import assets
        self.bEditorImport = True
        # register the .dae extension as supported
        self.Formats = ['dae;Collada']
        # set the UClass this UFactory will generate
        self.SupportedClass = StaticMesh
    
    # this functions starts with an uppercase letter, so it will be visible to the UE system
    # not required obviously, but it will be a good example
    def FixMeshData(self):
        # move from collada system (y on top) to ue4 one (z on top, forward decreases over viewer)
        for i in range(0, len(self.vertices), 3):
           xv, yv, zv = self.vertices[i], self.vertices[i+1], self.vertices[i+2]
           # invert forward
           self.vertices[i] = zv * -1
           self.vertices[i+1] = xv
           self.vertices[i+2] = yv
           xn, yn, zn = self.normals[i], self.normals[i+1], self.normals[i+2]
           # invert forward
           self.normals[i] = zn * -1
           self.normals[i+1] = xn
           self.normals[i+2] = yn
        
        # fix uvs from 0 on bottom to 0 on top
        for i, uv in enumerate(uvs):
            if i % 2 != 0:
                uvs[i] = 1 - uv

    def PyFactoryCreateFile(self, uclass: Class, parent: Object, name: str, filename: str) -> Object:
        # load the collada file
        dae = Collada(filename)
        ue.log_warning(dae)
        # create a new UStaticMesh with the specified name and parent
        static_mesh = StaticMesh(name, parent)

        # prepare a new model with the specified build settings
        source_model = StaticMeshSourceModel(BuildSettings=MeshBuildSettings(bRecomputeNormals=False, bRecomputeTangents=True, bUseMikkTSpace=True, bBuildAdjacencyBuffer=True, bRemoveDegenerates=True))

        # extract vertices, uvs and normals from the da file (numpy.ravel will flatten the arrays to simple array of floats)
        triset = dae.geometries[0].primitives[0]
        self.vertices = numpy.ravel(triset.vertex[triset.vertex_index])
        # take the first uv channel (there could be multiple channels, like the one for lightmapping)
        self.uvs = numpy.ravel(triset.texcoordset[0][triset.texcoord_indexset[0]])
        self.normals = numpy.ravel(triset.normal[triset.normal_index])

        # fix mesh data
        self.FixMeshData()
        
        # create a new mesh, FRawMesh is an optimized wrapper exposed by the python plugin. read: no reflection involved
        mesh = FRawMesh()
        # assign vertices
        mesh.set_vertex_positions(self.vertices)
        # uvs are required
        mesh.set_wedge_tex_coords(self.uvs)
        # normals are optionals
        mesh.set_wedge_tangent_z(self.normals)
        
        # assign indices (not optimized, just return the list of triangles * 3...)
        mesh.set_wedge_indices(numpy.arange(0, len(triset) * 3))

        # assign the FRawMesh to the LOD0 (the model we created before)
        mesh.save_to_static_mesh_source_model(source_model)

        # assign LOD0 to the SataticMesh and build it
        static_mesh.SourceModels = [source_model]
        static_mesh.static_mesh_build()
        static_mesh.static_mesh_create_body_setup()

        return static_mesh
```

重新运行脚本并再次导入相同的文件（通过在内容浏览器中单击“导入”），如果一切顺利，您将以鸭子网格结束：

![鸭子](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/the_duck.png)

尝试使用代码中的 MeshBuildSettings 值（特别注意文件中的法线与自动生成的法线之间的差异。）

<a id="a-more-complex-model-mixamos-vampire"></a>

## 更复杂的模型：Mixamo's Vampire

下载此文件：https://github.com/20tab/UnrealEnginePython/raw/master/tutorials/WritingAColladaFactoryWithPython_Assets/vampire.dae

这是mixamo.com中的吸血鬼。

从技术上讲，它是一个带有动画的骨架网格物体（我们将在以后的教程中尝试导入它），如果我们尝试导入它，我们将以死去的吸血鬼结束：P

![破碎的吸血鬼](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/broken_vampire.png)

是时候使用一些向量数学来修复网格旋转了：

```python
...

from unreal_engine import FVector, FRotator
...
def FixMeshData(self):
        # move from collada system (y on top) to ue4 one (z on top, forward decreases over viewer)
        for i in range(0, len(self.vertices), 3):
           xv, yv, zv = self.vertices[i], self.vertices[i+1], self.vertices[i+2]
           # invert forward
           vec = FVector(zv * -1, xv, yv) * FRotator(0, -90, 180)
           self.vertices[i] = vec.x
           self.vertices[i+1] = vec.y
           self.vertices[i+2] = vec.z
           xn, yn, zn = self.normals[i], self.normals[i+1], self.normals[i+2]
           nor = FVector(zn * -1, xn, yn) * FRotator(0, -90, 180)
           # invert forward
           self.normals[i] = nor.x
           self.normals[i+1] = nor.y
           self.normals[i+2] = nor.z
        
        # fix uvs from 0 on bottom to 0 on top
        for i, uv in enumerate(self.uvs):
            if i % 2 != 0:
                self.uvs[i] = 1 - uv
```

重新运行并重新导入吸血鬼，它现在应该正确旋转。

显然，如果我们用当前代码重新导入鸭子，它的旋转将会是错误的。因此，是时候为工厂添加配置器 GUI 了。

<a id="adding-a-gui-to-the-importer-the-slate-api"></a>

## 将 GUI 添加到导入器： Slate API

Slate是Unreal Engine的GUI技术。它基于大量预处理器宏，以简化构建图形界面的开发人员的可读性。它的蟒蛇包装试图通过适应蟒蛇风格来模仿这种精神。注意：slate python api 包装器开发完全由 Kite & Lightning (http://kiteandlightning.la/) 赞助。非常感谢他们。

Python Slate 界面如下所示：

```python
from unreal_engine import SWindow, SVerticalBox, SHorizontalBox, SButton, STextBlock, SBorder, FLinearColor
from unreal_engine.enums import EHorizontalAlignment, EVerticalAlignment

import unreal_engine as ue

SWindow(title='Hello I am Slate', client_size=(1024, 512))(
    SVerticalBox()
    (
        STextBlock(text='I am the first top vertical item, without alignment'),
    )
    (
        SBorder(color_and_opacity=FLinearColor(1, 0, 0, 1))
        (
            STextBlock(text='I am the second top vertical item with center/bottom alignment'),      
        ),
        h_align = EHorizontalAlignment.HAlign_Center,
        v_align = EVerticalAlignment.VAlign_Bottom
    )
    (
        SHorizontalBox()
        (
            SButton(text='Button Left', on_clicked=lambda: ue.log('Hello from left'), h_align=EHorizontalAlignment.HAlign_Center)
        )
        (
            SButton(text='Button Right', on_clicked=lambda: ue.log('Hello from right'), v_align=EVerticalAlignment.VAlign_Center)
        ),
        fill_height=0.2
    )
)
```

请随意运行前面的代码以获得类似的内容（单击按钮，它们将写入控制台！）：

![Slate演示](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/slate_demo.png)

请注意 SWindow() 行末尾的左括号。重要的是第一个开头位于同一行，以通知 python 解析器指令尚未结束。 （仅首次开通时需要）

现在我们要在解析 dae 文件后创建一个模态窗口，以要求用户确认导入并指定要应用于网格的旋转：

```python

...

from unreal_engine import SWindow, SVerticalBox, SHorizontalBox, SButton, SRotatorInputBox
from unreal_engine.enums import EHorizontalAlignment

...
def PyFactoryCreateFile(self, uclass: Class, parent: Object, name: str, filename: str) -> Object:

    ...

    def open_collada_wizard(self):

        def cancel_import():
            self.wizard.request_destroy()

        def confirm_import():
            self.do_import = True
            self.wizard.request_destroy()

        def update_roll(roll):
            self.force_rotation.roll=roll

        def update_pitch(pitch):
            self.force_rotation.pitch=pitch

        def update_yaw(yaw):
            self.force_rotation.yaw=yaw

        self.wizard = SWindow(title='Collada Import Options', modal=True, sizing_rule=1)(
                          SVerticalBox()
                          (
                              SRotatorInputBox(roll=lambda:self.force_rotation.roll,
                                               pitch=lambda:self.force_rotation.pitch,
                                               yaw=lambda:self.force_rotation.yaw,
                                               on_roll_changed=update_roll,
                                               on_pitch_changed=update_pitch,
                                               on_yaw_changed=update_yaw,
                                               ),
                              auto_height=True,
                              padding = 10
                          )
                          (
                              SHorizontalBox()
                              (
                                  SButton(text='Cancel', on_clicked=cancel_import, h_align = EHorizontalAlignment.HAlign_Center)
                              )
                              (
                                  SButton(text='Import', on_clicked=confirm_import, h_align = EHorizontalAlignment.HAlign_Center)
                              ),
                              auto_height=True,
                              padding = 4,
                          ),
                          
                      )
        self.wizard.add_modal()

```

将方法添加到ColladaFactory并修改PyFactoryCreateFile函数，如下所示：

```python
def PyFactoryCreateFile(self, uclass: Class, parent: Object, name: str, filename: str) -> Object:
        # load the collada file
        dae = Collada(filename)
        ue.log_warning(dae)

        self.do_import = False
        self.force_rotation = FRotator()
        self.open_collada_wizard()

        # if the user click on 'Cancel', return !
        if not self.do_import:
            return None
        ....
```

重新运行导入将导致此向导：

![导入选项](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/import_options.png)

请记住更改 FixMeshData 函数以遵循 self.force_rotation 值：

```python
# this functions starts with an uppercase letter, so it will be visible to the UE system
    # not required obviously, but it will be a good example
    def FixMeshData(self):
        # move from collada system (y on top) to ue4 one (z on top, forward decreases over viewer)
        for i in range(0, len(self.vertices), 3):
           xv, yv, zv = self.vertices[i], self.vertices[i+1], self.vertices[i+2]
           # invert forward
           vec = FVector(zv * -1, xv, yv) * self.force_rotation
           self.vertices[i] = vec.x
           self.vertices[i+1] = vec.y
           self.vertices[i+2] = vec.z
           xn, yn, zn = self.normals[i], self.normals[i+1], self.normals[i+2]
           nor = FVector(zn * -1, xn, yn) * self.force_rotation
           # invert forward
           self.normals[i] = nor.x
           self.normals[i+1] = nor.y
           self.normals[i+2] = nor.z
        
        # fix uvs from 0 on bottom to 0 on top
        for i, uv in enumerate(self.uvs):
            if i % 2 != 0:
                self.uvs[i] = 1 - uv
```

<a id="persistent-importer-options-more-subclassing"></a>

## 持久导入器选项：更多子类化

一切都应该可以正常工作，但是如果在导入之间记住我们在导入器向导中设置的选项，那就更酷了。

显然，我们可以创建一个 python 类来存储值并将其实例映射到ColladaFactory，但是有一种更好的方法可以让我们自动生成板岩小部件（无需描述界面的每个部分）。

请记住，您可以继承每个UClass，甚至UObject！

```python
from unreal_engine.classes import Material, Object
from unreal_engine.struct import Rotator

class ColladaImportOptions(Object):

    # this is exposed as a UProperty
    DefaultRotation = Rotator
    # this is exposed as a UProperty
    DefaultMaterial = Material
    
...

class ColladaFactory(PyFactory):

    ImportOptions = ColladaImportOptions()
    
    ...

```

现在，每次生成 ColladaFactory 时，它都会保存对 ColladaImportOptions() 实例的引用。这样，我们输入的值将在运行之间被记住。

请注意，我们已经设置了分配给网格的默认材质。

新的 open_collada_wizard 函数现在非常简单，因为小部件将由 `ue.create_detail_view(obj)` 函数自动生成：

```python
def open_collada_wizard(self):

        def cancel_import():
            self.wizard.request_destroy()

        def confirm_import():
            self.do_import = True
            self.wizard.request_destroy()

        self.wizard = SWindow(title='Collada Import Options', modal=True, sizing_rule=1)(
                          SVerticalBox()
                          (
                              ue.create_detail_view(self.ImportOptions),
                              auto_height=True,
                              padding = 10
                          )
                          (
                              SHorizontalBox()
                              (
                                  SButton(text='Cancel', on_clicked=cancel_import, h_align = EHorizontalAlignment.HAlign_Center)
                              )
                              (
                                  SButton(text='Import', on_clicked=confirm_import, h_align = EHorizontalAlignment.HAlign_Center)
                              ),
                              auto_height=True,
                              padding = 4,
                          ),
                          
                      )
        self.wizard.add_modal()
```

要将材质分配给网格，只需在返回 static_mesh 之前添加此调用：

```python
static_mesh.StaticMaterials = [StaticMaterial(MaterialInterface=self.ImportOptions.DefaultMaterial, MaterialSlotName='Main')]
```

您可以在此处下载完整更新的脚本：

https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython_Assets/collada_factory.py

<a id="automatically-add-the-colladafactory-on-editor-startup"></a>

## 在编辑器启动时自动添加 ColladaFactory

当您对新类感到满意时，您可能希望在 editor/engine 启动时自动加载它。

请记住，/Content/Scripts/ue_site.py 脚本会在启动时自动导入（如果找到），因此只需创建一个空脚本并插入：

```python
import collada_factory
```


<a id="improvements-and-final-notes"></a>

## 改进和最终说明

这只是对子类化和板岩API的简要介绍。两者仍处于开发阶段，因此期待更多改进和捷径。

一个伟大的（未来）添加将是加载骨架网格物体和动画......更多内容即将推出
