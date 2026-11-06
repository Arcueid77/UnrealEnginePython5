[English](Transactions_API.md) | [简体中文](Transactions_API.zh-CN.md)

<a id="the-trasaction-api"></a>

交易API
=

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

Unreal Engine 4 中的事务是记录的编辑器命令序列，可以重新执行或恢复。它是undo/redo系统Unreal Engine4的基础。

如果您想检查事务的管理方式，请打开选择“编辑->撤消历史记录”菜单项。

<a id="managing-transactions"></a>

管理交易
-

强烈建议在打开“撤消历史记录”面板的情况下执行命令：

```python
from unreal_engine.classes import Actor, Character
import unreal_engine as ue

# get the editor world
world = ue.get_editor_world()

# begin a new transaction (can be reverted/reapplied)
ue.begin_transaction('My first transaction')
actor1 = world.actor_spawn(Actor)
actor2 = world.actor_spawn(Actor)
actor3 = world.actor_spawn(Actor)
ue.end_transaction()

# begin a new transaction (can be reverted/reapplied)
ue.begin_transaction('My second transaction')
character1 = world.actor_spawn(Character)
character2 = world.actor_spawn(Character)
character3 = world.actor_spawn(Character)
ue.end_transaction()

# undo the two transactions
ue.editor_undo()
ue.editor_undo()

# redo the last one
ue.editor_redo()
```


<a id="managing-transactions-with-property-modification"></a>

通过属性修改管理交易
-
在这个小示例中，我们使用引擎内容中的静态网格对象创建一个圆锥体。我们启动一个事务并将圆锥体移动 15 单位，并使用 `modify` 调用将属性修改推送到撤消堆栈。

```python

import unreal_engine as ue
from unreal_engine import FVector
from unreal_engine.classes import StaticMesh, StaticMeshActor

#Create procedurally a Cone in the Editor
world = ue.get_editor_world()
cone2 = world.actor_spawn(StaticMeshActor)
cone2.StaticMeshComponent.StaticMesh = ue.load_object(StaticMesh, '/Engine/BasicShapes/Cone')

#Start Transaction 
ue.begin_transaction("Move Up +15")
position = cone2.get_actor_location()
position.y += 15

#Call modify to track property changes before setting the position
cone2.modify()
cone2.set_actor_location(position)
ue.end_transaction()

#Undo "Move Up +15"
##ue.editor_undo()
```




<a id="functions"></a>

功能
-

```python
# begin a new transaction with the psecified description (returns the transaction id)
transaction_id = unreal_engine.begin_transaction(description)

# cancel the current transaction
unreal_engine.cancel_transaction()

# end the transaction (returns the next transaction id)
tid = unreal_engine.end_transaction()

# returns True if we are currently into a transaction
is_active = unreal_engine.is_transaction_active()

# get the current transaction name
name = unreal_engine.get_transaction_name()

# redo the current transaction
unreal_engine.redo_transaction()

# reset the current transaction
unreal_engine.reset_transaction()

# get the list of transactions
transactions = unreal_engine.transactions()

# undo (return True on success)
success = unreal_engine.editor_undo()

# red (return True on success)
success = unreal_engine.editor_redo()
```
