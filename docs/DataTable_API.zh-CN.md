[English](DataTable_API.md) | [简体中文](DataTable_API.zh-CN.md)

<a id="the-datatable-api"></a>

# DataTable API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

DataTables 允许您存储（作为资产）结构的“列表”（或更好的字典）。

将DataTable分配给UStruct，然后可以用行填充它。

每行都有唯一的名称和值。该值是与DataTable关联的UStruct的结构。

因此，如果您有一个“FWeaponStruct”，您可以构建一个充满“FWeaponStruct”的DataTable（每行一个）

您可以直接从 python 创建一个 DataTable （除了直接从内容浏览器创建它之外）：

```python
import unreal_engine as ue

from unreal_engine.classes import DataTableFactory
from unreal_engine.structs import Transform

dt_factory = DataTableFactory()
dt_factory.Struct = Transform

dt = dt_factory.factory_create_new('/Game/TransformDataTable')
```

作为 UStruct，Transform 对于 DataTable 来说是完全有效的类型（显然您可以使用任何结构，请检查 https://github.com/20tab/UnrealEnginePython/blob/master/examples/create_user_defined_struct.py 以创建自定义结构）

一旦获得 DataTable 的引用，您就可以使用该 api：

<a id="data_table_add_rowrow_name-struct"></a>

### data_table_add_row（row_name，结构体）

```python
# add an empty Transform
dt.data_table_add_row('FirstRow', Transform())
```

<a id="data_table_remove_rowrow_name"></a>

### data_table_remove_row(row_name)

<a id="data_table_rename_rowold_row_name-new_row_name"></a>

### data_table_rename_row(old_row_name, new_row_name)

<a id="data_table_as_dict"></a>

### data_table_as_dict()

<a id="data_table_as_jsonflags0"></a>

### data_table_as_json（标志=0）

<a id="data_table_find_rowrow_name"></a>

### data_table_find_row(row_name)

<a id="data_table_get_all_rows"></a>

### data_table_get_all_rows()
