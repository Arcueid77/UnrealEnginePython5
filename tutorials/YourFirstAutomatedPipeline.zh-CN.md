[English](YourFirstAutomatedPipeline.md) | [简体中文](YourFirstAutomatedPipeline.zh-CN.md)

<a id="your-first-automated-pipeline-with-unrealenginepython-part-1"></a>

您的第一个自动化管道UnrealEnginePython（部分1）
=

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

在本教程中，我将尝试向您展示如何构建一个 python 脚本，该脚本可以生成新的 Unreal Engine 4 Blueprint 实现 Kaiju（日本大型怪物）及其材质和动画。在第二部分中，基于行为树的简单 AI 将添加到 Blueprint 以及一堆简单的单元测试。

从 Unreal Engine Python 控制台运行脚本将生成本机 Blueprint（以及网格、动画、黑板和行为树图），不需要 python 插件即可工作。

从技术上讲，我展示的是插件的“编辑器脚本”功能，而不是其“游戏脚本”模式。

如果这是您第一次使用 UnrealEnginePython 插件，您应该考虑以下注意事项：

* 当您在Python代码中看到CamelCase（对于属性和函数调用）时，这意味着正在使用UE4反射系统。尽管变量和函数的CamelCase不是“Pythonic”，但您应该将其视为跳入UE4反射系统的“信号”。

* 在本教程中，我使用嵌入式 python 编辑器。它非常原始，如果您愿意，您可以使用您最喜欢的编辑器（Vim、Sublime、Emacs...）。任何可以编辑Python文件的东西都很好。

* Python脚本存储在项目的“/Game/Scripts”文件夹中

* Python代码非常冗长，并且不断重复以显示尽可能多的API功能，如果您打算为自己的管道构建一些东西，我强烈建议您使用reorganize/refactor它

* 它已经使用编辑器版本4.15和python3.6进行了测试

<a id="installing-unrealenginepython"></a>

安装UnrealEnginePython
-

显然第一步是安装UnrealEnginePyton插件。

只需为您运行的system/ue4版本组合获取一个二进制版本，并将其解压到项目的Plugins目录中（如果不存在则创建它）。

您可以从这里下载二进制版本：

https://github.com/20tab/UnrealEnginePython/releases

强烈建议您使用嵌入式Python，这样您就不需要在系统中安装Python。您可以从 Blueprint 或 C++ 项目开始，两者都可以。

将 zip 文件解压到 Plugins 目录后，您就可以运行您的项目

通过打开 Edit/Plugins 菜单确保插件已启用：

![检查插件](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/check_plugin.png)

勾选“启用”复选框并确认编辑器重新启动。

如果一切顺利，您将在“窗口”菜单下看到一个新选项，称为“Python控制台”：

![窗口菜单截图](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/screenshot_window_menu.png)

运行它，并确保您的 python 环境正常工作：

![Python控制台](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/python_console.png)

在“窗口”菜单中，您将找到另一个工具（可选），即Python编辑器。这是一个非常简单的编辑器，用于管理您的项目脚本。显然，您可以随意使用您最喜欢的编辑器。

![Python编辑](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/python_editor.png)

<a id="initializing-the-environment"></a>

初始化环境
-

创建一个新的Python脚本（只需在Python编辑器中单击`New`，或者在您喜欢的编辑器中的`Scripts`项目目录下创建一个新文件），将其命名为kaiju_slicer_pipeline.py，并包含以下内容

```python
import unreal_engine as ue

print('Hello i am your pipeline automator')
```

![编辑器中的第一个脚本](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/first_script_editor.png)

保存脚本并单击“执行”运行脚本。

如果您不使用嵌入式编辑器，则可以使用 py_exec 命令从控制台运行 python 脚本

```python
import unreal_engine as ue
ue.py_exec('name_of_script.py')
```

![控制台中的第一个脚本](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/first_script_console.png)

最后，下载https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/Kaiju_Assets.zip文件并将其解压缩到桌面文件夹中。这些是我们将使用 python 脚本导入项目的原始文件（fbx、tga...）。这些文件是由AIV（意大利视频游戏学院，http://aiv01.it）的 Matteo Baccaro 和 Giacomo Caneschi “捐赠”给我的

<a id="importing-the-mesh-fbx"></a>

导入网格FBX
-

让我们开始将 Kaiju 网格 (~/Desktop/Kaiju_Assets/Slicer/slicer.fbx) 导入到 Unreal Engine。为了导入资产，我们需要一个“工厂”（它是一个UE4类）。

每种资产类型基本上都有一个工厂。 FbxFactory是专门用于导入Fbx文件的。

不幸的是，默认情况下，每当您尝试导入 fbx 时，该工厂都会打开一个配置向导，因此将使用替代类（PyFbxFactory）。

它是UnrealUnginePython插件中包含的工厂，它是FbxFactory的简单子类，但没有向导。

