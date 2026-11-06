[English](SnippetsForStaticAndSkeletalMeshes.md) | [简体中文](SnippetsForStaticAndSkeletalMeshes.zh-CN.md)

<a id="snippets-for-static-and-skeletal-meshes"></a>

# 静态和骨架网格体的片段

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

这是 StaticMeshes 和 SkeletalMeshes manipulation/creation. 的 snippets/examples 的集合

还包括对动画、变形目标和 LOD 的操作

代码有很多注释，大部分解释都在那里！

<a id="introduction"></a>

## 简介

在开始使用片段之前，我们应该介绍一些约定：

每个脚本（除非另有指定）应从控制台或嵌入式 python 编辑器手动运行，并将执行到内容浏览器或世界大纲中当前选定的对象。

要访问当前选定的资产，您可以使用以下函数（它返回UObjects的列表）：

```python
import unreal_engine as ue
uobjects = ue.get_selected_assets()
```

要访问编辑器世界大纲中当前选定的演员：

```python
actors = ue.editor_get_selected_actors()
```

这是使用 python 列表理解获取所选资产名称的屏幕截图：

![内容浏览器](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/content_browser.PNG)

![get_selected_assets](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/get_selected_assets.PNG)

代码片段中使用的另一个约定是，只要必须将错误返回给用户，就使用自定义 python 异常：

```python
import unreal_engine as ue

class DialogException(Exception):
    """
    Handy exception class for spawning a message dialog on error
    """
    def __init__(self, message):
        # 0 here, means "show only the Ok button", for other values
        # check https://docs.unrealengine.com/latest/INT/API/Runtime/Core/GenericPlatform/EAppMsgType__Type/index.html
        ue.message_dialog_open(0, message)
```

提高 DialogException(message) 将触发如下内容：

![Python异常](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/python_exception.PNG)

最后，大多数脚本（出于安全原因）都会生成原始对象的副本。显然，您可以自由地更新原始对象（风险自负！）


<a id="staticmesh-centering-pivot"></a>

## StaticMesh：定心枢轴

最烦人的问题之一（特别是在与没有经验的建模者一起工作时）是完全毫无意义的枢轴。请记住，网格的枢轴是其原点轴（0X、0Y、0Z），仅此而已。

这是一个带有“奇怪”枢轴的网格：

![奇怪的枢轴](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/broken_pivot.PNG)

为了修复它，我们需要获取网格边界（您可以通过单击StaticMeshEditor工具栏中的“边界”按钮来查看它们）及其原点，然后将该向量减去每个网格顶点（这样边界的原点也将成为顶点的原点）：

![奇怪的枢轴](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/mesh_bounds.PNG)


```python
import unreal_engine as ue
from unreal_engine.classes import StaticMesh

def fix_pivot(static_mesh):
    if not static_mesh.is_a(StaticMesh):
        raise DialogException('Asset is not a StaticMesh')    
           
    # get the origin of the mesh bounds
    center = static_mesh.ExtendedBounds.Origin
    
    # get the raw data of the mesh, FRawMesh is a structure holding vertices, uvs, tangents, material indices of a LOD (by default lod 0)
    raw_mesh = static_mesh.get_raw_mesh()   
    
    # now we create a duplicate of the mesh in the /Game/RePivoted_Meshes folder with the same name suffixed with _RePivoted
    new_asset_name = '{0}_RePivoted'.format(static_mesh.get_name())
    package_name = '/Game/RePivoted_Meshes/{0}'.format(new_asset_name)
    new_static_mesh = static_mesh.duplicate(package_name, new_asset_name)
    
    # time to fix each vertex
    updated_positions = []

    for vertex in raw_mesh.get_vertex_positions():
        updated_positions.append(vertex - center)
        # this is a trick for giving back control to Unreal Engine avoiding python to block it on slow operations
        ue.slate_tick()

    # update the FRawMesh structure with new vertices
    raw_mesh.set_vertex_positions(updated_positions)
        
    # assign the mesh data to the first LOD (LODs are exposed in SourceModels array)
    raw_mesh.save_to_static_mesh_source_model(new_static_mesh.SourceModels[0])
    # rebuild the whole mesh
    new_static_mesh.static_mesh_build()
    # re-do the body setup (collisions and friends)
    new_static_mesh.static_mesh_create_body_setup()
    # notify the editor about the changes
    new_static_mesh.post_edit_change()
    # save the new asset
    new_static_mesh.save_package()

for uobject in ue.get_selected_assets():
    fix_pivot(uobject)
```

执行脚本后，您的新资产的中心将具有枢轴：

![固定枢轴](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/fixed_pivot.PNG)


<a id="staticmesh-adding-lods"></a>

## StaticMesh：添加 LOD

在前面的代码片段中，我们研究了 StaticMesh 的已可用 LOD。这次（假设网格具有单个 LOD），我们将添加两个新的 LOD。您可以将任何类型的网格数据放入每个 lod 中（它们可以是完全不相关的网格）。在此示例中，我们将通过将每个顶点的顶点颜色设置为不同的值来执行一些不太有用的操作。

这里我们使用 UE4 人体模型骨架网格物体，转换为静态骨架网格物体，两个材质槽映射到相同的“哑”材质，只需将顶点颜色的值写入片段基色通道

![人体模型](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/mannequin.PNG)

![顶点颜色材质](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/vertex_color_material.PNG)

```python
import unreal_engine as ue
from unreal_engine.classes import StaticMesh
from unreal_engine.structs import StaticMeshSourceModel, MeshBuildSettings
from unreal_engine import FColor

def generate_vertex_colors(raw_mesh, color0, color1):
    # generate a list of new vertex colors
    # iterate each face to check which material slot is in use, and generate 3 new vertex colors
    updated_colors = []
    for material_index in raw_mesh.get_face_material_indices():
        color = color0
        if material_index == 1:
            color = color1
        updated_colors.append(color)
        updated_colors.append(color)
        updated_colors.append(color)

    # update the FRawMesh structure with new vertex colors
    raw_mesh.set_wedge_colors(updated_colors)

def add_lods(static_mesh):
    if not static_mesh.is_a(StaticMesh):
        raise DialogException('Asset is not a StaticMesh')    
               
    # get the raw data of the mesh, FRawMesh is a strcture holding vertices, uvs, tangents, material indices of a LOD (by default lod 0)
    raw_mesh = static_mesh.get_raw_mesh()   
    
    # now we create a duplicate of the mesh in the /Game/ReLODed_Meshes folder with the same name suffixed with _ReLODed
    new_asset_name = '{0}_ReLODed'.format(static_mesh.get_name())
    package_name = '/Game/ReLODed_Meshes/{0}'.format(new_asset_name)
    new_static_mesh = static_mesh.duplicate(package_name, new_asset_name)
    
    
    # generate LOD1
    lod1 = StaticMeshSourceModel(BuildSettings=MeshBuildSettings(bRecomputeNormals=False, bRecomputeTangents=True, bUseMikkTSpace=True, bBuildAdjacencyBuffer=True, bRemoveDegenerates=True))
    generate_vertex_colors(raw_mesh, FColor(0, 0, 255), FColor(0, 255, 255))
    raw_mesh.save_to_static_mesh_source_model(lod1)

    # generate LOD2
    lod2 = StaticMeshSourceModel(BuildSettings=MeshBuildSettings(bRecomputeNormals=False, bRecomputeTangents=True, bUseMikkTSpace=True, bBuildAdjacencyBuffer=True, bRemoveDegenerates=True))
    generate_vertex_colors(raw_mesh, FColor(255, 0, 0), FColor(0, 255, 0))
    raw_mesh.save_to_static_mesh_source_model(lod2)
        
    # assign the new LODs (leaving the first one untouched)
    new_static_mesh.SourceModels = [new_static_mesh.SourceModels[0], lod1, lod2]
    # rebuild the whole mesh
    new_static_mesh.static_mesh_build()
    # re-do the body setup (collisions and friends)
    new_static_mesh.static_mesh_create_body_setup()
    # notify the editor about the changes
    new_static_mesh.post_edit_change()
    # save the new asset
    new_static_mesh.save_package()

for uobject in ue.get_selected_assets():
    add_lods(uobject)
```

