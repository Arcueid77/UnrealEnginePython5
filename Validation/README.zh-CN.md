[English](README.md) | [简体中文](README.zh-CN.md)

<a id="uep-58-automated-validation"></a>

# UEP 5.8 自动验证

> 当前版本 — **1.0.0**、UE**5.8.1**、引擎CPython **3.11.8**、Win64**Development/Shipping**。 [发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布范围。
> 下面标注日期的部分保留了其捕获时间证据和限制。

当前验证使用已批准的上游 UE 5.8.1 更新和捆绑的 CPython 3.11。对于每个迁移批次，`Test-UEPStagedBatch.ps1`测试隔离的仅Git索引核心和示例存档，然后`Save-UEPBatchAcceptance.ps1`记录有界本机证据。 Host/model 检查不是运行时验收。本机运行保留其实际的 DLL 来源。稍后的源哈希冻结不会重新执行旧方案。不合格或未完成的批次不得按已接受的方式提交。请参阅[批次账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/tree/dev/release-1.0.0/UEPLyraIntegration/Migration/Acceptance)和[当前进度](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/PROGRESS.zh-CN.md)。

根据2026-10-20的要求，默认情况下回归是增量的。分阶段驱动程序检查更改的Pythonsyntax/imports，并选择受本地导入、继承和文字module/file引用影响的主机测试。每个报告都会列出更改的路径、选定的测试、依赖性原因和未映射的路径。对于静态分析无法解析的依赖项，添加`-TestPattern 'test_footstep_*.py'`。未识别测试的代码更改会因请求显式测试范围而失败。它永远不会默默地扩展到整个套件。对于受影响的功能，本机资产、运行时、调用者和生命周期场景仍然运行。

仅将`-FullRegression`用于有意进行的广泛检查，例如共享SDK更改或版本接受。它还检查每个索引的 Python 文件。直接主机运行程序具有匹配的 `--test-pattern`、`--changes-file` 和显式 `--all` 选项。历史上的全套套房数量仍然是历史性的。增量报告仅证明其列出的测试。完整模式包括示例和验证Python测试。

`UEP58Host` 是一个一次性的、最小的 C++ 项目，用于根据 Unreal Engine 5.8 和引擎捆绑的 CPython 3.11 验证当前插件。

验证驱动程序将项目和当前插件源复制到`.build/Validation/UEP58Host`。它永远不会将插件安装到引擎中，也不会修改Unreal Engine源代码。

<a id="incremental-regression-and-historical-validation-scope"></a>

## 增量回归和历史验证范围

[路线图](../ROADMAP.zh-CN.md) 将实施、历史证据和发布批准分开。在历史性的0.8审查中，候选者尚未发布：旧的Lyra`All`运行不包括`HUDAudit`，仅强制执行一个活动演示者，验证关闭后零拥有的回调，或证明渲染的动画奇偶性。更新后的驱动程序现在审核启用了HUD的`All`，并强制执行一名活动演示者以及最终的Python退出证据。主机检查、新的严格HUD审核和当前脚本NullRHI独立现已通过。集成`All`，同步网络、包裹、视觉验收保持开放。请参阅[验证历史记录](../docs/Validation_History.zh-CN.md)中的范围2026-09-07记录。

运行轻量级检查而不启动或编译 Unreal：

```powershell
& F:\UnrealEngine\Engine\Binaries\ThirdParty\Python3\Win64\python.exe -B Validation/Run-UEPLyraHostTests.py --result .build/host-incremental.json
.\Validation\Tests\Test-LyraHUDContracts.ps1
```

这些目前通过 17 Python 测试和 28 PowerShell 检查。运行时报告架构 5 将 `hud` 保留为活动快照，并在 UEP Mixin 退出前清理之后添加来自 Python `atexit` 的 `shutdown.hud`。 `awaiting_shutdown` 未成功。驱动程序等待进程完成并验证有序的退出标记。缺少最终确定或剩余counters/references失败。

使用diff/format/link检查文档。 Python更改的主机测试和受影响的运行时场景。影响 C++/reflection 的增量构建。并在 Blueprint 声明发生变化时上演 generation/audits。重用本机二进制文件进行仅脚本工作需要匹配本机源出处并记录实际的新脚本哈希值。在开始之前公布完整的cook/package工作，并为候选项或相关风险保留完整的矩阵。

本节中描述的历史通用驱动程序包是Win64Development。通用驱动程序接受DebugGame，但本次审查未建立DebugGame或Shipping验证。未来的RC必须使用[候选记录](../docs/Validation_History.zh-CN.md#candidate-record-template)记录准确的core/Examples/engine/Python/configuration出处。旧的绿色结果和跳过模式不是当前源发布批准。

仅桌面主机禁用用于编辑器、cook 和打包执行的不相关的 `AndroidFileServer` 插件，因此 Android 部署工具不在本验收契约之内。它的打包步骤等待虚幻的全局UAT互斥体，而不是在另一个项目正在运行时失败或干扰。它还使用 UE 的松散熟包编写器，因此暂存不依赖于 Cook 退出后仍保持活动状态的瞬态本地 Zen 服务器。驱动程序的`MaxParallelActions`限制和`-NoUBA`策略适用于直接编辑器编译和UAT的嵌套游戏构建。包等待时间为两个小时，因此内存安全的低并行度构建不会被误认为编译器失败。

<a id="core-release-gate"></a>

## 核心释放门

仅当干净的完整运行返回退出代码 0 及其 `summary.json` 报告 `status: passed`、UE 5.8、Python 3.11 以及所有六个必需套件时，核心门才完成。未更改的0.5.0核心合约包含70所需的检查：21共享核心检查、21独立核心检查、两个隔离异常恢复检查、五个编辑器检查和21打包核心检查。核心案例练习基于UE5`FField`的动态class/function生成、`TSet`、重要字符串返回、线程诊断、动画、UDP接收器生命周期、父事件覆盖和增强输入回调释放。已知的排除项必须明确列出，而不是默默地算作通过。

发布验收项还保留了独立的Python-第一第三人称审核、无头游戏烟雾和[`../Demos/README.md`](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/README.zh-CN.md)中记录的打包游戏烟雾。仅凭绿色核心报告并不能声称游戏玩法具有同等性。

验证输出是本地证据，并且被 Git 故意忽略。源更改后必须重新运行。旧的绿色结果不能替代测试更改后的源。

候选版本结果`20260812-043408`通过了所有六个套件，并且70/70针对UE5.8.0和CPython3.11.8进行了检查。其完整的DevelopmentBuildCookRun报告了`BUILD SUCCESSFUL`和ExitCode0，其哈希记录的稳定包完成了打包的核心套件，没有致命或错误诊断。

<a id="full-acceptance-run"></a>

## 全面验收运行

从存储库根目录：

```powershell
.\Validation\Run-UEP58Validation.ps1 -EngineRoot F:\UnrealEngine
```

完整运行执行：

1. `UEP58HostEditor`编译和插件模块链接。
2. `UEP58Host` 游戏compilation/linking 作为打包的一部分。
3. 核心反射测试，同时共享 Epic 的 Python 解释器。
4. 与`-DisablePython`进行相同的核心测试，因此UEP拥有CPython3.11。
5. 共享和独立的异常边界进程，其预期回溯被严格过滤以防止任何意外的engine/Python错误。
6. 完整编辑器Actor、资产、序列器和Slate生命周期测试。
7. Win64 Development cook/package 和打包运行时核心测试。
8. JSON结果和日志验证，包括fatal/assert检测。

结果写在`.build/Validation/Results/<timestamp>/summary.json`下。任何失败的构建、丢失结果、失败的测试、致命日志标记或非零子进程退出都会导致驱动程序返回退出代码1。两个异常通道可能返回 0 或 1，因为 UE commandlet 将已处理的记录的 Python 异常计为错误。它们的 JSON 恢复结果和每个 `Log*: Error:` 行仍然经过显式验证。

带时间戳的结果保留每次运行日志、JSON 报告和测试游戏可执行文件的SHA-256。包本身直接存档到受保护的固定路径`.build/Validation/Package`。 Windows 防火墙通过完整的可执行路径来密钥未打包的侦听器，因此以后的运行不会显示为新的 `UEP58Host` 应用程序。为`.build/Validation/Package/Windows/UEP58Host/Binaries/Win64/UEP58Host.exe`预配置TCP/UDP入站**阻止**规则，或者如果Windows询问一次，则选择**取消**。仅环回UDP生命周期测试不需要public/private入站访问。不要全局禁用防火墙通知。

打包成功并不能仅从 JSON 标记推断出来。在 Unreal 拆除其对象系统和 UEP 拥有的 CPython 后，可执行文件必须返回退出代码 0。这捕获了一个 `BlendSpace` 反射结构浅拷贝，它通过了所有断言，但在进程关闭期间损坏了内存。

每个结果目录都保存UBT日志、完整的AutomationTool日志、每个套件的Unreal日志和机器可读的JSON报告。成功的完整运行包含六个套件：

| 套房 | 解释器所有权 | 必要的检查 |
| --- | --- | --- |
| core/shared | 史诗`PythonScriptPlugin` | 反射、值、`TSet`、动画、UDP生命周期、动态classes/functions、增强型输入回调生命周期、委托和 GC |
| core/standalone | UEP | 与`-DisablePython`相同的核心合约 |
| exception/shared | 史诗`PythonScriptPlugin` | 反射回调异常日志记录和后续调用恢复 |
| exception/standalone | UEP | 与 UEP 拥有的 Python 具有相同的异常边界 |
| editor/shared | 史诗`PythonScriptPlugin` | Actor生命周期、asset/Level序列save/load、序列器操作和Slate项目所有权 |
| core/packaged | UEP | 煮熟的可执行启动和完整的核心合约 |

所有模式都需要引擎捆绑的CPython3.11。打包套件还需要 `UEP_PACKAGED_VALIDATION_PASSED` 运行时标记。

<a id="faster-development-run"></a>

## 更快的开发运行

跳过打包并重用现有的暂存目录：

```powershell
.\Validation\Run-UEP58Validation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -SkipPackage `
    -Incremental
```

省略 `-Incremental` 以获得干净的暂存副本。清理仅限于标记有脚本的 `.build/Validation/UEP58Host` 和 `.build/Validation/Package` 目录。

快速运行仍然通过UBT的foreign-plugin模式来编译Runtime插件。当仅迭代 Python 测试时，也可以跳过该编译：

```powershell
.\Validation\Run-UEP58Validation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -SkipPackage `
    -SkipRuntimeCompile `
    -Incremental
```

<a id="linux-lane-and-platform-readiness"></a>

## Linux 车道和站台准备情况

Win64主机可以记录另一个UBT平台是否具有所需的UE5.8SDK，而无需安装或更改SDK：

```powershell
.\Validation\Test-UEP58PlatformReadiness.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Platform Linux
```

当无效平台导致 CI 失败时添加`-Strict`。 UE5.8Linux机器可以运行`Validation/Run-UEP58LinuxValidation.sh`。匹配的 GitHub 工作流程以标记为 `linux` 和 `unreal-engine-5.8` 的自托管运行器为目标。它构建编辑器和外部运行时插件目标，然后执行两种解释器所有权模式。仅仅定义此通道并不是Linux支持声明：需要绿色的`summary.json`产物。

<a id="current-intentional-exclusions"></a>

## 目前的有意排除

该套件记录了这些已知的限制，但不会失败：

- 未使用Unreal的无人值守资产删除参考扫描。编辑器进程退出后，驱动程序仅删除两个确切的一次性Material/Level序列资产文件。
- 当前本地UE5.8安装缺少所需的Linux`v26_clang-20.1.8-rockylinux8`SDK，因此只有Win64经过了发布验证。

运行时排除在套件 JSON 中保持可见。平台可用性保留在单独的就绪 JSON 中，直到存在真正的Linux 通道结果。

<a id="lyra-050-source-content-and-gameplay-gates"></a>

## Lyra 0.5.0 来源、内容和游戏关卡

源引擎签出下的 Git Lyra 示例故意省略了内容。检查候选项目而不更改它：

```powershell
.\Validation\Test-UEP58LyraReadiness.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject
```

该报告将`source_ready` 与`content_ready` 分开。仅当缺少 Marketplace 内容导致调用作业失败时才添加 `-Strict`。内容就绪项目必须包含基本 GameData、front-end/editor 地图、游戏地图以及每个 Lyra 游戏功能插件的根 GameFeatureData 资源。关键文件还必须带有有效的Unreal包头。 zero-byte/place-holder 文件无法满足网关要求。

仅源兼容通道可独立运行：

```powershell
.\Validation\Run-UEP58LyraSourceValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\UnrealEngine\Samples\Games\Lyra\Lyra.uproject
```

它将Lyrasource/config/plugin代码复制到脚本标记的`.build/LyraValidation/Stage/Lyra`，注入当前的UEP源和`UEPLyraBridge`，并仅在该一次性阶段禁用内容支持的Lyra启动。然后，它构建`LyraEditor`，在独立模式下运行`/Engine/Maps/Entry`，并运行第二个无内容专用服务器，该服务器必须侦听其请求的UDP端口并通过`unreal_engine.request_exit()`退出。通过证明compiler/UHT兼容性、模块加载、游戏线程桥接访问和干净的无头关闭。它明确记录了`source_content_gate: not_claimed`，并且不能替代真实的Lyra游戏玩法、网络或打包。

当前的证据是干净的源结果`20260811-165230`，最终源回归`20260811-183357`（独立加专用服务器优雅退出），完整的通用回归`20260811-184425`（70/70包括打包的运行时），以及完整内容准备结果`20260812-005352` （`status: ready`、UE5.8.0、CPython3.11.8，所有五个游戏功能和所有关键包均有效）。参考项目为`F:\LyraStarterGame\LyraStarterGame.uproject`。它仍然是外部的，并且永远不会通过验证进行修改。

<a id="full-content-acceptance-lane"></a>

### 全内容受理通道

将完整驱动程序指向此存储库和Unreal Engine源树之外的完整项目：

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -Mode All
```

驱动程序首先调用严格准备并拒绝创建其一次性阶段，除非所有必需的 assets/maps 和根 GameFeatureData 资产都存在。然后，它将项目复制到受标记保护的`.build/LyraValidation/Full/Stage/Lyra`，注入UEP和`UEPLyraBridge`，并覆盖示例拥有的`W_Healthbar`Mixin声明。它永远不会将覆盖写入参考项目。 `GenerateHUDAssets`通道将其阶段重置为官方健康栏，引用before/after阶段创作的哈希值，并仅复制回两个声明的覆盖资产。 `HUDAudit` 盘点相关的 Healthbar/layout/action-set 资产而不更改它们。生成的 Unreal 包元数据不是字节稳定的，因此门会检查声明的 Interface/Profile 语义和运行时行为。驱动程序仅在该一次性阶段禁用不相关的桌面`AndroidFileServer`。编译完整的编辑器目标后，它会禁用 gameplay/package 执行的仅测试 `ShooterTests` 和 `RuntimeTests` 根，以便运行时证据涵盖生产 Lyra 功能。 ShooterTests 内容仍在准备阶段并进行验证。运行时启动引脚`-culture=en`，因为UE5。8的启动核心冒烟测试比较源语言UnifiedError字符串。在本地化的Windows文化上，这些引擎测试否则会发出错误的`LogAutomationTest: Error`诊断。严格的运行时错误门并没有放松。驱动程序在不更改参考项目的情况下运行这些门：

1. 17快速presenter/bootstrap/shutdown在引擎捆绑的CPython3.11下进行测试，包括仅源缺失资产路径，然后进行warning/error-free`LyraEditor`构建。
2. 真实`L_Expanse`独立体验，包括主动`ShooterCore`、仅注册内容`ShooterMaps`、本地典当、PlayerState、增强输入、ASC和健康状况，其次是Python驱动GAS 伤害、重复拒绝和恢复。 Lyra现有的`W_Healthbar_C`仍为CommonUI所有，而Pythonmixin演示者观察真实的`100 -> 90 -> 100`委托事件。
3. 专用的server/client对证明远程连接、服务器权威、客户端`AutonomousProxy`，在两个角色上复制PlayerState和ASC。客户端Python首先证明`RejectedNotAuthority`。服务器Python然后应用10伤害，客户端Python观察复制的运行状况90，服务器Python仅在确认后恢复，并且客户端Python观察运行状况100。两个进程都在共享的释放信号后面等待，直到观察到两个完成的标记。客户端还必须通过Pawn替换、体验拥有的`Add Widgets`操作teardown/recreation和第二次切图cleanup/reconstruction，而专用服务器记录零HUD创建或订阅。和
4. Win64 BuildCookRun 随后是相同的 `100 -> 90 -> 100` 游戏合约和Python HUD `LyraGame.exe` 中的生命周期以及UEP 拥有的CPython 3.11。

新的完整内容阶段没有缓存的资产注册表。在启动游戏或两个基于编辑器的网络对等点之前，驱动程序运行一个无头编辑器commandlet来完成初始扫描并保留其 discovery/sharded 缓存。运行时进程以只读方式消耗该缓存。这可以避免在客户端服务握手之前出现未缓存的多进程启动停顿，并且摘要会记录每个缓存路径和字节数。

每次运行的日志和 JSON 保留在`Results/<timestamp>`下，而包直接存档到标记保护的固定路径`.build/LyraValidation/Full/Package`。 UAT的内部可执行文件仍为`Windows/LyraStarterGame/Binaries/Win64/LyraGame.exe`。驱动程序将其完整的`Binaries/Win64`树同步到仅验证的稳定侦听器路径`Windows/LyraGame/Binaries/Win64/LyraGame.exe`。它会在启动前验证两个可执行文件SHA-256值是否匹配，并通过UE的`-basedir=`覆盖传递原始目录，因此项目、引擎和ICU内容仍然从未修改的UAT布局解析。这避免了每个时间戳的包大小的镜像和新的Windows防火墙应用程序标识。每个结果都会记录包装器、原始内部可执行文件、测试的侦听器和两个哈希值。如果主机没有现有策略，则为稳定监听路径预配置TCP/UDP入站**Block**规则。打包的独立验证不需要public/private入站访问。不要全局禁用防火墙通知。基于编辑器的网络通道仅将其服务器绑定到`127.0.0.1`。为了避免在新机器上出现首次监听提示，还需为 `Engine/Binaries/Win64/UnrealEditor-Cmd.exe` 预先配置准确的 TCP/UDP 入站阻止规则。活动Profile的现有精确规则也足够了。

`-Incremental`保留注入插件`Binaries`/`Intermediate`，跳过大小和UTC时间戳不变的文件，并修剪过时的源文件。直接UBT和BuildCookRun的UBT子级都默认通过`-MaxParallelActions`执行两个非UBA操作。仅在具有足够内存的主机上覆盖脚本参数。

`Readiness`、`HUDAudit`、`GenerateHUDAssets`、`Standalone`、`Network` 和 `Package` 模式运行较窄的诊断通道。游戏玩法和HUD切片在运行时模式下默认启用。 `-SkipGameplaySlice` 和 `-SkipHUDSlice` 存在用于 focused/back-compat 诊断，但只有同时启用这两个功能的 `All` 才能设置 `full_acceptance: true`，并且更新的标志还需要其运行中 HUD 审核才能通过。 `HUDAudit` 仍然独立可用。 HUD启用的`All`现在也调用它。渲染视觉接受度仍然是一个单独的开放大门。 `-GameplaySliceDamage` 通过25 接受0.01 并默认为发布值10。负面结果 `20260811-184148` 正确报告 `blocked`，并有 11 缺少内容原因，且本地 Git 示例没有暂存项目。

预发布`All`结果`20260812-025232`通过了准备、编辑器构建、独立和同步网络角色，然后完成了其冷DDCWin64BuildCookRun和UATExitCode 0。它的归档后可执行防护在打包启动之前暴露了一个错误的假定内部目录。经过更正、哈希验证的包通过了精确的打包游戏玩法和严格的生命周期/日志契约，结果为`20260812-042711-packaged-resume`。

正式命名提交结果 `20260812-051532` 在一次 `All` 调用中验证发布代码提交 `c797d56`。其总结报告`status: passed`和`full_acceptance: true`。准备就绪、编辑器、单机、服务器和客户端同步、4,046包Win64BuildCookRun以及打包的游戏玩法全部通过。每个进程都退出0，严格的UAT/runtime错误计数为零，并且存档的内部和稳定测试的可执行文件哈希值匹配。

对于0.5开发，增量独立结果`20260812-233341`通过了新的权威GAS命令和精确的`100 -> 90 -> 100`健康生命周期。增量网络结果`20260812-233801`通过了客户端权威拒绝、服务器命令幂等性和客户端复制观察。正式的`All`结果`20260812-234501`随后通过了完整的游戏切片候选并报告了`full_acceptance: true`。准备就绪，编辑器，独立，网络角色UAT和打包游戏退出0。 UAT 报告 `BUILD SUCCESSFUL`，可执行哈希值匹配，严格运行时 fatal/error 计数为零。

在目标选择器被强化以拒绝多个匹配的人类控制器之后，精确源网络结果`20260813-005436`仅重建了`UEPLyraBridge`并通过了两个角色。独立结果`20260813-005835`是最新的并通过了本地序列。硬化后没有重复Cook/package。这些仍然是历史0.5证据。

对于历史的0.8候选者，干净基生成结果`20260903-033001`和`20260903-033049`通过了相同的两个Profile语义后置条件，而参考Healthbar哈希保持不变。只读 HUD 审核结果 `20260903-032632` 确认 `LAS_ShooterGame_StandardHUD` 包含一个具有 1 布局和 11 小部件条目的 `GameFeatureAction_AddWidgets`。正式`All`结果`20260903-033426`报告`full_acceptance: true`：主机测试、准备情况、编辑器构建、资产注册prime、独立、同步网络、Win64BuildCookRun和打包运行时全部退出0。每个UI角色记录了真实的Health`100 -> 90 -> 100`、Pawn替换、3构造/2在两个体验生命周期后解构和平衡委托。专用服务器记录零HUD状态。存档的和经过稳定测试的可执行文件哈希值匹配，并且所有严格的日志都通过了。

该`All`调用使用了NullRHI并且具有`hud_audit: null`。上述审计和生成是独立运行的。它的快照并不强制执行一个活动的演示者或退出后零拥有的回调，并且它的预引导修复source/six主机测试不是当前结束树的新运行。现有的清理日志事件不会弥补这些验证差距或暗示观察到的泄漏。需要经过修正的电流源完整渲染运行。保留的IDs和限制位于[验证历史记录](../docs/Validation_History.zh-CN.md)中。

完整的所有权和拒绝契约记录在[`../docs/Lyra_Gameplay_Slice_0.5.0.md`](../docs/Lyra_Gameplay_Slice_0.5.0.zh-CN.md)中。 0.8 小部件所有权、Mixin 路由和生命周期合约记录在 [`../docs/Lyra_Python_HUD_0.8.0.md`](../docs/Lyra_Python_HUD_0.8.0.zh-CN.md) 中。

[Lyra网络验收计划](../docs/Lyra_Network_Acceptance_Plan.md)需要一台服务器和两个独立的客户端，具有明确的玩家定位、HUD隔离、交错命令和leave/rejoin清理。 `Network` 和 HUD 启用 `All` 现在需要双客户端运行程序。旧的单客户端诊断名为`NetworkPrecheck`，无法满足完全接受。

使用已构建的匹配标记阶段，无需 UBT/cook/package: 即可运行

```powershell
.\Validation\Run-UEP58FocusedNetworkValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\Full\Results\Network-NewRun `
    -ClientCount 2 -ServerPort 7788
```

这会检查 source/module 奇偶校验和输入哈希值，同步 Python 脚本，运行主机合约和只读 HUD 审核，然后在环回上启动隐藏的 NullRHI 进程。 B0 退出，B1 重新加入：三个并发进程，总共四个进程实例。需要一个新的输出目录。失败只会停止此调用的进程。现有模块不匹配会出现故障，无需修复。三个机器人保留了原生的热身参与，但它们的大脑逻辑被选择加入的测试探针停止，以将健康变化与随机的AI枪声隔离开来。 Health/GAS/replication 和人类玩家输入不会被此线束取代。 `multi_client_acceptance` 与 `full_acceptance` 分开（此处始终为 false）。可见网络播放、弱网络和打包网络测试仍然是分开的。

<a id="first-weapon-hud-batch-09-development"></a>

### 第一个武器HUD批次（0.9开发）

`Run-UEP58FocusedWeaponHUDValidation.ps1` 重用了标记的完整内容阶段以及匹配的本地源、模块BuildIds 和八个武器覆盖资产。在 PowerShell 7 中运行此条目。它同步当前的Python脚本，检查未更改的source/binary/script/asset哈希值和官方的四个BP参考哈希值，并运行持久的CDOoriginal-BP/Python差分夹具。它从不调用UBT/UAT、保存资产、修复元数据或更改防火墙设置。使用新的输出目录。

```powershell
.\Validation\Run-UEP58FocusedWeaponHUDValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\WeaponHUD-NewRun `
    -CheckPlayableStartup
```

隔离渲染的 Entry 夹具检查 42 UI 场景和一个 PNG、严格的错误日志、正常的 Python/process 退出和四个路由器的恢复。它还检查原生 Gameplay Message取消、无构造重放的四个实时Profile往返以及三个受控的reload/native-GC周期。这里介绍了本机重新加载输入注入。真正的firing/GAS/replication使用单独的武器网络通道。 `LyraWeaponHUDContracts.ps1` 及其十六个主机测试拒绝 missing/duplicate 场景、仅 BP 执行、错误的本机值、缺少 CDO 声明和夸大的网络接受度。

可选的启动检查不使用UEP测试标志。它会在本机体验加载后观察 NullRHI 下的普通 Lyra 20 秒，并仅显式停止其拥有的进程。它的强制清理是单独记录的，并且不被称为优雅退出测试。全面接受和武器网络接受仍然是错误的。

`Run-UEP58FocusedNetworkValidation.ps1 -WeaponGameplay` 使用专用编辑器服务器和两个渲染客户端运行 19 实际输入阶段。本地生产者、复制的所有者状态、Python武器面板和原始BP比较小部件必须一致，包括两次切图和B0exit/B1重新加入。共享采样器标记为`read-only-frame-sampler`。 QuickBar/Pawn 信号是原生的，而不是发明的弹药复制委托。 `WeaponNetwork08` 通过了当前 import/profile 修复的所有四个正常出口。

`Run-UEP58FocusedLifecycleValidation.ps1` 在一个编辑器中为三个实际的 PIE 会话重用通用主机。 `Run-UEP58FocusedCallMatrixValidation.ps1` 运行生产signature/fallback/rejection、预编译调用程序、实验主体和隔离的expected-exception/no-fallthrough/recovery 夹具。它现在还运行 `delegate_broadcast_validation.py`：相同的反射多播属性接收本机和 Python 广播，无效参数将被拒绝而不传递，稍后有效的调用将恢复，并且取消订阅会阻止稍后传递。空的内联代表被行使。不暗示稀疏委托覆盖范围。这是委托调用，而不是Mixin路由器拦截委托签名UFunctions。 `Run-UEP58FocusedThirdPersonValidation.ps1` 准备两个变体，重用源匹配编辑器模块并记录本机输入渲染的游戏帧。它仅执行项目拥有的元数据刷新，无需 C++ 编译。

`Run-UEP58FocusedWeaponPackageValidation.ps1`使用`-NoEngineChanges`、cooks/archives构建游戏目标，保留以前的托管包，并使用其所需的`basedir`测试稳定的防火墙覆盖的可执行文件。运行时帮助程序源是 NonUFS 文件，必须导入到打包的 VM 中。仅当较早的 build/archive 日志和所有记录的运行时输入未更改时才使用 `-ReusePackageEvidence <summary.json>`。 `-SkipPackagedNetwork`明确限制对包presentation/lifetime的接受并记录网络跳过。它永远不会关闭完整的释放门。

专用套餐网络仍然开放。 LyraGame是游戏目标。 `-server`不能替代LyraServer。还尝试了Editor/cooked混合拓扑，但因生成World分区级别包不匹配而失败。干巴巴的LyraServer计划输出1,235冷酷的动作。没有运行服务器编译。这些失败的通道将被保留，而不是表示为打包的网络支持。两次 CC 调用超时并且未产生任何审核决定。

<a id="010-ammo-reticle-pilot"></a>

### 0.10 弹药十字线飞行员

`Run-UEP58FocusedReticleValidation.ps1` 检查第一个持久的弹药十字线副本、原始参考哈希、当前 scripts/native 源、十个真实的 original-BP/Python 材料案例、实时Profile往返、渲染的 PNG、关闭观察者范围并命令正常退出。它是带有`culture=en`的入口地图展示通道，没有build/cook/package或网络批准。真正的十字线游戏使用和后期批量资产需要单独验收。

选择加入的`-WeaponGameplay -CombatHUD`网络扩展通过实际增强的Input/GAS比较Python/BPFireButton绑定点击意图，并从生产计数器的本机武器初始化显式测试拥有的弹药条覆盖。原始武器定义未列出此弹药条小部件。夹具不得声明生产可达性。模式4断言本机向上目标和每个所有者numeric/material健康状况，以及本机ammo/HUD、respawn/travel/rejoin和退出后观察者清理。屏幕截图经过哈希处理。这不是物理接触测试或新的打包运行时证据。

```powershell
.\Validation\Run-UEP58FocusedNetworkValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\CombatHUD-NewRun `
    -WeaponGameplay -CombatHUD
```

`CombatHUDNetwork04` 经过19 阶段车道，有四个干净的出口和八个 PNG。 `HealthBootstrapRegression01`通过延迟-ASC恢复加上普通的健康动画和中期动画Profile清理。使用聚焦的 HUD `-Mode All -RenderOffscreen` 进行渲染，而不显示交互式窗口。两条通道都重复使用匹配的本机二进制文件。在这些情况下，builds/cooks/packages. 音频均不会禁用：保留现有的本机 EarlyReflections/TapIDs 警告，不将其视为音频接受或从屏幕截图中隐藏。

<a id="effect-pad-world-interaction-pilots"></a>

### Effect Pad 世界交互试点

`Run-UEP58FocusedEffectPadValidation.ps1` 在真正的独立Lyra Pawn 上验证八个parent/child 案例和十六个物理enter/leave 回合。测试拥有的焊盘在原生构建之前选择BP/Python。本机传送驱动真正的碰撞，GASapplies/removes效果，并且健康状况是读取而不是写入。现有的非致命本地桥仅提供明确的起始生命值。关闭需要零个HUD/weapon观察者和恢复的父路由器。

`Run-UEP58FocusedEffectPadNetworkValidation.ps1` 添加了一个编辑器专用服务器和两个渲染离屏客户端、十六个 parent/child x 效果 x 所有者 x Profile比较、本机运行状况复制和 numeric/material HUD 检查。它不要求物理客户端输入、客户端效果预测、pad 复制或打包网络。两位车手都需要有标记的舞台和新的证据目录。既不builds/cooks/packages也不更改防火墙。

`CallMatrixRegression02` 包括构造转发器和继承选择器固定装置以及早期的五个 call/exception/body 检查。子显式父路由使用虚拟 BP 助手，而不是新的运行时拦截合约。 `PhysicalGAS03` 和十六个案例`PadNetwork02` 通过了三个干净的网络出口。这些结果保留了它们自己运行中的 input/DLL 哈希值。后续不相关的HUD更改不会追溯重新运行。

重点武器网络驱动程序接受`-WeaponGameplay -CombatHUD -DebugSpread`作为调试传播试点。它需要真正的本机自动刻度（探针不调用Python刻度）、BP/Python/native格式化文本以及在19个本机input/lifecycle阶段上的非零观察角度。旧报告无法满足新的选择加入通道。删除调试检查点失败。 `DebugSpreadNetwork01` 通过了四个干净的退出和八个屏幕截图，并保留了已知的本机audio/Editor 警告。它不是生产调试小部件的可达性或包批准。

`Run-UEP58FocusedOpenMenuValidation.ps1` 检查保留的 CommonUI 按钮的 Python/BP/Python Profile往返和三个本机异步层推送/停用。它需要一个最初卸载的菜单类、保留的小部件类型、实际可见的菜单 PNG、有序的干净关闭和稳定的 source/asset/ DLL/reference 哈希值。 `MenuDifferential04` 通过并带有经过检查的屏幕截图。使用标记的完整Lyra阶段和新的证据目录。驱动程序不build/cook/package。它不验证物理触摸、输入令牌恢复/取消行为、生产可达性或多人菜单隔离。

`Run-UEP58FocusedReticleHostValidation.ps1` 检查八个本机生产主机与原始 BP 案例，包括默认自动武器路由、三个本机配备的武器上下文、Profile保存和注入的本机死亡事件 hiding/one-shot 侦听器清理。 `HostDifferential02`通过了经过检查的屏幕截图和最终的host/child范围3/3和9/9.这不是物理拾取或致命伤害的游戏。

将 `-ReticleHosts` 添加到重点网络驱动程序的 `-WeaponGameplay -CombatHUD -DebugSpread -ProductionReticles` 通道，以要求实际生产主机 configuration/owner/child/visibility 检查点和最终主机作用域关闭。 `ReticleHostNetwork01`经过十九个阶段，两个客户端加B重新加入，四个干净退出。服务器不会创建UI。该通道不调用PythonTick或OnWeaponChanged来制造生产工艺路线。旧的报告无法证明这一点。两个驱动程序都重用匹配的二进制文件，并且从不build/cook/package.

<a id="ability-duration-progress-and-typed-transport-regressions"></a>

### 能力持续时间进展和类型化传输回归

`Run-UEP58FocusedAbilityProgressValidation.ps1`使用实际生产的W_AbilityProgress和测试拥有的原始BP基线。 `ProgressDifferential02` 通过十一个owner/foreign/repeat/countdown/paused-native-clock/hidden-Profile/ 销毁案例，具有真正的自动UMG 勾选和最终范围3/3. 检查了其屏幕截图。输入是编译的类型化合成持续时间广播，而不是实际的交互能力。初始StartTime不同，因为两个小部件在不同时间初始化。广播后，本地字段匹配。

`Run-UEP58FocusedTypedMessageValidation.ps1` 重新运行旧信号，键入 UI/Verb，嵌套有效负载复制，错误的 reader/outside-delivery 针对扩展六功能适配器拒绝和取消。启动超时不是通过。

将 `-AbilityProgress` 添加到 `-WeaponGameplay -CombatHUD` 作为可选网络通道。每个阶段必须显示一个所有者交付、一个非Pawn发起者拒绝、可见的original-BP/Python倒计时比较和本机完成。它检查实际生产UI而不调用PythonTick，并且需要零个专用服务器UI加上travel/rejoin/exit.之后的平衡客户端范围外部有效负载使用所属控制器而不是Pawn。这是多个进程中本地合成的UI交付，而不是远程玩家交互、本地能力生产或GameplayMessage复制。在下面的生命周期修复后，该通道在`AbilityProgressNetwork03`中得到验证。

前两个网络运行暴露了切图中隐藏的小部件重用缺陷：Destruct 关闭监听器，而一次性 OnInitialized 和 Collapsed Tick 无法重新武装它。现在构造幂等重新武装。原始 BP 后备使用显式保留模型恢复。 `ProgressReconstructRegression01` 通过了 12 次比较，包括本机相同小部件重新安装、最终范围 4/4 和检查的图像。 `AbilityProgressNetwork03`经过十九个阶段，两个travels/respawn/rejoin，四个干净退出和最终server/A/B0/B1进度范围0/0，6/6，6/6，2/2.十二个PNG是散列。检查选定的进度图像。已知的本机警告仍然存在。这些是有界的试点门，不是完整的0.10，本机交互生产或包接受。

<a id="ability-failure-feedback-bounded-differential-and-native-ftext-accepted"></a>

### 能力失败反馈：有界微分和原生FText接受

`Run-UEP58AbilityFailureAssetAuthoring.ps1` 必须首先在标记的工作区阶段生成可接受的资产报告。聚焦的`Run-UEP58FocusedAbilityFailureValidation.ps1`需要通过`-AssetAuthoringDirectory`的目录。失败的创作在UE启动之前被拒绝。 `fixture-preflight01.json` 验证此防护是否发生实际失败的运行。

选择加入 `-UEPAbilityFailureResult=` 装置会传入 `FailureDifferential06`。十七个案例将实际制作W_AbilityFailureFeedback与同一类的监听器恢复的原始BP基线进行比较：ownership/de-duplication、pause/one-second原生Outro计时、自然动画、隐藏的Profile恢复、原生Destruct/remount、延迟的payload/persistent回调结果和待处理的工作取消。没有直接的小部件lifecycle/completion事件调用。退出后需要scope/ticker余额、准确的case/state库存、严格关闭的日志、稳定的输入哈希值和PNG。计时器偏差不能超过观察到的两个UI帧或0.15秒。检查了校正后的可见 PNG。

`Run-UEPLyraHostTests.py --result <workspace .build path>` 在`20261014-batch2h/host-tests08.json` 中传递237。门测试使用人工报告。他们不验证这十七个运行时案例。合成显示文本输入无法证明本机本地化FText身份、死亡行为、本机GAS故障生产、多个客户端或包接受。 `Assets06` 干净地编译了 ten-function/32-node 传输以及仅声明的 int32 潜在完成。最终定时器调用原生RetriggerableDelay。没有外部股票代码或新股票代码。 `-CultureIdentity -TextFixtureAssetResult <accepted seed report>` 选择单独的培养泳道。 `NativeCulture02` 通过en/zh-Hans/en 传递本地实时表FText，无需重播。检查了其更正的屏幕截图。用于保留文本的计时器取消是明确测试拥有的。种子仅限阶段。 `-AbilityFailure`向现有的双客户端武器驱动程序添加本地综合ownership/visual/cleanup检查。本机GAS故障产生和故障消息复制仍然无人认领。否 build/cook/package.

<a id="dash-cooldown-bounded-standalone-production-pool-network-retest"></a>

### 达世币冷却时间：有界独立、生产池网络重新测试

`Run-UEP58WidgetAssetAuthoring.ps1 -Widget DashCooldown` 仅创作标记的工作区阶段并将接受的 BP/Mixin 资源复制到示例中。它重用现有的持续时间适配器，保留class/Tick/animations，并仅添加代理所有权以及四节点委托清理。 `Run-UEP58FocusedDashCooldownValidation.ps1 -AssetAuthoringDirectory <accepted directory>` 运行十一次比较。九用生产UI。 Destruct/remount 是声明的同级视口固定装置，而不是生产池重新安装声明。材料公差为0.00001。 DashDifferential05 通过检查 PNG。池修复重复DashDifferential06中的十一个（50.297s，范围11/11，池监视2/2，零active/errors）。收紧的纯最终门独立地重新检查保存的报告。 `-DashCooldown` 添加了生产UI/native-pool 生命周期和本地合成持续时间与双客户端武器通道的比较。第一次运行在第二次切图重复的生产范围上失败。共享只读GetAllEntries采样器解除非活动条目，防止非活动Tick运行状况重新绑定，并允许自然重新插入而无需事件重播。 DashNetwork02 正在修复中运行。 Host-tests08 通过了270，但没有运行时证明。原生达世币生产、原生death/invalid-health和打包保持开放。

后来 DashNetwork05 通过所有十九个 phases/two travels/rejoin/four 退出并观察到本机池停用 A/B0. NativeDash02 通过原始 GAS 冲刺持续时间（1.5s)，自然死亡和缺席-Pawn 反馈案例。被拒绝的重复不会发出本机失败消息。那些早期开放的标签已经成为历史。满 package/batch 故障产生者范围保持开放。

<a id="nameplate-widget-bounded-581-acceptance"></a>

### 铭牌小部件：有界5.8.1接受

`Run-UEP58WidgetAssetAuthoring.ps1 -Widget Nameplate` 首先编译复制的Interface/CDO、原始class/Tick、类型化的初始化状态帮助程序和精确的委托清理。 `Run-UEP58FocusedNameplateValidation.ps1 -AssetAuthoringDirectory <accepted directory>` 然后在 14 个声明的案例中比较实际生产绑定和同级原始 BP。它拥有其原生的股票行情处理。Profile比较使用匹配的本机简历纪元，而不是状态复制。

`20261015-ue581-acceptance/NameplateDifferential06` 通过了经过检查的 PNG、范围 23/23、团队代理 13/13、初始化委托 10/10 并且没有 residual/errors/ 确保。当本机初始化状态owner/manager已经消失时，`init_owner_released`单独计数。在这次接受的运行中它为零。该门仍然需要执行显式取消注册。原生伤害、团队重新分配、投射平价、Source/Manager组件和铭牌特定的多人游戏均未经过这 14 个 Widget 案例的认证。

<a id="fresh-process-package-discovery"></a>

### 新工艺包发现

`Run-UEP58FocusedPackageLoadValidation.ps1 -StageProject <marked generic host> -OutputDirectory <fresh workspace .build path>`在一次性主机中保存两个唯一命名的BP包和一个Mixin集，然后启动单独的编辑器进程。加载 Main 还通过硬性 CDO 类引用导入 Companion。加载阶段必须自动发现两者，无需显式注册，并证明Python替换、显式原始调用、缺席可调用回退、同类每实例Profile和取消注册恢复。 Source/module/input 哈希值、序列化资产哈希值、不同进程 IDs 和关闭的日志被门控。不涉及构建、Cook、规范固定资产或官方项目编写。 `20261015-ue581-acceptance/PackageLoad01`传递重建的5.8.1编辑器。这涵盖了编辑器OnEndLoadPackage，而不是普通的non-Editor/cooked发现。

<a id="respawn-timer"></a>

### 重生计时器

`Run-UEP58WidgetAssetAuthoring.ps1 -Widget RespawnTimer`接受复制的Interface/CDO和五节点清理，同时保留官方资产哈希。 `Run-UEP58FocusedRespawnTimerValidation.ps1 -AssetAuthoringDirectory <accepted directory>` 启用原生音频组件并比较十个生产小部件/原始 BP 案例。 RespawnDifferential04通过（51.578秒），材料公差0.00001，精确两个Python范围纪元，零最终pool/scope状态并检查PNG。剩余时间是派生的本机截止日期，而不是 BP 堆栈读取。尽管紧凑的多链接图具有误导性的第一链接推断，但这两种材料都会在实际编译的基线中更新。对于 `-NativeRespawn`，NativeRespawn02 通过原始 GA_AutoRespawn/native GAS -> 5s duration/UI -> 新 Pawn/completion (49.735s)，无合成duration/completion，手动小部件事件或Health/CDO写入。这是death-state/event证据，而不是致命的damage/acoustic平价。 `-RespawnTimer`向双客户端武器通道添加本地duration/completion过滤和本机池生命周期。客户端启用本机音频。 RespawnNetwork01 正在运行。主机检查pass299，不是网络证明。