```python
import os.path
from unreal_engine.classes import PyFbxFactory

# instantiate a new factory
fbx_factory = PyFbxFactory()

# build the path for the fbx file
kaiju_assets_dir = os.path.join(os.path.expanduser('~/Desktop'), 'Kaiju_Assets/Slicer')

slicer_fbx = os.path.join(kaiju_assets_dir, 'slicer.fbx')

# configure the factory
fbx_factory.ImportUI.bCreatePhysicsAsset = False
fbx_factory.ImportUI.bImportMaterials = False
fbx_factory.ImportUI.bImportTextures = False
fbx_factory.ImportUI.bImportAnimations = False
# scale the mesh (the Kaiju is 30 meters high !)
fbx_factory.ImportUI.SkeletalMeshImportData.ImportUniformScale = 0.1;

# import the mesh
slicer_mesh = fbx_factory.factory_import_object(slicer_fbx, '/Game/Kaiju/Slicer')
```

运行脚本，如果一切顺利，你的 Kaiju 将被导入到你的内容浏览器中：

![ContentBrowser中的怪兽](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_mesh.png)

很可怕，不是吗？

![怪兽模型](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_without_materials.png)

只是关于这一行的注释：

```python
fbx_factory.ImportUI.SkeletalMeshImportData.ImportUniformScale = 0.1;
```

Kaiju 的原始模型有30 米高，因此我们将其缩小以在不同于“东京受到攻击”的背景下使用。

<a id="creating-the-materials"></a>

创建材料
-

从几何角度来看，该模型看起来不错，但您可以注意到（在上一个屏幕截图的左上角）没有为网格指定任何材质。

我们将创建两种不同的材料，一种用于刀片（元素0），另一种用于怪兽身体（元素1）

两种材质均基于`Substance Designer`纹理，第二种材质将包含使用sinfunction/node.“闪烁”发射纹理的功能

将此代码添加到您的脚本中

```python
from unreal_engine.classes import MaterialFactoryNew

material_factory = MaterialFactoryNew()

material_blades = material_factory.factory_create_new('/Game/Kaiju/Slicer/Blades_Material')

material_body = material_factory.factory_create_new('/Game/Kaiju/Slicer/Body_Material')
```

并运行它，您将得到两个新资产：

![怪兽素材](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_materials.png)

在编辑材质之前，我们需要导入8所需的纹理（4用于刀片，4用于身体）：

```python
from unreal_engine.classes import TextureFactory

# instantiate a factory for importing textures
texture_factory = TextureFactory()
# ensures textures are overwritten (2 means, YesAll, defined in Engine/Source/Runtime/Core/Public/GenericPlatform/GenericPlatformMisc.h, EAppReturnType::YesAll)
texture_factory.OverwriteYesOrNoToAllState = 2

slicer_blade_texture_base_color_tga = os.path.join(kaiju_assets_dir, 'Textures/slicer_blade_BaseColor.tga')
slicer_blade_texture_base_color = texture_factory.factory_import_object(slicer_blade_texture_base_color_tga, '/Game/Kaiju/Slicer/Textures')

slicer_blade_texture_normal_tga = os.path.join(kaiju_assets_dir, 'Textures/slicer_blade_Normal.tga')
slicer_blade_texture_normal = texture_factory.factory_import_object(slicer_blade_texture_normal_tga, '/Game/Kaiju/Slicer/Textures')

slicer_blade_texture_emissive_tga = os.path.join(kaiju_assets_dir, 'Textures/slicer_blade_Emissive.tga')
slicer_blade_texture_emissive = texture_factory.factory_import_object(slicer_blade_texture_emissive_tga, '/Game/Kaiju/Slicer/Textures')

# orm stands for OcclusionRoughnessMetallic
slicer_blade_texture_orm_tga = os.path.join(kaiju_assets_dir, 'Textures/slicer_blade_OcclusionRoughnessMetallic.tga')
slicer_blade_texture_orm = texture_factory.factory_import_object(slicer_blade_texture_orm_tga, '/Game/Kaiju/Slicer/Textures')

slicer_texture_base_color_tga = os.path.join(kaiju_assets_dir, 'Textures/slicer_BaseColor.tga')
slicer_texture_base_color = texture_factory.factory_import_object(slicer_texture_base_color_tga, '/Game/Kaiju/Slicer/Textures')

slicer_texture_normal_tga = os.path.join(kaiju_assets_dir, 'Textures/slicer_Normal.tga')
slicer_texture_normal = texture_factory.factory_import_object(slicer_texture_normal_tga, '/Game/Kaiju/Slicer/Textures')

slicer_texture_emissive_tga = os.path.join(kaiju_assets_dir, 'Textures/slicer_Emissive.tga')
slicer_texture_emissive = texture_factory.factory_import_object(slicer_texture_emissive_tga, '/Game/Kaiju/Slicer/Textures')

# orm stands for OcclusionRoughnessMetallic
slicer_texture_orm_tga = os.path.join(kaiju_assets_dir, 'Textures/slicer_OcclusionRoughnessMetallic.tga')
slicer_texture_orm = texture_factory.factory_import_object(slicer_texture_orm_tga, '/Game/Kaiju/Slicer/Textures')
```