这里的关键概念是构建新 LOD 所需的 StaticMeshSourceModel 和 MeshBuildSettings 结构的使用

结果将是人体模型根据与观看者的距离改变颜色：

![人体模型 LOD](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/mannequin_lods.PNG)

<a id="staticmesh-merging"></a>

## StaticMesh：合并

此代码片段展示了如何通过组合多个来构建新的StaticMesh。如果模型导出错误或作为优化，它可能非常方便。 mesh_merge() 函数采用可选参数“merge_materials”来指示脚本为每个网格生成材质槽，或者为所有网格使用单一材质（减少绘制调用，但很可能会破坏结果）。

将打开一个对话框询问路径，而不是自动生成资产名称。注意：所有选定的静态网格体将合并为一个新的静态网格体。

目标是合并以下静态网格物体：

![要合并的静态网格体](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/static_meshes_to_merge.PNG)

```python
import unreal_engine as ue
from unreal_engine import FRawMesh
from unreal_engine.classes import StaticMesh
from unreal_engine.structs import StaticMeshSourceModel, MeshBuildSettings

def mesh_merge(meshes, merge_materials=False):
    new_path = ue.create_modal_save_asset_dialog('Choose destination path', '/Game')
    package_name = ue.object_path_to_package_name(new_path)
    object_name = ue.get_base_filename(new_path)

    materials = []
    vertices = []
    texcoords = []
    normals = []
    indices = []
    material_indices = []
    for mesh in meshes:
        if not mesh.is_a(StaticMesh):
            raise DialogException('only StaticMeshes can be merged')

        raw_mesh = mesh.get_raw_mesh()
        
        # manage wedges
        original_indices = raw_mesh.get_wedge_indices()
        for i, index in enumerate(original_indices):
            original_indices[i] += len(vertices)
        indices += original_indices

        # manage materials
        original_material_indices = raw_mesh.get_face_material_indices()
        for i, index in enumerate(original_material_indices):
            if original_material_indices[i] >= 0:
                original_material_indices[i] += len(material_indices)
        material_indices += original_material_indices

        vertices += raw_mesh.get_vertex_positions()
        texcoords += raw_mesh.get_wedge_tex_coords()
        normals += raw_mesh.get_wedge_tangent_z()
        materials += mesh.StaticMaterials
        # give back control to ue to not block the interface too much
        ue.slate_tick()

    # assemble the new mesh
    sm = StaticMesh(object_name, ue.get_or_create_package(package_name))
    new_raw_mesh = FRawMesh()
    new_raw_mesh.set_vertex_positions(vertices)
    new_raw_mesh.set_wedge_indices(indices)
    new_raw_mesh.set_wedge_tex_coords(texcoords)
    new_raw_mesh.set_wedge_tangent_z(normals)
    if not merge_materials:
        new_raw_mesh.set_face_material_indices(material_indices)

    lod0 = StaticMeshSourceModel(BuildSettings=MeshBuildSettings(bRecomputeNormals=False, bRecomputeTangents=True, bUseMikkTSpace=True, bBuildAdjacencyBuffer=True, bRemoveDegenerates=True))
    
    new_raw_mesh.save_to_static_mesh_source_model(lod0)

    sm.SourceModels = [lod0]
    if merge_materials:
        materials = [materials[0]]
    sm.StaticMaterials = materials
    # rebuild the whole mesh
    sm.static_mesh_build()
    # re-do the body setup (collisions and friends)
    sm.static_mesh_create_body_setup()
    # notify the editor about the changes (not strictly required)
    sm.post_edit_change()

    sm.save_package()

    return sm
        

new_mesh = mesh_merge(ue.get_selected_assets())

ue.open_editor_for_asset(new_mesh)
    
```

![已合并](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/mesh_merged.PNG)

在屏幕截图中，您可以注意到突出显示特定材质槽将如何突出显示网格的特定部分（如果合并材质，这将不起作用，因为所有面都将映射到第一个材质槽）

<a id="skeleton-building-a-new-tree"></a>

## 骨架：构建一棵新树

骨骼是一种描述影响SkeletalMesh的骨骼树的资产。虽然构建新骨架（或向其添加骨骼）非常容易，但修改或销毁骨架始终是一项危险的操作。每当您需要更改骨骼树时，您应该始终生成一个新的骨架和相关的SkeletalMesh。

在此示例中，我们创建一个简单的骨架：

```python
import unreal_engine as ue
from unreal_engine import FTransform, FVector, FRotator
from unreal_engine.classes import Skeleton

new_skeleton = Skeleton()

# -1 as parent means we are the root bone (THERE CAN BE ONLY ONE ROOT BONE !)
root_bone_index = new_skeleton.skeleton_add_bone('root', -1, FTransform())

# add two bones to the root one
bone_left_index = new_skeleton.skeleton_add_bone('bone_left', root_bone_index, FTransform(FVector(0, -100, 100), FRotator(0, 0, 90)))
bone_right_index = new_skeleton.skeleton_add_bone('bone_right', root_bone_index, FTransform(FVector(0, 100, 100), FRotator(0, 0, 90)))

# add another to the left one
bone_last_index = new_skeleton.skeleton_add_bone('bone_last', bone_left_index, FTransform(FVector(0, 0, 200)))

new_skeleton.save_package('/Game/CustomSkeletons/Skel001')

ue.open_editor_for_asset(new_skeleton)
```

![骨头树](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/bone_tree.PNG)

请记住，您只能有一个根骨骼（Python api 将检查它，而 C++ 只会使编辑器崩溃）。每个骨骼都有其在创建骨骼时指定的“姿势”变换（主要用于重定向）

一旦构建了骨架，您可以简单地使用它（阅读：无需脚本）的唯一方法是将其分配给具有相同骨骼名称的骨架的网格体。嗯，有点没用：）

注意，如果你成功构建了一个无效的骨架，你可能会在编辑器中结束assert/crash.在紧急情况下（你的编辑器继续崩溃），只需从 Content/ 目录中手动删除包含损坏骨架的 .uasset 文件

<a id="skeletalmesh-bulding-from-static-meshes"></a>

## SkeletalMesh：从静态网格体构建

在开始操作骨架之前，我们希望能够使用骨架网格物体，因为没有它们，我们将无法看到我们的工作:)

骨架网格体由FSoftSkinVertex结构序列构建。这些结构保存经典的顶点信息（位置、法线、uv、材质索引...）以及骨骼对每个顶点的“影响”。一个顶点最多可以受到8 个骨骼的影响。

在此片段中，我们采用UE4立方体静态网格物体，并通过为立方体的每个面分配骨骼将其转换为SkeletalMesh。

