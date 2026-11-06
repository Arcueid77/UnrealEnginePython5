[English](FixingMixamoRootMotionWithPython.md) | [简体中文](FixingMixamoRootMotionWithPython.zh-CN.md)

<a id="fixing-mixamo-root-motion-with-python"></a>

# 使用 Python 修复 Mixamo Root Motion

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

Mixamo.com 是免费（几乎）角色动画的最大来源之一。不幸的是，它的根运动支持的工作方式与 Unreal Engine 4 的预期完全不同。

修复它是一项相当繁重（且手动）的任务：您需要向骨架添加新骨骼，修复骨骼影响并更新新骨骼的动画曲线。您可以从 Blender、Maya 或任何能够修改 fbx 文件的工具中进行点化。 （而且我很确定有一个 UE4 插件可以做到这一点）

以下教程展示了如何使用简单的 python 脚本完成相同的任务。

这些脚本已使用 Unreal Engine 4.16 和 python 3.6 进行了测试。如果这是您第一次使用 Unreal Engine Python 插件，我强烈建议您从更温和的教程开始：https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython.md#installing-the-python-plugin

<a id="steps"></a>

## 步骤

导入 mixamo 资源后，我们需要执行以下步骤：

* 向骨架中添加一个新骨骼，该骨骼将成为整棵树的根（该骨骼将被称为“根”）

* 修改SkeletalMesh骨骼影响，因为添加新骨骼后索引将发生变化

* 将“臀部”相关动画曲线拆分为另外两条曲线，一条包含将映射到“根”轨迹的根运动（相对于局部轴原点的平移），另一条映射到仅包含旋转的“臀部”轨迹。 “根”轨道必须是第一个。

为了避免损坏，我们将为每个资产生成一个副本，以便您始终能够使用原始资产。

<a id="step-1-importing-mixamo-animations"></a>

## 步骤1：导入mixamo动画

创建一个文件夹，然后从 mixamo 导入一堆基于根运动的动画。 （需要下载普通fbx版本）

在此示例中，我选择吸血鬼作为网格，并选择奔跑、攀爬和飓风踢动画

