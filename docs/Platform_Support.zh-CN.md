[English](Platform_Support.md) | [简体中文](Platform_Support.zh-CN.md)

<a id="platform-support-and-readiness"></a>

# 平台支持与环境准备

<a id="100-support-matrix"></a>

## 1.0.0 支持矩阵

本版本面向 UE5.8.1、引擎自带 CPython3.11 和 Win64。API 范围冻结于[受支持 API 清单](Supported_API_Inventory.zh-CN.md)。

| 配置 | 发布验证 |
| --- | --- |
| Win64 Development | 通用 70 项检查、Mixin 调用及 PIE、PythonFirst/Mixin 带渲染的游戏包，以及 Lyra 双客户端打包验证 |
| Win64 Shipping | 源码归档构建、完整 Lyra Cook/归档、13 项玩法恢复、前端流程及包内 Python 来源核验 |

发布记录列出了各验收项对应的引擎 BuildId、源码组合、二进制和依赖哈希。该版本以源码归档形式交付。[发布说明](Release_1.0.0.zh-CN.md)

<a id="historical-08-target-and-evidence"></a>

## 历史0.8目标和证据

UnrealEnginePython 0.8.0 是一个未发布的候选者，目标是 Win64、Unreal Engine 5.8 和引擎捆绑的 CPython 3.11。使用的历史运行 UE 5.8.0 和 CPython 3.11.8。他们不会验证当前检出目录中的每个更改。核心门编译编辑器和游戏插件目标，运行共享的和UEP拥有的解释器，运行完整的编辑器测试，烹饪Development包并执行打包的游戏。 Lyra门增加了严格的内容准备，独立游戏，同步专用-server/client权威和复制，完整的Win64BuildCookRun和打包的Experience/Pawn/Input/ASC/Health验证以及有界的Python驱动GAS 伤害、权威拒绝、复制和恢复切片。 0.8 门还通过 Pawn 替换、体验拥有的小部件操作 teardown/recreation、重复切图和专用服务器零UI 行为来执行保留类 Python Healthbar 呈现器。

历史0.8结果`20260903-033426`通过了当时实施的`All`车道与`full_acceptance: true`。独立，同步客户端和打包游戏各自观察健康`100 -> 90 -> 100`，3小部件构造和2破坏与平衡委托。专用服务器未创建HUD状态。 BuildCookRun 和打包的运行时退出0，严格的日志通过，并且存档的和经过稳定测试的可执行哈希值匹配。

该Development运行使用了NullRHI并包含`hud_audit: null`。它不能证明渲染的视觉效果或更正的发行契约。结束代码添加了恰好一个演示者和退出后零拥有的回调检查，但它们现在具有主机测试和当前脚本NullRHI独立传递。仍然需要全新的完整实时运行。请参阅[路线图](../ROADMAP.zh-CN.md)和[验证历史](Validation_History.zh-CN.md)。

第一次2026-09-07只读编辑器审核尝试无法启动项目：引擎清单BuildId是`91898095-bb6d-4da0-9340-28669c3653b3`，而分阶段插件和多个引擎插件使用`160ea5ae-f247-4a72-996b-dea22b186e2f`。单独匹配源文件并不能使这些二进制文件兼容。随后，受保护的UBT预检仅发现元数据操作已过时。官方UBT分两次更新了manifests/receipt，并保留了引擎当前的BuildId。未使用手动 GUID 覆盖或 C++ 编译。新的严格审核和独立版随后通过，最终 HUD presenters/references 为零，并且拥有平衡的订阅。这些重点运行不会建立包、网络、渲染或发布验收。

| Win64配置 | 2026-09-07 审核中的证据 |
| --- | --- |
| Development | 历史Editor/Game/package结果如下。当前0.8释放门打开 |
| DebugGame | 被通用驱动程序接受，但未建立保留验证 |
| Shipping | 没有保留验证。当前的通用驱动程序不公开此配置 |

制作游戏1.0支持声明需要在RC期间使用专用的Shipping门。在此之前，Development证据不得被描述为Shipping支持。

历史通用Win64结果`20260812-043408`（2026-08-12）通过了70/70共享、独立、异常边界、Editor/Slate和打包运行时检查。其 Development BuildCookRun 与 UAT ExitCode 0 一起完成。这不是新运行的0.8通用矩阵。

历史Lyra结果`20260812-051532`通过了命名发布代码提交`c797d56`的完整`All`通道并报告了`full_acceptance: true`，包括同步的client/server证据和4,046包Win64BuildCookRun。

0.5 Lyra结果`20260812-234501`通过了扩展的`All`通道，其中`full_acceptance: true`：独立和打包进程证明了准确的运行状况`100 -> 90 -> 100`，客户端证明了`RejectedNotAuthority`，观察到了两个网络角色服务器复制，UAT返回ExitCode0，并且测试的可执行文件哈希值匹配。所有运行时进程均以零严格 fatal/assert/`Log*: Error` 诊断退出0。

然后，0.5目标选择器强化传递了精确源网络结果`20260813-005436`和独立结果`20260813-005835`。两者都使用UE5.8.0、CPython3.11.8以及相同的`100 -> 90 -> 100`合约和干净的日志。没有为最终的 0.5 树重建包，因此 `20260812-234501` 是早期切片的历史包级证据，而不是精确树包声明。

这些工作流程不需要或允许任何Unreal Engine源更改。

<a id="linux-lane"></a>

## Linux 车道

`Validation/Run-UEP58LinuxValidation.sh` 是用于Linux UE5.8 安装的真实build/runtime 通道。它编译编辑器插件和外部 UnrealGame 插件目标，然后使用两个解释器所有者执行核心套件。 GitHub 工作流程需要一个标记为 `linux` 和 `unreal-engine-5.8` 的自托管运行器，并将 `UE_ENGINE_ROOT` 配置为存储库变量。

值机通道并不能证明Linux有效。仅当 `summary.json` 和日志保留为绿色产物后，Linux 才会经过发布验证。

<a id="historical-local-readiness-and-recheck"></a>

## 历史本地准备情况和复查

准备情况结果`20260811-154243`报告Linux未准备好在Win64UE5安装。8在`F:\UnrealEngine`安装，并将`v26_clang-20.1.8-rockylinux8`确定为所需的SDK。 UEP 不会自动安装SDK 或更改引擎树。

在不更改SDK的情况下重新检查：

```powershell
.\Validation\Test-UEP58PlatformReadiness.ps1 -Platform Linux
```

当未做好准备时必须返回失败代码，请在 CI 中使用`-Strict`。

Mac、LinuxArm64、Android 和控制台平台没有 0.8.0 发布级运行时结果，因此不包含在支持声明中。
