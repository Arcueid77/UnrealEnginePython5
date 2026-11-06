[English](Plugin_API.md) | [简体中文](Plugin_API.zh-CN.md)

<a id="plugin-api"></a>

# 插件API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

这个API公开了Unreal Engine的`IPluginManager`和`IPlugin`接口。从UEP0.6.0开始，发现和描述符读取在编辑器和打包运行时进程中都可用。

<a id="discovering-listing-and-referencing-plugins"></a>

## 发现、列出和引用插件

```python
import unreal_engine as ue

# get the list of all discovered plugins
plugins_list = ue.get_discovered_plugins()

# get the list of enabled plugins
plugins_list = ue.get_enabled_plugins()

# name is the string name of the plugin (like 'UnrealEnginePython' or 'Paper2D')
plugin = ue.find_plugin(name)
```

当当前进程未知插件时，`find_plugin()`返回`unreal_engine.IPlugin`或`None`。

<a id="iplugin-methods"></a>

## IPlugin方法

```python
import unreal_engine as ue

paper2d = ue.find_plugin('Paper2D')

# the name of the plugin
name = paper2d.get_name()

base_dir = paper2d.get_base_dir()

content_dir =  paper2d.get_content_dir()

descriptor_file_name = paper2d.get_descriptor_file_name()

mounted_asset_path = paper2d.get_mounted_asset_path()

can_contain_content = paper2d.can_contain_content()

is_enabled = paper2d.is_enabled()
```

<a id="managing-the-descriptor"></a>

## 管理描述符

您可以 load/write 一个 json 字符串 from/to 插件描述符

布尔参数是 bPluginTypeEnabledByDefault 字段（它是编辑器插件菜单中的“启用”勾选）

```python
# get the current json descriptor of the plugin
json = paper2d.to_json(True)

# load a json in the plugin descriptor
paper2d.from_json(json_blob, True)
```

<a id="iplugin-properties-read-only"></a>

## IPlugin 属性（只读）

```python
.category
.can_contain_content
.enabled_by_default
.installed
.is_beta_version
.requires_build_platform
.created_by
.created_by_url
.description
.docs_url
.file_version
.friendly_name
.marketplace_url
.support_url
.version
.version_name
```