![怪兽纹理](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_textures.png)

纹理已准备就绪，我们可以开始“编程”我们的材质，将节点添加到图形中。

让我们从刀片开始。唯一需要考虑的两件事是 OcclusionRoughnessMetallic 纹理必须关闭 sRGB 标志，并且其每个颜色通道都将映射到不同的材质组件：

* 绿色 -> 粗糙度
* 蓝色 -> 金属色
* 红色 -> 环境光遮挡

```python
# setup the slicer blades material

# turn sRGB off for orm textures
slicer_blade_texture_orm.SRGB = False

from unreal_engine.classes import MaterialExpressionTextureSample
from unreal_engine.enums import EMaterialSamplerType
from unreal_engine.structs import ColorMaterialInput, VectorMaterialInput, ScalarMaterialInput

# notify the editor we are about to modify the material
material_blades.modify()

# create the BaseColor node
material_blades_base_color = MaterialExpressionTextureSample('', material_blades)
material_blades_base_color.Texture = slicer_blade_texture_base_color
material_blades_base_color.MaterialExpressionEditorX = -400
material_blades_base_color.MaterialExpressionEditorY = 0

# create the Normal node
material_blades_normal = MaterialExpressionTextureSample('', material_blades)
material_blades_normal.Texture = slicer_blade_texture_normal
# force the sampler to 'Normal'
material_blades_normal.SamplerType = EMaterialSamplerType.SAMPLERTYPE_Normal
material_blades_normal.MaterialExpressionEditorX = -400
material_blades_normal.MaterialExpressionEditorY = 200

# create the Emissive node
material_blades_emissive = MaterialExpressionTextureSample('', material_blades)
material_blades_emissive.Texture = slicer_blade_texture_emissive
material_blades_emissive.MaterialExpressionEditorX = -400
material_blades_emissive.MaterialExpressionEditorY = 400

# create the OcclusionRoughnessMetallic node
material_blades_orm = MaterialExpressionTextureSample('', material_blades)
material_blades_orm.Texture = slicer_blade_texture_orm
# force the sampler to 'LinearColor' (remember you turned off sRGB)
material_blades_orm.SamplerType = EMaterialSamplerType.SAMPLERTYPE_LinearColor
material_blades_orm.MaterialExpressionEditorX = -400
material_blades_orm.MaterialExpressionEditorY = 600

# assign nodes to the material
material_blades.Expressions = [material_blades_base_color, material_blades_normal, material_blades_emissive, material_blades_orm]

# link nodes
material_blades.BaseColor = ColorMaterialInput(Expression=material_blades_base_color)
# normals are vectors
material_blades.Normal = VectorMaterialInput(Expression=material_blades_normal)
material_blades.EmissiveColor = ColorMaterialInput(Expression=material_blades_emissive)
# use masking for orm nodes, it turns on/off specific channels, all of the items are scalars
material_blades.Roughness = ScalarMaterialInput(Expression=material_blades_orm, Mask=1, MaskG=1)
material_blades.Metallic = ScalarMaterialInput(Expression=material_blades_orm, Mask=1, MaskB=1)
material_blades.AmbientOcclusion = ScalarMaterialInput(Expression=material_blades_orm, Mask=1, MaskR=1)

# run material compilation
material_blades.post_edit_change()
```

这是我们刚刚生成的：

![怪兽刀片材料](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_blades_material.png)

主体材质会更复杂一些，因为我们想要“blink/beam”发射纹理