```python
import unreal_engine as ue
from unreal_engine.classes import StaticMesh, SkeletalMesh, Skeleton
from unreal_engine import FVector, FTransform, FRotator, FSoftSkinVertex
import math

cube = ue.load_object(StaticMesh, '/Engine/BasicShapes/Cube')

skeleton = Skeleton()
# create the required bones (please always add a root bone first...)
root_bone = skeleton.skeleton_add_bone('root', -1, FTransform())
left_bone = skeleton.skeleton_add_bone('left', root_bone, FTransform(FVector(0, -50, 0), FRotator(0, 0, -90)))
right_bone = skeleton.skeleton_add_bone('right', root_bone, FTransform(FVector(0, 50, 0), FRotator(0, 0, 90)))
up_bone = skeleton.skeleton_add_bone('up', root_bone, FTransform(FVector(0, 0, 50), FRotator(0, 90, 0)))
down_bone = skeleton.skeleton_add_bone('down', root_bone, FTransform(FVector(0, 0, -50), FRotator(0, -90, 0)))
forward_bone = skeleton.skeleton_add_bone('forward', root_bone, FTransform(FVector(50, 0, 0), FRotator(0, 0, 0)))
backward_bone = skeleton.skeleton_add_bone('backward', root_bone, FTransform(FVector(-50, 0, 0), FRotator(0, 0, 180)))

skeleton.save_package('/Game/StaticToSkel/Cube_Skeleton')

mesh = SkeletalMesh()
mesh.skeletal_mesh_set_skeleton(skeleton)

# get raw data from static mesh
cube_raw = cube.get_raw_mesh()

# optimization: read the whole list of normals from the static mesh
# we will use normals to understand to which bone each vertex must be mapped
normals = cube_raw.get_wedge_tangent_z()

# the list of FSoftSkinVertex that will build the SkeletalMesh
vertices = []

# for 'wedge' UE4 means the group of infos (position, normals, uvs...) of a single vertex
for wedge in range(0, cube_raw.get_wedges_num()):
    # get the vertex normal using the wedge as the list index
    normal = normals[wedge]

    # we use the dot product to recognize the direction of the vertex/face
    dot_product_fwd = normal.dot(FVector(1, 0, 0))
    dot_product_right = normal.dot(FVector(0, 1, 0))
    dot_product_up = normal.dot(FVector(0, 0, 1))

    # create a new FSoftSkinvertex struct, we fill only the position, normal and influences
    # uvs are left to the reader :)
    v = FSoftSkinVertex()
    v.position = cube_raw.get_wedge_position(wedge)
    v.tangent_z = normal
    
    # by default a vertex has no infuences
    bone_index = 0
    influence = 0

    if math.isclose(dot_product_up, 1, abs_tol=0.0001):
        bone_index = up_bone
        influence = 255
    elif math.isclose(dot_product_up, -1, abs_tol=0.0001):
        bone_index = down_bone
        influence = 255
    elif math.isclose(dot_product_right, 1, abs_tol=0.0001):
        bone_index = right_bone
        influence = 255
    elif math.isclose(dot_product_right, -1, abs_tol=0.0001):
        bone_index = left_bone
        influence = 255
    elif math.isclose(dot_product_fwd, 1, abs_tol=0.0001):
        bone_index = forward_bone
        influence = 255
    elif math.isclose(dot_product_fwd, -1, abs_tol=0.0001):
        bone_index = backward_bone
        influence = 255

    v.influence_bones = (bone_index, 0, 0, 0, 0, 0, 0, 0)
    v.influence_weights = (influence, 0, 0, 0, 0, 0, 0, 0)

    vertices.append(v)

# build LOD0 for the StaticMesh using a list of FSoftSkinVertex
mesh.skeletal_mesh_build_lod(vertices)
mesh.save_package('/Game/StaticToSkel/Cube_Mesh')

ue.open_editor_for_asset(mesh)
```

![立方体骨架](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/cube_skel.PNG)

尝试translating/rotating每个骨骼以查看结果。

如果您对 dot_product 部分感到困惑，这是一种了解两个向量是否指向同一方向的方法。如果点积的结果接近1，则两个向量（几乎）指向同一方向，-1表示它们指向相反的方向。

在脚本中，UVs不被尊重（它们都是零）。请记住，一个网格可以有多个 UV 通道，因此 FRawMesh 的 get_wedge_tex_coords() 方法返回一个列表列表，而 FSoftSkinVertex() 的 'uvs' 字段需要一个元组的元组：

```
v.uvs = ((u0, v0), (u1, v1), ...)
```

<a id="skeletalmesh-sections"></a>

## SkeletalMesh：部分

SkeletalMesh 的每个 LOD 可以由多个部分组成。每个部分都可以分配不同的材料，因此从技术上讲，每个部分都需要进行抽奖。

部分是通过遵循 FSoftSkinVertex 的 material_index 字段自动生成的。注意：此行为特定于 python 插件，C++ api 的工作方式截然不同。

我们将前面的示例（骨架立方体）更改为每个面都有一个部分（这样您就可以将不同的材质映射到每个面）：

```python
import unreal_engine as ue
from unreal_engine.classes import StaticMesh, SkeletalMesh, Skeleton
from unreal_engine import FVector, FTransform, FRotator, FSoftSkinVertex
from unreal_engine.structs import SkeletalMaterial, MeshUVChannelInfo
import math

cube = ue.load_object(StaticMesh, '/Engine/BasicShapes/Cube')

skeleton = Skeleton()
# create the required bones (please always add a root bone first...)
root_bone = skeleton.skeleton_add_bone('root', -1, FTransform())
left_bone = skeleton.skeleton_add_bone('left', root_bone, FTransform(FVector(0, -50, 0), FRotator(0, 0, -90)))
right_bone = skeleton.skeleton_add_bone('right', root_bone, FTransform(FVector(0, 50, 0), FRotator(0, 0, 90)))
up_bone = skeleton.skeleton_add_bone('up', root_bone, FTransform(FVector(0, 0, 50), FRotator(0, 90, 0)))
down_bone = skeleton.skeleton_add_bone('down', root_bone, FTransform(FVector(0, 0, -50), FRotator(0, -90, 0)))
forward_bone = skeleton.skeleton_add_bone('forward', root_bone, FTransform(FVector(50, 0, 0), FRotator(0, 0, 0)))
backward_bone = skeleton.skeleton_add_bone('backward', root_bone, FTransform(FVector(-50, 0, 0), FRotator(0, 0, 180)))

skeleton.save_package('/Game/StaticToSkel/Cube_Skeleton')

mesh = SkeletalMesh()
mesh.skeletal_mesh_set_skeleton(skeleton)

# get raw data from static mesh
cube_raw = cube.get_raw_mesh()

# optimization: read the whole list of normals from the static mesh
# we will use normals to understand to which bone each vertex must be mapped
normals = cube_raw.get_wedge_tangent_z()

# the list of FSoftSkinVertex that will build the SkeletalMesh
vertices = []

# for 'wedge' UE4 means the group of infos (position, normals, uvs...) of a single vertex
for wedge in range(0, cube_raw.get_wedges_num()):
    # get the vertex normal using the wedge as the list index
    normal = normals[wedge]

    # we use the dot product to recognize the direction of the vertex/face
    dot_product_fwd = normal.dot(FVector(1, 0, 0))
    dot_product_right = normal.dot(FVector(0, 1, 0))
    dot_product_up = normal.dot(FVector(0, 0, 1))

    # create a new FSoftSkinvertex struct, we fill only the position, normal and influences
    # uvs are left to the reader :)
    v = FSoftSkinVertex()
    v.position = cube_raw.get_wedge_position(wedge)
    v.tangent_z = normal
    
    # by default a vertex has no infuences
    bone_index = 0
    influence = 0
    section = 0

    if math.isclose(dot_product_up, 1, abs_tol=0.0001):
        bone_index = up_bone
        influence = 255
        section = 0
    elif math.isclose(dot_product_up, -1, abs_tol=0.0001):
        bone_index = down_bone
        influence = 255
        section = 1
    elif math.isclose(dot_product_right, 1, abs_tol=0.0001):
        bone_index = right_bone
        influence = 255
        section = 2
    elif math.isclose(dot_product_right, -1, abs_tol=0.0001):
        bone_index = left_bone
        influence = 255
        section = 3
    elif math.isclose(dot_product_fwd, 1, abs_tol=0.0001):
        bone_index = forward_bone
        influence = 255
        section = 4
    elif math.isclose(dot_product_fwd, -1, abs_tol=0.0001):
        bone_index = backward_bone
        influence = 255
        section = 5

    v.material_index = section
    v.influence_bones = (bone_index, 0, 0, 0, 0, 0, 0, 0)
    v.influence_weights = (influence, 0, 0, 0, 0, 0, 0, 0)

    vertices.append(v)

# build LOD0 for the StaticMesh using a list of FSoftSkinVertex
mesh.skeletal_mesh_build_lod(vertices)

# create material slots, UVChannelData field is required !
mesh.Materials = [
    SkeletalMaterial(MaterialSlotName='Up', UVChannelData=MeshUVChannelInfo(bInitialized=True)),
    SkeletalMaterial(MaterialSlotName='Down', UVChannelData=MeshUVChannelInfo(bInitialized=True)),
    SkeletalMaterial(MaterialSlotName='Right', UVChannelData=MeshUVChannelInfo(bInitialized=True)),
    SkeletalMaterial(MaterialSlotName='Left', UVChannelData=MeshUVChannelInfo(bInitialized=True)),
    SkeletalMaterial(MaterialSlotName='Forward', UVChannelData=MeshUVChannelInfo(bInitialized=True)),
    SkeletalMaterial(MaterialSlotName='Backward', UVChannelData=MeshUVChannelInfo(bInitialized=True)),
    ]

mesh.save_package('/Game/StaticToSkel/Cube_Mesh')

ue.open_editor_for_asset(mesh)
```

