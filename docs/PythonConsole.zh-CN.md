[English](PythonConsole.md) | [简体中文](PythonConsole.zh-CN.md)

<a id="the-python-console"></a>

Python 控制台
------------------

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

这是一个插件模块，为您提供运行 python 命令的 shell。这是编写编辑器本身脚本的主要方式：

![替代文本](../screenshots/unreal_screenshot4.png?raw=true "Screenshot 4")

在此屏幕截图中，您可以看到如何访问编辑器世界，以及如何向其中添加演员。

控制台支持历史记录

<a id="running-python-scripts"></a>

运行 python 脚本
----------------------

虽然你可以在ue_site.py中设置启动环境或者导入模块，但它们通常要求你在修改它们时重新启动编辑器。

控制台允许您使用 ue.exec(filename) 命令即时运行 python 脚本：

```py
import unreal_engine as ue
ue.exec('yourscript.py')
# now you can modify it, and re-run the new version
ue.exec('yourscript.py')
```

从/Content/Scripts目录中搜索python脚本

注意：在python2上ue.exec不是一个有效的函数，你需要使用ue.py_exec

<a id="editor-scripting-example"></a>

编辑器脚本示例
------------------------

这是来自 python 控制台的编辑器脚本示例

```py
# get access to the editor world
editor = unreal_engine.get_editor_world()

# get the list of selected actors
selected_actors = unreal_engine.editor_get_selected_actors()

# deselect actors
unreal_engine.editor_deselect_actors()

# select an actor
unreal_engine.editor_select_actor(an_actor)

# import an asset
new_asset = unreal_engine.import_asset(filename, package[, factory_class])
```

<a id="asset-importing-example"></a>

资产导入示例
-----------------------

以下代码展示了如何从 python 导入资源（图像作为纹理）：

```py
import unreal_engine as ue

# get a factory class
factory = ue.find_class('TextureFactory')

# import the asset using the specified class
new_asset = ue.import_asset('C:/Users/Tester/Desktop/logo.png', '/Game/FooBar/Foo', factory)

# print the asset class (it will be a Texture2D)
ue.log(new_asset.get_class().get_name())
```

最后一个参数（工厂类）可以省略，在这种情况下，工厂将通过文件扩展名进行检测。

如果您想自定义工厂（用于修改导入选项），您可以直接生成一个新的工厂对象并设置其属性：

```py
import unreal_engine as ue

factory = ue.find_class('TextureFactory')
# instantiate the factory
factory_obj = ue.new_object(factory)

# print the properties list
ue.log(str(factory_obj.properties()))

# set a property
factory_obj.set_property('bRGBToEmissive', True)

# import the asset (this time using a factory object instead of a factory class)
new_object = ue.import_asset('C:/Users/Tester/Desktop/logo.png', '/Game/FooBar/20tab', factory_obj)
```

<a id="reimporting-example"></a>

重新导入示例
-------------------

您可以使用 asset_reimport() 方法重新导入对象：

```py
uobject.asset_reimport([ask_for_new_file, show_notification, filename])
```

<a id="assets-listing-example"></a>

资产列表示例
----------------------

```py
# get the assets under the specified path
assets = unreal_engine.get_assets(path[, recursive])

# get all the assets implementing the specified class (class_name is a string, like 'SkeletalMesh')
assets = unreal_engine.get_assets_by_class(class_name[, includes_subclasses])

# get the assets currently selected in the content browser
assets = unreal_engine.get_selected_assets()
```


<a id="pyfbxfactory"></a>

PyFbxFactory
------------

这是一个临时工厂，对标准FbxFactory进行了子类化（非常感谢 Chris Emerson 的想法）。它的唯一目标是禁用 fbx 导入器对话框，以便轻松编写 fbx 导入脚本。您可以通过“set_fbx_import_option()”函数设置fbx导入器选项：

```py
import unreal_engine as ue
import os
import os.path
from unreal_engine.classes import PyFbxFactory, Skeleton
from unreal_engine.enums import EFBXImportType

"""
Scan a directory for FBX's and import them with a single skeleton
"""

# directory to scan for fbx's
fbx_directory = 'D:/FBXs'
# skeoton class to set
skeleton_name = 'UE4_Mannequin_Skeleton'

# get the skeleton reference (you could use get_asset() too)
skeleton = ue.find_object(skeleton_name)

# get the PyFbxFactory
factory = PyFbxFactory()

# setup fbx importer options
factory.ImportUI.MeshTypeToImport = EFBXImportType.FBXIT_Animation
factory.ImportUI.Skeleton = skeleton

# the fbx import procedure
def fbx_import(filename, asset_name):
    ue.log('importing ' + filename + ' to ' + asset_name)
    # import the file using PyFbxFactory
    asset = factory.factory_import_object(filename, asset_name)
    # print the skeleton name
    ue.log('FBX imported with skeleton: ' + asset.Skeleton.get_name())
    
    
# scan the directory and uatomatically assign a name using an incremental id
for _id, fbx in enumerate(os.listdir(fbx_directory)):
    if fbx.endswith('.FBX'):
        filename = os.path.join(fbx_directory, fbx)
        fbx_import(filename, '/Game/Skeletonz/Skel_{}'.format(_id))
```

<a id="message-dialog"></a>

消息对话框
--------------

您可以打开一个模式窗口（消息对话框）并等待其响应：

```py
ret = ue.message_dialog_open(ue.APP_MSG_TYPE_YES_NO, "Do you want to shot ?")
if ret == ue.APP_RETURN_TYPE_YES:
    ue.log('You choose "YES"')
```

<a id="multiline-mode"></a>

多行模式
--------------

如果语句以“：”结尾，Python 控制台将假定命令“不完整”，并等待下一行不以空格开头来发出指令。此模式允许您在控制台中输入函数、类、循环。
