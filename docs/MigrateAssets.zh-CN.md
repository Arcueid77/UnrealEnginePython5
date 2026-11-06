[English](MigrateAssets.md) | [简体中文](MigrateAssets.zh-CN.md)

<a id="assets-migration"></a>

# 资产迁移

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

资产迁移是一个允许您将项目的资产导出到另一个虚幻引擎项目的过程。

从编辑器触发它时，您将获得要导出的包列表以及保存它们的位置。

在这里我们将看到如何从 python 自动化任务

<a id="step1-getting-asset-dependencies"></a>

## Step1：获取资产依赖关系

您需要了解的一个重要主题是导出包而不是单个资产。包被映射到真实的文件中。

包可以包含多个资产（尽管强烈建议不要这么做）。

当我们想要迁移资产时，我们需要获取其包以及该资产引用的所有其他包（例如，带有StaticMeshComponent的蓝图，保存对StaticMesh资产的引用，因此我们需要将其导出到）。

unreal_engine.get_asset_dependencies(package_name) 可以解决这个问题：

```python
import unreal_engine as ue

# get the currently selected asset
asset = ue.get_selected_assets()[0]

# retrieve the package path
package_path = asset.get_outermost().get_path_name()
print(package_path)

def recursive_deps(pkg_path, deps):
    deps.append(pkg_path)
    for _dep in ue.get_asset_dependencies(pkg_path):
        if _dep not in deps:
            if not _dep.startswith('/Engine') and not _dep.startswith('/Script'):
                recursive_deps(_dep, deps)


deps = []

recursive_deps(package_path, deps)

print(deps)
```

<a id="step2-fixing-dirty-packages"></a>

## Step2：修复脏包

当一个包被修改但没有保存时，它会被标记为脏。在此步骤中，我们将检查需要迁移的每个包，并最终保存它：

```python
for _dep in deps:
    # load the package
    pkg = ue.load_package(_dep)
    # check for dirty packages
    if pkg.package_is_dirty():
        pkg.save_package()
```

<a id="step3-copying-uasset-files-in-the-destination-project"></a>

## Step3：复制目标项目中的.uasset文件

这是最后一步，我们检索每个包的文件名并将其复制到目标目录中。

完整的迁移脚本：

```python
import unreal_engine as ue
import os
from shutil import copyfile

# get the currently selected asset
asset = ue.get_selected_assets()[0]

# retrieve the package path
package_path = asset.get_outermost().get_path_name()
print(package_path)

def recursive_deps(pkg_path, deps):
    deps.append(pkg_path)
    for _dep in ue.get_asset_dependencies(pkg_path):
        if _dep not in deps:
            if not _dep.startswith('/Engine') and not _dep.startswith('/Script'):
                recursive_deps(_dep, deps)


deps = []

recursive_deps(package_path, deps)

print(deps)

destination = 'D:/UdemyCast/Content'

for _dep in deps:
    # check for dirty packages
    pkg = ue.load_package(_dep)
    if pkg.package_is_dirty():
        pkg.save_package()
    src = pkg.package_get_filename()
    sub = src.split('/Content/', 1)[1]
    dst = os.path.join(destination, sub)
    copyfile(src, dst)

print('asset migrated')
```

确保目标目录是UE4项目中的/Content目录