![立方体骨架剖面](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/cube_skel_sections.PNG)

除了 material_index 字段之外，我们还直接从脚本创建材质槽（显然您可以手动执行），否则编辑器中的“部分”区域将不会出现，直到您创建相关材质槽。

<a id="skeleton-renaming-bones"></a>

## 骨骼：重命名骨骼

由于我们现在能够构建SkeletalMeshes，因此我们可以开始重命名和操作骨骼，而不会导致编辑器崩溃。

在此示例中，我们获取原始网格，复制它（通过打开一个向导询问用户在哪里保存新资源），然后通过将每个骨骼大写并反转来重命名它：


```python
import unreal_engine as ue
from unreal_engine.classes import Skeleton, SkeletalMesh

original_mesh = ue.get_selected_assets()[0]

if not original_mesh.is_a(SkeletalMesh):
    raise DialogException('the script only works with Skeletal Meshes')

# open a dialog for saving assets, it returns a full path
new_path = ue.create_modal_save_asset_dialog('Choose destination path', '/Game')
# get the package name part from the full path
package_name = ue.object_path_to_package_name(new_path)
# get the object name from the full path
object_name = ue.get_base_filename(new_path)

original_skeleton = original_mesh.Skeleton

# add the _Skeleton suffix to the asset, we use a package-per-asset like suggested by UE4 pipeline best-practices
new_skeleton = Skeleton('{0}_Skeleton'.format(object_name), ue.get_or_create_package('{0}_Skeleton'.format(package_name)))

# iterate each bone and rename it
for bone_index in range(0, original_skeleton.skeleton_bones_get_num()):
    # get the index of the parent bone
    parent_index = original_skeleton.skeleton_get_parent_index(bone_index)
    # get the transform of the bone
    bone_transform = original_skeleton.skeleton_get_ref_bone_pose(bone_index)
    # get the bone name
    bone_name = original_skeleton.skeleton_get_bone_name(bone_index)
    # create the new bone by uppercasing the original one and reversing it
    new_skeleton.skeleton_add_bone(bone_name.upper()[::-1], parent_index, bone_transform)

new_skeleton.save_package()

# the last True argument, allows for overwrite
new_mesh = original_mesh.duplicate(package_name, object_name, True)
# assign the new skeleton to the mesh. THIS WORKS ONLY BECAUSE THE NUMBER OF BONES IS >= than the original one
new_mesh.skeletal_mesh_set_skeleton(new_skeleton)

new_mesh.save_package()

ue.open_editor_for_asset(new_mesh)
```

![重命名骨头](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/renamed_bones.PNG)

使用 skeletal_mesh_set_skeleton(new_skeleton) 方法就足够了，因为新骨架中的骨骼数量与原始骨骼中的骨骼数量相等（或更高，事实上您可以向脚本中添加更多骨骼）。

如果你需要移除骨骼，或者更一般地说，你需要改变骨架的结构树，你需要相应地更新SkeletalMesh。

在下面的示例中，我们将骨架减少为三个骨骼（根、上、下），并根据每个顶点的 z 值将每个顶点映射到“上”或“下”：

```python
import unreal_engine as ue
from unreal_engine.classes import Skeleton, SkeletalMesh
from unreal_engine import FTransform, FVector

original_mesh = ue.get_selected_assets()[0]

if not original_mesh.is_a(SkeletalMesh):
    raise DialogException('the script only works with Skeletal Meshes')

new_path = ue.create_modal_save_asset_dialog('Choose destination path', '/Game')
package_name = ue.object_path_to_package_name(new_path)
object_name = ue.get_base_filename(new_path)


new_skeleton = Skeleton('{0}_Skeleton'.format(object_name), ue.get_or_create_package('{0}_Skeleton'.format(package_name)))

root_bone = new_skeleton.skeleton_add_bone('root', -1, FTransform())
down_bone = new_skeleton.skeleton_add_bone('down', root_bone, FTransform(FVector(0, 0, 100)))
up_bone = new_skeleton.skeleton_add_bone('up', down_bone, FTransform(FVector(0, 0, 100)))

new_skeleton.save_package()

new_mesh = SkeletalMesh(object_name, ue.get_or_create_package(package_name))
# we can assign a skeleton safely as the mesh is empty
new_mesh.skeletal_mesh_set_skeleton(new_skeleton)

# iterate each LOD of the mesh
for lod_id in range(0, original_mesh.skeletal_mesh_lods_num()):
    # get the FSoftSkinVertex list of the whole LOD (the same structure you can pass to skeletal_mesh_build_lod())
    vertices = original_mesh.skeletal_mesh_get_lod(lod_id)
    # assign bone to vertex based on vertical position
    for v in vertices:
        if v.position.z <= 100.0:
            bone_index = down_bone
        else:
            bone_index = up_bone
            
        v.influence_bones = (bone_index, 0, 0, 0, 0, 0, 0, 0)
        v.influence_weights = (255, 0, 0, 0, 0, 0, 0, 0)

    new_mesh.skeletal_mesh_build_lod(vertices, lod_id)

# copy material slots
new_mesh.Materials = original_mesh.Materials

new_mesh.save_package()

ue.open_editor_for_asset(new_mesh)
```

![人体模型重新骨骼化](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/mannequin_reskeleted.PNG)

<a id="skeleton-sockets"></a>

## 骨架：插槽

管理套接字仅需要使用SkeletalMeshSocket类。

在此示例中，给定一个骨架，我们为每个骨骼添加一个套接字（注意：此脚本就地工作，因此原始文件将被修改）：