```python
from unreal_engine.classes import MaterialExpressionSine, MaterialExpressionMultiply, MaterialExpressionTime
from unreal_engine.structs import ExpressionInput

# turn sRGB off for orm textures
slicer_texture_orm.SRGB = False

# inform the editor we want to modify the material
material_body.modify()

# build the material graph

# start with texture samples (as we did with the blades material)
material_body_base_color = MaterialExpressionTextureSample('', material_body)
material_body_base_color.Texture = slicer_texture_base_color
material_body_base_color.MaterialExpressionEditorX = -400
material_body_base_color.MaterialExpressionEditorY = 0

material_body_normal = MaterialExpressionTextureSample('', material_body)
material_body_normal.Texture = slicer_texture_normal
material_body_normal.SamplerType = EMaterialSamplerType.SAMPLERTYPE_Normal
material_body_normal.MaterialExpressionEditorX = -400
material_body_normal.MaterialExpressionEditorY = 200

material_body_emissive = MaterialExpressionTextureSample('', material_body)
material_body_emissive.Texture = slicer_texture_emissive
material_body_emissive.MaterialExpressionEditorX = -400
material_body_emissive.MaterialExpressionEditorY = 400

material_body_orm = MaterialExpressionTextureSample('', material_body)
material_body_orm.Texture = slicer_texture_orm
material_body_orm.SamplerType = EMaterialSamplerType.SAMPLERTYPE_LinearColor
material_body_orm.MaterialExpressionEditorX = -400
material_body_orm.MaterialExpressionEditorY = 600

# create a Sine node
material_body_sine = MaterialExpressionSine('', material_body)
material_body_sine.MaterialExpressionEditorX = -1000
material_body_sine.MaterialExpressionEditorY = 0

# create a Time node
material_body_time = MaterialExpressionTime('', material_body)
material_body_time.MaterialExpressionEditorX = -1200
material_body_time.MaterialExpressionEditorY = 0

# create a Multiply node
material_body_multiply = MaterialExpressionMultiply('', material_body)
material_body_multiply.MaterialExpressionEditorX = -800
material_body_multiply.MaterialExpressionEditorY = 0

# assign nodes to the graph
material_body.Expressions = [material_body_base_color, material_body_normal, material_body_emissive, material_body_orm, material_body_time, material_body_sine, material_body_multiply]

# connect Time to Sine Input
material_body_sine.Input = ExpressionInput(Expression=material_body_time)
# connect the Emissive Texture to the Multiply pin A
material_body_multiply.A = ExpressionInput(Expression=material_body_emissive)
# connect the Sine to the Multiply pin B
material_body_multiply.B = ExpressionInput(Expression=material_body_sine)

# link nodes 
material_body.BaseColor = ColorMaterialInput(Expression=material_body_base_color)
material_body.EmissiveColor = ColorMaterialInput(Expression=material_body_multiply)
material_body.Normal = VectorMaterialInput(Expression=material_body_normal)
material_body.Roughness = ScalarMaterialInput(Expression=material_body_orm, Mask=1, MaskG=1)
material_body.Metallic = ScalarMaterialInput(Expression=material_body_orm, Mask=1, MaskB=1)
material_body.AmbientOcclusion = ScalarMaterialInput(Expression=material_body_orm, Mask=1, MaskR=1)

# run material compilation
material_body.post_edit_change()
```

这是主体材料结果：

![怪兽本体材料](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_body_material.png)

缺少最后一步：将材质分配给切片器网格：

```python
from unreal_engine.structs import SkeletalMaterial, MeshUVChannelInfo

# SkeletalMaterial is a struct holding information about material mappings
# the Materials property is the array of assigned materials (setting UVChannelData is required, otherwise you will get assertions)
slicer_mesh.Materials = [SkeletalMaterial(MaterialInterface=material_blades, MaterialSlotName='Blades', UVChannelData=MeshUVChannelInfo(bInitialized=True)),SkeletalMaterial(MaterialInterface=material_body, MaterialSlotName='Body', UVChannelData=MeshUVChannelInfo(bInitialized=True))]

# and save them all
slicer_mesh.save_package()
material_blades.save_package()
material_body.save_package()
```

最终结果：

![怪兽与素材](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_with_materials.png)

<a id="importing-animations-and-creating-a-new-monodimensional-blendspace-for-locomotion"></a>

导入动画并创建新的单维 BlendSpace 用于运动
-

导入动画对 Fbx 网格使用相同的工厂。

我们有6动画可供导入：闲置、无聊、攻击、咆哮、奔跑和行走

这将是一项简单的任务：

```python
anim_factory = PyFbxFactory()
# you need to set the skeleton before importing animations
anim_factory.ImportUI.Skeleton = slicer_mesh.Skeleton
anim_factory.ImportUI.bImportMesh = False
anim_factory.ImportUI.bImportMaterials = False
anim_factory.ImportUI.bImportTextures = False
# remember to scale them as you did with the base mesh
anim_factory.ImportUI.AnimSequenceImportData.ImportUniformScale = 0.1;

slicer_idle_fbx = os.path.join(kaiju_assets_dir, 'Animations/slicer_idle.fbx')
animation_idle = anim_factory.factory_import_object(slicer_idle_fbx, '/Game/Kaiju/Slicer/Animations')

slicer_bored_fbx = os.path.join(kaiju_assets_dir, 'Animations/slicer_bored.fbx')
animation_bored = anim_factory.factory_import_object(slicer_bored_fbx, '/Game/Kaiju/Slicer/Animations')

slicer_attack_fbx = os.path.join(kaiju_assets_dir, 'Animations/slicer_attack.fbx')
animation_attack = anim_factory.factory_import_object(slicer_attack_fbx, '/Game/Kaiju/Slicer/Animations')

slicer_roaring_fbx = os.path.join(kaiju_assets_dir, 'Animations/slicer_roaring.fbx')
animation_roaring = anim_factory.factory_import_object(slicer_roaring_fbx, '/Game/Kaiju/Slicer/Animations')

slicer_run_fbx = os.path.join(kaiju_assets_dir, 'Animations/slicer_run.fbx')
animation_run = anim_factory.factory_import_object(slicer_run_fbx, '/Game/Kaiju/Slicer/Animations')

slicer_walk_fbx = os.path.join(kaiju_assets_dir, 'Animations/slicer_walk.fbx')
animation_walk = anim_factory.factory_import_object(slicer_walk_fbx, '/Game/Kaiju/Slicer/Animations')
```

