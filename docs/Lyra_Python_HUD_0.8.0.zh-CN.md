[English](Lyra_Python_HUD_0.8.0.md) | [简体中文](Lyra_Python_HUD_0.8.0.zh-CN.md)

<a id="lyra-python-hud-foundation-for-080"></a>

# Lyra Python HUD 0.8.0 的基础

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

未发布的UEP0.8.0候选者将Lyra现有健康栏的event/subscription行为移动到Python而不替换`ALyraHUD`，绕过CommonUI，更改小部件类，或编辑Lyra/Engine源树。一次性验证阶段覆盖`/Game/UI/Hud/W_Healthbar`的配置副本。活动对象仍然是`W_Healthbar_C`，并且仍然由Lyra的游戏功能`Add Widgets`操作创建和删除。

Data/lifecycle 和 animation/interpolation 已实施。 2026-09-10隔离实-UMG夹具通过。完整的发布验收尚未完成。 [路线图](../ROADMAP.zh-CN.md)定义了剩余的工作，而不是已经通过的契约。

[网络验收计划](Lyra_Network_Acceptance_Plan.md)指定了所需的one-server/two-independent-client收尾，包括玩家定位、HUD所有权隔离、交错命令和leave/rejoin清理。单客户端运行只是一种诊断预检查。实现了显式播放器snapshots/tokens、restart/health定位和无构建20相驱动程序。运行时结果和失败的迭代记录在验证历史记录中。集中运行`20260912-network-run-05`通过所有20阶段，客户端所有权和B0leave/B1重新加入，干净的server/A/B0/B1Python/OS退出。这是一个环回NullRHI传递。集成的完整版本和打包网络仍未经过验证。

<a id="ownership-boundary"></a>

## 所有权边界

| 关注 | 0.8.0的所有者 |
| --- | --- |
| HUD布局，CommonUI图层和小部件creation/removal | Lyra 游戏特色动作 |
| 卫生权威、游戏效果和复制 | Lyra GAS 和 `ULyraHealthComponent` |
| 小部件`Construct`/`Destruct`，控制器和健康订阅 | Python mixin 演示者 |
| 当前棋子选择和占有变化后的重新绑定 | Python mixin 演示者 |
| 健康正常化和刷新时间 | Python mixin 演示者 |
| 动态材质、条形动画和数字小部件基元 | 保留`W_Healthbar`assets/helpers。 Python 选择动画，标准化材质并开始插值 |
| 专用服务器UI | 无。验收契约需要零个widget/presenter实例 |

主持人故意狭隘。它读取复制的健康状况并调用Lyra现有的视觉辅助功能。它不会设置属性、激活体验、授予能力、替换输入映射或将游戏权威移至Python。有界的0.5健康增量桥仍然负责通过Lyra的本机游戏效果生成验证序列。

<a id="mixin-declaration-and-selection"></a>

## Mixin申报与选择

示例存储库拥有两个覆盖资产：

- `/Game/UI/Hud/W_Healthbar`，官方小部件的同路径副本，添加了`UEPPythonMixinInterface`和`PythonMixinProfile`选择器。
- `/Game/UEPMixins/DA_LyraHealthbarMixin`，其`Python`和`BlueprintFallback`Profile指向两个演示者类。

默认的 `Python` Profile在运行时替换小部件的反射 `Construct`、`Destruct` 和继承的 `OnAnimationFinished` 函数。最后一个事件在完成死亡链之前保留其原始实现。 `BlueprintFallback` 调用保留的 Blueprint `Construct`，提供每个实例的逃生舱口，而无需更改对象的 Unreal 类型。原始的Blueprint图保留在复制的资产中，并在路由器取消注册时恢复。

资产仅在受标记保护的一次性副本 Lyra 中生成：

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -OutputRoot F:\UnrealEnginePython5\.build\LyraValidation\HUD08 `
    -Mode GenerateHUDAssets `
    -Incremental
