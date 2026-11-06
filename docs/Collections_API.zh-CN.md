[English](Collections_API.md) | [简体中文](Collections_API.zh-CN.md)

<a id="the-collections-api"></a>

# 收藏API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

ICollectionManager类公开了管理资产集合的方法：

```python
from unreal_engine import ICollectionManager

print(ICollectionManager.get_collections())
# 1 means ECollectionShareType::CST_Local
print(ICollectionManager.get_child_collections('FooBar', 1))
```

集合可以是“静态”（它们包含对资产的引用）或“动态”（它们应用搜索字符串来获取资产列表）

该 API 需要了解一堆映射为 int 的枚举：

`ECollectionShareType`

```c
enum Type
{
    CST_System,
    CST_Local,
    CST_Private,
    CST_Shared,
    CST_All,
}
```

`ECollectionStorageMode`

```c
enum Type
{
    Static,
    Dynamic,
}
```



<a id="get_collections"></a>

### get_collections()

以 Python 元组列表形式返回集合列表，格式为 (name, ECollectionShareType)

<a id="get_root_collections"></a>

### get_root_collections()

以 Python 元组列表形式返回根集合列表，格式为 (name, ECollectionShareType)

<a id="get_child_collectionsname-ecollectionsharetype"></a>

### get_child_collections（名称，ECollectionShareType）

返回集合的子集合列表（以名称和类型给出）作为元组的 python 列表，其形式为 (name, ECollectionShareType)

<a id="get_root_collection_names"></a>

### get_root_collection_names()

以 python 字符串列表形式返回根集合的名称

<a id="get_collection_names"></a>

### get_collection_names()

以 Python 字符串列表形式返回集合名称

<a id="create_static_collectionname-ecollectionsharetype"></a>

### create_static_collection（名称，ECollectionShareType）

创建一个给定名称和类型的新静态集合

<a id="create_dynamic_collectionname-ecollectionsharetype"></a>

### create_dynamic_collection（名称，ECollectionShareType）

创建一个给定名称和类型的新动态集合

<a id="create_collectionname-ecollectionsharetype-ecollectionstoragemode"></a>

### create_collection（名称，ECollectionShareType，ECollectionStorageMode）

创建一个给定名称、类型和存储模式的新动态集合

<a id="reparent_collectionname-ecollectionsharetype-new_name-ecollectionsharetype"></a>

### reparent_collection（名称，ECollectionShareType，new_name，ECollectionShareType）

将“name”集合移动到“new_name”父级

<a id="add_to_collectionname-ecollectionsharetype-objectpath"></a>

### add_to_collection（名称，ECollectionShareType，对象路径）

使用资源路径将资源添加到静态集合

<a id="collection_existsname-ecollectionsharetype"></a>

### collection_exists（名称，ECollectionShareType）

如果集合已存在则返回 true

<a id="create_unique_collection_namename-ecollectionsharetype"></a>

### create_unique_collection_name（名称，ECollectionShareType）

返回具有唯一集合名称的字符串

<a id="destroy_collectionname-ecollectionsharetype"></a>

### destroy_collection（名称，ECollectionShareType）

删除现有集合并在成功时返回 true，在失败时返回 false

<a id="empty_collectionname-ecollectionsharetype"></a>

### empty_collection（名称，ECollectionShareType）

从集合中删除所有现有资产。成功时返回 true，失败时返回 false

<a id="get_dynamic_query_textname-ecollectionsharetype"></a>

### get_dynamic_query_text（名称，ECollectionShareType）

从动态集合中返回搜索文本。如果你在静态集合上使用它，你会得到一个错误

<a id="set_dynamic_query_textname-ecollectionsharetype-searchtext"></a>

### set_dynamic_query_text（名称，ECollectionShareType，搜索文本）

将搜索文本设置为动态集合。成功时返回 true，失败时返回 false

<a id="remove_from_collectionname-ecollectionsharetype-objectpath"></a>

### remove_from_collection（名称，ECollectionShareType，对象路径）

使用资产路径从静态集合中删除资产。成功时返回 true，失败时返回 false

<a id="get_assets_in_collectionname-ecollectionsharetype-recursionoptional"></a>

### get_assets_in_collection（名称，ECollectionShareType，递归（可选））

返回包含所有资源路径的列表。还有第三个可选参数用于递归。默认值为1。此函数仅适用于静态集合

<a id="get_objects_in_collectionname-ecollectionsharetype-recursionoptional"></a>

### get_objects_in_collection（名称，ECollectionShareType，递归（可选））

返回包含所有对象路径的列表。还有第三个可选参数用于递归。默认值为1。此函数仅适用于静态集合

<a id="get_classes_in_collectionname-ecollectionsharetype-recursionoptional"></a>

### get_classes_in_collection（名称，ECollectionShareType，递归（可选））

返回包含所有类的列表。还有第三个可选参数用于递归。默认值为1。此函数仅适用于静态集合

<a id="get_parent_collectionname-ecollectionsharetype"></a>

### get_parent_collection（名称，ECollectionShareType）

返回父集合。如果集合没有父集合，则返回 None。

<a id="has_collections"></a>

### has_collections()

如果项目有或没有任何集合，则返回 True 或 False。