![怪兽与素材](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_animations.png)

现在我们要创建一个BlendSpace1D资产。它将由 3 运动相关动画（空闲、行走、跑步）组成，并由称为速度的变量（X）控制，最小值为 0，最大值为 300。

```python
from unreal_engine.classes import BlendSpaceFactory1D
from unreal_engine.structs import BlendSample, BlendParameter
from unreal_engine import FVector

blend_space_factory = BlendSpaceFactory1D()
# you need to assign the related Skeleton
blend_space_factory.TargetSkeleton = slicer_mesh.Skeleton

# create the asset
slicer_locomotion = blend_space_factory.factory_create_new('/Game/Kaiju/Slicer/Animations/slicer_locomotion')

ue.open_editor_for_asset(slicer_locomotion)

# set blend parameters
slicer_locomotion.modify()
slicer_locomotion.BlendParameters = BlendParameter(DisplayName='Speed', Min=0, Max=300, GridNum=2)

# assign animations
# 0 -> idle
# 150 -> walk
# 300 -> run
# mark them as 'valid' explicitely !
slicer_locomotion.SampleData = [BlendSample(Animation=animation_idle, SampleValue=FVector(0, 0, 0), bIsValid=True, RateScale=1), BlendSample(Animation=animation_walk, SampleValue=FVector(150, 0, 0), bIsValid=True, RateScale=1), BlendSample(Animation=animation_run, SampleValue=FVector(300, 0, 0), bIsValid=True, RateScale=1)]

# compute blend space and update the editor preview
slicer_locomotion.post_edit_change()

slicer_locomotion.save_package()

ue.close_editor_for_asset(slicer_locomotion)
```

请注意 ue.open_editor_for_asset(slicer_locomotion) 和 ue.close_editor_for_asset(slicer_locomotion) 调用。它们允许在修改后重建混合空间（当前在 UE4 中没有 slate 接口之外的 api 可以执行此操作）


![怪兽运动BlendSpace](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_locomotion.png)

<a id="creating-the-animationblueprint"></a>

创建AnimationBlueprint
-

我们的动画资源已准备就绪，因此我们可以开始创建动画蓝图。

它将包含一个在以下状态之间切换的状态机：

* 运动（我们之前创建的混合空间）

* 攻击（用刀刃攻击或随机发生30%的时间发出嘲讽的咆哮）

* 无聊（闲置时间超过10秒时，开始环顾四周）

它的事件图管理混合空间的速度变量和触发“无聊”状态的空闲计时器。

```python
from unreal_engine.classes import AnimBlueprintFactory


# ensure no blueprint with the same name exists
# find_asset() returns None if the asset does not exist
anim_bp = ue.find_asset('/Game/Kaiju/Slicer/slicer_AnimBP.slicer_AnimBP')
if anim_bp:    
    ue.delete_asset(anim_bp.get_path_name())

anim_bp_factory = AnimBlueprintFactory()
anim_bp_factory.TargetSkeleton = slicer_mesh.Skeleton

anim_bp = anim_bp_factory.factory_create_new('/Game/Kaiju/Slicer/slicer_AnimBP')
```

始终考虑到使用现有名称创建Blueprint（任何类型）都会触发错误。如果ue.find_asset()成功，我们将销毁已经存在的资产。

创建蓝图后，我们需要分配一个自定义事件“DoAttack”（当 Kaiju 靠近 Pawn 时触发），另一个称为“Boring”（当 Kaiju 位于 stationary/idle 超过 10 秒时触发）， 2 布尔变量（攻击、无聊）和浮点变量（速度）：

```python
# DoAttack custom event
node_do_attack = anim_bp.UberGraphPages[0].graph_add_node_custom_event('DoAttack', 0, -200)

# Boring custom event
node_boring = anim_bp.UberGraphPages[0].graph_add_node_custom_event('Boring', 0, -400)

# bool variables
ue.blueprint_add_member_variable(anim_bp, 'Attack', 'bool')
ue.blueprint_add_member_variable(anim_bp, 'Bored', 'bool')

# float variable
ue.blueprint_add_member_variable(anim_bp, 'Speed', 'float')
```

![怪兽动画Blueprint](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_anim_blueprint.png)

我们现在可以添加图形节点：