```

生成器将一次性阶段重置为官方健康栏包，创建一个新的MixinDataAsset，编译并保存两个阶段资产，然后仅将这两个经过验证的文件复制到示例覆盖中。它比较前后引用`W_Healthbar.uasset`的SHA-256，并且从不写入`F:\LyraStarterGame`或`F:\UnrealEngine`。虚幻包保存元数据是特定于生成的，因此验收检查语义配置和运行时行为，而不是要求生成字节相同的 uassets。

<a id="runtime-sequence"></a>

## 运行时顺序

1. `ue_site.py` 跳过 Cook 和其他commandlet中的所有运行时注册。
2. 启动的游戏加载暂存的`W_Healthbar_C`并注册其接口声明的Mixin集。
3. Lyra激活其正常的体验和游戏功能操作，从而创建`W_Healthbar_C`到CommonUI。
4. 路由的`Construct`保留后续解绑所需的确切回调对象，通过现有的Blueprint助手创建Lyra的动态材质，订阅`APlayerController.OnPossessedPawnChanged`，然后绑定当前Pawn的`OnHealthChanged`和`OnMaxHealthChanged` 代表们。
5. Python读取health/max健康状况，钳位标准化值，更新小部件状态并调用现有的Blueprint视觉基元。
6. 所有权变更会在绑定新健康组件之前解除旧健康组件的绑定。 `Destruct`，路由器清理和解释器在释放演示者状态之前关闭所有明确的健康状况和控制器委托。

无勾选民意调查会驱动健康栏。初始渲染是明确的。后来的更新是由健康组件或占有委托引起的。

<a id="required-acceptance-contract-unreal-closeout-still-pending"></a>

## 所需的验收契约（虚幻收尾仍悬而未决）

0.8 完整内容通道必须在 UE 5.8 和引擎捆绑的 CPython 3.11 上证明以下所有内容。这是目标合约，而不是每个项目都已传递到当前源的声明：

- 29主机端presenter/bootstrap/shutdown测试涵盖纯源资产缺失、精确回调标识、事件驱动渲染、Pawn替换、Blueprint回退、动画中断、插值、销毁、注册表清理和最终Python退出，以及40 PowerShell positive/negative 在启动虚幻进程之前进行验收检查。
- 生成保留未触及的参考小部件，而只读审核证明分阶段副本声明了预期的接口、Mixin集、选择器、Profile、反射状态和ShooterCore`Add Widgets`形状。
- 独立和网络客户端从委托回调中观察真实复制的`100 -> 90 -> 100`序列，并且单独的渲染运行验证damage/heal/death/respawn视觉效果和数字插值。
- 权威驱动的Pawn重新启动取代了Pawn，并恰好生成一个与新健康组件的活动绑定。
- 第一个相同地图体验替换驱动真实的`LAS_ShooterGame_StandardHUD` `Add Widgets`deactivation/activation路径，拆除旧的小部件并重建一个干净的演示者。
- 第二次独立的同地图切图重复teardown/reconstruction，因此客户必须完成至少三个构造、两个破坏和一个平衡的主动演示者。
- 专用服务器记录零健康栏构造、订阅或健康呈现事件。
- 所需的双客户端网络通道明确识别两个玩家，检查每个客户端自己的Health/HUD和交错命令幂等性，然后验证一个客户端的departure/rejoin而不干扰另一个客户端。当前的单客户端驱动程序和仅限角色的目标选择器不满足这个新的门。所有启动的连接过程都需要自己的最终证据。
- 显式小部件销毁、mixin 清理和 Python 关闭不会留下陈旧的回调余额。和
- 严格日志不包含编译器、致命、断言、未处理的异常或意外的`Log*: Error`诊断。

目前的平仓缺口：

- HUD启用的`All`现在调用`HUDAudit`并需要其传递的结果。以前仅审计模式的行为是历史性的。集成路径仍然需要当前源 Unreal 运行。
- Probe/driver 检查现在只需要一名活动演示者。报告模式5首先写入`awaiting_shutdown`，并在Mixin退出前清理之后从Python`atexit`最终确定，并使用单独的`shutdown.hud`快照。驱动程序检查零最终拥有的callbacks/references，并在流程完成后订购退出标记。主机负面测试和实际的UE独立退出路径传递当前脚本。同步network/package验证仍然悬而未决。
- 演示者仅针对 initial/new Pawn 或重生进行初始化。伤害和治疗使用保留的动画和`InterpolateToValue(health, 1, 4, 0)`。材料使用实际最大生命值。死亡会在`OnEliminated`之前等待`OnDamaged`完成。 Pawn 替换和普通破坏在停止动画之前完成撤防。路由器清理会在没有完成事件的情况下暂停，因为在修改期间调度不可用。这些路径具有宿主和真实的UMG回归覆盖。
- 重复电流源完整runtime/network/package验收。使用原生 Lyra 游戏玩法或独立装置来覆盖 lethal/death。不要为了测试方便而扩大非致命桥的权威。

现有的清理路径和历史清理日志是真实的证据。这些间隙不会造成电流泄漏。 29 Python 测试使用假反射对象和真实的 CPython 仅子进程退出，而不是正在运行的虚幻游戏。第一次 2026-09-07 编辑器尝试在不匹配的模块 BuildIds 上失败。在UBT仅元数据修复后，新的严格审核和当前脚本NullRHI独立版通过了。活动presenter/reference计数为1/1。 Python退出后，两者都是0，控制器绑定是3/3，健康绑定6/6.未执行C++编译，cook/package或资产保存。整合的`All`路径仍然需要自己的证据。渲染的证据已添加到2026-09-10。

<a id="focused-no-build-self-acceptance"></a>

## 专注的无构建自我接纳

`Validation/Run-UEP58FocusedHUDValidation.ps1` 重用已构建的、标记为 Lyra 的阶段。它从不调用UBT，保存Blueprint资产、厨师或包。它在检查本机source/module奇偶校验后仅同步示例脚本。陈旧的binaries/records失败而不是被默默地修复。模式为`All`（均为重点检查）、`Callsite`和`Visual`。使用新的输出目录：

```powershell
.\Validation\Run-UEP58FocusedHUDValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\Focused-NewRun
```

调用者固定装置在注册之前编译两个瞬态BP，生成两个同类目标，然后证明original/mixed/repeated/swapped/restored路由。仅从Python调用调用方条目。它的字节码通过Actor引用调用目标。编辑器fixture写入使用`set_property`，避免`PostEditChange`重建。这不是属性编辑器回归。

视觉装置在隔离的`/Engine/Maps/Entry`地图中使用真实的`W_Healthbar_C`、材质、CommonUI数字文本和UMG动画。显式启用的仅测试运行状况读取器驱动`100 -> 60 -> 100 -> 0 -> 100`。它不会附加到Pawn/ASC、授予权威或拓宽游戏桥梁。检查八个 PNG 帧、实际的 displayed/target 数字、动画历史记录和最终清理计数。其可见窗口可以填充着色器缓存。正常的Lyra运行永远不会导入这个灯具。 Source/binary/screenshot 哈希值和实际进程退出证据被保留。 `full_acceptance` 仍然是错误的。这证明了表示，而不是GAS委托、网络或打包运行时。

聚焦 `All` 还会在单独的进程中重复 `Visual` 和 `-SwitchDuringAnimation`。它在开始致命伤害后立即切换到`BlueprintFallback`，然后删除小部件。旧的演示者通过路由器清理（不是合成的Python Destruct）关闭。这暴露了`PythonFunction.cpp`中修复的无参数本机回退错误：即使`PropertiesSize`为零，也至少分配一个字节。仅包含四个操作的插件增量构建验证了该修正。聚焦的脚本本身仍然无法构建。

新暂存的Lyra树没有资产注册表缓存。在多进程运行时测试之前，驱动程序会完成一次无头编辑器扫描并保留生成的只读缓存。这可以防止两个`Editor -game`进程在客户端可以为其网络握手提供服务之前竞争未缓存的初始Lyra扫描。缓存路径和字节计数记录在运行摘要中。

使用以下命令运行现有的组合 runtime/package 通道：

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -Mode All
```

