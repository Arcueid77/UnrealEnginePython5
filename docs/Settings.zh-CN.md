[English](Settings.md) | [简体中文](Settings.zh-CN.md)

<a id="managing-settings"></a>

管理设置
=

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

设置（编辑器和用户定义）存储在标准 UObject 类中。如果这些类存储特定设置，则为“可变默认对象”。

要访问类的“可变默认对象”，您可以使用 ```unreal_engine.get_mutable_default(class)``` 函数。

以下示例代码显示了如何更改 Editor/Appearance 设置：

```python
import unreal_engine as ue
from unreal_engine.classes import EditorProjectAppearanceSettings
from unreal_engine.enums import EUnit

# access the editor appearance settings
appearance_settings = ue.get_mutable_default(EditorProjectAppearanceSettings)

# print properties
ue.log(appearance_settings.properties())

# assign meters as the default distance/length unit (as list of values)
appearance_settings.DistanceUnits = [EUnit.Meters]

appearance_settings.save_config()
```

另一个改变输入系统的动作映射的例子：

```python
import unreal_engine as ue
from unreal_engine.classes import InputSettings
from unreal_engine.structs import InputActionKeyMapping, Key

inp = ue.get_mutable_default(InputSettings)

km = InputActionKeyMapping()
km.ActionName = 'Kill'
key = Key()
key.KeyName = 'x'
km.Key = key
km.bAlt = True

km2 = InputActionKeyMapping()
km2.ActionName = 'Explode'
key = Key()
key.KeyName = 'y'
km2.Key = key
km2.bAlt = False

inp.ActionMappings = [km, km2]
inp.save_config()
```