```python
# add nodes to the graph
from unreal_engine.classes import KismetSystemLibrary, KismetMathLibrary

# set Attack to True
node_set_attack001 = anim_bp.UberGraphPages[0].graph_add_node_variable_set('Attack', None, 300, -200)
node_set_attack001.node_find_pin('Attack').default_value = 'true'

# Delay of 2 seconds (cooldown)
from unreal_engine.classes import KismetSystemLibrary
node_delay_2_seconds = anim_bp.UberGraphPages[0].graph_add_node_call_function(KismetSystemLibrary.Delay, 600, -200)
node_delay_2_seconds.node_find_pin('Duration').default_value = '2.0'

# set Attack to False
node_set_attack002 = anim_bp.UberGraphPages[0].graph_add_node_variable_set('Attack', None, 900, -200)
node_set_attack002.node_find_pin('Attack').default_value = 'false'

# set Bored to True
node_set_bored001 = anim_bp.UberGraphPages[0].graph_add_node_variable_set('Bored', None, 300, -400)
node_set_bored001.node_find_pin('Bored').default_value = 'true'

# Delay of 5 seconds (cooldown)
from unreal_engine.classes import KismetSystemLibrary
node_delay_5_seconds = anim_bp.UberGraphPages[0].graph_add_node_call_function(KismetSystemLibrary.Delay, 600, -400)
node_delay_5_seconds.node_find_pin('Duration').default_value = '5.0'

# set Attack to False
node_set_bored002 = anim_bp.UberGraphPages[0].graph_add_node_variable_set('Bored', None, 900, -400)
node_set_bored002.node_find_pin('Bored').default_value = 'false'
```

...并将它们链接起来

```python
# link nodes

# DoAttack to Set Attack True
node_do_attack.node_find_pin('then').make_link_to(node_set_attack001.node_find_pin('execute'))
# Set Attack True to Delay
node_set_attack001.node_find_pin('then').make_link_to(node_delay_2_seconds.node_find_pin('execute'))
# Delay to Set Attack False
node_delay_2_seconds.node_find_pin('then').make_link_to(node_set_attack002.node_find_pin('execute'))

# Boring to Set Bored True
node_boring.node_find_pin('then').make_link_to(node_set_bored001.node_find_pin('execute'))
# Set Attack True to Delay
node_set_bored001.node_find_pin('then').make_link_to(node_delay_5_seconds.node_find_pin('execute'))
# Delay to Set Attack False
node_delay_5_seconds.node_find_pin('then').make_link_to(node_set_bored002.node_find_pin('execute'))
```

![怪兽动画 Blueprint 带节点](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_anim_blueprint_with_nodes.png)

事件图缺少的最后一部分是将速度分配给演员速度。

正如您所看到的，“BlueprintUpdateAnimation”事件和“TryGetPawnOwner”纯函数会自动添加到动画图中。因此，我们需要对函数进行商品化以找到对它们的引用：

```python
from unreal_engine.classes import K2Node_Event, K2Node_CallFunction, Actor, AnimInstance

def find_event_node(graph, name):
    for node in graph.Nodes:
        if node.is_a(K2Node_Event):
            if node.EventReference.MemberName == name:
                return node
    return None
    
def find_function_node(graph, name):
    for node in graph.Nodes:
        if node.is_a(K2Node_CallFunction):
            if node.FunctionReference.MemberName == name:
                return node
    return None

update_animation_event = find_event_node(anim_bp.UberGraphPages[0], 'BlueprintUpdateAnimation')
try_get_pawn_owner = find_function_node(anim_bp.UberGraphPages[0], 'TryGetPawnOwner')
# weird enough, sometimes the TryGetPawnOwner node is not automatically added ... (is it a race condition ?)
if not try_get_pawn_owner:
    try_get_pawn_owner = anim_bp.UberGraphPages[0].graph_add_node_call_function(AnimInstance.TryGetPawnOwner, 0, 200)
```

我们现在可以添加“GetVelocity”节点和“VectorLength”节点。它的返回值将被存储到 Speed 变量中

```python
node_get_velocity = anim_bp.UberGraphPages[0].graph_add_node_call_function(Actor.GetVelocity, 300, 200)
# note the functions is called VSize albeit the graph editor reports it as VectorLength
node_vector_length = anim_bp.UberGraphPages[0].graph_add_node_call_function(KismetMathLibrary.VSize, 600, 200)
node_speed_set = anim_bp.UberGraphPages[0].graph_add_node_variable_set('Speed', None, 900, 0)


#link nodes

# BlueprintUpdateAnimation to Speed Set
update_animation_event.node_find_pin('then').make_link_to(node_speed_set.node_find_pin('execute'))

# TryGetPawnOwner to GetVelocity
try_get_pawn_owner.node_find_pin('ReturnValue').make_link_to(node_get_velocity.node_find_pin('self'))

# GetVelocity to VectorLength
node_get_velocity.node_find_pin('ReturnValue').make_link_to(node_vector_length.node_find_pin('A'))

# VectorLength to Speed Set
node_vector_length.node_find_pin('ReturnValue').make_link_to(node_speed_set.node_find_pin('Speed'))
```

![怪兽动画Blueprint事件图](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_anim_blueprint_event_graph.png)

我们已经完成了事件图，现在可以转到AnimGraph并定义状态机

