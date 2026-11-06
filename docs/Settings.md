[English](Settings.md) | [简体中文](Settings.zh-CN.md)

Managing Settings
=

> API examples and upstream reference. The [1.0.0 supported API inventory](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.md) defines the release contract. Individual examples record their original environment.

Settings (both Editor and User-defined) are stored in standard UObject classes. The "mutable default object" if those classes is what stores the specific settings.

To access the "mutable default object" of a class you can use the ```unreal_engine.get_mutable_default(class)``` function.

The following example code shows how to change the Editor/Appearance settings:

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

Another example changing action mappings of the input system:

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
