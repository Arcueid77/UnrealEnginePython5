[English](Graph_API.md) | [简体中文](Graph_API.zh-CN.md)

<a id="add-a-foreachloop-macro-node"></a>

添加ForEachLoop宏节点
-

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

```python
import unreal_engine as ue
from unreal_engine.classes import K2Node_MacroInstance, EdGraph
from unreal_engine.structs import GraphReference

# for_each_loop = ue.load_object(EdGraph, '/Engine/EditorBlueprintResources/StandardMacros.StandardMacros:ForEachLoop')
for_each_loop = ue.find_object('ForEachLoop')

# get a reference to your blueprint
blueprint = ...

# add the node
node = blueprint.UberGraphPages[0].graph_add_node(K2Node_MacroInstance)
# assign the macro graph to the node
node.MacroGraphReference = GraphReference(MacroGraph=for_each_loop)
# allocate pins
node.node_allocate_default_pins()

# update the blueprint
ue.blueprint_mark_as_structurally_modified(bp)
```