```python
# create the State Machine
from unreal_engine.classes import AnimGraphNode_StateMachine

state_machine = anim_bp.FunctionGraphs[0].graph_add_node(AnimGraphNode_StateMachine, -300, 0)
# assign a name to the state machine
state_machine.EditorStateMachineGraph.set_name('Slicer State Machine')

# connect the state machine to the first node of the anim graph
state_machine.node_find_pin('Pose').make_link_to(anim_bp.FunctionGraphs[0].Nodes[0].node_find_pin('Result'))
```

![怪兽动画Blueprint状态机](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_state_machine.png)

（您收到的警告是因为状态机为空）

是时候添加“状态”了：

```python
# adding states
from unreal_engine.classes import AnimStateNode

# Locomotion
locomotion_state = state_machine.EditorStateMachineGraph.graph_add_node(AnimStateNode, 200, 0)
locomotion_state.BoundGraph.set_name('Locomotion')

# Attack
attack_state = state_machine.EditorStateMachineGraph.graph_add_node(AnimStateNode, 400, -150)
attack_state.BoundGraph.set_name('Attack')

# Bored
bored_state = state_machine.EditorStateMachineGraph.graph_add_node(AnimStateNode, 400, 150)
bored_state.BoundGraph.set_name('Bored')
```

![怪兽动画Blueprint状态](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_states.png)


我们从“无聊”状态开始，因为它是一个简单的状态（只需循环播放动画）

```python
# The Bored State -> simply play an animation
from unreal_engine.classes import AnimGraphNode_SequencePlayer
from unreal_engine.structs import AnimNode_SequencePlayer

bored_player = bored_state.BoundGraph.graph_add_node(AnimGraphNode_SequencePlayer, -300, 0)
bored_player.Node = AnimNode_SequencePlayer(Sequence=animation_bored, bLoopAnimation=True)
bored_player.node_find_pin('Pose').make_link_to(bored_state.BoundGraph.Nodes[0].node_find_pin('Result'))
```

![怪兽动画Blueprint无聊状态](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_states_bored.png)

接下来是“运动”状态，它是由“速度”变量控制的混合空间的简单操作：

```python
# The Locomotion State -> play the blendspace driven by the 'Speed' variable
from unreal_engine.classes import AnimGraphNode_BlendSpacePlayer
from unreal_engine.structs import AnimNode_BlendSpacePlayer

locomotion_player = locomotion_state.BoundGraph.graph_add_node(AnimGraphNode_BlendSpacePlayer, -300, 0)
locomotion_player.Node = AnimNode_BlendSpacePlayer(BlendSpace=slicer_locomotion, bLoop=True)

locomotion_speed_get = locomotion_state.BoundGraph.graph_add_node_variable_get('Speed', None, -500, 0)

# link nodes
locomotion_speed_get.node_find_pin('Speed').make_link_to(locomotion_player.node_find_pin('X'))
locomotion_player.node_find_pin('Pose').make_link_to(locomotion_state.BoundGraph.Nodes[0].node_find_pin('Result'))
```

![怪兽动画Blueprint状态运动](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_states_locomotion.png)

最后一个状态是“攻击”状态，它使用随机播放器，播放 70% 的时间攻击动画，以及 30% 的回退到嘲讽（咆哮动画）

```python
# The Attack State -> 70% of the time it will run the blades animation, the other time will run the roar one (like a taunt)
from unreal_engine.classes import AnimGraphNode_RandomPlayer
from unreal_engine.structs import AnimNode_RandomPlayer, RandomPlayerSequenceEntry

attack_player = attack_state.BoundGraph.graph_add_node(AnimGraphNode_RandomPlayer, -300, 0)
attack_player.Node = AnimNode_RandomPlayer(Entries=[RandomPlayerSequenceEntry(Sequence=animation_attack, ChanceToPlay=0.7), RandomPlayerSequenceEntry(Sequence=animation_roaring, ChanceToPlay=0.3)])

attack_player.node_find_pin('Pose').make_link_to(attack_state.BoundGraph.Nodes[0].node_find_pin('Result'))
```

![怪兽动画Blueprint状态攻击](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_states_attack.png)

现在我们可以建立连接，请注意，我们使用引脚的“connect()”方法而不是“make_link_to”，因为“connect”将尊重节点功能（对于状态节点，它会自动生成条件图）

```python
# time to make states connections
entry_state = state_machine.EditorStateMachineGraph.Nodes[0]

# Entry to Locomotion
entry_state.node_find_pin('Entry').connect(locomotion_state.node_find_pin('In'))
# Locomotion to Bored
locomotion_state.node_find_pin('Out').connect(bored_state.node_find_pin('In'))
# Bored to Locomotion
bored_state.node_find_pin('Out').connect(locomotion_state.node_find_pin('In'))
# Locomotion to Attack
locomotion_state.node_find_pin('Out').connect(attack_state.node_find_pin('In'))
# Attack to Locomotion
attack_state.node_find_pin('Out').connect(locomotion_state.node_find_pin('In'))
```

