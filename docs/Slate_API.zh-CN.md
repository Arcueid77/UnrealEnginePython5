[English](Slate_API.md) | [简体中文](Slate_API.zh-CN.md)


<a id="the-slate-api"></a>

# Slate API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

Slate是Unreal Engine4中的GUI工具包。它允许您创建窗口、按钮、滑块以及您在编辑器中看到的所有图形元素。它也是 Blueprint 小部件的基础。

UnrealEnginePython 允许您使用 Slate api 从 python 构建 GUI。

python 包装器开发由 Kite & Lightning (http://kiteandlightning.la/) 赞助

本文档假设环境为python3。如果您使用的是 python2，请确保在看到字符串时使用 unicode。

它是一项“正在进行的工作”，其目标是为用户提供足够的基础来开始构建其工具。这里只解释了可用小部件的一个有意义的子集，非常欢迎扩展此页面的拉取请求。

<a id="swidget-and-ue_pyswidget"></a>

## SWidget 和 ue_PySWidget

SWidget是所有Slate小部件的C++基类，它包装在名为ue_PySWidget的Python对象（PyObject）中。

每个暴露给 python 的 SWidget 都有其 ue_PySWidget 表示。您可以从这里获取暴露的SWidget列表：https://github.com/20tab/UnrealEnginePython/tree/master/Source/UnrealEnginePython/Private/Slate（带有“UEPyS”前缀的列表）

<a id="swindow"></a>

## SWindow

这是您通常使用的第一个小部件，因为它将是其他小部件的容器。它代表一个窗口：

```python
from unreal_engine import SWindow

window = SWindow(client_size=(512, 512), title='First Slate Window')
```

![SWindow](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SWindow.png)

正如您所看到的，只需实例化 Slate，您就可以创建并显示它们。

在 C++ api 中，每个SWidget 都有其一系列的FArguments (https://api.unrealengine.com/INT/API/Runtime/Slate/Widgets/Input/SComboBox/FArguments/index.html)。

它们是 SWidget 的选项，在 python api 中，您将它们作为参数传递给构造函数（注意使用小写下划线分隔转换的名称的 python 化）。

在这种情况下，ClientSizeFArguments（http://api.unrealengine.com/INT/API/Runtime/SlateCore/Widgets/SWindow/FArguments/ClientSize/index.html）变成“client_size”，标题（http://api.unrealengine.com/INT/API/Runtime/SlateCore/Widgets/SWindow/FArguments/Title/index.html）变成“标题”。请注意从 FVector2D 到简单的 2 元素浮动元组的快捷方式。 （两者都支持）


<a id="stextblock"></a>

## STextBlock

STextBlock (https://api.unrealengine.com/INT/API/Runtime/Slate/Widgets/Text/STextBlock/index.html) 显示一个简单的文本标签：

```python
from unreal_engine import SWindow, STextBlock

window = SWindow(client_size=(512, 512), title='First Slate Window')

text = STextBlock(text='Hello i am an STextBlock')

window.set_content(text)
```

![STextBlock](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_STextBlock.png)

再次使用 FArguments (https://api.unrealengine.com/INT/API/Runtime/Slate/Widgets/Text/STextBlock/FArguments/index.html) 您可以（作为示例）将文本的颜色设置为红色：

```python
from unreal_engine import SWindow, STextBlock, FLinearColor
from unreal_engine.structs import SlateColor

window = SWindow(client_size=(512, 512), title='First Slate Window')

red = SlateColor(SpecifiedColor=FLinearColor(1, 0, 0))

text = STextBlock(text='Hello i am an STextBlock', color_and_opacity=red)

window.set_content(text)
```

![STextBlock红色](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_STextBlock_red.png)

<a id="dynamic-binding-for-farguments"></a>

## 动态绑定FArguments

与 C++ Slate 一样，您可以将“委托”（好吧，Python 中的可调用对象）映射到某些 FArguments。例如，您可以动态更改 STextBlock 的“文本”属性，使其随当前时间不断更新：

```python
from unreal_engine import SWindow, STextBlock, FLinearColor
from unreal_engine.structs import SlateColor
import time

window = SWindow(client_size=(512, 512), title='First Slate Window')

red = SlateColor(SpecifiedColor=FLinearColor(1, 0, 0))

text = STextBlock(text=lambda: str(time.time()), color_and_opacity=red)

window.set_content(text)
```

显然，您可以使用普通函数代替 lambda（任何可调用的都可以）：

```python
from unreal_engine import SWindow, STextBlock, FLinearColor
from unreal_engine.structs import SlateColor
import time

def what_time_is_it():
    return str(time.time())

window = SWindow(client_size=(512, 512), title='First Slate Window')

red = SlateColor(SpecifiedColor=FLinearColor(1, 0, 0))

text = STextBlock(text=what_time_is_it, color_and_opacity=red)

window.set_content(text)
```

<a id="content-assignment-shortcut"></a>

## 内容分配快捷方式

在前面的示例中，我们了解了如何使用 set_content() 将 STextBlock 添加到 SWindow。

这是处理 GUI 的一种非常“程序化”的方式。从技术上讲，Slate（以及其他工具包）强制开发人员在描述用户界面时采用非常“可视化”的风格。因此，如果您不喜欢“过程”方法，则可以滥用 ue_PySWidget 对象的特定功能：当它们是容器时，它们是“可调用的”，并且调用它们将在内部调用 set_content() （或类似的）。

基于此你可以这样重写第一个STextBlock示例：

```python
from unreal_engine import SWindow, STextBlock

window = SWindow(client_size=(512, 512), title='First Slate Window')(STextBlock(text='Hello i am an STextBlock'))
```
或“视觉上”更好（注意SWindow同一行中打开的括号）

```python
from unreal_engine import SWindow, STextBlock

window = SWindow(client_size=(512, 512), title='First Slate Window')(
    STextBlock(text='Hello i am an STextBlock')
)
```

<a id="sverticalbox"></a>

## SVerticalBox

盒子是容器中 organize/align 多个小部件的众多 Slate 方法之一。

SVerticalBox (https://api.unrealengine.com/INT/API/Runtime/SlateCore/Widgets/SVerticalBox/index.html) 是一个盒子，允许您在容器中垂直对齐小部件（盒子的每个元素都被命名为“slot”，很多有效地包含小部件以及各种属性）：

```python
from unreal_engine import SWindow, STextBlock, SVerticalBox

window = SWindow(client_size=(512, 512), title='First Slate Window')

vertical_box = SVerticalBox()

vertical_box.add_slot(STextBlock(text='Hello i am an STextBlock [line 0]'))
vertical_box.add_slot(STextBlock(text='Hello i am an STextBlock [line 1]'))
vertical_box.add_slot(STextBlock(text='Hello i am an STextBlock [line 2]'))

window.set_content(vertical_box)
```

![SVerticalBox](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SVerticalBox.png)

或者以“视觉”风格（始终注意在 SWindow 的同一行中第一个打开的括号来伪造解析器）：

```python
from unreal_engine import SWindow, STextBlock, SVerticalBox

window = SWindow(client_size=(512, 512), title='First Slate Window')(
    SVerticalBox()
    (
        STextBlock(text='Hello i am an STextBlock [line 0]')
    )
    (
        STextBlock(text='Hello i am an STextBlock [line 1]')
    )
    (
        STextBlock(text='Hello i am an STextBlock [line 2]')
    )
)
```

<a id="slot-attributes"></a>

## 插槽属性

我们已经看到，盒子和各种小部件之间的映射是由“槽”管理的。每个槽描述了一个小部件在盒子中的管理方式（主要是对齐和填充）：

```python
from unreal_engine import SWindow, STextBlock, SVerticalBox
from unreal_engine.enums import EVerticalAlignment, EHorizontalAlignment

window = SWindow(client_size=(512, 512), title='First Slate Window')

vertical_box = SVerticalBox()

vertical_box.add_slot(STextBlock(text='Hello i am an STextBlock [line 0]'), auto_height=True, padding=(10, 20, 10, 100))
vertical_box.add_slot(STextBlock(text='Hello i am an STextBlock [line 1]'), max_height=173, h_align=EHorizontalAlignment.HAlign_Center)
vertical_box.add_slot(STextBlock(text='Hello i am an STextBlock [line 2]'), h_align=EHorizontalAlignment.HAlign_Right, v_align=EVerticalAlignment.VAlign_Bottom, padding=(0, 0, 50, 50))

window.set_content(vertical_box)
```

![插槽](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_Slot.png)

第一个槽的高度将自动映射到所包含小部件的高度（STextBlock），并且顶部填充10单位，左侧填充20，右侧填充10，底部填充100。 （稍后将详细介绍填充）。

第二个时隙的起始位置比第一个时隙低 100 个单位（由第一个时隙的填充引起）。其内容将与中心对齐，最大高度为173单位（我们在这里使用“最大”措辞，因为SVerticalBox对齐可能会被迫使其更小）。

第三个槽向右并垂直于底部对齐，并以 rght/bottom 填充50 单位。

有用的链接：

https://api.unrealengine.com/INT/API/Runtime/SlateCore/Widgets/SVerticalBox/FSlot/index.html

https://api.unrealengine.com/INT/API/Runtime/SlateCore/Types/EHorizontalAlignment/index.html

https://api.unrealengine.com/INT/API/Runtime/SlateCore/Types/EVerticalAlignment/index.html



很难看出这里发生了什么，但添加 SBorder 会澄清事情......

<a id="sborder"></a>

## SBorder

SBorder 是一个特殊的容器，它将在其包含的小部件周围添加边框：

```python
from unreal_engine import SWindow, STextBlock, SVerticalBox, SBorder
from unreal_engine.enums import EVerticalAlignment, EHorizontalAlignment

window = SWindow(client_size=(512, 512), title='First Slate Window')

vertical_box = SVerticalBox()

vertical_box.add_slot(SBorder()(STextBlock(text='Hello i am an STextBlock [line 0]')), auto_height=True, padding=(10, 20, 10, 100))
vertical_box.add_slot(SBorder()(STextBlock(text='Hello i am an STextBlock [line 1]')), max_height=173, h_align=EHorizontalAlignment.HAlign_Center)
vertical_box.add_slot(SBorder()(STextBlock(text='Hello i am an STextBlock [line 2]')), h_align=EHorizontalAlignment.HAlign_Right, v_align=EVerticalAlignment.VAlign_Bottom, padding=(0, 0, 50, 20))

window.set_content(SBorder()(vertical_box))
```

![SBorder](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SBorder.png)

现在插槽属性应该更加清晰了。请注意，SBorder有一个set_content()方法，但这里我们使用“视觉”风格（与程序风格混合）：

```python
SBorder()(STextBlock(text='Hello i am an STextBlock [line 0]'))
```

SBorder 的 FArguments 列表可在此处获取：https://api.unrealengine.com/INT/API/Runtime/Slate/Widgets/Layout/SBorder/FArguments/

<a id="padding"></a>

## 填充

槽的填充属性定义了它们的边距大小。

python api 中的填充接受各种形式：

```python
from unreal_engine import SWindow, STextBlock, SVerticalBox, SBorder
from unreal_engine.enums import EVerticalAlignment, EHorizontalAlignment

window = SWindow(client_size=(512, 512), title='First Slate Window')

vertical_box = SVerticalBox()

vertical_box.add_slot(SBorder()(STextBlock(text='Hello i am an STextBlock [line 0]')), padding=100, v_align=EVerticalAlignment.VAlign_Fill)

window.set_content(SBorder()(vertical_box))
```

传递单个浮点数将为顶部、左侧、底部和右侧指定相同数量的单位：

![填充](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_Padding.png)

```python
from unreal_engine import SWindow, STextBlock, SVerticalBox, SBorder
from unreal_engine.enums import EVerticalAlignment, EHorizontalAlignment

window = SWindow(client_size=(512, 512), title='First Slate Window')

vertical_box = SVerticalBox()

vertical_box.add_slot(SBorder()(STextBlock(text='Hello i am an STextBlock [line 0]')), padding=(100, 100), v_align=EVerticalAlignment.VAlign_Fill)

window.set_content(SBorder()(vertical_box))
```

2-items 浮动元组将指定顶部和左侧，并将底部和右侧强制为0：

![填充2](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_Padding2.png)

```python
from unreal_engine import SWindow, STextBlock, SVerticalBox, SBorder
from unreal_engine.enums import EVerticalAlignment, EHorizontalAlignment

window = SWindow(client_size=(512, 512), title='First Slate Window')

vertical_box = SVerticalBox()

vertical_box.add_slot(SBorder()(STextBlock(text='Hello i am an STextBlock [line 0]')), padding=(100, 100, 30, 30), v_align=EVerticalAlignment.VAlign_Fill)

window.set_content(SBorder()(vertical_box))
```

我们已经看到了 4-items 浮动元组来指定顶部、左侧、底部和右侧：

![填充3](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_Padding3.png)

除了 float/float-tuples 之外，您还可以使用 FMargin 结构指定填充：

```python
from unreal_engine.structs import Margin
print(Margin.properties())
```
回报

```python
['Left', 'Top', 'Right', 'Bottom']
```

所以：

```python
from unreal_engine import SWindow, STextBlock, SVerticalBox, SBorder
from unreal_engine.enums import EVerticalAlignment, EHorizontalAlignment
from unreal_engine.structs import Margin

window = SWindow(client_size=(512, 512), title='First Slate Window')

vertical_box = SVerticalBox()

vertical_box.add_slot(SBorder()(STextBlock(text='Hello i am an STextBlock [line 0]')), padding=Margin(Left=100, Right=50), v_align=EVerticalAlignment.VAlign_Fill)

window.set_content(SBorder()(vertical_box))
```

![填充4](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_Padding4.png)

<a id="shorizontalbox"></a>

## SHorizontalBox

SHorizontalBox 允许您水平对齐容器中的小部件：

```python
from unreal_engine import SWindow, STextBlock, SHorizontalBox, SBorder
from unreal_engine.enums import EVerticalAlignment, EHorizontalAlignment
from unreal_engine.structs import Margin

window = SWindow(client_size=(512, 512), title='First Slate Window')

horizontal_box = SHorizontalBox()

horizontal_box.add_slot(SBorder()(STextBlock(text='Left')), padding=Margin(Left=100, Right=50, Bottom=30), v_align=EVerticalAlignment.VAlign_Fill)
horizontal_box.add_slot(SBorder()(STextBlock(text='Right')), padding=Margin(Left=10, Right=20, Top=50), v_align=EVerticalAlignment.VAlign_Fill)

window.set_content(SBorder()(horizontal_box))
```

![SHorizontalBox](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SHorizontalBox.png)

显然，您可以组合垂直和水平框（这次使用“视觉”样式）

```python
from unreal_engine import SWindow, STextBlock, SHorizontalBox, SVerticalBox, SBorder, FLinearColor
from unreal_engine.enums import EVerticalAlignment, EHorizontalAlignment, ETextJustify
from unreal_engine.structs import Margin, SlateColor

SWindow(client_size=(512, 256), title='Slate Window')(
    SVerticalBox()
    (
        SHorizontalBox()
        (
            SBorder()(STextBlock(text='Left top', justification=ETextJustify.Center)), v_align=EVerticalAlignment.VAlign_Fill
        )
        (
            SBorder(border_background_color=SlateColor(SpecifiedColor=FLinearColor.Green))(STextBlock(text='Right top', highlight_text='Right'))
        )
    )
    (
        SHorizontalBox()
        (
            SBorder(border_background_color=SlateColor(SpecifiedColor=FLinearColor(1, 0, 0)), padding=20)
            (
                STextBlock(text='Left bottom')
            ), v_align=EVerticalAlignment.VAlign_Fill
        )
        (
            SBorder()(STextBlock(text='Middle bottom', justification=ETextJustify.Right)), v_align=EVerticalAlignment.VAlign_Center
        )
        (
            SBorder(border_background_color=SlateColor(SpecifiedColor=FLinearColor.Yellow))(STextBlock(text='Right bottom')), v_align=EVerticalAlignment.VAlign_Fill
        )
    )
)
```

![SHorizontalBox2](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SHorizontalBox2.png)

有关SHorizontalBox的更多信息：https://api.unrealengine.com/INT/API/Runtime/SlateCore/Widgets/SHorizontalBox/index.html

<a id="sgridpanel"></a>

## SGridPanel

该小部件允许您在虚拟网格中对齐子项。对于每个插槽，您指定列和行，以及最终它水平和垂直“跨越”的程度：

```python
from unreal_engine import SWindow, STextBlock, SGridPanel, SBorder

margin = 40

SWindow(client_size=(512, 512), title='Slate Window')(
    SGridPanel()
    (
        SBorder(padding=margin)(STextBlock(text='cell0')), column=0, row=0
    )
    (
        SBorder(padding=margin)(STextBlock(text='cell1')), column=1, row=0
    )
    (
        SBorder(padding=margin)(STextBlock(text='cell2')), column=2, row=0
    )
    (
        SBorder(padding=margin)(STextBlock(text='cell3')), column=0, row=1
    )
    (
        SBorder(padding=margin)(STextBlock(text='cell4')), column=3, row=1, row_span=3
    )
    (
        SBorder(padding=margin)(STextBlock(text='cell5')), column=2, row=2
    )
    (
        SBorder(padding=margin)(STextBlock(text='cell6')), column=0, row=3, column_span=2
    )
)
```

![SGridPanel](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SGridPanel.png)

<a id="sscrollbox"></a>

## SScrollBox

该容器允许您滚动大系列的小部件：

```python
from unreal_engine import SWindow, STextBlock, SGridPanel, SBorder, SScrollBox
from unreal_engine.enums import EOrientation

margin = 40

SWindow(client_size=(512, 256), title='Slate Window')(
    SScrollBox(orientation=EOrientation.Orient_Vertical)
    (
        SGridPanel()
        (
            SBorder(padding=margin)(STextBlock(text='cell0')), column=0, row=0
        )
        (
            SBorder(padding=margin)(STextBlock(text='cell1')), column=1, row=0
        )
        (
            SBorder(padding=margin)(STextBlock(text='cell2')), column=2, row=0
        )
        (
            SBorder(padding=margin)(STextBlock(text='cell3')), column=0, row=1
        )
        (
            SBorder(padding=margin)(STextBlock(text='cell4')), column=3, row=1, row_span=3
        )
        (
            SBorder(padding=margin)(STextBlock(text='cell5')), column=2, row=2
        )
        (
            SBorder(padding=margin)(STextBlock(text='cell6')), column=0, row=3, column_span=2
        )
    )
)
```

![SScrollBox](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SScrollBox.png)

更多信息在这里：https://api.unrealengine.com/INT/API/Runtime/Slate/Widgets/Layout/SScrollBox/

<a id="sbutton"></a>

## SButton

是时候进行用户交互了。当用户点击 SButton 小部件时，它会引发一个事件：

```python
from unreal_engine import SWindow, SVerticalBox, SButton
from unreal_engine.enums import EHorizontalAlignment
import unreal_engine as ue
import time

window = SWindow(client_size=(512, 256), title='Slate Window')(
    SVerticalBox()
    (
        SButton(text='Button 001', on_clicked=lambda: ue.log('Hello i am Button001'))
    )
    (
        SButton(text='Button 002', h_align=EHorizontalAlignment.HAlign_Center, on_clicked=lambda: (ue.message_dialog_open(ue.APP_MSG_TYPE_OK, 'Hello i am Button002'), window.bring_to_front()))
    )
    (
        SButton(text='Update title with current time', on_clicked=lambda: window.set_title(str(time.time())))
    )
    (
        SButton(text='Close Window', on_clicked=lambda: window.request_destroy())
    )
)
```

![SButton](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SButton.png)

请注意，从技术上讲，SButton是容器，因此您可以为它们分配另一个小部件：

```python
SButton(on_clicked=lambda: window.request_destroy())(STextBlock(text='Hello'))
```

更多信息在这里：https://api.unrealengine.com/INT/API/Runtime/Slate/Widgets/Input/SButton/index.html

<a id="simage"></a>

## SImage

该小部件绘制图形资源（图像、实体块）。

```python
from unreal_engine import SWindow, SImage, SVerticalBox, FLinearColor, SBorder
from unreal_engine.structs import SlateBrush, SlateColor, Vector2D
from unreal_engine.classes import Texture2D
import unreal_engine as ue
import os

plugin = unreal_engine.find_plugin('UnrealEnginePython')
plugin_base_dir = plugin.get_base_dir()

image_file = os.path.join(plugin_base_dir, 'Resources/Icon128.png')

texture = ue.load_object(Texture2D, '/Game/Mannequin/Character/Textures/UE4_LOGO_CARD')


window = SWindow(client_size=(128, 512), title='Slate Window', sizing_rule=0)(
    SVerticalBox()
    (
        SImage(image=SlateBrush(ResourceName=image_file, bIsDynamicallyLoaded=True)),
    )
    (
        SImage(image=SlateBrush(ResourceObject=texture))
    )
    (
        SImage(image=SlateBrush(TintColor=SlateColor(SpecifiedColor=FLinearColor(1, 0, 0))))
    )
    (
        SImage(image=SlateBrush(ResourceName=image_file, bIsDynamicallyLoaded=True, TintColor=SlateColor(SpecifiedColor=FLinearColor(0, 1, 0))))
    )
    (
        SBorder()(SImage(image=SlateBrush(ResourceObject=texture, ImageSize=Vector2D(X=64, Y=64)))), auto_height=True
    )
)    
```

![SImage](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SImage.png)

请注意SlateBrush的bIsDynamicallyLoaded字段，如果您传递非ue4资源（通过ResourceName），则必须指示UE将资源作为纹理加载（通过将bIsDynamicallyLoaded设置为true）。使用ResourceObject时不需要这样做。

组合 SButton 和 SImage 非常方便：

```python
SButton(on_clicked=lambda: ue.log('Image Clicked'))(SImage(image=SlateBrush(ResourceName=image_file, bIsDynamicallyLoaded=True)))
```

有关SlateBrush的更多信息：

https://api.unrealengine.com/INT/API/Runtime/SlateCore/Styling/FSlateBrush/index.html


<a id="seditabletextbox"></a>

## SEditableTextBox

该小部件允许用户输入字符串：

```python
from unreal_engine import SWindow, SEditableTextBox, SHorizontalBox, SButton
from unreal_engine.classes import Object
import unreal_engine as ue

asset_name=SEditableTextBox()

window = SWindow(client_size=(512, 32), title='Open Asset', sizing_rule=0)(
    SHorizontalBox()
    (
        asset_name
    )
    (
        SButton(text='Ok', on_clicked=lambda: ue.open_editor_for_asset(ue.load_object(Object, asset_name.get_text()))), auto_width=True
    )
)    
```

![SEditableTextBox](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SEditableTextBox.png)

get_text() 方法将返回当前插入的文本。

当用户单击“确定”时，SEditableTextBox中指定的资源将被验证、加载并在相关编辑器中打开。

更多信息（查看FArguments）：

https://api.unrealengine.com/INT/API/Runtime/Slate/Widgets/Input/SEditableTextBox/index.html


<a id="the-assign-hack"></a>

## .assign() 黑客

在前面的示例中，我们使用“混合”视觉样式来允许将 SEditableTextBox 分配给 python 变量，以便能够在 on_clicked 事件中引用它。

python SWidget api 支持另一种方法来分配对 SWidget 的引用。这确实是一个 hack（老实说不是很 Pythonic），但是对于大接口来说应该大大简化管理：

```python
from unreal_engine import SWindow, SEditableTextBox, SHorizontalBox, SButton
from unreal_engine.classes import Object
import unreal_engine as ue

asset_name=None

window = SWindow(client_size=(512, 32), title='Open Asset', sizing_rule=0)(
    SHorizontalBox()
    (
        SEditableTextBox().assign('asset_name')
    )
    (
        SButton(text='Ok', on_clicked=lambda: ue.open_editor_for_asset(ue.load_object(Object, asset_name.get_text()))), auto_width=True
    )
)   
```

基本上， .assign(global_name) 方法会将 SWidget 映射到指定为 global_name 的全局项。 .assign() 方法将检查传递的名称的有效性，因此拼写错误不会成为问题。

<a id="scheckbox"></a>

## SCheckBox

对于管理布尔值非常有用：

```python
from unreal_engine import SWindow, SEditableTextBox, SHorizontalBox, SButton, SCheckBox, STextBlock
from unreal_engine.classes import Object
from unreal_engine.enums import EVerticalAlignment
import unreal_engine as ue

asset_name=None
checkbox_bool=False

def open_or_validate(path, only_validate):
    try:
        asset = ue.load_object(Object, path)
    except:
        ue.message_dialog_open(ue.APP_MSG_TYPE_OK, 'invalid path')
        return
        
    if only_validate:
        ue.message_dialog_open(ue.APP_MSG_TYPE_OK, 'path is valid')
    else:
        ue.open_editor_for_asset(asset)

window = SWindow(client_size=(512, 32), title='Open Asset', sizing_rule=0)(
    SHorizontalBox()
    (
        SEditableTextBox().assign('asset_name')
    )
    (
        STextBlock(text='only validate path'), auto_width=True, v_align=EVerticalAlignment.VAlign_Center
    )
    (
        SCheckBox().assign('checkbox_bool'), auto_width=True
    )
    (
        SButton(text='Ok', on_clicked=lambda: open_or_validate(asset_name.get_text(), checkbox_bool.is_checked())), auto_width=True
    )
)   
```

![SCheckBox](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SCheckBox.png)

<a id="oop-refactoring"></a>

## 面向对象重构

是时候重构代码使其更加优雅，并允许重用custom/complex小部件了：

```python
from unreal_engine import SWindow, SEditableTextBox, SHorizontalBox, SButton, SCheckBox, STextBlock, SVerticalBox
from unreal_engine.classes import Object
from unreal_engine.enums import EVerticalAlignment
import unreal_engine as ue

class AssetOpener(SHorizontalBox):

    def __init__(self):
        super().__init__(self)
        self.asset_name_picker = SEditableTextBox()
        self.only_validate_path = SCheckBox()

        self.add_slot(self.asset_name_picker)
        self.add_slot(STextBlock(text='only validate path'), auto_width=True, v_align=EVerticalAlignment.VAlign_Center)
        self.add_slot(self.only_validate_path, auto_width=True)
        self.add_slot(SButton(text='Ok', on_clicked=self.open_or_validate), auto_width=True)

    def open_or_validate(self):
        try:
            asset = ue.load_object(Object, self.asset_name_picker.get_text())
        except:
            ue.message_dialog_open(ue.APP_MSG_TYPE_OK, 'invalid path')
            return
        
        if self.only_validate_path.is_checked():
            ue.message_dialog_open(ue.APP_MSG_TYPE_OK, 'path is valid')
        else:
            ue.open_editor_for_asset(asset)
       


window = SWindow(client_size=(512, 64), title='Open Asset', sizing_rule=0)(
    SVerticalBox()
    (
        STextBlock(text='OOP widget below')
    )
    (
        AssetOpener()
    )
)    
```

![面向对象](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_OOP.png)

如您所见，您可以从SWidget继承。显然，您可以将“视觉”风格与完全程序化的风格混合在一起，但是类的使用将简化“上下文”管理。

<a id="sobjectpropertyentrybox"></a>

## SObjectPropertyEntryBox

该小部件允许用户从特定类别中选择资产

```python
from unreal_engine import SWindow, SObjectPropertyEntryBox
from unreal_engine.classes import Material
import unreal_engine as ue



window = SWindow(client_size=(512, 256), title='Material Selector', sizing_rule=0)(
    (  
        SObjectPropertyEntryBox(allowed_class=Material, on_object_changed=lambda choice: ue.open_editor_for_asset(choice.get_asset()))
    )
)    
```

![SObjectPropertyEntryBox](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SObjectPropertyEntryBox.png)

请注意，on_object_changed执行的可调用函数接收一个FAssetData对象作为参数（这就是为什么我们需要调用get_asset()）

更多信息在这里：https://api.unrealengine.com/INT/API/Editor/PropertyEditor/SObjectPropertyEntryBox/index.html

<a id="spythoneditorviewport"></a>

## SPythonEditorViewport

这可能是最有趣的小部件，一个EditorViewportClient和整个World都在一个SWidget中：

```python
from unreal_engine import SWindow, SPythonEditorViewport, FVector, FRotator
from unreal_engine.classes import Blueprint
import unreal_engine as ue

editor_viewport = SPythonEditorViewport()
world = editor_viewport.get_world()
world.actor_spawn(ue.load_object(Blueprint, '/Game/ThirdPersonCPP/Blueprints/ThirdPersonCharacter').GeneratedClass)
editor_viewport_client = editor_viewport.get_editor_viewport_client()
editor_viewport_client.set_view_location(FVector(-200, 300, 200))
editor_viewport_client.set_view_rotation(FRotator(0, -30, -90))

window = SWindow(client_size=(512, 256), title='Mannequin Properties', sizing_rule=0)(
    (  
        editor_viewport
    )
)   
```

![SPythonEditorViewport](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SPythonEditorViewport.png)

请注意，通过在 SPythonEditorViewport 实例上调用 .simulate(bool) 方法，您可以 enable/disable 世界滴答作响

<a id="nomad-tabs"></a>

## 游牧标签

如果您打算制作一个 slate 工具，您很可能不想生成一个普通的 SWindow，而是需要一个可以在编辑器中 move/rearrange 的底座 (SDockTab)，并且（更重要的是）它是唯一的并且可以从编辑器菜单运行。

这可以通过 nomad tabspawner 一步完成：

```python
from unreal_engine import SWindow, SPythonEditorViewport, FVector, FRotator
from unreal_engine.classes import Blueprint
import unreal_engine as ue


def create_tab(dock_tab):
    editor_viewport = SPythonEditorViewport()
    world = editor_viewport.get_world()
    world.actor_spawn(ue.load_object(Blueprint, '/Game/ThirdPersonCPP/Blueprints/ThirdPersonCharacter').GeneratedClass)
    editor_viewport_client = editor_viewport.get_editor_viewport_client()
    editor_viewport_client.set_view_location(FVector(-200, 300, 200))
    editor_viewport_client.set_view_rotation(FRotator(0, -30, -90))

    editor_viewport.simulate(True)

    dock_tab.set_content(editor_viewport)

ue.register_nomad_tab_spawner('Hello Nomads !', create_tab)
```

![Nomad](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_Nomad.png)

要生成 nomad 选项卡，您需要搜索“Hello Nomads !” Window/Developer 工具菜单中的条目。 （目前无法放置在其他位置）

如果您想生成（或给予焦点）特定选项卡（作为在工具栏按钮扩展器上运行它的示例），只需运行

```python
ue.invoke_tab('Hello Nomads !')
```

<a id="properties-editors"></a>

## 属性编辑器

```python
from unreal_engine import SWindow
import unreal_engine as ue

window = SWindow(client_size=(512, 256), title='Mannequin Properties', sizing_rule=0)(
    (  
        ue.create_detail_view(uobject=ue.get_selected_assets()[0].GeneratedClass.get_cdo())
    )
)    
```

![SDetailView](https://github.com/20tab/UnrealEnginePython/raw/master/docs/screenshots/slate_SDetailView.png)

<a id="extenders"></a>

## 延长器

扩展器允许您使用新条目或按钮“扩展”菜单或工具栏。

检查这个例子：https://github.com/20tab/UnrealEnginePython/blob/master/examples/extenders_example.py

它甚至展示了如何注册新的样式集。

<a id="spythonlistview"></a>

## SPythonListView

<a id="spythontreeview"></a>

## SPythonTreeView

<a id="spythonwidget"></a>

## SPythonWidget

<a id="character-event-user-indices-ue5-port"></a>

## 字符事件用户索引（UE5端口）

`ue.FCharacterEvent(character, repeat, modifier_keys, user_index)`接受可选的第四位置用户索引。现有的two/three-argument调用仍然使用零。例如：

```python
event = ue.FCharacterEvent('x', False, ue.FSlateApplication.get_modifier_keys(), 1)
assert event.get_user_index() == 1
```

构造事件不发送硬件输入。现有的`ue.FSlateApplication.process_key_char_event(event)`调用该用户的本机Slate处理。本机处理可以在辅助 LocalPlayer 的 CommonUI 焦点标记之前创建进程本地 Slate 用户。自动化设备必须声明综合输入设置与物理输入接受分开。