![mixamo 导入](https://github.com/20tab/UnrealEnginePython/raw/master/tutorials/FixingMixamoRootMotionWithPython_Assets/mixamo.png)

如果你打开“奔跑”动画并启用根运动，你将以这个奇怪的姿势结束：

![破跑](https://github.com/20tab/UnrealEnginePython/raw/master/tutorials/FixingMixamoRootMotionWithPython_Assets/broken_run.png)

原因在于角色的操纵方式：

![default_skeleton](https://github.com/20tab/UnrealEnginePython/raw/master/tutorials/FixingMixamoRootMotionWithPython_Assets/default_skeleton.png)

正如您所看到的，骨架树的根是“臀部”joint/bone. 动画使用此骨骼进行平移和旋转，打破了 UE4 的工作方式。 Unreal Engine 期望骨架的根位于本地原点，并且所有其他bones/joints（加权到顶点）位于其下方。

因此，我们的第一步将是使用此特定配置构建一个新骨架。

<a id="step-2-generating-a-new-skeleton"></a>

## 步骤2：生成新骨架

打开您最喜欢的 python 编辑器（或嵌入式编辑器）并创建 /Game/Scripts/mixamo.py 文件：

```python
import unreal_engine as ue
from unreal_engine.classes import SkeletalMesh, Skeleton
from unreal_engine import FTransform


class DialogException(Exception):
    """
    Handy exception class for spawning a message dialog on error
    """
    def __init__(self, message):
        ue.message_dialog_open(0, message)

class RootMotionFixer:

    def add_root_to_skeleton(self, mesh, bone='root'):
        # retrieve the mesh path, so we can give the user a handy default for the file picker
        base_path = mesh.get_path_name()
        # open the save asset dialog with handy defaults
        new_path = ue.create_modal_save_asset_dialog('Choose destination path', ue.get_path(base_path), ue.get_base_filename(base_path) + '_rooted')
        if not new_path:
            raise DialogException('Please specify a new path for the Skeletal Mesh copy')

        # build package and object names for the mesh copy
        package_name = ue.object_path_to_package_name(new_path)
        object_name = ue.get_base_filename(new_path)
        # the last True allows for overwrites
        new_mesh = mesh.duplicate(package_name, object_name, True)

        # generate a new skeleton
        new_skel = self.build_new_skeleton(mesh.Skeleton, object_name + '_Skeleton', bone)
        # save the new skeleton in the same package directory of the new skeletal mesh
        new_skel.save_package(package_name)

        # assign the new skeleton to the new mesh
        new_mesh.skeletal_mesh_set_skeleton(new_skel)

        new_skel.save_package()

    def build_new_skeleton(self, skeleton, name, root):
        """
        Generate a new skeleton with a 'root' bone
        """
        new_skel = Skeleton(name)
        # add the root bone with -1 as parent
        new_skel.skeleton_add_bone(root, -1, FTransform())

        # copy bone indices from the original skeleton
        for index in range(0, skeleton.skeleton_bones_get_num()):
            # get bone name, parent index and ref pose
            bone_name = skeleton.skeleton_get_bone_name(index)
            bone_parent = skeleton.skeleton_get_parent_index(index)
            bone_transform = skeleton.skeleton_get_ref_bone_pose(index)

            # if this is the old 'root' bone (Hips), change its parent to the new 'root'
            if bone_parent == -1:
                bone_parent_name = root
            else:
                bone_parent_name = skeleton.skeleton_get_bone_name(bone_parent)

            # get new bone parent id
            new_bone_parent = new_skel.skeleton_find_bone_index(bone_parent_name)
            # add the new bone
            new_skel.skeleton_add_bone(bone_name, new_bone_parent, bone_transform)
        return new_skel


root_motion_fixer = RootMotionFixer()

# get the list of currently selected assets in the content browser
for uobject in ue.get_selected_assets():
    # check if uobject is a SkeletlMesh
    if uobject.is_a(SkeletalMesh):
        root_motion_fixer.add_root_to_skeleton(uobject)
    else:
        raise DialogException('Only Skeletal Meshes are supported')
```

`DialogException` 类是在错误时生成模态窗口的有用技巧。这比简单地在控制台中吐出错误更加UE4友好。每当您抬起它时，都会出现该对话框。

`ue.create_modal_save_asset_dialog(title, default_package_name, default_object_name)`功能打开UE4资产管理器，允许用户指定保存SkeletalMesh/Skeleton副本的位置。显然，如果发生大量转换，您可以避免它，只需在代码中指定自动文件模式即可。

注意骨骼的结构方式。它们基本上以数字的形式引用，每个骨骼映射到父索引（-1 表示链中的第一个骨骼）。

脚本的最后一部分为内容浏览器中的每个选定资产运行 `add_root_to_skeleton()` 方法（但如果其中一个资产不是骨架网格体，则会引发异常）。

因此，选择吸血鬼骨架网格体并从 UE4 python 控制台运行 `mixamo.py` 脚本（或在嵌入式 python 编辑器中单击“执行”）：

```python
ue.py_exec('mixamo.py')
```

最后您将获得两项新资产，一项用于SkeletalMesh，另一项用于骨骼。

双击骨架打开其编辑器，您应该看到以“root”为父级的新骨骼层次结构。现在旋转左肩，您应该注意到一些可怕的结果：

![无影响](https://github.com/20tab/UnrealEnginePython/raw/master/tutorials/FixingMixamoRootMotionWithPython_Assets/no_influences.png)

<a id="step-3-fixing-skeletal-mesh-bone-influences"></a>

## 步骤3：修复骨骼网格物体骨骼影响

在最后一张截图中，我们看到了破碎的变形。我们的吸血鬼怎么了？

每个骨架网格物体 LOD 都有一系列映射到它的“软皮肤顶点”。每个顶点数据结构包含经典位置、切线（包括法线）和 uvs 值，以及用于存储最多 8“骨骼影响”的2附加字段。骨骼影响由骨骼指数（注意：与骨骼的指数不同，见下文）和骨骼权重组成。重量定义了骨骼使顶点变形的程度。

更改骨骼层次结构（请记住，我们添加了“根”骨骼）会导致不同的骨骼索引，因此每个顶点都可能指向错误的骨骼。

除此之外，软蒙皮顶点不使用骨架层次结构，而是指向包含所用骨骼的简单数组的附加贴图（BoneMap）。

BoneMap 看起来像这样：

```python
[17, 22, 26, 30]
```

所以索引0表示骨骼17，索引1表示骨骼22，依此类推。这个额外的映射是出于性能原因，但我们需要处理它。

要检索骨架网格物体的BoneMap，您可以使用：

```python
bone_map = mesh.skeletal_mesh_get_bone_map()
```

并分配一个新的：

```python
mesh.skeletal_mesh_set_bone_map([17, 22, 26, 30, ...])
```

以同样的方式，您可以检索软皮肤顶点：

```python
vertices = mesh.skeletal_mesh_get_soft_vertices()
```

每个顶点都是一个 FSoftSkinVertex 类，具有以下字段：

* 位置（顶点位置向量）
* color（顶点颜色，材质可以使用）
* tangent_x, tangent_y, tangent_z (tangents/normal)
* uvs（纹理坐标）
* influence_bones（最多具有 8 BoneMap 索引的元组）
* influence_weights（骨骼重量为整数，0至255）

我们的目标是更新每个顶点的 influence_bones 元组并重新生成 BoneMap：

```python

class RootMotionFixer:

    ...
    
    def fix_bones_influences(self, mesh, old_skeleton):
        # get current soft vertices
        vertices = mesh.skeletal_mesh_get_soft_vertices()
        new_vertices = []
        # get current bone map
        old_bone_map = mesh.skeletal_mesh_get_bone_map()
        new_bone_map = []

        # fix bones influence for each vertex
        for vertex in vertices:
            bone_ids = list(vertex.influence_bones)
            for index, bone_id in enumerate(bone_ids):
                # only fix bone with weight > 0
                if vertex.influence_weights[index] > 0:
                    bone_ids[index] = self.get_updated_bone_index(old_skeleton, mesh.Skeleton, old_bone_map, new_bone_map, bone_id)
            vertex.influence_bones = bone_ids
            new_vertices.append(vertex)

        # assign new vertices
        mesh.skeletal_mesh_set_soft_vertices(new_vertices)
        # add the new bone mapping
        mesh.skeletal_mesh_set_bone_map(new_bone_map)

        # specify which bones are active and required (ensure root is added to required bones)
        mesh.skeletal_mesh_set_active_bone_indices(new_bone_map)
        if 0 not in new_bone_map:
            new_bone_map += [0]
        mesh.skeletal_mesh_set_required_bones(new_bone_map)

    def get_updated_bone_index(self, old_skeleton, new_skeleton, old_bone_map, new_bone_map, index):
        """
        Convert indices betwen skeletons
        """
        # get the skeleton bone_id from the map
        true_bone_id = old_bone_map[index]

        # get the bone name
        bone_name = old_skeleton.skeleton_get_bone_name(true_bone_id)

        # get the new index
        new_bone_id = new_skeleton.skeleton_find_bone_index(bone_name)

        # check if a new mapping is available
        if new_bone_id in new_bone_map:
            return new_bone_map.index(new_bone_id)

        new_bone_map.append(new_bone_id)
        return len(new_bone_map)-1
```

请注意对 `skeletal_mesh_set_active_bone_indices()` 和 `skeletal_mesh_set_required_bones()` 的调用：它们需要完成新映射的构建。

现在只需在 `add_root_to_skeleton()` 方法的末尾添加以下两行：

```python
class RootMotionFixer:

    def add_root_to_skeleton(self, mesh, bone='root'):
        ...
        # fix bone influences
        self.fix_bones_influences(new_mesh, mesh.Skeleton)

        new_mesh.save_package()
    
    ...
```

您现在可以删除之前生成的资源（SeletalMesh 和骨架）并重新运行脚本（请记住至少选择一个骨架网格体资源）。

如果一切顺利，打开新骨架并再次旋转左肩。现在它应该可以完美地工作：

![固定影响](https://github.com/20tab/UnrealEnginePython/raw/master/tutorials/FixingMixamoRootMotionWithPython_Assets/fixed_influences.png)

手臂不再变形:)

<a id="step-4-splitting-hips-track-in-animation"></a>

## 步骤4：在动画中分割“臀部”轨迹

最后一步是修复动画。我们基本上需要为根运动添加一个新轨道，并从“臀部”骨骼的轨道中删除平移（请记住，每个骨骼都映射到动画中的不同轨道）。

我们将为“有根”骨架创建一个新的空动画，并且我们将从所选动画中复制（并最终修复）每个轨道。

这次我们将要求用户使用平板窗口选择骨架资源，但我们不会询问在哪里保存新副本，而是自动生成一个名称（显然可以随意添加资源保存对话框）。

```python
import unreal_engine as ue
from unreal_engine.classes import SkeletalMesh, Skeleton, AnimSequence, AnimSequenceFactory
from unreal_engine import FTransform, FRawAnimSequenceTrack, FQuat
from unreal_engine import SWindow, SObjectPropertyEntryBox

class RootMotionFixer:

    ...
    def set_skeleton(self, asset_data):
        """
        This hook will be called after you selected a skeleton from the slate wizard
        """
        self.choosen_skeleton = asset_data.get_asset()
        self.window.request_destroy()

    def split_hips(self, animation, bone='Hips'):
        """
        SObjectPropertyEntryBox is the asset selector widget (we limit it to the Skeleton class)
        """
        # this will contain the user-selected skeleton (if-any)
        self.choosen_skeleton = None
        # first ask for which skeleton to use:
        self.window = SWindow(title='Choose your new Skeleton', modal=True, sizing_rule=1)(
                     SObjectPropertyEntryBox(allowed_class=Skeleton, on_object_changed=self.set_skeleton)
                 )
        # add_modal() will block the script until the user make some kind of input in the window
        self.window.add_modal()
        
        # ensure a skeleton has been selected
        if not self.choosen_skeleton:
            raise DialogException('Please specify a Skeleton for retargeting')

        # create a new empty animation from the skeleton
        factory = AnimSequenceFactory()
        factory.TargetSkeleton = self.choosen_skeleton
        
        # automatically build its new path
        base_path = animation.get_path_name()
        package_name = ue.get_path(base_path)
        object_name = ue.get_base_filename(base_path)

        new_anim = factory.factory_create_new(package_name + '/' + object_name + '_rooted')

        # copy the number of frames and duration
        new_anim.NumFrames = animation.NumFrames
        new_anim.SequenceLength = animation.SequenceLength

        # first step is generatin the 'root' track
        # we need to do it before anything else, as the 'root' track must be the 0 one
        for index, name in enumerate(animation.AnimationTrackNames):
            if name == bone:
                data = animation.get_raw_animation_track(index)
                # extract root motion
                root_motion = [(position - data.pos_keys[0]) for position in data.pos_keys]

                # create a new track (the root motion one)
                root_data = FRawAnimSequenceTrack()
                root_data.pos_keys = root_motion
                # ensure empty rotations !
                root_data.rot_keys = [FQuat()]
        
                # add  the track
                new_anim.add_new_raw_track('root', root_data)
                break
        else:
            raise DialogException('Unable to find bone {0}'.format(bone))
           
        # now append the original tracks, but removes the position keys
        # from the original root bone
        for index, name in enumerate(animation.AnimationTrackNames):
            data = animation.get_raw_animation_track(index)
            if name == bone:
                # remove root motion from original track
                data.pos_keys = [data.pos_keys[0]]
                new_anim.add_new_raw_track(name, data)
            else:
                new_anim.add_new_raw_track(name, data)

        new_anim.save_package()
```

两个“for 循环”是修复发生的地方。考虑到某些动画可能需要额外的操作，例如，您可能希望删除运行循环的 z 和 x 变换：

```python
# extract root motion
root_motion = [((position - data.pos_keys[0]) * FVector(0, 1, 0)) for position in data.pos_keys]
```

并且永远记住，修改根运动中的 z 轴需要您的角色处于“飞行”运动模式。

现在在最终循环中添加对 AnimSequence 的支持：

```python
for uobject in ue.get_selected_assets():
    if uobject.is_a(SkeletalMesh):
        root_motion_fixer.add_root_to_skeleton(uobject)
    elif uobject.is_a(AnimSequence):
        root_motion_fixer.split_hips(uobject)
    else:
        raise DialogException('Only Skeletal Meshes and Anim Sequences are supported')
```

从内容浏览器中选择动画并运行脚本。


![动画已修复](https://github.com/20tab/UnrealEnginePython/raw/master/tutorials/FixingMixamoRootMotionWithPython_Assets/animation_fixed.png)

您可以在此处下载完整代码：

https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/FixingMixamoRootMotionWithPython_Assets/mixamo.py

<a id="bonus-step-adding-a-context-menu"></a>

## 奖励步骤：添加上下文菜单

从命令行运行脚本不是很方便（除非您正在进行某种大规模转换）。

通过右键单击内容浏览器中的资源来执行它会更酷。您可以添加上下文菜单扩展：

```python
class RootMotionFixer:

    ...
    def run_tasks(self, selected_assets):
        # asset_data is an FAssetData instance.It is not a UObject !
        for asset_data in selected_assets:
            if asset_data.asset_class == 'SkeletalMesh':
                self.add_root_to_skeleton(asset_data.get_asset())
            elif asset_data.asset_class == 'AnimSequence':
                self.split_hips(asset_data.get_asset())
            else:
                raise DialogException('Only Skeletal Meshes and Anim Sequences are supported')

    def __call__(self, menu, selected_assets):
        menu.begin_section('mixamo', 'mixamo')
        menu.add_menu_entry('fix root motion', 'fix root motion', self.run_tasks, selected_assets)
        menu.end_section()
    
    
# add a context menu
ue.add_asset_view_context_menu_extension(RootMotionFixer())
ue.log('Mixamo Root Motion Fixer registered')
```

（记住从前面的代码中删除 ue.get_selected_assets() 循环和 RootMotionFixer() 实例！）

每当用户在内容浏览器中右键单击资源并生成菜单时，都会调用 `__call__` 方法

要在编辑器启动时自动注册 mixamo 模块，只需将其导入到 /Game/Scripts/ue_site.py 中（如果不存在则创建它）：

```python
import mixamo
```

<a id="final-notes"></a>

## 最后的注释

选择资产名称时请务必注意（特别是如果您自动生成它们）。尝试创建具有冲突名称的UObject可能会导致编辑器崩溃。

请记住，您只需调用 ```ue.open_editor_for_asset(uobject)``` 即可打开资产相关编辑器

请注意，每次调用```ue.add_asset_view_context_menu_extension(callable)```都会生成一个新的上下文菜单。目前不支持清理上下文菜单（好吧，除了重新启动编辑器：P）

<a id="update-20170927-by-issue-228"></a>

## 按问题更新20170927228

https://github.com/20tab/UnrealEnginePython/issues/228

Marat Yakupov 在第 228 期报告了 mixamo ybot 模型的问题。该问题是由网格中可用的多个部分引起的。 mixamo.py 已更新以支持多个部分：

```python
    def fix_bones_influences(self, mesh, old_skeleton):
        active_bones = []
        for section in range(0, mesh.skeletal_mesh_sections_num()):
            vertices = mesh.skeletal_mesh_get_soft_vertices(0, section)
            ue.log_warning(len(vertices))
            new_vertices = []
            old_bone_map = mesh.skeletal_mesh_get_bone_map(0, section)
            new_bone_map = []

            for vertex in vertices:
                bone_ids = list(vertex.influence_bones)
                for index, bone_id in enumerate(bone_ids):
                    if vertex.influence_weights[index] > 0:
                        bone_ids[index] = self.get_updated_bone_index(old_skeleton, mesh.Skeleton, old_bone_map, new_bone_map, bone_id)
                        if new_bone_map[bone_ids[index]] not in active_bones:
                            active_bones.append(new_bone_map[bone_ids[index]])
                vertex.influence_bones = bone_ids
                new_vertices.append(vertex)

            # assign new vertices
            mesh.skeletal_mesh_set_soft_vertices(new_vertices, 0, section)
            # add the new bone mapping
            mesh.skeletal_mesh_set_bone_map(new_bone_map, 0, section)

        # specify which bones are active and required (ensure root is added to required bones)
        mesh.skeletal_mesh_set_active_bone_indices(active_bones)
        # mark all the bones as required (eventually you can be more selective)
        mesh.skeletal_mesh_set_required_bones(list(range(0, mesh.Skeleton.skeleton_bones_get_num())))
```

正如您所看到的，我们仍然假设单个 LOD（该部分之前的 0 始终是 lod）
