[English](PlottingGraphsWithMatplotlibAndUnrealEnginePython.md) | [简体中文](PlottingGraphsWithMatplotlibAndUnrealEnginePython.zh-CN.md)

<a id="plotting-graphs-with-matplotlib-and-unreal-engine-python"></a>

# 使用 Matplotlib 和 Unreal Engine Python 绘制图形

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

在本教程中，我们将了解如何在 Unreal Engine 项目中使用第三方 python 模块。

选择的模块是“matplotlib”https://matplotlib.org/.

来自官方网站：

>Matplotlib 是一个 Python 2D 绘图库，它以各种硬拷贝格式和跨平台的交互环境生成出版质量的图形。 Matplotlib 可用于 Python 脚本、Python 和 IPython shell、jupyter 笔记本、Web 应用程序服务器以及四个图形用户界面工具包。

因此，我们的目标是将图形绘制到 Unreal Engine 纹理资源中，无论是在编辑器中（预生成资源）还是在游戏过程中（动态更新纹理图数据）

<a id="creating-the-project"></a>

## 创建项目

第一步显然是创建一个新项目。

我们将使用第三人称模板

![ThirdPerson模板](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/third_person.png)

<a id="installing-the-python-plugin"></a>

## 安装Python插件

确保您的project/editor已关闭。

从此处下载最新的嵌入式二进制版本：https://github.com/20tab/UnrealEnginePython/releases

如果您的系统中已经安装了 python 并且您对它有信心，您也可以使用非嵌入式版本。

本教程中唯一的区别在于 matplotlib 模块的安装位置：

对于嵌入式版本，安装将发生在插件目录本身中。对于非嵌入式，它将位于 python 系统路径中。

显然，如果你的系统 python 安装已经包含 matplotlib，你可以简单地跳过下面的相关段落。

>注意：在Linux和Mac系统上，您将使用系统安装（不提供嵌入式发行版）或直接使用源发行版。本教程的其余部分将与平台无关。

在您的项目中创建一个 Plugins/ 目录并将插件存档解压缩到其中。

重新启动您的项目，然后在 Edit/Plugins 菜单中您将能够启用 python 插件：

![插件安装](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/enable_plugin.png)

<a id="pip-installing-matplotlib"></a>

## pip 安装 matplotlib

如果您安装了嵌入式发行版，只需移至终端中的Plugins/UnrealEnginePython/Binaries/Win64目录，然后运行：

```sh
./python.exe -m pip install --target . matplotlib
```

（--target . 确保模块不会安装到 Lib/site-packages 子目录中）

![pip 安装 matplotlib](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/pip_install.png)

如果您使用的是系统 python 安装（或者您使用的是Linux/Mac），只需运行：

```sh
pip3 install matplotlib
```

或（根据您的配置）

```sh
pip install matplotlib
```

在 Unreal Engine Python 控制台（在“Window/Developer Tools/Python Console”菜单条目下）运行

```python
import matplotlib
```

如果一切正常，您将不会收到导入错误

<a id="testing-matplotlib-in-unreal-engine-generating-a-graph-texture"></a>

## 在 Unreal Engine 中测试 matplotlib：生成图形纹理

是时候检查一下是否一切正常了。

我们将从生成纹理资源开始。该纹理的内容将由 matplotlib 管理。

您可以使用附带的 python 编辑器来编辑脚本（位于“Window/Python编辑器”菜单项下），或您最喜欢的编辑器（SublimeText、Vim、PyCharm...），只需确保脚本位于项目的Content/Scripts目录下即可。

步骤是：在内存中生成纹理，绘制图形，将图形数据传输到纹理内存中，保存为资产并打开相关编辑器。

```python
import unreal_engine as ue
# EPixelFormat defines the various pixel formats for a texture/image, we will use RGBA with 8bit per channel
from unreal_engine.enums import EPixelFormat

import matplotlib
# set the Agg renderer as we do not need any toolkit
matplotlib.use('Agg')

import matplotlib.pyplot as plt

# set texture/plot dimensions and dpi, ensure dpi is a float !
width = 1024
height = 1024
dpi = 72.0

# create a new figure with the specified sizes
fig = plt.figure(1)
fig.set_dpi(dpi)
fig.set_figwidth(width/dpi)
fig.set_figheight(height/dpi)

# plot a simple graph with a label on the y axis
plt.plot([1, 2, 3, 4])
plt.ylabel('some numbers')

# draw the graph (in memory)
fig.canvas.draw()

# create a texture in memory (will be saved later)
texture = ue.create_transient_texture(width, height, EPixelFormat.PF_R8G8B8A8)
# copy pixels from matplotlib canvas to the texture as RGBA
texture.texture_set_data(fig.canvas.buffer_rgba())

# save the texture
texture.save_package('/Game/FirstGraphTexture')

# open its editor
ue.open_editor_for_asset(texture)
```