```python
import unreal_engine as ue
from unreal_engine.classes import Skeleton, SkeletalMeshSocket
from unreal_engine import FVector, FRotator

skeleton = ue.get_selected_assets()[0]

current_sockets = skeleton.Sockets
new_sockets = []

if not skeleton.is_a(Skeleton):
    raise DialogException('the script only works with Skeletons')

# iterate each bone and add a random socket to it
for bone_index in range(0, skeleton.skeleton_bones_get_num()):
    bone_name = skeleton.skeleton_get_bone_name(bone_index)

    # SkeletalMeshSocket outer must be set to the related Skeleton
    new_socket = SkeletalMeshSocket('', skeleton)
    new_socket.SocketName = 'dumb_socket_for_bone_{0}'.format(bone_name)
    new_socket.BoneName = bone_name
    new_socket.RelativeLocation = FVector(17, 22, 30)
    new_socket.RelativeRotation = FRotator(0.17, 0.22, 0.30)
    new_socket.RelativeScale = FVector(1, 1, 1)
    
    new_sockets.append(new_socket)

# set the new sockets list
skeleton.Sockets = current_sockets + new_sockets

skeleton.save_package()

ue.open_editor_for_asset(skeleton)
```

![套接字](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/sockets.PNG)

<a id="skeletalmesh-merging"></a>

## SkeletalMesh：合并

这是一个非常疯狂的例子，但将重点关注一个非常重要的要求：骨骼名称在骨架中必须是唯一的

这里我们取一个SkeletalMesh并将其“加倍”，注意重命名每个骨骼。新树将有一个根，后面跟着两个“相对根”，每个根都与整个骨骼树相关。由于解释起来相当复杂，这次最好先展示一下之前的屏幕截图：

![合并骷髅](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/merged_skel.PNG)

```python
import unreal_engine as ue
from unreal_engine.classes import Skeleton, SkeletalMesh
from unreal_engine import FTransform

original_mesh = ue.get_selected_assets()[0]

if not original_mesh.is_a(SkeletalMesh):
    raise DialogException('the script only works with Skeletal Meshes')

new_path = ue.create_modal_save_asset_dialog('Choose destination path', '/Game')
package_name = ue.object_path_to_package_name(new_path)
object_name = ue.get_base_filename(new_path)

original_skeleton = original_mesh.Skeleton

new_skeleton = Skeleton('{0}_Skeleton'.format(object_name), ue.get_or_create_package('{0}_Skeleton'.format(package_name)))

root_bone = new_skeleton.skeleton_add_bone('root', -1, FTransform())

# add a whole new skeleton tree to the main one
# all of the old roots of sub-skeletons are attached to the main root
def add_tree(suffix):
    for bone_index in range(0, original_skeleton.skeleton_bones_get_num()):
        # get the bone name
        bone_name = original_skeleton.skeleton_get_bone_name(bone_index)
        # fix name
        bone_name = '{0}_{1}'.format(bone_name, suffix)
        # get the transform of the bone
        bone_transform = original_skeleton.skeleton_get_ref_bone_pose(bone_index)
        # get the index of the parent bone
        parent_index = original_skeleton.skeleton_get_parent_index(bone_index)
        # if the parent is -1, use 0, otherwise search in the current tree
        if parent_index == -1:
            parent_index = root_bone
        else:
            original_parent_name = original_skeleton.skeleton_get_bone_name(parent_index)
            parent_name = '{0}_{1}'.format(original_parent_name, suffix)
            parent_index = new_skeleton.skeleton_find_bone_index(parent_name)
        new_skeleton.skeleton_add_bone(bone_name, parent_index, bone_transform)


# add firt skeleton
add_tree('OfFirstModel')
# add the second skeleton
add_tree('OfSecondModel')

new_skeleton.save_package()

new_mesh = SkeletalMesh(object_name, ue.get_or_create_package(package_name))

new_mesh.skeletal_mesh_set_skeleton(new_skeleton)

vertices = original_mesh.skeletal_mesh_get_lod()
merged_vertices = []

# given the original index and a suffix, return the new bone index
def get_new_bone_index(index, suffix):
    bone_name = original_skeleton.skeleton_get_bone_name(index)
    # fix name
    bone_name = '{0}_{1}'.format(bone_name, suffix)
    return new_skeleton.skeleton_find_bone_index(bone_name)

# fix bones indices for the first mesh
for vertex in vertices:
    bones = list(vertex.influence_bones)
    for i in range(0, 8):
        bones[i] = get_new_bone_index(vertex.influence_bones[i], 'OfFirstModel')
    v = vertex.copy()
    v.influence_bones = bones
    merged_vertices.append(v)

# fix bones indices for the second mesh
for vertex in vertices:
    bones = list(vertex.influence_bones)
    for i in range(0, 8):
        bones[i] = get_new_bone_index(vertex.influence_bones[i], 'OfSecondModel')
    v = vertex.copy()
    v.influence_bones = bones
    merged_vertices.append(v)

new_mesh.skeletal_mesh_build_lod(merged_vertices)

new_mesh.save_package()

ue.open_editor_for_asset(new_mesh)
```

请注意，打开骨架编辑器时，所有生成的骨骼都将“正在使用”。如果您只想标记活动骨骼，请将包含所有有效索引的列表传递给 SkeletalMesh 对象的 skeletal_mesh_set_active_bones() 方法。

<a id="skeletalmesh-vertex-colors-and-lods"></a>

## SkeletalMesh：顶点颜色和 LOD

即使对于骨架网格物体，您也可以使用顶点颜色。与StaticMesh不同，它们必须显式启用。

在此示例中，我们创建一个具有 4 LOD 的 SkeletalMesh，每个 LOD 具有不同的顶点颜色值。单击 SkeletalMesh 编辑器的“显示”菜单，然后选择“顶点颜色”以查看颜色。

```python
import unreal_engine as ue
from unreal_engine.classes import SkeletalMesh
from unreal_engine import FColor
import random

original_mesh = ue.get_selected_assets()[0]

if not original_mesh.is_a(SkeletalMesh):
    raise DialogException('the script only works with Skeletal Meshes')

new_path = ue.create_modal_save_asset_dialog('Choose destination path', '/Game')
package_name = ue.object_path_to_package_name(new_path)
object_name = ue.get_base_filename(new_path)

# get original vertex data
vertices = original_mesh.skeletal_mesh_get_lod()

# the last True argument, allows for overwrite
new_mesh = original_mesh.duplicate(package_name, object_name, True)

# inform UE4 that this SkeletalMesh has vertex colors
new_mesh.bHasVertexColors = True

# random colors (LOD 0, overwrites the original one)
for vertex in vertices:
    vertex.color = FColor(random.randrange(0, 256), random.randrange(0, 256), random.randrange(0, 256))
new_mesh.skeletal_mesh_build_lod(vertices, 0)

# blue gradient based on vertex z value (LOD 1)
for vertex in vertices:
    vertex.color = FColor(0, 0, int(vertex.position.z % 255))
new_mesh.skeletal_mesh_build_lod(vertices, 1)

# red (LOD 2)
for vertex in vertices:
    vertex.color = FColor(255, 0, 0)
new_mesh.skeletal_mesh_build_lod(vertices, 2)

# green (LOD 3)
for vertex in vertices:
    vertex.color = FColor(0, 255, 0)
new_mesh.skeletal_mesh_build_lod(vertices, 3)

new_mesh.save_package()

ue.open_editor_for_asset(new_mesh)
```

![骨架颜色](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/skel_colors.PNG)

请注意，此示例使用网格的原始骨架。对于现实世界的情况，最好也复制骨架并分配给新的网格，如前所述。

