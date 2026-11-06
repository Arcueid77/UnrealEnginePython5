[English](YourFirstAutomatedPipeline_Part2.md) | [简体中文](YourFirstAutomatedPipeline_Part2.zh-CN.md)

<a id="your-first-automated-pipeline-with-unrealenginepython-part-2"></a>

# 您的第一个自动化管道UnrealEnginePython（部分2）

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

在本教程中，我们将了解如何引用之前创建的资源，以及如何使用行为树和 BlackBoard 创建 AI。

最后我们将为 Kaiju 添加一个单元测试。

工作IN进展


<a id="filling-the-blueprint-event-graph"></a>

## 填充Blueprint事件图

TODO：实现触发无聊状态的空闲定时器

<a id="the-blackboard"></a>

## BlackBoard

```python
from unreal_engine.classes import BlackBoardDataFactory
from unreal_engine.classes import BlackboardKeyType_Bool, BlackboardKeyType_String

from unreal_engine.structs import BlackboardEntry

```

<a id="the-behavior-tree-graph"></a>

## 行为树图

TODO：实现一个装饰器检查球体中的 pawn，创建一个带有“移动到”、“引发事件（攻击）”、“等待”序列的 bt

<a id="the-kaiju-brain"></a>

## 怪兽大脑

TODO：将bt分配给Kaiju的AIController

<a id="testing-it"></a>

## 测试一下

TODO：编写一个单元测试，用一个哑棋子实例化 Kaiju 并检查其虚拟球体中的棋子。