![怪兽动画Blueprint状态机连接](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_state_machine_connections.png)

一旦建立连接，我们就可以定义转换图。不幸的是，UnrealEnginePython当前的二进制版本不包含node_get_title()方法，因此我们需要通过它们的id来引用转换图。幸运的是，它们按照创建的顺序编入索引：

```python
# get transitions graphs
locomotion_to_bored = state_machine.EditorStateMachineGraph.SubGraphs[3]
bored_to_locomotion = state_machine.EditorStateMachineGraph.SubGraphs[4]
locomotion_to_attack = state_machine.EditorStateMachineGraph.SubGraphs[5]
attack_to_locomotion = state_machine.EditorStateMachineGraph.SubGraphs[6]

# locomotion to bored
check_bored = locomotion_to_bored.graph_add_node_variable_get('Bored', None, -200, 0)
check_bored.node_find_pin('Bored').make_link_to(locomotion_to_bored.Nodes[0].node_find_pin('bCanEnterTransition'))

# bored to locomotion
check_not_bored = bored_to_locomotion.graph_add_node_variable_get('Bored', None, -300, 0)
check_not_bored_not_bool = bored_to_locomotion.graph_add_node_call_function(KismetMathLibrary.Not_PreBool, -150, 0)
check_not_bored.node_find_pin('Bored').make_link_to(check_not_bored_not_bool.node_find_pin('A'))
check_not_bored_not_bool.node_find_pin('ReturnValue').make_link_to(bored_to_locomotion.Nodes[0].node_find_pin('bCanEnterTransition'))

# locomotion to attack
check_attack = locomotion_to_attack.graph_add_node_variable_get('Attack', None, -200, 0)
check_attack.node_find_pin('Attack').make_link_to(locomotion_to_attack.Nodes[0].node_find_pin('bCanEnterTransition'))

# attack to locomotion
check_not_attack = attack_to_locomotion.graph_add_node_variable_get('Attack', None, -300, 0)
check_not_attack_not_bool = attack_to_locomotion.graph_add_node_call_function(KismetMathLibrary.Not_PreBool, -150, 0)
check_not_attack.node_find_pin('Attack').make_link_to(check_not_attack_not_bool.node_find_pin('A'))
check_not_attack_not_bool.node_find_pin('ReturnValue').make_link_to(attack_to_locomotion.Nodes[0].node_find_pin('bCanEnterTransition'))
```

![怪兽动画Blueprint状态机转换](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_state_machine_transitions.png)

FInally我们可以编译动画Blueprint并保存

```python
# compile and save
ue.compile_blueprint(anim_bp)
anim_bp.save_package()
```

<a id="put-it-all-in-a-new-blueprint"></a>

将其全部放入新的Blueprint
-

现在是时候创建角色Blueprint，我们将在其中附加之前创建的资源。

```python
from unreal_engine.classes import Character

# always check for already existing blueprints
slicer_bp = ue.find_asset('/Game/Kaiju/Slicer/slicer_Blueprint.slicer_Blueprint')
if slicer_bp:
    ue.delete_asset(slicer_bp.get_path_name())
    
slicer_bp = ue.create_blueprint(Character, '/Game/Kaiju/Slicer/slicer_Blueprint')
```

赋值时间：

```python

# configure the capsule
slicer_bp.GeneratedClass.get_cdo().CapsuleComponent.CapsuleHalfHeight = 150
slicer_bp.GeneratedClass.get_cdo().CapsuleComponent.CapsuleRadius = 60

# assign the the skeletal mesh and fix its relative position
slicer_bp.GeneratedClass.get_cdo().Mesh.SkeletalMesh = slicer_mesh
slicer_bp.GeneratedClass.get_cdo().Mesh.RelativeLocation = FVector(10, -3, -144)

# assign the animation blueprint
slicer_bp.GeneratedClass.get_cdo().Mesh.AnimClass = anim_bp.GeneratedClass
```

get_cdo() 方法返回“类默认对象”，它是定义以下实例应继承的默认属性和组件的类的特殊实例。当您编辑蓝图类时，您可以有效地编辑其“cdo”。

我们现在可以通过编译蓝图来完成教程的第一部分：

```python
ue.compile_blueprint(slicer_bp)
slicer_bp.save_package()
```

![怪兽Blueprint](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/slicer_blueprint.png)

<a id="final-notes"></a>

最后的笔记
-

您可以在这里获取整个脚本：https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/YourFirstAutomatedPipeline_Assets/kaiju_slicer_pipeline.py

现在，您可以将蓝图拖放到场景中或对其进行子类化。

你最终可以直接从 python 生成它：

```python
# get a reference to the editor world
world = ue.get_editor_world()
world.actor_spawn(slicer_bp.GeneratedClass, FVector(17, 22, 30))
```

在第二部分中，我们将看到如何为我们的 Kaiju 提供“大脑”。