<a id="skeletalmesh-building-from-collada"></a>

## SkeletalMesh：从 Collada 构建

已经有一个将 collada 文件导入为静态网格物体的教程 (https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython.md)。此代码片段展示了如何导入骨架网格物体。您可以将两者结合起来构建一个功能齐全的导入器。

这里的主要话题是如何处理矩阵。 Collada 文件将骨骼信息公开为 4x4 列主要矩阵。可以通过按照 UE4 约定（行优先）向其传递 4x4 矩阵来构建 FTransform 对象。 Collada 显然遵循 OpenGL 约定（列主），因此我们需要转置所有矩阵。 pycollada 模块以 numpy 数组的形式返回矩阵，因此除了转置之外，我们还需要将它们展平（FTransform需要一个16浮点元素的简单迭代器）。

记得安装 pycollada 模块：

```
pip install pycollada
```

这是代码，注意这次我们不保存资产。所有对象都是暂时的（存储它们留作练习）。

检查我们需要如何修复UVs，因为UE4不使用左下角的texcoords原点的OpenGL约定（该死，这开始变得烦人了。）。有关切换约定的更多信息，请参见以下有关 ThreeJS 模型的片段。

```python
import unreal_engine as ue
from unreal_engine.classes import Skeleton, SkeletalMesh
from unreal_engine import FTransform, FSoftSkinVertex, FVector, FRotator, FQuat

from collada import Collada
import numpy

class ColladaLoader:

    def __init__(self, filename):
        self.dae = Collada(filename)
        self.controller = self.dae.controllers[0]
        # while i love quaternions, building them from euler rotations
        # looks generally easier to the reader...
        # this rotation is required for fixing the inverted Z axis on
        # bone positions. As bind pose should have rotations set to 0
        # we will apply this quaternion directly to bone positions
        self.base_quaternion = FRotator(0, 180, 180).quaternion()
        self.skeleton = self.get_skeleton()
        self.mesh = self.get_mesh(self.controller.geometry)
        
    def get_skeleton(self):
        # this mapping will allows us to fast retrieve a bone index, given its name
        # instead of relying on UE4 api
        self.bone_mapping = {}
        for scene in self.dae.scenes:
            # find the first node of type 'JOINT'
            for node in scene.nodes:
                if node.xmlnode.attrib.get('type', None) == 'JOINT':
                    self.skeleton = Skeleton()
                    self.traverse_hierarchy(node, FTransform(), -1)
                    return self.skeleton

    def traverse_hierarchy(self, node, parent_transform, parent_id):
        transform = FTransform(self.controller.joint_matrices[node.id].transpose().flatten())
        v0 = transform.translation
        q0 = transform.quaternion

        # fix axis from OpenGL to UE4 (note the quaternion multiplication that we use instead of inverting the z)
        transform.translation = FVector(v0.z, v0.x, v0.y) * self.base_quaternion
        transform.quaternion = FQuat(q0[2], q0[0] * -1, q0[1] * -1, q0[3])

        # each bone in collada is in world position (while unreal wants relative positions), we 'subtract' here the parent position
        relative_transform = transform * parent_transform.inverse()
        
        parent_id = self.skeleton.skeleton_add_bone(node.id, parent_id, relative_transform)
        # used for fast joint mapping
        self.bone_mapping[node.id] = parent_id
        for child in node.children:
            if child.xmlnode.attrib.get('type', None) == 'JOINT':
                self.traverse_hierarchy(child, transform, parent_id)

    def get_mesh(self, geometry):
        print(self.bone_mapping)
        self.mesh = SkeletalMesh()
        self.mesh.skeletal_mesh_set_skeleton(self.skeleton)
        triset = geometry.primitives[0]
        # the numpy.ravel function, completely flatten an array
        vertices = numpy.ravel(triset.vertex[triset.vertex_index])
        uvs = numpy.ravel(triset.texcoordset[0][triset.texcoord_indexset[0]])
        normals = numpy.ravel(triset.normal[triset.normal_index])
        # currently pycollada has no shortcuts for bones list
        bones = []
        weights = []
        for index in triset.vertex_index:
            influence_bones = []
            influence_weights = []
            for influence in self.controller.index[index]:
                influence_bones.append(self.bone_mapping[self.controller.weight_joints[influence[0]]])
                weight_value = int(self.controller.weights[influence[1]] * 255)
                # hack for avoiding required bones to be skipped
                # most of file weights will result in 254 instead of 255 (this is caused by float instability)
                if weight_value == 0:
                    weight_value = 1
                influence_weights.append(weight_value)
            bones.append(influence_bones)
            weights.append(influence_weights)
        soft_vertices = self.build_soft_vertices(vertices, uvs, normals, bones, weights)
        self.mesh.skeletal_mesh_build_lod(soft_vertices)
        return self.mesh
        
    def build_soft_vertices(self, vertices, uvs, normals, bones, weights):
        soft_vertices = []
        for i in range(0, len(vertices), 3):
           v = FSoftSkinVertex()
           xv, yv, zv = vertices[i], vertices[i+1], vertices[i+2]
           # invert forward
           v.position = FVector(zv * -1, xv, yv)
           xn, yn, zn = normals[i], normals[i+1], normals[i+2]
           # invert forward
           v.tangent_z = FVector(zn * -1, xn, yn)

           # get uv index
           uv_index = int(i / 3 * 2)
           # fix uvs from 0 on bottom to 0 on top
           v.uvs = [(uvs[uv_index], 1 - uvs[uv_index+1])]

           # get joint index
           joint_index = int(i / 3)
           # fix a special condition where the first bone has zero weight
           # but there are multiple influences. This is required as UE4 automatically
           # modify the first bone if weight normalization fails
           new_best_index = weights[joint_index].index(max(weights[joint_index]))
           if new_best_index > 0:
               first_bone = bones[joint_index][new_best_index]
               first_weight = weights[joint_index][new_best_index]
               bones[joint_index][new_best_index] = bones[joint_index][0]
               weights[joint_index][new_best_index] = weights[joint_index][0]
               bones[joint_index][0] = first_bone
               weights[joint_index][0] = first_weight
           v.influence_bones = bones[joint_index]
           v.influence_weights = weights[joint_index]
           soft_vertices.append(v)

        return soft_vertices

filename = ue.open_file_dialog('Choose a Collada file', '', '', 'Collada|*.dae;')[0]
loader = ColladaLoader(filename)
ue.open_editor_for_asset(loader.skeleton)
```

UE4 中有关关节管理的说明。

Unreal 期望每个顶点权重都被标准化。这意味着它们的总和必须为255（FSoftSkinVertex的最大值）。如果总和不是255，UE4将自动将所需的权重添加到第一个骨骼影响中。

此行为可能会导致由浮动错误生成的恼人错误（Collada 将骨骼权重公开为0..1范围内的浮动值）。

例如，大多数顶点的总权重将为254（而不是255），并且（更糟糕），Collada 不会强制第一个影响力成为具有最高值的影响力。

出于这两个原因，我们将 1 添加到 0 权重（collada 文件不会报告权重为 0 的骨骼影响，因此我们是安全的），更重要的是，我们以第一个始终是权重较高的方式重新排序骨骼影响（更多信息请参见代码注释）：

```python
           new_best_index = weights[joint_index].index(max(weights[joint_index]))
           if new_best_index > 0:
               first_bone = bones[joint_index][new_best_index]
               first_weight = weights[joint_index][new_best_index]
               bones[joint_index][new_best_index] = bones[joint_index][0]
               weights[joint_index][new_best_index] = weights[joint_index][0]
               bones[joint_index][0] = first_bone
               weights[joint_index][0] = first_weight
           v.influence_bones = bones[joint_index]
           v.influence_weights = weights[joint_index]
```

