[English](sequencer_API.md) | [简体中文](sequencer_API.zh-CN.md)

<a id="the-sequencer-api"></a>

音序器API
-----------------

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

定序器API的开发由Matthew Whelan (http://www.mattwhelan.com/)赞助

也应该感谢 Ron Fischer，因为他向我解释了排序器 api 。）

<a id="creating-a-sequencer-asset"></a>

创建定序器资源
--------------------------

您可以使用 LevelSequencerFactoryNew 类创建新的“关卡序列”资源：

```python
from unreal_engine.classes import LevelSequenceFactoryNew

factory = LevelSequenceFactoryNew()
seq = factory.factory_create_new('/Game/MovieMaster')
```

<a id="adding-a-master-track-to-a-level-sequence"></a>

将主轨道添加到关卡序列
-----------------------------------------

在以下示例中，我们添加 MovieSceneAudioTrack 作为主轨道

```python
from unreal_engine.classes import MovieSceneAudioTrack

audio_track = seq.sequencer_add_master_track(MovieSceneAudioTrack)
```

<a id="getting-the-available-track-classes"></a>

获取可用的赛道类别
-----------------------------------

以下代码片段打印 MovieSceneTrack 类的名称

```python
import unreal_engine as ue
from unreal_engine.classes import MovieSceneTrack

for uclass in ue.all_classes():
    if uclass.is_child_of(MovieSceneTrack):
        print(uclass.get_name())
```

<a id="getting-the-list-of-master-tracks"></a>

获取主曲目列表
---------------------------------

```python
tracks = seq.sequencer_master_tracks()
```

<a id="possessables-and-spawnables"></a>

拥有物和生成物
---------------------------

<a id="adding-tracks"></a>

添加曲目
-------------

<a id="adding-a-section-to-a-track"></a>

将部分添加到轨道
---------------------------

这是一个非常复杂的示例，我们添加一个骨骼动画轨道，然后添加一堆部分（每个部分都应该使用 AnimSequence 字段指向一个动画资源）

```python
from unreal_engine.classes import MovieSceneSkeletalAnimationTrack

# add an animation track mapped to the just added actor
anim = seq.sequencer_add_track(MovieSceneSkeletalAnimationTrack, guid)

# create 3 animations sections (assign AnimSequence field to set the animation to play)
anim_sequence = anim.sequencer_track_add_section()
anim_sequence.StartTime = 1
anim_sequence.EndTime = 3
anim_sequence.RowIndex = 0

anim_sequence2 = anim.sequencer_track_add_section()
anim_sequence2.RowIndex = 1
anim_sequence2.StartTime = 2
anim_sequence2.EndTime = 5

anim_sequence3 = anim.sequencer_track_add_section()
anim_sequence3.RowIndex = 1
anim_sequence3.SlotName = 'Hello'
anim_sequence3.StartTIme = 0
anim_sequence3.EndTime = 30
```

<a id="adding-keyframes-to-sections"></a>

将关键帧添加到部分
----------------------------

```python
from unreal_engine import FTransform, FVector
from unreal_engine.classes import MovieScene3DTransformTrack

# possess an actor and get its binding guid
guid = seq.sequencer_add_actor(an_actor_in_the_scene)

transform_track = seq.sequencer_add_track(MovieScene3DTransformTrack, guid)
transform_section = transform_track.sequencer_track_add_section()

# set section size
transform_section.StartTime = 0
transform_section.EndTime = 5

# adding keyframes to section
transform_section.sequencer_section_add_key(0.0, FTransform(FVector(17, 22, 30)))
transform_section.sequencer_section_add_key(0.17, FTransform(FVector(30, 17, 22)))
```

<a id="managing-the-camera-cut-track"></a>

管理相机剪切轨迹
-----------------------------

<a id="folders"></a>

文件夹
-------

列出文件夹

```python

# get the root folders
root_folders = seq.sequencer_folders()

# get subfolders
sub_folders = seq.sequencer_folders(root_folders[0])
```

创建文件夹

```python
new_folder = seq.sequencer_create_folder('Folder001')

# create subfolder
new_sub_folder = seq.sequencer_create_folder('SubFolder001', new_folder)
```

<a id="notify-changes-to-the-editor"></a>

通知编辑者更改
----------------------------

某些sequencer api操作不会更新编辑器，如果您需要强制更新，可以使用

```python
seq.sequencer_changed(True)
```

布尔参数（如果为 True）将编辑器焦点移动到音序器

<a id="example"></a>

示例
-------

在这里查看：https://github.com/20tab/UnrealEnginePython/blob/master/examples/sequencer_scripting.py
