[English](Lyra_Gameplay_Slice_0.5.0.md) | [简体中文](Lyra_Gameplay_Slice_0.5.0.zh-CN.md)

<a id="python-driven-lyra-gameplay-slice-for-050"></a>

# Python驱动的Lyra0.5.0的游戏切片

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

<a id="scope"></a>

## 适用范围

版本0.5.0推进了0.4Lyra从观察到故意狭窄的游戏玩法编写的桥梁。 Python 选择命令ID、健康增量、目标角色和时间。项目端 C++ 适配器验证策略并调度 Lyra 的现有游戏效果。 Lyra仍然拥有其能力系统、属性、伤害执行、游戏阶段和复制。

该实施分为完整的Lyra项目的一次性副本。它不会编辑 Unreal Engine 源或外部 Lyra 参考项目。支持的解释器仍然是引擎捆绑的 CPython 3.11。

<a id="ownership-boundary"></a>

## 所有权边界

| 关注 | 业主 | 0.5行为 |
| --- | --- | --- |
| 命令ID、damage/heal值和排序 | Python探头 | 选择10点伤害命令，等待复制观察，然后选择恢复命令 |
| 线索、权威、目标和价值政策 | `UEPLyraBridge` | 拒绝游戏外的调用thread/server、不明确的目标、不安全的IDs或幅度、致命伤害、过度治疗和重复 |
| 体验和游戏功能激活 | Lyra | Python等待原生体验和功能状态。它不会激活它们 |
| 损伤免疫 | Lyra GAS/game 阶段 | 快照暴露免疫性并且命令返回`RejectedDamageImmune`。 Python 等待而不是绕过它 |
| damage/heal执行 | Lyra GAS | 桥创建Lyra配置的SetByCallerDamage/Heal规范并通过目标ASC应用它 |
| 健康存储和复制 | Lyra 属性集 | 没有引入直接的运行状况属性写入或自定义复制路径 |
| client/server同步 | Python 探针加文件系统证据 | 对等方使用原子 JSON 确认，因此恢复无法领先于客户端伤害观察 |

这是Python驱动的垂直切片，而不是Python重写Lyra。行为决策和编排是Python。对性能和权威敏感的原语仍然是原生的。

<a id="reflected-command"></a>

## 反射命令

`UUEPLyraWorldSubsystem::ApplyAuthorityHealthDelta`接受：

- 仅包含字母、数字、`.`、`_`或`-`的命令ID，最多96字符。
- 一个有限的、非零的健康增量，其绝对值至多为25。和
- 精确、明确的目标策略：一名本地玩家用于单机游戏或一名远程`APlayerController`用于专用服务器。

该命令要求：

- Unreal的游戏线程。
- 非客户端世界和权威目标Pawn。
- 初始化的LyraPawn扩展，ASC和健康组件。
- 造成至少一项生命值的损害。
- 治疗量不超过MaxHealth。和
- 未使用的命令ID。

可接受的伤害使用`ULyraGameData::DamageGameplayEffect_SetByCaller`和`LyraGameplayTags::SetByCaller_Damage`。治疗使用匹配配置的治疗效果和标签。如果观察到的增量不存在或与请求不同，桥会立即读回运行状况并报告失败。

结果结构记录了command/status、accepted/applied标志、服务器权威、目标路径、请求的增量和before/after/max健康状况。预期的拒绝是数据，而不是`Log*: Error`消息。

重要的结果状态包括：

| 状态 | 含义 |
| --- | --- |
| `Applied` | Lyra GAS 按确切请求的增量更改了运行状况 |
| `RejectedNotAuthority` | 客户端尝试写入。没有生成RPC |
| `RejectedDuplicateCommand` | 权威已使用该命令ID |
| `RejectedDamageImmune` | Lyra当前游戏阶段可阻挡伤害 |
| `RejectedAmbiguousTarget` | 多个玩家控制器与请求的local/remote角色匹配 |
| `RejectedInvalidCommandId` / `RejectedInvalidMagnitude` | 输入超出有界命令格式 |
| `RejectedUnsafeDamage` / `RejectedUnsafeHeal` | 该请求会杀死或过度治疗目标 |
| `RejectedNoTarget` / `RejectedNoAbilitySystem` / `RejectedNoHealth` | 确切的Lyra游戏目标尚未准备好 |
| `FailedNoObservedChange` / `FailedUnexpectedDelta` | 原生效果没有产生预期的结果 |