如果您使用附带的 Python 编辑器，请单击“保存”，然后单击“执行”

如果您使用外部编辑器，您可以使用以下命令从 python 控制台运行脚本：

```python
import unreal_engine as ue
ue.py_exec('name_of_your_script.py')
```

![纹理已创建](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/texture_created.png)

如果您最终在新图形上打开了纹理编辑器，那么您就可以进行下一步了



<a id="our-project-plotting-a-pie-chart-tracking-overlap-events"></a>

## 我们的项目：绘制跟踪重叠事件的饼图

我们的目标是在我们的关卡中有一个特殊的蓝图，以 3 不同的颜色展示3 立方体。

每当您将其中一个立方体与角色重叠时，它们的内部计数器就会增加。

饼图“地毯”位于地板上，并使用重叠计数器数据进行更新（立方体重叠得越多，图表中的切片就越大）

此时，我强烈建议您重新启动编辑器，以便正确设置您的Python环境以在/Content/Scripts目录中搜索模块（这是因为Python模块搜索路径在启动时没有填充不存在的目录，不幸的是，当您第一次运行插件时，/Content/Scripts仍然不存在）

<a id="setting-up-materials"></a>

### 设置材料

我们需要4材质和1材质实例用于该项目：

* 完全红色的材质（只需将常量向量3链接到基色）

* 完全绿色材料

* 完全蓝色的材料

* 具有链接到基色的名为“Graph”的纹理参数的材质（使用您拥有的任何纹理，它将在运行时被替换）

* 公开纹理参数的先前材质的实例（因此可以在运行时更新它，同样任何纹理都可以，即使是与父材质相同的纹理）

<a id="the-pie-chart-carpet-blueprint"></a>

### “饼图地毯”蓝图

我们要创建的第一个蓝图是“地毯”（我们称之为Graph_Blueprint）

![图Blueprint](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/graph_blueprint.png)

正如您所看到的，这非常简单：

* 继承标准Actor
* 添加一个 StaticMeshComponent （如果需要，可以作为根），以平面作为网格（在所有轴上将其缩放到 10）以及您之前创建的材质实例
* 添加一个 Python 组件，模块为“plotter”，类为“PlotComponent”（这是 matplotlib 部分所在的位置）
* 添加一个名为“OnGraphDataUpdated”的事件调度程序（每当角色跨过立方体时就会触发），并采用类型为“Actor”的名为“Platform”的单个输入参数

您现在可以创建（再次进入Content/Scripts）plotter.py python 脚本

```python
import unreal_engine as ue
from unreal_engine.enums import EPixelFormat

import matplotlib
matplotlib.use('Agg')

import matplotlib.pyplot as plt

class PlotComponent:
  
    def begin_play(self):
        width = 1024
        height = 1024
        dpi = 72.0
        self.texture = ue.create_transient_texture(width, height, EPixelFormat.PF_R8G8B8A8)

        self.uobject.get_owner().StaticMeshComponent.OverrideMaterials[0].set_material_texture_parameter('Graph', self.texture)

        self.fig = plt.figure(1)
        self.fig.set_dpi(dpi)
        self.fig.set_figwidth(width/dpi)
        self.fig.set_figheight(height/dpi)

        self.uobject.get_owner().bind_event('OnGraphDataUpdated', self.update_graph)

    def update_graph(self, platform):
        # clear the current plot data
        plt.clf()
        # draw a pie chart        
        plt.pie([platform.RedCubeCounter, platform.GreenCubeCounter, platform.BlueCubeCounter], colors=['r', 'g', 'b'], labels=['RedCube', 'GreenCube', 'BlueCube'], shadow=True)

        self.fig.canvas.draw()
        self.texture.texture_set_data(self.fig.canvas.buffer_rgba())
```

唯一相关的部分是由“OnGraphDataUpdated”事件调度程序触发的update_graph函数。

该函数接收触发事件的Actor作为“平台”参数。这个Actor（我们将在下一阶段创建）暴露了重叠立方体的计数器。我们使用该值重新生成饼图，并在触发事件时将其上传到纹理内存中