如果一切顺利，您将最终正确加载模型（屏幕截图显示 mixamo 导出的模型）：

![Collada](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/collada.PNG)

正如您可能已经在评论中注意到的，collada 文件中的 joints/bones 矩阵是相对于世界的，而 UE4 期望每个骨骼都相对于父级。因此，我们将每个矩阵与其父矩阵的逆矩阵相乘。

<a id="skeletalmesh-morph-targets"></a>

## SkeletalMesh：变形目标

变形目标（或混合形状）是一种简单的动画形式，其中特定顶点（最终是其法线）被转换到新位置。通过插入从默认位置到变形目标定义的新位置的过渡，您可以生成动画。变形目标在面部动画中很常见，或者更一般地，当对象必须严重变形时。

以下屏幕截图显示了从0（插值）到1的面部变形目标：

![将0变形为1](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/morph_0_to_1.PNG)

在代码片段中，我们生成一个映射到单个骨骼的简单三角形，并为其顶点 1 分配一个变形目标，该目标在 z 轴上向上移动顶点 100 单位：

```python
import unreal_engine as ue
from unreal_engine.classes import Skeleton, SkeletalMesh, MorphTarget
from unreal_engine import FTransform, FVector, FSoftSkinVertex, FMorphTargetDelta

skel = Skeleton()

root_bone_index = skel.skeleton_add_bone('root', -1, FTransform())

skel.save_package('/Game/Snippets/Triangle001_Skeleton')

vertices = []

v = FSoftSkinVertex()
v.position = FVector(0, 0, 0)
# UE4 supports up to 8 bone influences
# the influence value goes from 0 (no influence) to 255 (full influence)
v.influence_weights = (255, 0, 0, 0, 0, 0, 0)
v.influence_bones = (root_bone_index, 0, 0, 0, 0, 0, 0)

vertices.append(v)

v = FSoftSkinVertex()
v.position = FVector(100, 100, 0)
v.influence_weights = (255, 0, 0, 0, 0, 0, 0)
v.influence_bones = (root_bone_index, 0, 0, 0, 0, 0, 0)

vertices.append(v)

v = FSoftSkinVertex()
v.position = FVector(100, 0, 0)
v.influence_weights = (255, 0, 0, 0, 0, 0, 0)
v.influence_bones = (root_bone_index, 0, 0, 0, 0, 0, 0)

vertices.append(v)

mesh = SkeletalMesh()
mesh.skeletal_mesh_set_skeleton(skel)

# build a new skeletal mesh from the vertices list
mesh.skeletal_mesh_build_lod(vertices)

# a MorphTarget must have its SkeletalMesh as outer
# leaving the first string as empty will generate a unique name (often the safest choice)
morph = MorphTarget('', mesh)

# a FMorphTargetDelta structure describes how much a vertex (and/or its normal) must be translated
delta = FMorphTargetDelta()
delta.position_delta = FVector(0, 0, 100)
# this is the id of the vertex to morph, pay attention, this is the internal vertex id
# that could be different from the original one (its index in the 'vertices' list)
# to get the mapping between original and internal id, you can use skeletal_mesh_to_import_vertex_map()
delta.source_idx = 1

# always check for True return value, UE4 could decide to not
# import a morph delta if the translation is too little
if morph.morph_target_populate_deltas([delta]):
    mesh.skeletal_mesh_register_morph_target(morph)

mesh.save_package('/Game/Snippets/Triangle001_Mesh')

# open the asset editor for SkeletalMesh
ue.open_editor_for_asset(mesh)
```

注意“delta.source_idx”值，因为在较大的网格上它无法映射到原始网格（请参阅下一个片段）

![变形三角形](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/morph_target.PNG)

<a id="animations-root-motion-from-svg-path"></a>

## 动画：来自 SVG 路径的根运动

这个有趣的示例从 SVG 文件构建动画。

动画将仅包含运动轨迹（针对根骨骼），并将根据 SVG 文件中找到的第一条路径曲线设置关键点。

您可以使用令人惊叹的 Inkscape 来绘制贝塞尔曲线：

![贝塞尔曲线](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/bezier.PNG)