`All` 包括完整的 Win64 cook/package，并且可能比 `Standalone` 或 `Network` 花费更长的时间。 HUD启用的`All`现在包括审核，重点检查HUD检查和双客户端网络导致其成功条件（驱动程序摘要架构5）。主驱动程序还公开 `MixinCallsite`/`HUDVisual`，但与聚焦脚本不同，这些模式保留驱动程序的 staging/build 前导码。不要将绿色摘要等同于发布批准。更新后的组合车道尚未在虚幻中通过。在迭代期间使用较窄的模式。

<a id="retained-historical-evidence"></a>

## 保留历史证据

- HUD审核`20260903-032632`：官方操作集有一个`GameFeatureAction_AddWidgets`、1布局条目和11小部件条目。
- Clean-base资产生成`20260903-033001`和`20260903-033049`：都通过相同的`W_Healthbar_C`、`Python`默认、双Profile和选择器后置条件。参考包哈希保持不变。
- 完整运行`20260903-033426`：在UE5.8.0和CPython3.11.8上运行`full_acceptance: true`。单机、网络客户端和打包游戏均报告真实的`100 -> 90 -> 100`序列、3构造和2破坏。专用服务器报告零HUD状态。 BuildCookRun 和打包运行时退出0，严格日志通过，并且archived/tested 可执行哈希值匹配。

完整的运行是NullRHI/headless，有`hud_audit: null`，并且没有打开可见的手动客户端。它的`full_acceptance`字段记录的是该驱动版本的检查，而不是修改后的契约。它早于最终的纯源引导fix/seventh测试，并且仅是Development，而不是DebugGame或Shipping证据。请参阅[验证历史](Validation_History.zh-CN.md)。

<a id="deliberate-boundary"></a>

## 刻意的边界

0.8.0 仅针对健康栏和生命周期基础。 0.9优先考虑Mixin工程，一条weapon/ammoHUD链和一个有界可重用的游戏消息订阅表面。完整的QuickBar，十字线，团队得分，淘汰饲料和荣誉是1.1+积压。运行时 Mixin API 保留 [Mixin_API.md](Mixin_API.zh-CN.md) 中记录的 0.7 限制。