<a id="the-plotter-platforms"></a>

### “绘图仪平台”

“PlotterPlatforms”蓝图实现了包含3立方体的参与者并管理重叠事件以及递增3计数器。

让我们从视口开始，您需要添加3静态网格物体，每个网格物体都有一个立方体和我们之前创建的相关纯色材质。确保它们的碰撞模式设置为OverlapAll：

![PlotterPlatforms Blueprint视口](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/platforms_viewport.png)

然后我们定义一个蓝图函数“NotifyPlotter”，它将触发Graph_Blueprint（我们的地毯）上的事件调度程序：

![PlotterPlatforms Blueprint 通知绘图仪](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/platforms_notify_plotter.png)

最后我们有了事件图，这里我们简单地增加相关的计数器变量并调用“NotifyPlotter”函数：

![PlotterPlatforms Blueprint 事件图](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/platforms_event_graph.png)

确保为计数器添加 3 整数变量（检查屏幕截图的左下侧）！

<a id="playing-it"></a>

### 播放它

将两个蓝图（Graph_Blueprint和PlotterPlatforms）拖到关卡中（为它们选择合适的位置。）并在编辑器中点击“播放”：

![播放](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/play.png)

走过 3 立方体并查看饼图更新

<a id="writing-a-simple-unit-test"></a>

### 编写一个简单的单元测试

抱歉，我永远不会停止告诉你单元测试有多么重要，所以，即使我们开发了一个非常简单的脚本，我们也会编写一个单元测试:)

我们需要测试当多维数据集上触发“ComponentOverlap”事件时，右侧计数器会递增：

```python
import unittest
import unreal_engine as ue
from unreal_engine.classes import Blueprint

class TestPlotterPlatform(unittest.TestCase):

    def setUp(self):
        ue.allow_actor_script_execution_in_editor(True)
        ue.begin_transaction('test')
        self.world = ue.get_editor_world()
        self.blueprint = ue.load_object(Blueprint, '/Game/PlotterPlatforms.PlotterPlatforms')

    def tearDown(self):
        ue.end_transaction()
        ue.editor_undo()
        ue.allow_actor_script_execution_in_editor(False)

    def test_red_cube_overlap(self):
        actor = self.world.actor_spawn(self.blueprint.GeneratedClass)
        self.assertEqual(actor.RedCubeCounter, 0)
        actor.RedCube.broadcast('OnComponentBeginOverlap')
        self.assertEqual(actor.RedCubeCounter, 1)
        self.assertEqual(actor.GreenCubeCounter, 0)
        self.assertEqual(actor.BlueCubeCounter, 0)

    def test_green_cube_overlap(self):
        actor = self.world.actor_spawn(self.blueprint.GeneratedClass)
        self.assertEqual(actor.GreenCubeCounter, 0)
        actor.GreenCube.broadcast('OnComponentBeginOverlap')
        self.assertEqual(actor.RedCubeCounter, 0)
        self.assertEqual(actor.GreenCubeCounter, 1)
        self.assertEqual(actor.BlueCubeCounter, 0)

    def test_blue_cube_overlap(self):
        actor = self.world.actor_spawn(self.blueprint.GeneratedClass)
        self.assertEqual(actor.BlueCubeCounter, 0)
        actor.BlueCube.broadcast('OnComponentBeginOverlap')
        self.assertEqual(actor.RedCubeCounter, 0)
        self.assertEqual(actor.GreenCubeCounter, 0)
        self.assertEqual(actor.BlueCubeCounter, 1)

if __name__ == '__main__':
    unittest.main(exit=False)
```

您可以使用以下命令运行单元测试：

```python
ue.sandbox_exec('test_plotter_platforms.py')
```

“sanbox”执行，确保初始化一个干净的 python 子解释器，而不是破坏主子解释器。

检查如何测试setUp和tearDown方法，确保你的世界最终被清理干净（使用虚幻引擎的事务API：https://github.com/20tab/UnrealEnginePython/blob/master/docs/Transactions_API.md）

<a id="downloading-scripts"></a>

### 下载脚本：

plotter.py Python 组件：https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/plotter.py

graph_texture.py 示例脚本：https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/graph_texture.py

“绘图仪平台”蓝图的单元测试：https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/PlottingGraphsWithMatplotlibAndUnrealEnginePython_Assets/test_plotter_platforms.py