要解析 svg 路径，您需要一个外部 python 模块 (https://pypi.python.org/pypi/svgpathtools)。

```
pip install svgpathtools svgwrite numpy
```

svgpathtools 将 SVG 曲线转换为 numpy 多项式数组，因此我们可以访问特定时间的点值（如果您愿意，也可以访问梯度）：

```python
import unreal_engine as ue
from unreal_engine.classes import AnimSequenceFactory, Skeleton
from unreal_engine import FRawAnimSequenceTrack, FVector, FQuat, FRotator
from svgpathtools import svg2paths
import numpy

# use the currently selected skeleton
skeleton = ue.get_selected_assets()[0]

# open file dialog to choose the file (returns a list so we get only the first element)
paths, attributes = svg2paths(ue.open_file_dialog('Open SVG file', '', '', 'Scalable Vector Graphics|*.svg;')[0])

# an SVG file can contains multiple paths, just get the first one
path = paths[0]

# how many frame per second ?
fps = 30
# the duration of the animation
duration = 10
# scale size
scale = 3

factory = AnimSequenceFactory()
factory.TargetSkeleton = skeleton

anim = factory.factory_create_new('/Game/BezierAnimation001')
anim.NumFrames = duration * fps
anim.SequenceLength = duration
# enable root motion
anim.bEnableRootMotion = True

pos_keys = []
for t in numpy.arange(0, 1, 1.0/fps/duration):
    # get the point at specific time
    point = path.point(t)
    x, y = point.real, point.imag
    pos_keys.append(FVector(x, y, 0) * scale)

# add the track for the root bone
track = FRawAnimSequenceTrack()
track.pos_keys = pos_keys
track.rot_keys = [FQuat()]
anim.add_new_raw_track('root', track)

anim.save_package()
ue.open_editor_for_asset(anim)
```

由于我们启用了根运动，一旦我们播放动画（如果您使用动画蓝图，请记住也启用根运动），角色就会移动。

这是一个调试会话，其中角色在其位置下绘制了一个点

![根运动](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/root_motion.PNG)

您可以从这里下载示例 svg：https://raw.githubusercontent.com/20tab/UnrealEnginePython/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/bezier_path.svg

<a id="animations-parsing-threejs-json-models-version-3"></a>

## 动画：解析 ThreeJS json 模型（版本 3）

这是一个相当大的脚本，它将把 ThreeJS json 模型文件导入到 Unreal Engine 4 中。

我们鼓励您将其实现为工厂，如下所述：https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython.md

您可以从这里下载脚本：https://raw.githubusercontent.com/20tab/UnrealEnginePython/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/threejs_importer.py

示例模型是经典的knight.js（格式3）：https://raw.githubusercontent.com/20tab/UnrealEnginePython/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/knight.js

运行脚本后，您将以带有动画的 SkeletalMesh 和 3 变形目标结束：

![骑士](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/knight.PNG)

![骑士变形](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/knight_morph.PNG)

代码中唯一相关的部分是（有点复杂）我们从基于OpenGL的约定（y在上，x右，z向前右手，逆时针背面剔除）转向UE4约定（z在上，x向前左手，y右，顺时针背面剔除）的方式

这个方法就是我们构建骨架的方法：

```python
    def build_skeleton(self, pkg_name, obj_name):
        pkg = ue.get_or_create_package('{0}_Skeleton'.format(pkg_name))
        skel = Skeleton('{0}_Skeleton'.format(obj_name), pkg)
        # add a root bone from which all of the others will descend 
        # (this trick will avoid generating an invalid skeleton [and a crash], as in UE4 only one root can exist)
        skel.skeleton_add_bone('root', -1, FTransform())
        # iterate bones in the json file, note that we move from opengl axis to UE4
        # (y on top, x right, z forward right-handed) to (y right, x forward left-handed, z on top)
        for bone in self.model['bones']:
            # assume no rotation
            quat = FQuat()
            # give priority to quaternions
            # remember to negate x and y axis, as we invert z on position
            if 'rotq' in bone:
                quat = FQuat(bone['rotq'][2], bone['rotq'][0] * -1,
                             bone['rotq'][1] * -1, bone['rotq'][3])
            elif 'rot' in bone:
                quat = FRotator(bone['rot'][2], bone['rot'][0] - 180
                                , bone['rot'][1] - 180).quaternion()
            pos = FVector(bone['pos'][2] * -1, bone['pos'][0],
                          bone['pos'][1]) * self.scale
            # always set parent+1 as we added the root bone before
            skel.skeleton_add_bone(
                bone['name'], bone['parent'] + 1, FTransform(pos, quat))
        skel.save_package()
        return skel
```

正如您所看到的，我们更改平移的轴映射（x 变为 y，y 变为 z，z 变为反转的 x），同时反转俯仰和滚动以进行旋转。我们总是优先考虑四元数，因为它们更坚固（尽管更难掌握，下一个片段将展示为什么它们比普通的rotators/euler旋转要好得多）

另一个重要部分是我们如何处理变形目标。在内部，MorphTarget对象的source_idx字段（如前所述）映射到一个优化索引，该索引与我们创建软顶点数组时使用的索引不同。幸运的是，UE4公开了一个数组，其中包含优化索引和原始索引之间的映射：

```python
...
# get the mapping
import_map = self.mesh.skeletal_mesh_to_import_vertex_map()

# iterate mapping
for idx, import_index in enumerate(import_map):
    # get the true index for accessing soft vertices data, use idx for source_idx
    vertex_index = original_vertices[import_index]
    ...
    morph_target.source_idx = idx
    ...
```

最后，虚幻中的动画具有固定数量的帧，而通常我们只有关键帧（时间和值的元组）。

因此，常见的操作是从一系列非线性关键帧生成新的关键帧。 numpy.interp() 函数非常方便，以下代码片段展示了我们如何从一系列基于非线性向量的关键帧中获取特定时间的向量。

```python
    def interpolate_vector(self, timeline, t):
        keys = []
        x_values = []
        y_values = []
        z_values = []
        for key, value in timeline:
            keys.append(key)
            x_values.append(value[0])
            y_values.append(value[1])
            z_values.append(value[2])

        x = numpy.interp(t, keys, x_values)
        y = numpy.interp(t, keys, y_values)
        z = numpy.interp(t, keys, z_values)
        return FVector(x, y, z)
```

请记住，您可以对四元数使用相同的方法，但不能对旋转器使用！

<a id="animations-getting-curves-from-bvh-files"></a>

## 动画：从 BVH 文件获取曲线

BVH 文件之所以有趣有很多原因。首先，BVH 基本上是动作捕捉设备事实上的标准。它是一种人类可读的文本格式。而且，也许对于本页来说更重要的是，它将极大地提高您的线性代数技能......

BVH 规格在这个旧文档中进行了描述：https://research.cs.wisc.edu/graphics/Courses/cs-838-1999/Jeff/BVH.html

幸运的是，在 20tab 中我们构建了一个用于解析 bvh 文件的 python 模块：https://github.com/20tab/bvh-python

```
pip install bvh
```

它是一个简单的解析器，返回简单的浮点数lists/tuples，我们可以用它来构建向量和四元数。

BVH 文件仅包含骨架定义（通过指定关节位置）和动画。

该脚本将解析 bvh 文件并返回瞬态骨架（具有关联的空骨架网格物体）和动画：

```python
import unreal_engine as ue
from unreal_engine.classes import Skeleton, SkeletalMesh, AnimSequence
from unreal_engine import FTransform, FVector, FRotator, FQuat, FRawAnimSequenceTrack

from bvh import Bvh

filename = ue.open_file_dialog('Choose your bvh file', '', '', 'Mocap BVH files|*.bvh;')[0]

with open(filename) as f:
    mocap = Bvh(f.read())

skeleton = Skeleton()

for joint_name in mocap.get_joints_names():
    offset = mocap.joint_offset(joint_name)
    parent_id = mocap.joint_parent_index(joint_name)
    # fix z value by inverting it, it will avoid left/right bone name mismatching
    position = FVector(*offset) * FVector(1, 1, -1)
    skeleton.skeleton_add_bone(joint_name, parent_id, FTransform(position))

mesh = SkeletalMesh()
mesh.skeletal_mesh_set_skeleton(skeleton)

# build an empty LOD, this is the minimal required to see bones
# in the editor
mesh.skeletal_mesh_build_lod([])

anim = AnimSequence()
anim.Skeleton = skeleton
anim.NumFrames = mocap.nframes
anim.SequenceLength = mocap.frame_time * mocap.nframes

# iterate each skeleton joint and create a track for each one
for joint_id, joint_name in enumerate(mocap.get_joints_names()):
    track = FRawAnimSequenceTrack()
    bone_transform = skeleton.skeleton_get_ref_bone_pose(joint_id)
    pos_keys = []
    rot_keys = []
    # the python bvh module allows us to choose in which order we want channels
    rotations = mocap.frames_joint_channels(joint_name, ('Xrotation', 'Yrotation', 'Zrotation'))
    positions = []

    # get root motion data for first bone
    if joint_id == 0:
        positions = mocap.frames_joint_channels(joint_name, ('Xposition', 'Yposition', 'Zposition'), 0)
   
    # quaternions do not suffer from gimbal lock as we can choose the rotation order
    for rotation in rotations:
        # BVH uses the ZXY rotation order (roll, pitch, yaw)
        roll = FRotator(rotation[0], 0, 0).quaternion()
        pitch = FRotator(0, rotation[1], 0).quaternion()
        yaw = FRotator(0, 0, rotation[2]).quaternion()
        # remember that quaternion multiplications are applied in the reverse
        q = yaw * pitch * roll

        # as we did not fix the bones axis, we rotate the root one accordingly
        if joint_id == 0:
            q = FRotator(-90, 0, 0).quaternion() * q

        rot_keys.append(q)

    # remember to always add the bind pose position to the animation track
    for position in positions:
        pos_keys.append(bone_transform.translation + FVector(position[0], position[2], position[1]))

    if not pos_keys:
        pos_keys = [bone_transform.translation]

    track.pos_keys = pos_keys
    track.rot_keys = rot_keys
    anim.add_new_raw_track(joint_name, track)

ue.open_editor_for_asset(anim)
```

同样，处理不同的约定是最复杂的部分。在此示例中，我们不交换轴，而是在动画本身中旋转根骨骼：

![BVH](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/SnippetsForStaticAndSkeletalMeshes_Assets/bvh.PNG)


<a id="final-notes"></a>

## 最后的注释

以下两个教程是这些片段的好伴侣：

https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/FixingMixamoRootMotionWithPython.md（用于修复 Mixamo 根部运动）

https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/WritingAColladaFactoryWithPython.md（Collada StaticMesh 进口商）

大多数片段适用于当前选择的asset/actors.，请随意将它们关联到上下文菜单或资产加载器。

如果您有一个很酷的片段想要分享，只需提出拉取请求即可！
