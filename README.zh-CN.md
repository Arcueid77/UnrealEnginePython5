[English](README.md) | [简体中文](README.zh-CN.md)

<a id="unrealenginepython"></a>

# UnrealEnginePython

适用于 **UE 5.8.1** 的运行时 Python 脚本与引擎绑定。
可以用 Python 编写玩法、扩展既有 Blueprint 类，并在编辑器及 Win64 打包游戏中运行。

**稳定版 1.0.0 · 2026 年 11 月 6 日**

[下载 1.0.0](https://github.com/Arcueid77/UnrealEnginePython5/releases/tag/v1.0.0)
· [发布说明](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)
· [受支持 API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)
· [示例工程](https://github.com/Arcueid77/UnrealEnginePython5Examples/tree/dev/release-1.0.0)

[文档索引](docs/README.zh-CN.md)

<a id="what-you-can-build"></a>

## 可以用来做什么

- **Python 玩法逻辑**。访问 UObject 反射属性、调用 UFunction，并使用 Actor、组件、容器、委托、定时器及 Enhanced Input。
- **Blueprint Mixin**。保留既有 Blueprint 类身份，为不同对象选择命名 Python Profile。未实现的方法可以回退到原蓝图函数，也可以显式组合 Python 与原函数。
- **Python 定义 Unreal 类型**。生成临时 UClass、FProperty 和 UFunction，并覆盖受支持的反射父类事件。
- **运行时回调管理**。显式解绑委托和输入，使用订阅作用域管理清理及类路由恢复。
- **编辑器工具**。使用资产、Sequencer 和 Slate 辅助接口。

插件使用引擎自带的 Python 运行时。编辑器中的解释器由 Epic 的 PythonScriptPlugin 初始化时，UEP 可以共享该解释器。独立运行时，UEP 负责初始化和管理解释器。公开契约规定了解释器所有权、游戏线程访问及受控重载的边界。
[生命周期与线程](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Lifecycle_Threading_API.zh-CN.md)

<a id="release-support"></a>

## 发布支持范围

| 项目 | 1.0.0 发布范围 |
| --- | --- |
| Unreal Engine | 5.8.1 |
| Python | 引擎自带的 CPython 3.11.8 |
| 平台 | Windows / Win64 |
| 构建配置 | Development 和 Shipping，分别记录验证结果 |
| 交付内容 | 插件源码、匹配的 Examples 源码、验证清单和 SHA256SUMS |

1.0.0 以源码形式分发，需要安装 UE 5.8.1 对应的 Windows C++ 编译工具链。发布记录列出了实际验证的引擎构建及产物来源。
[平台支持](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Platform_Support.zh-CN.md)

<a id="get-100"></a>

## 获取 1.0.0

下载固定版本的源码归档与校验文件。

- [插件源码](https://github.com/Arcueid77/UnrealEnginePython5/releases/download/v1.0.0/UnrealEnginePython-1.0.0-source.zip)
- [匹配的 Examples 源码](https://github.com/Arcueid77/UnrealEnginePython5/releases/download/v1.0.0/UnrealEnginePythonExamples-1.0.0-source.zip)
- [SHA256SUMS.txt](https://github.com/Arcueid77/UnrealEnginePython5/releases/download/v1.0.0/SHA256SUMS.txt)
- [验证清单](https://github.com/Arcueid77/UnrealEnginePython5/releases/download/v1.0.0/validation.json)

通过 Git 获取时，克隆 **v1.0.0 标签**及其固定的 `Demos` 子模块。

```powershell
git clone --branch v1.0.0 --recurse-submodules https://github.com/Arcueid77/UnrealEnginePython5.git UnrealEnginePython5
cd UnrealEnginePython5
```

已有位于该标签的检出目录时，运行 `git submodule update --init Demos` 初始化匹配的示例。

<a id="install-in-a-project"></a>

## 安装到项目

1. 准备 UE 5.8.1 C++ 项目及引擎自带的 Python 运行时。
2. 将插件源码归档解压到 `YourProject/Plugins/UnrealEnginePython`，使 `UnrealEnginePython.uplugin` 直接位于该目录下。
3. 生成项目文件，将项目的 Editor 目标编译为 **Win64 Development**。
4. 打开项目，在插件窗口启用 **UnrealEnginePython**，按提示重启编辑器。

Python 运行时选择与依赖暂存通过 UnrealBuildTool 的 `Python3` 模块完成。

<a id="run-your-first-script"></a>

### 运行第一个脚本

创建 `YourProject/Content/Scripts/ue_site.py`。

```python
import unreal_engine as ue

ue.log("UnrealEnginePython is ready")
```

插件初始化时会导入 `ue_site`。重启编辑器后，可以在 Output Log 中查看该消息。插件的 Python Console 也支持交互式执行 `unreal_engine` 调用。

打包游戏时，项目 Python 脚本需要作为 NonUFS 松散文件暂存，以供 CPython 导入。示例包含完整的构建、暂存和打包运行流程。

<a id="playable-examples"></a>

## 可玩示例

配套示例仓库固定为发布检出中的 `Demos` 子模块。Third Person 驱动会根据引擎官方 Blueprint 模板创建隔离工程，并将插件复制到该工程。

| 示例 | 展示内容 |
| --- | --- |
| Third Person `PythonFirst` | Python 定义的 Character、Controller 和 GameMode，以及移动、相机、收集物与 HUD |
| Third Person `Mixin` | 保留 Blueprint 类、按实例选择 Python Profile、原函数回退与实时 Profile 切换 |
| Lyra 集成 | Python 表现层、选定的游戏 C++ 业务迁移、原生玩法组合，以及生命周期、权威与复制验证 |

在主仓库根目录运行下列命令，将 `-EngineRoot` 设置为本机 UE 5.8.1 安装路径。

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Variant Mixin `
    -Mode Play `
    -Incremental
```

使用 `-Variant PythonFirst` 运行 Python 定义玩法的示例。驱动还提供 `Prepare`、`Audit`、`Smoke` 和 `Package` 模式。
[示例运行流程](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/README.zh-CN.md)

已验收的 Lyra 迁移覆盖 **22 项原定 Blueprint 条件**和 **30 个已确认的游戏 C++ 候选组**，其中 29 组属于生产替换，1 组属于能力验证。完成索引记录了各批次及其验收证据。
[迁移完成索引](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/completion_status.json)

<a id="validation"></a>

## 验证结果

1.0.0 发布记录包含以下已通过的验收项。

| 验收项 | 已记录结果 |
| --- | --- |
| 源码检查 | 5,866 项宿主检查，检查 2,027 个 Python 文件 |
| 通用运行时 | 6 组原生测试、70 项检查，覆盖共享及独立解释器、异常恢复、编辑器与打包运行 |
| Mixin 与生命周期 | 11 条调用矩阵路径，连续 3 次 PIE 及最终清理 |
| Third Person | 两种变体均通过带渲染的编辑器及游戏包运行 |
| Lyra Development | 重新 Cook，每条 Damage/Pawn 路径包含监听服权威端和两个远端客户端，共 16 份独立客户端观测 |
| Lyra Shipping | 源码归档安装、构建、Cook 和打包，13 项异常恢复，以及前端流程和包内 Python 来源核验 |

稳定版采用已通过 `1.0.0-rc.1` 验收的实现。版本化游戏包检查确认了最终 1.0.0 源码组合。发布说明记录了构建来源、复用的源码一致产物，以及不同配置的验证结果。
[稳定版验证记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/v1.0.0/Releases/1.0.0/validation.json)
· [候选版验证详情](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0-rc.1.zh-CN.md)

迁移验收还包含限定负载下的 20 分钟内存及生命周期运行，以及原生/Python 路径的帧率、CPU 和 GameThread 对比。对应记录列出了硬件、负载和测量结果。
[内存与生命周期](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H02-acceptance.json)
· [性能结果](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/RENDERED_PERFORMANCE.zh-CN.md)

<a id="api-and-integration-guides"></a>

## API 与集成指南

- [受支持 API 清单](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)
- [Blueprint Mixin 与 Profile](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Mixin_API.zh-CN.md)
- [Python 定义 Unreal 类](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Subclassing_API.zh-CN.md)
- [UObject 反射与调用](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/uobject_API.zh-CN.md)
- [Enhanced Input](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/EnhancedInput_API.zh-CN.md)
- [运行时订阅](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Runtime_Subscriptions_API.zh-CN.md)
- [所有权、线程与重载](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Lifecycle_Threading_API.zh-CN.md)
- [原生玩法迁移](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Native_Gameplay_Migration.zh-CN.md)

Mixin 路由支持文档规定的反射调用入口和签名。静态函数、RPC、委托及 latent 函数的函数体由其原生或 Blueprint 实现负责。修改生成的 Unreal 类型或反射签名需要重启进程。受控的 Python/Profile 重载通过显式订阅清理和路由恢复完成。

<a id="project-history-and-license"></a>

## 项目历史与许可

本 UE5 延续版本基于 Roberto De Ioris 与 20tab 的 UnrealEnginePython 项目。原始 UE4 文档及早期 UE5 里程碑说明可以在版本历史中查阅。
[原始项目](https://github.com/20tab/UnrealEnginePython)
· [历史 README](https://github.com/Arcueid77/UnrealEnginePython5/blob/v1.0.0/README.md#historical-ue5-migration-notes)

采用 MIT 许可。
[LICENSE](LICENSE)