<a id="automated-sequence"></a>

## 自动序列

探针等待经验、`ShooterCore`、正确的local/remote角色、Pawn、PlayerState、ASC、生命值和Lyra损伤免疫力结束。运行时URLs请求三个LyraAI机器人，以便真正的预热阶段前进。机器人控制器不是`APlayerController`目标。

单机和打包执行证明：

1. Python 授权提交`-10`，并通过`100 -> 90` 接收`Applied`。
2. Python 重复相同的命令 ID 并接收 `RejectedDuplicateCommand`，没有第二次更改。
3. 稍后的 Python 刻度通过快照观察运行状况 90。
4. Python提交`+10`，接收`Applied`，随后观察到健康状况恢复到100。

Dedicated-server/client执行证明：

1. 客户端Python提交`-10`，接收`RejectedNotAuthority`，验证健康状态100并自动发布`client-denied.json`。
2. 服务器Python等待该证据，将`-10`应用于确切的远程玩家的ASC，证明重复拒绝并发布`server-damaged.json`。
3. 客户端Python等待，直到复制的运行状况为90，然后发布`client-damage-observed.json`。
4. 服务器Python在应用`+10`和发布`server-restored.json`之前等待客户端观察。
5. 客户端Python等待，直到复制的运行状况返回到100并发布`client-restore-observed.json`。
6. 这两个过程仅在完整序列后完成，然后穿过驾驶员现有的共享出口门。

专用服务器仅绑定`127.0.0.1`。验证不会将侦听器暴露给 LAN。

<a id="reproducing-the-gates"></a>

## 再现大门

快速本地游戏迭代（编辑器构建加独立版，无Cook/package）：

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -Mode Standalone `
    -Incremental
```

Dedicated-server/client 复制通道（无Cook/package）：

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -Mode Network `
    -Incremental
```

正式发布验收增加了新的Standalone/network通证、Win64BuildCookRun并打包执行：

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -Mode All `
    -Incremental
```

默认情况下，每个运行时模式都会启用游戏切片。诊断后向兼容运行可以使用`-SkipGameplaySlice`，但这样的`All`运行无法设置`full_acceptance: true`。 `-GameplaySliceDamage`可以从0.01到25中选择一个值。默认和发布合约使用10。

<a id="current-evidence"></a>

## 目前的证据

- 独立结果`20260812-233341`：UE5.8.0、CPython3.11.8，严格构建和运行时通过。机器证据记录`Applied`、`RejectedDuplicateCommand`、`Applied`和健康`100 -> 90 -> 100`。
- 网络结果`20260812-233801`：专用服务器和客户端通过。客户端记录`RejectedNotAuthority`，两个角色记录相同的服务器GAS命令，并且客户端事件显示复制的运行状况`100 -> 90 -> 100`。
- 正式`All`结果`20260812-234501`：UE5.8.0和CPython3.11.8上的`full_acceptance: true`。准备就绪、编辑器、单机、环回server/client、UAT以及打包的游戏玩法全部退出0。 BuildCookRun 报告 `BUILD SUCCESSFUL`，内部和稳定测试的可执行文件哈希值匹配，并且所有四个运行时日志都包含 gameplay/normal-close 标记，且严格的 fatal/assert/`Log*: Error` 诊断为零。
- 精确源网络结果`20260813-005436`：最终选择器强化仅重建`UEPLyraBridge`。服务器和客户端重复权威拒绝、幂等性、复制和干净关闭恢复。
- 精确来源独立结果`20260813-005835`：桥梁构建是最新的并且本地游戏序列成功重复。选择器强化后没有运行Cook/package，因此`20260812-234501`仍然是最新的包证据，而不是确切的源包结果。

<a id="intentional-limits"></a>

## 有意限制

0.5 不会公开任意游戏效果类、原始属性写入、功能激活、能力授予、输入重新映射、通用目标选择或自动客户端到服务器RPC。它并没有声称Lyra的完整游戏堆栈已转移到Python。这些省略使第一个写入表面保持较小、可审计且足够安全，以便在考虑更广泛的Python所有权之前进行验证。
