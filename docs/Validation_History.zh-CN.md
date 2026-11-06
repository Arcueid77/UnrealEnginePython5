[English](Validation_History.md) | [简体中文](Validation_History.zh-CN.md)

<a id="validation-history"></a>

# 验证历史

历史里程碑和保留的结果标识符，与[当前路线图](../ROADMAP.zh-CN.md)分开。已在2026-09-10上审核。

<a id="how-to-read-this-archive"></a>

## 如何阅读此存档

这些记录保留了先前运行检查的内容。它们的日期、结果IDs、检查计数和状态字段不得被视为当前 HEAD 接受。如果下面没有记录确切的源修订，请不要追溯分配今天的提交。机器本地结果路径不是可移植的发布产物。未来的候选版必须保留自己的清单和可访问的日志。

审查优先于历史完成措辞的资格：

- 0.1 保留了确切的源包间隙。
- 0.3/0.4 Win64 结果不验证Linux。 70/70通用结果`20260812-043408`来自2026-08-12，而不是新的0.8核心运行。
- 0.5 的最终选择器更改进行了 Network/Standalone 测试，但没有重新运行确切的源包，即使历史版本已标记。
- 0.7 已标记，但可见客户端对其最终树的接受未记录。
- 0.8没有发布标签。 `20260903-033426`包含`full_acceptance: true`、`hud_audit: null`和`hud_asset_generation: null`。单独的 audit/generation 运行不得显示为该调用执行的步骤。 NullRHI 验证状态，而不是渲染的健康栏动画。
- 该 0.8 运行使用了当时的六台主机测试，并且早于后来的纯源引导 fix/seventh 测试。当前仍需要完整的实时重新运行。匹配一些分阶段的 Python 文件哈希值并不会使整个运行成为当前源证据。
- 如果其 count/balance 检查另外同意，则关闭前验证器接受两个活跃的演示者，并在退出前记录成功。因此，现有的`3 Constructs / 2 Destructs`快照不会强制执行一个演示者或关闭后零拥有的回调。旧日志确实包含清理事件。这是缺少验证保证，而不是发现实际泄漏。
- 这里描述的保留的包裹证据是Win64Development。 DebugGame 和 Shipping 在本次审查中没有保留验证。

历史运行记录的0.8 archived/tested可执行文件SHA-256为`07618B6071C837E1334E4F9FEE2212ACC6A604FD881EEB94419C19AD9DA8F3E9`。 HUD 审计 `20260903-032632` 和干净基础生成 `20260903-033001` / `20260903-033049` 是单独的支持记录。参考健康栏SHA-256为`7AD30080E82AF2BB2FB40DD132F632A35E3429076ABAD49A37FDFD657895CF66`。

保留的`20260903-032632`审核没有健康栏`mixin`申报字段。是asset/graph库存，不是后来严格的Interface/profile审核合约的通行证。更新后的语义验证器正确拒绝旧数据。

<a id="010--ue-58-foundation"></a>

## 0.1.0 — UE 5.8 基金会

历史状态：已标记。实现已完成，确切的源包确认已推迟。

- 针对 UE 5.8 构建所有运行时和编辑器插件模块。
- 使用引擎捆绑的 CPython 3.11 运行时。
- 支持共享和UEP拥有的解释器生命周期。
- 验证反射、通用属性类型、函数、委托、垃圾收集、编辑器对象和打包的运行时行为。
- 提供第三人称集成演示以及额外的Python游戏玩法。

验收门：四套件验证运行通过了所有40所需的检查，第三人称冒烟测试通过，并且两个工作流程都没有更改引擎源。

<a id="020--python-first-third-person"></a>

## 0.2.0 — Python-第一第三人称

历史状态：已标记。里程碑当时被标记为完成。请参阅上面的资格。

- 在 UE5 的 `FField` 反射模型上重建动态 Python `UClass`/`UFunction` 生成，其中 Python 子类和事件覆盖需要它。
- 制作官方UE5.8第三人称模板的Python第一个变体：character/Pawn生命周期、摄像机吊杆和控制旋转、增强输入映射设置、move/look/jump动作、PlayerController/GameMode引导和运动状态计算移出Blueprint 事件逻辑。
- 从Python驱动动画实例，同时保留骨架网格物体、动画剪辑和姿势混合资源作为虚幻资源。 Blueprint 图表应被删除或减少为仅资产粘合物，并记录原因。
- 保持参考 Blueprint 模板不变，并单独暂存 Python 变体，以便可以自动比较行为。
- 添加针对输入绑定、移动、跳跃、相机响应、动画状态变化、地图切图、独立播放和打包执行的确定性测试。

接受门：Python-第一个变体达到了与keyboard/mouse游戏的基本第三人称模板相同的功能，其剩余的Blueprint逻辑被清点，并且所有游戏检查都以可见和无头模式通过。

已完成的门：UE5.8.0和Python3.11.8通过了46共享、独立、编辑器和打包核心检查。 Python-第一个演示通过了Blueprint审核、无头烟雾、打包烟雾和渲染的独立捕获，而未更改的模板覆盖继续通过其回归烟雾测试。

<a id="030--api-and-platform-hardening"></a>

## 0.3.0 — API 和平台强化

历史状态：已标记。里程碑当时被标记为完成。请参阅上面的资格。

- 添加通用 `TSet` 属性编组并将其提升到所需的核心套件中。
- 扩展生命周期、重新加载、异常、线程和长时间运行的压力测试。
- 审核其余编辑器、动画、Slate、音序器、网络和资产包装器的UE5行为，而不是仅编译兼容性。
- 在声明更广泛的平台支持之前，添加至少一个非Windowsbuild/runtime验证通道。
- 定义可复制的源代码和可选的二进制发布包。

验收门：六套件Win64矩阵通过所有67所需的检查，包括熟打包执行和有序interpreter/process关闭。包装器审计具有行为覆盖范围，平台声明与保留的产物相匹配，并且发布档案是从干净的命名提交生成的。

已完成的门：UE5.8.0和CPython3.11.8通过了20共享核心、20独立核心、两个隔离异常边界、五个编辑器和20打包核心检查完整结果`20260811-153622`。该运行暴露并修复了`BlendSpace`参数浅复制关闭损坏，然后以零致命、编译器或意外错误诊断和进程退出代码0完成。 Linux 仍然明确无人认领：就绪结果 `20260811-154243` 报告所需的 `v26_clang-20.1.8-rockylinux8` SDK 未在本地安装。

<a id="040--lyra-integration"></a>

## 0.4.0 — Lyra 集成

历史状态：已标记。里程碑当时被标记为完成。请参阅上面的资格。

- 首先对Lyra的游戏功能插件、模块化游戏玩法、增强输入、游戏能力系统、资产管理和多人游戏生命周期边界进行能力审核。
- 引入具有显式线程、权威、复制和热重载规则的窄Python扩展点，而不是尝试立即Lyra重写。
- 根据未更改的 Lyra 参考项目验证编辑器启动、游戏功能激活、client/server 播放、Cook和打包行为。
- 仅当性能和生命周期测量表明其安全且可维护时，才扩展Python所有权。

Lyra 故意不是 0.2.0 接受依赖项。

源门结果`20260811-165230`构建了一个干净的一次性`LyraEditor`阶段，链接了`UEPLyraBridge`，开始了与UEP拥有的CPython3.11.8的游戏世界，捕获了game-thread/Standalone快照并关闭了零编译器、致命或`Log*: Error`诊断。历史准备情况结果`20260811-184203`正确地将本地 Git 示例报告为源代码就绪但内容受阻止。完整项目就绪结果 `20260812-005352`，随后是完整驱动程序就绪结果 `20260812-013646`，通过 UE 5.8.0、CPython 3.11.8，所有五个游戏功能和每个关键虚幻包`F:\LyraStarterGame\LyraStarterGame.uproject`。最终源回归`20260811-183357`还通过了独立和真正的UDP监听专用服务器优雅退出门。最终的通用回归`20260812-043408`通过了70/70检查，包括Editor/Slate、完整的DevelopmentBuildCookRun和打包的CPython3.11.8。 `Run-UEP58LyraValidation.ps1` 现在编码完整的独立、显式同步的 dedicated-server/client 和打包运行时合约。阴性结果`20260811-184148`拒绝了分期前的无内容物样品。预发布`All`结果`20260812-025232`然后通过了准备，编辑器构建，独立游戏，dedicated-server/client权威和复制，以及冷DDC完整Win64BuildCookRun。在 UAT 成功存档后，其可执行布局防护暴露并因一个不正确的内部路径假设而停止。更正后的位相同包通过了完整的游戏玩法和生命周期契约，严格结果`20260812-042711-packaged-resume`、CPython3.11.8以及零致命或`Log*: Error`诊断。

命名的发布代码提交`c797d56`随后通过一次调用从就绪状态通过打包运行时传递正式的`All`结果`20260812-051532`并设置`full_acceptance: true`。它烘焙了4,046包，为编辑器、独立版、两个网络角色、UAT和打包的游戏返回退出代码0，并保留了零严格的runtime/UAT错误诊断以及匹配的可执行哈希值。

完成的边界保持Lyra原生的游戏功能激活、能力授予、输入映射和复制的权威敏感状态。 Python 通过一次性桥观察这些状态。参考项目和Unreal Engine源在整个验证过程中保持不变。

<a id="050--python-driven-lyra-gameplay-slice"></a>

## 0.5.0 — Python驱动的Lyra游戏切片

历史状态：已标记。里程碑当时被标记为完成。请参阅上面的资格。

- 添加一项有界权威写入，而不是广泛的任意 GAS 访问。 Python 选择命令ID、健康增量、目标角色和时间。适配器检查游戏线程、权威、目标准备情况、大小、non-lethal/non-overheal策略、损害免疫和幂等性。
- 通过目标ASC执行Lyra现有的SetByCallerDamage/Heal游戏效果。不要直接写入 Health 或替换Lyra 复制。
- 证明客户端写入在本地被拒绝，没有隐式RPC。
- 证明专用服务器Python进程更改了真实远程玩家的健康状况，客户端Python观察到复制的损坏值，服务器Python仅在确认后才恢复，并且客户端Python观察到恢复。
- 保留0.4观测合约和不变的外部Engine/Lyra树。

验收门：严格的独立，同步dedicated-server/client，Win64BuildCookRun和打包的游戏全部传递UE5.8与引擎捆绑CPython3.11。结果 JSON 必须记录权威拒绝、准确的 `100 -> 90 -> 100` 运行状况、重复命令拒绝和有序关闭（无需编译器）、fatal/assert 或 `Log*: Error` 诊断。

增量执行结果`20260812-233341`（单机）和`20260812-233801`（网络）通过新的命令、权威、幂等性和复制合约。正式的`All`结果`20260812-234501`然后通过了完整的游戏切片候选者`full_acceptance: true`：就绪，编辑器，独立，环回专用server/client，Win64BuildCookRun和打包执行全部传递UE5.8.0和CPython3.11.8。每个进程都退出0，包哈希匹配，并且严格的运行时日志不包含fatal/assert/`Log*: Error`诊断。在控制器选择器经过强化以拒绝模糊的人类目标后，精确源结果`20260813-005436`（网络）和`20260813-005835`（独立）通过，而没有另一个Cook/package.对该确切源的最终包确认保持开放。该版本随后被标记。该标签并不能弥补这一证据差距。

<a id="060--playable-python-first-third-person"></a>

## 0.6.0 — 可玩 Python-第一人称第三人称

历史状态：于2026-08-24完成并发布。轻量级检查、无头UE5.8独立合约、Blueprint审计、打包运行时合约和可见客户端门通行证。然后，完成的演示历史记录被移至`AvaloNero/UnrealEnginePython5Examples`，并作为`Demos`子模块固定在此处。

- 将以前的543行组合的runtime/smoke模块替换为一个包，该包将生成的游戏类、动画、游戏状态、可见演员、视口HUD、世界生命周期和自动化分开。
- 将模板奇偶校验证明变成一个完整的小回合：六个可收集的球体、累积分数、计时器、完成状态、自动下一轮和Python驱动的伴侣。
- 将每帧调试 HUD 文本替换为当前游戏世界会话拥有的一个真正的命中测试不可见 Slate 树。
- 将 PythonFirst 设置为默认演示，同时保留原始 Blueprint 覆盖仅作为显式兼容性回归。
- 保持官方UE5.8地图、网格、动画和输入资源不变，并保持空项目C++模块没有游戏性。

验收门：UE-捆绑CPython3.11通过纯状态测试。 Blueprint审核保持稳定。 headless Standalone 证明了生成的类、五个输入绑定、movement/look/jump、四种动画状态、所有六个拾取器、score/victory、伴随运动、HUDattach/update、相同地图切图和显式清理。可见 1280x720 运行可玩。相同的合约以Win64包的形式传递，并具有严格的干净日志。

历史证据：无头独立结果`20260824-211718`通过了完整的模式-5runtime/teardown与UE5.8.0，CPython3.11.8的合约以及加载的UEP 0.6.0 描述符。它通过官方映射上下文提供`W`、`MouseX`/`MouseY`和`SpaceBar`，并记录移动、外观、跳跃和所有释放的按键。 Blueprint审核结果`20260824-211829`保留预期的四个蓝图、27图表和173节点。 Win64打包结果`20260824-203312`记录UAT`Build=False`，存档1754Pak条目并从内部打包目标传递相同的模式-5契约，零释放阻塞UAT/runtime 诊断。可见的播放结果`20260824-044028`确认了渲染的PythonHUD、物理鼠标外观和SpaceBarjump/fall/land序列。最终禁用跟踪的包重新启动时带有零个 TCP 侦听器，并且没有 Windows 安全选择器。

<a id="070--blueprint-mixins-and-retained-class-third-person"></a>

## 0.7.0 — Blueprint mixins 和保留类第三人称

历史状态：已标记。源码实现、资产生成、无头独立和Win64Cook/package验收完成。可见-客户接受待定。

- 为 Blueprint 生成的类添加 `register_mixin`、`mixin`、`unregister_mixin` 和注册表检查。
- 通过 Blueprint 接口或显式 Python API 添加具有 CDO 声明的 Mixin 设置、互斥命名Profile和缓存的每个实例Profile选择的类路由器。
- 替换选定的 Blueprint `UFunction` 地图条目，同时将每个对象和资产保留在其原始 Unreal 类上。
- 当活动Profile省略路由器联合中的一项功能时，自动调用保留的Blueprint实现。
- 保留显式的 `call_mixin_original` 路径、每个 UObject Python 状态和辅助方法，而不保留绑定方法引用循环。
- 在显式注销、重新加载和进程关闭时恢复每个原始功能。
- 从编辑器、游戏和打包构建中的包完成中发现直接声明的接口所有者。继承的Blueprint子级共享父路由器。
- 在 selector/initializer/teardown/dispatch 回调期间拒绝注册表修改，同时允许不同对象的嵌套初始化。
- 在直接原始调度之前，通过在注入和保留的 UFunction 的本机参数布局之间进行复制来保留本机返回值和常量引用输入。
- 添加第三人称Mixin变体，其中官方角色BP的两个实例选择不同的Profile，其中一个缺失的`Move`回落到Blueprint，而本机跳转和AnimBP保持不变。

接受门：两个活的`BP_ThirdPersonCharacter_C`对象在选择不同的Profile时必须保留相同的类。玩家必须从move/look到Python，在Profile切换后通过自动Blueprint回退，调用其原始BeginPlay，保留Blueprintjump/animation，在相同的情况下生存unregister/re-register pawn 并恢复原来的 Blueprint Move 实现。已安装的Engine/template保持不变。示例存储库有意拥有一个同路径角色 BP 副本，除了 Epic 的游戏图之外，仅包含 Mixin 界面配置。

历史证据：重复生成结果`20260831-012003`和模式-4无头独立结果`20260831-012054`compile/link在UE5.8.0和CPython 3.11.8。可玩角色声明`DA_ThirdPersonCharacterMixin`，读取其可实例编辑的`PythonMixinProfile`变量，并传递相同BP选择、Blueprint回退、直接和声明的重新注册、完全恢复、包加载固定装置、本机const-array/return和回调重入门。 Win64 打包结果 `20260831-014230` 构建游戏目标，cooks/stages/archives 并在打包的运行时中传递相同的合约。它的Cook日志证明命令行引导程序被跳过，并且没有路由函数映射被序列化到资产中。模板审核`20260829-225525`和Python-首次回归`20260829-225336`也通过。严格的package/build/runtime日志是干净的。该树尚未记录可见客户端证据。

<a id="080--lyra-python-hud-foundation"></a>

## 0.8.0 — Lyra Python HUD 基金会

历史状态：未发布的开发候选者。 2026-09-03运行通过了当时实施的检查，而不是更正后的0.8发布契约。它是NullRHI/headless，省略了HUDAudit，并且没有强制执行最终清理或只有一个活跃的演示者。视觉奇偶校验和当前源重新运行仍然开放。

- 重用经过验证的HUD/session生命周期，同时保留Lyra的`ALyraHUD`、游戏功能激活和CommonUI所有权。
- 将可见的健康栏行为替换为绑定到 Lyra 的健康组件事件的 Python 呈现器。
- 证明复制`100 -> 90 -> 100`、重生、体验拥有的`Add Widgets`teardown/recreation、重复切图和零专用服务器小部件创建。

历史结果`20260903-033426`通过了当时在UE5.8.0和CPython3.11.8上实施的`All`通道以及`full_acceptance: true`。单机、网络客户端和打包游戏分别记录3构建/2解构并平衡最终委托。专用服务器记录零HUD状态。 BuildCookRun，打包的运行时退出0，并具有匹配的可执行哈希值和干净的严格日志。

<a id="2026-09-07-closeout-progress--host-checks-audit-and-focused-standalone"></a>

## 2026-09-07 收尾进度 — 主机检查、审计和重点独立

文档基线被作为核心`55d8670`/示例`6a749ee`推送。以下关闭更改是从后续的脏工作树测试的，而不是新标记的或完全运行时接受的版本：

- HUD启用`All`调用严格审核，并且在没有通过运行审核的情况下无法设置其完整标志。诊断跳过仍然妨碍完全接受。
- Probe/driver 检查拒绝重复的活动演示者。架构 5 保留活动快照，写入 `awaiting_shutdown`，并在 UEP 的 Mixin 退出前清理之后记录来自 Python `atexit` 的最终 HUD 状态。外部驱动程序在进程完成后检查最终的zero-owned-callback/reference计数并排序退出标记。 Missing/unclean 最终确定失败关闭。
- 17 Python 测试和 28 PowerShell positive/negative 检查通过。 Python 测试包括真实的 CPython 子进程退出并进行清理、残留绑定以及 `os._exit(0)` 绕过终结器。这些不是虚幻运行时测试。日志在`.build/LyraValidation/Full/Results/20260907-hud-closeout/`下保留为`python-host-tests.log`和`powershell-contract-tests.log`。两个进程都退出0。该目录中的`hud-audit.log`记录了失败的编辑器启动。
- 旧的`20260903-033426`运行时JSON被新的schema/final-evidence合约拒绝。它仍然是历史证据，在磁盘上没有变化。
- 只读编辑器尝试 `20260907-hud-closeout` 在运行审核之前退出 1。引擎BuildId是`91898095-bb6d-4da0-9340-28669c3653b3`，而分阶段插件和多个引擎插件的`160ea5ae-f247-4a72-996b-dea22b186e2f`。 `DerivedDataBuildController` 加载失败。此时这是一个 environment/binary-provenance 拦截器，而不是失败的 Python 演示者测试。引擎的`UnrealEditor.target`收据有第三个BuildId、`81feb3cc-2985-40bd-9e05-ca9d4172c49f`。仅凭启动失败并不能确定是哪个构建步骤导致了这种不一致。没有BuildIds被手动覆盖。 Startup 确实调用了 Unreal 的 SDK 验证，而不是 C++ 编译。
- 后续诊断发现`NetCore.dll`比某些引擎插件清单更新：旧的All run使用`160ea5ae...`，而DLL/root元数据随后更改为2026-09-0219:53:45/46UTC。未确定具体的发起命令。旧的基础`UnrealEditor.target`收据本身并不能证明ABI不匹配。
- 受保护的 UBT 预检 (`build-preflight-detailed.log`) 仅发现两个过时的元数据操作，没有 compiler/linker 操作。现有生成的记录已复制到`metadata-backup/`（344 文件）。官方UBT随后只执行了`WriteMetadata UnrealEditor.version (LyraEditor)`和`WriteMetadata LyraEditor.target`，在3.72秒内成功，并回收了当前引擎BuildId`91898095-bb6d-4da0-9340-28669c3653b3`。 `build-metadata-repair.log` 保留动作列表。未编辑任何引擎源。 NetCore、UEP 和 LyraGame DLL SHA-256 值未更改。
- `hud-audit-after-repair.json`及其日志记录了新的严格审核通过。编辑器退出0。真正的 Healthbar 保留其类，声明 `UEPPythonMixinInterface`，选择 `Python` 并保留 `BlueprintFallback`。编写的图形引脚默认值是在没有compiling/saving资产的情况下读取的。
- 当前覆盖Python脚本已同步到现有阶段。本机分阶段源与签出相匹配，并且没有调用 C++ 构建。 `standalone-shutdown-summary.json` 保留脏树 core/Examples 修订版、脚本和二进制哈希以及显式 `full_acceptance: false` 范围。 `standalone-shutdown.json`在UE5.8.0 / Python3.11.8上传递模式5：健康`100 -> 90 -> 100`，Pawn替换，小部件动作娱乐和切图通行证，只有一个活动presenter/reference.实际UE关机后，快照记录0presenters/references、3构造/3破坏、1路由器拆解，控制器 binds/unbinds 3/3 和运行状况 binds/unbinds 6/6，没有演示者错误。进程在102.024秒后退出0。当前驱动程序的严格report/log断言通过。日志顺序为`UEP_LYRA_AWAITING_SHUTDOWN`、`Goodbye Python`、`UEP_LYRA_HUD_SHUTDOWN_PASSED`，然后是`Log file closed`。
- 参考 Healthbar 哈希值仍为上面的值。上演的健康栏仍然是`3247123608F568DCA5A5D48A9ECEE6B02F02DE36EC59716BA27E57515795D1AC`。

此时，视觉修复和调用方 BP 固定装置仍然开放（请参阅下一个后续内容）。 2026-09-07 运行未完整运行`All`、同步网络、cook/package 或提交验收。组合门仍然需要新的证据。无论是这个重点通过还是旧的绿色运行都不是发布批准。

<a id="2026-09-10-animation-and-cross-actor-follow-up"></a>

### 2026-09-10动画及跨界Actor后续

Python 演示者现在使用保留的 `OnDamaged`/`OnHealed` 动画和 CommonUI 插值，而不是在每个健康通知上重置。 Initial/new-Pawn状态使用`InitializeBarVisuals`。最大健康状况标准化不再硬编码为100。反射的`OnAnimationFinished`事件链伤害完成到`OnEliminated`。在正常破坏中停止动画之前，取消会解除等待死亡的武装。路由器清理静静地暂停。主机检查通过 29 Python 测试和 40 PowerShell 案例。

`.build/LyraValidation/Full/Results`下保留的记录：

- `20260907-hud-closeout/standalone-visuals-20260910-summary.json`：真实当前动画脚本NullRHI独立传递健康事件，Pawn替换，游戏功能动作替换和切图，然后最终零演示者/引用和控制器3/3，健康6/6绑定。它早于后来的附加动画事件分类帐和独立的视觉测试模块，并且不会追溯分配给整个最终树。
- `20260910-hud-visuals/callsite-04.json`：在Mixin注册之前编译的调用者BP会调用两个预先存在的同类Actor目标。原始、Mixin、重复、交换和恢复阶段都通过。 Python不会隐式调用保留的BP。缺少的方法可以做到这一点，取消注册会恢复已编译的调用点。未保存Blueprint资产。早期的固定装置尝试在编辑器`PostEditChange`重建上失败。运行时风格`set_property`编写隔离调度行为。
- `20260910-hud-visuals/visual-02.json`和八个PNG：实际D3D12UMG渲染显示伤害`100 -> 93 -> 60`，治疗`60 -> 67 -> 100`，消除0并恢复全部生命值。屏幕截图检查确认了红色伤害、绿色愈合和`ELIMINATED`状态。最初失败的尝试称为未反射的当前值获取器。夹具现在读取真实的`GetText()`输出和反射的目标。值是采样帧，而不是精确帧计时的承诺。
- `20260910-hud-closeout-integrated/summary.json`：签入的重点验证器一起通过两项检查，记录native/script/PNG哈希值和最终清理（一个Construct/Destruct，不保留widgets/callbacks）。它明确是**不是**完整的Lyra`All`：`full_acceptance: false`，没有UBT，C++编译，cook/package或资源保存。最终的运行程序修订版也会在`20260910-hud-closeout-final`下重新检查。

视觉运行使用一个独立的真实小部件和一个仅供测试的健康读取器。它不是 GAS/delegate/network 或打包运行时测试。普通覆盖仅使用显式视觉验证标志导入该装置。

共享引擎活动在迭代期间更改了NetCore和模块记录。官方UBT预检仅列出了两个元数据操作，然后重新生成记录。修复本身并没有compile/link或更改检查的DLL哈希值。集中综合证据使用BuildId`347adf8a-0e10-4046-9bb4-c7a62877a03a`。未编辑 Engine source/reference 项目。参考健康栏SHA-256仍为`7AD30080E82AF2BB2FB40DD132F632A35E3429076ABAD49A37FDFD657895CF66`。完整的驱动程序审核 + 新检查 + Standalone/network/package 组合尚未重新运行，并且这些重点传递没有暗示 0.8 发布标签。

其他同匝边缘情况记录：

- `20260910-hud-switch-probe` 将完成调度复制到变异路由器中，然后是致命的零大小原始`Destruct` 帧。随后的`20260910-hud-switch-fixed`运行确认静默暂停消除了完成重入，但没有消除独立的本机后备断言。
- `20260910-hud-visuals/build-native-fallback.log`：官方UBT和`-NoEngineChanges`在24.15秒内执行了四个操作：编译`PythonFunction.cpp`，链接UEPlib/DLL，并写入项目元数据。唯一的本机源更改使零大小函数的原始后备分配非空。没有重建引擎源、游戏目标或包。
- 早期的重点传递早于最终的本地更改。后修复`20260910-hud-native-closeout`记录重新运行调用者路由，包括无参数本机回退、正常渲染清理和单独的立即animation/profile-switch进程。不要将早期记录的 DLL 哈希值重新标记为新的 DLL。
- `20260907-hud-closeout/standalone-native-final-20260910-summary.json`：原生修复后常规Lyra独立版也会在98.906秒内传递，包括健康事件、Pawn替换、小部件操作替换、切图、一位活跃演示者和最终3/3Constructs/Destructs， 3/3 控制器绑定，6/6 健康绑定和零拥有的小部件引用。两次修复后运行都记录UEP DLL SHA-256`39E68245A1919FA901CE5D79AAA9482972B13DA331CBAA97C5672D0588F079C7`。最终的覆盖脚本哈希仍然与传递的聚焦运行匹配。只是专注跑步者对无效`Mode`/switch组合和文档的拒绝随后收紧。没有更改运行时scripts/native源。

<a id="2026-09-12--two-client-network-closeout-implementation"></a>

## 2026-09-12 — 两个客户端网络关闭实现

扩展后的合约是一台真正的专用服务器和两个独立的客户端，B0退出，B1重新加入（四个流程实例）。示例桥现在公开显式的 World/Player 令牌、每个玩家快照、有界健康命令和 Pawn 重新启动。核心的无构建运行程序执行新的HUD审计、source/module/hash检查、阶段障碍、严格日志和全进程atexit清理。 `Network/All` 需要此门，而`NetworkPrecheck` 保留旧的单客户端诊断。 NullRHI 网络不证明渲染或打包的网络行为，并且从不设置完整发布标志。

本机构建出处，位于`.build/LyraValidation/Full/Results`下：

- `20260912-network-build-01`：官方UBT和`-NoEngineChanges`在C++编译之前停止，因为现有引擎module/version元数据需要重新生成。 UHT生成了三个阶段文件。这不是运行时传递。
- `20260912-network-build-02`：备份326受影响的引擎元数据文件，检查官方操作导出，然后运行恰好五个操作：桥接编译、DLL/lib链接、引擎元数据和项目元数据。构建在 51.06 秒内成功。未执行引擎 C++ 编译或cook/package。 NetCore DLL SHA-256 before/after 保留`E71D3F07887D6376297A23A3B3A65122DCB75CF2ABC9885C7858F8FF1E5DE1A1`。 Source/reference 资产未经编辑。模块 GUID 是由UBT生成的，不是手动欺骗的。

保留失败的线束迭代（不是验收证据）：

- `20260912-network-run-01`：真正的A加入，但在线身份取代了URL昵称。调查拒绝了自己错误的昵称假设。通过关联实际的 local/server PlayerState ID/name 和服务器令牌（而不是加入顺序或用户提供的昵称）来修复。
- `20260912-network-run-02`：damage/heal 隔离，颠倒了 ACK 顺序，并且两者都重新启动，然后瞬态 Windows 共享冲突中断了原子状态文件读取。添加了有界重试，保留永久错误和格式错误的 JSON 失败。
- `20260912-network-run-03`：本机机器人枪声在测试的玩家重新启动后引入了重复的12点健康变化。未更改的100/90/80检查拒绝了这种干扰。选择加入测试现在仅停止三个机器人的大脑逻辑。它保留了原生预热，并且不会改变玩家免疫力、生命值存储、复制或有界GAS命令规则。
- `20260912-network-run-04`：机器人助手最初无法解压UEP的单出参数元组。它的三隔离脑屏障保持关闭状态。源头检查发现错误。这次运行被故意停止并记录失败。添加了对真实返回形状和AI仅在重试之前写入边界的主机测试。

当前的主机套件有50Python测试和45PowerShell合约。这包括对抗性ACK身份、错误所有者HUD/events、缺失参与者、非有限健康状况、缺席最终确定、共享违规、反映的数组外处理以及新的强制性双客户端释放门。单独的主机传递并不是网络运行时的结果。

<a id="passed-focused-runtime-20260912-network-run-05"></a>

### 通过重点运行时：`20260912-network-run-05`

- `summary.json`：状态已通过，`multi_client_acceptance: true`，`full_acceptance: false`。运行ID`2fd770b9338043d39a6b1c0436b4d0f3`。 UE 5.8.0 / CPython 3.11.8、BuildId `038ca067-a15c-47cf-a35d-073bd334643e` 用于引擎和分阶段模块。核心`980587e4bf2d449a4154a7ba2b25ef500829cdc3`，示例`0395f360136070d96dd3ad17e1fb1023c4cc2595`，都是脏的。前后检查408本机源映射和99executable/script/test/config/asset输入哈希值。稍后仅对文档进行的更改不会更改这些输入。
- 新的HUD审核、50/50Python和45/45PowerShell主机合约通过。重复利用现有资产登记处。重点运行不执行 C++ 构建、cook/package、资产生成或防火墙更改。上面单独记录了必要的早期 Bridge 构建。
- 所有 20 服务器阶段和 N01–N16 通过。 A 观察100 → 90 → 100。 B0 和 B1 观察100→80→100。交错的 90/80 和反向的 ACK 顺序、命令重复数据删除（包括重定向尝试）、客户端权威拒绝、单独重新启动、两次非无缝相同地图切图和过时令牌拒绝均由每个参与客户端的本机快照和新拥有的委托事件证实。
- B0 在剩余的 A damage/heal 测试之前退出，然后 B1 与新的原生 token/Pawn. Server/A/B0/B1 分别保留 20/20/13/4 阶段记录。最终的 Python 退出报告、严格的 error/log 排序和真实操作系统退出代码都会针对所有四个流程实例（而不仅仅是最后一对）进行检查。

| 工艺流程 | 运行时间秒数 | 退出 | 主动构造/破坏 | 最终控制器binds/unbinds | 最终健康binds/unbinds | 最终小部件参考 |
| --- | ---: | ---: | --- | --- | --- | ---: |
| 服务器 | 187.337 | 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 |
| A | 168.506 | 0 | 3 / 2 | 3 / 3 | 7 / 7 | 0 |
| B0 | 110.955 | 0 | 3 / 2 | 3 / 3 | 6 / 6 | 0 |
| B1 | 21.051 | 0 | 1 / 0 | 1 / 1 | 1 / 1 | 0 |

离线Python交叉报告验证器和核心多客户端发布合约针对这些最终文件独立重新运行。没有保留测试UE过程。保留的NullRHI日志包含警告级别的本机Niagara/footstep`Accessed None`消息。这不是visual/FX 认证。未执行连接的渲染客户端、weak-network/LAN/WAN、stress/repeat-stability、打包网络或新组合的`All` 发布运行。没有暗示0.8发布标签。

<a id="09-batch-1a-progress--2026-10-13"></a>

## 0.9 第 1A 批进度 — 2026-10-13

证据根：`.build/LyraValidation/BlueprintPython/20261013-batch1a`。这是本地开发证据，而不是发布或接受的迁移批次。核心`980587e4bf2d449a4154a7ba2b25ef500829cdc3`和示例`0395f360136070d96dd3ad17e1fb1023c4cc2595`，在`dev/lyra-blueprint-python`上都是脏的。未执行任何提交、推送、标记或打包。 UE 5.8.0 / 引擎 CPython 3.11.8。引擎和分级模块BuildId`59220820-55ad-4797-9c21-bdc1adf3f709`。

- 静态范围清单已与 246 运行时 BP 业务候选、182 configuration/layout shell 和 63 保留动画、editor/test/interface 资产进行了协调。示例 `Migration/batches.json` 将 5/32/37/75/57/40 候选者分别分配给 0.9/0.10/0.11/0.12/0.13/0.14。 11 候选边界仍需要范围审查。计数不是迁移接受度或运行时可达性。
- 实验性函数体 thunk 的本机条目输出错误已修复：`ProcessEvent` 输出值必须复制到 `FFrame.OutParms` 调用者地址，而不仅仅是帧本地地址。打包的 bool 目的地使用它们自己的属性掩码。 `script-body-after-metadata.json`传递注册前编译的调用者，重复reflected/native条目，integer/bool输出写回，无隐式原始BP调用，类标识不变并取消注册恢复。输出为 33/false、-6/false，然后恢复为 13/true. 这个狭窄的 thunk 仍处于实验阶段，不被 Lyra Profile使用。它不验证所有签名、RPC 或潜在功能。
- `plugin-build.log`记录一个增量UEP模块compile/library/link（三个动作），UBT成功，9.45总共秒。没有 Engine/Lyra C++ 重建或 cook/package. 现有生成的模块 BuildId 不匹配阻止了第一个编辑器启动。备份916在`metadata-backup`下生成的元数据记录后，官方UBT`WriteMetadata`运行了两个仅元数据操作，总计5.81秒（`metadata-repair.log`）。引擎**来源**未经编辑。生成的Engine/stage模块元数据已修复，因此整个引擎目录并未声明未受影响。早期 Engine/stage ID 差异的原始原因尚未确定。
- 四个示例拥有的武器 BP 和四个Mixin 套装位于标记的一次性阶段中的generated/compiled 并复制到示例叠加层中。普通类名称和layout/material资产保持不变。原生库存、设备、GAS、输入和复制被调用，而不是重写。现在，创作会检查虚幻的当前项目是否与任何注册表或资产变更之前的标记阶段相匹配。官方Lyra资产未保存。 `weapon-hud-declared-audit-02.json` 独立地传递真实的UE 舞台保护和所有四个持久选择器。它的第一次只读尝试暴露了UEPcommandlet不存在`__file__`。工具导入已修复以定位提供的脚本参数，并且新的commandlet退出0，而不会保存资产。
- `WeaponDeclaredRegression02/summary.json` 通过持久的 Interface/CDO 默认值和所有 42 隔离实数UMG original-BP/Python 比较。检查精确的text/visibility、Pistol/Rifle/Shotgun低弹药阈值、两个材质图像、weapon/slot更改、空插槽、画笔助手、本机重新加载输入调度、未更改的类、四个路由器恢复和严格的正常process/Python退出。 source/stage 输入和四个原始 BP 参考哈希在运行期间保持稳定。 BP-left/Python-right PNG 已检查。未执行定量像素差异。
- 失败的`WeaponDeclaredRegression`证据被保留：新的重新加载路径暴露了无效的`ue.Vector`名称。尽管该装置有通过标记，但跑步者正确地拒绝了错误日志。它被修复到`ue.FVector`，成功调用计数器在回调工作后被移动，并且新的`02`运行通过而没有削弱断言。早期的`weapon-differential-01`也保留了刷失败的预期。对原始图的审计表明，其资源是提供的 UImage 对象本身。实现和期望已根据编写的行为进行了纠正，而不是针对新功能。
- 同样的重点`02`运行启动普通的`L_Expanse`，没有UEP验证标志。所有四个声明均注册，本机体验加载，并且进程在没有 probe/quit 标记的情况下保持活动状态 20 秒。然后，驱动程序有意仅停止该拥有的进程（退出 -1）。这个NullRHI观察不是rendered/input或优雅退出接受。
- `HealthRegression/summary.json` 通过预编译的跨Actor 调用并渲染damage/heal/death/respawn，并使用单独的实时animation/profile 切换进程。 `NetworkRegression/summary.json`通过现有的dedicated-server/two-client**Health/HUD**合约（N01–N16，20协议阶段，Bleave/rejoin）。 Server/A/B0/B1 全部在189.755/171.747/113.067/20.911 秒内退出0。两条聚焦车道仍为`full_acceptance: false`。他们通过的健康结果并不是新弹药的证明。
- 当前主机重新运行通过了67Python测试，现有的45PowerShellHUD/network契约和10附加窄武器证据契约。网络调用先于最后一次武器测试添加。其自己记录的主机结果不得重新标记为67测试调用。

第 1A 批仍然开放：真火和GAS重新加载、每个玩家复制ammo/UI、weapon/Pawn更换、事件驱动的弹药订阅和清理。武器Profile目前保留原始 BP Tick 轮询。隔离装置使用确定性本机库存输入，而不是真实的equipment/replication.更广泛的0.9call/lifecycle矩阵，受控重新加载，重复PIE/GC/travel，候选包和API冻结门也保持打开状态。不暗示0.9完成或完全接受gameplay/network。

<a id="09-batch-1a-runtime-follow-up--2026-10-13"></a>

## 0.9 第 1A 批运行时后续 — 2026-10-13

与前面的条目相同的脏Core/Examples源对，并进行了额外的范围修复。否 commit/push/tag. 当前编辑器 BuildId 是 `2cd71c4e-d118-4430-ab9a-53606fc64e3a`。每次运行都会记录范围和实际流程配置。官方Engine/Lyra来源和原始资产未经编辑。生成的构建元数据和一次性阶段发生了变化。

- `WeaponNetwork08` 通过专用编辑器服务器和两个渲染客户端的所有 19 真实输入武器阶段。 Server/A/B0/B1 在252.162/234.725/161.275/36.268 秒后退出0。原生fire/GAS重新加载、耗尽、现有拾取条目和插槽切换、Pawn重新启动、两次切图和B重新加入保留每个玩家原生ammo/PythonHUD/original-BP比较。探测器不写入弹药或库存。未测试物理拾取重叠。
- `WeaponScopeRegression05` 通过 42 实数 - UMG 比较，本机 QuickBar 消息取消，四个 Python -> BP -> Python Profile往返，无需构造重放和三个受控reload/native-GC 循环。一个共享的只读采样器取代了每个小部件的轮询。弹药生产者明确是`read-only-frame-sampler`，而不是发明的本机复制委托。
- `RuntimeImportCoreRegression` 分别通过 standalone/shared 21/21。其单独的缺失依赖项情况需要预期退出1和实际依赖项name/traceback。现有的 ue_site 故障不得作为不存在的可选钩子而被抑制。核心订阅测试通过9。示例通过82。 HUD/network契约通过45，武器契约16。
- `CallMatrixRegression`通过standalone/shared签名边界，预编译交叉Actor调用者，窄实验体输出写回和预期Mixinexception/no-native-fallthrough/recovery.预期异常退出1被隔离，检查并且不被算作普通干净进程。
- `PIERegression05`在一个编辑器中传递三个真实会话，placed/spawned未更改Actor类，生成构造，每个会话两个BeginPlay/EndPlay对，封闭范围，本机GC和原始功能恢复。
- `ThirdPersonRendered05` 通过了带有本机输入的 Mixin/Python-first 变体、movement/look/jump、六个渲染的 PNG 和严格的 cleanup/log 检查。现在记录0.7Mixin可见候选门。历史缺失的证据仍然是历史。增量变体准备在保留Mixin角色CDO同时删除其Python模块后得到修复。
- 在稍后的导入路径修复之前，`HealthCoreRegression`分别传递health/cross-Actor/eight-frame和实时动画Profile切换回归。未更改的健康实现不会被重新标记为较新的调用。
- `WeaponPackage05`记录当前游戏构建并成功Cook/archive.`WeaponPackagePresentation07`重用其未更改的inputs/archive并传递渲染的42-case/native-signal/profile/reload/GC固定装置，具有显式打包网络跳过和`full_acceptance: false`。 Internal/stable 本机可执行文件SHA-256 是`F65A8D7342093B064BE7F528AF0473AFEB1F4CA1CB6C329D63B20890FA29C28C`。核心帮助程序源是松散的 NonUFS 文件，并实际导入到游戏中。

保留故障及维修：

- 早期的武器网络固定装置故障暴露了未反射的GetItemDef、陈旧的无根InputAction、缺少第二个武器、未打包的GetAllActors输出元组和不可见基线小部件的GC。 Native/property 查找、输入生命周期和测试拥有的 root 已更正。后来的运行过去了。
- 本机 GC 测试暴露了 `new_object(Object)` 上真正的 UEP 崩溃，其中 UClass 是抽象的。 UEP 现在在 UE 的本机断言之前引发 TypeError。真实的UE装置验证了这一点。
- 单独生成的编辑器模块元数据漂移阻止了验证启动。官方UBTWriteMetadata在observer/generic元数据备份下刷新了备份后的现有记录。未使用手写的BuildId替换或引擎源代码编辑。
- Package01 已成功存档，但严格日志拒绝了两个 UnrealPak PlatformCrypto 模块加载错误。 `pak-metadata-backup` 保留之前生成的记录。官方WriteMetadata保留UnrealPakBuildId`5fcd6720-663f-4993-8774-c33f25582f7f`。 Package02 具有干净的 UAT 日志，但启动失败，因为稳定的可执行文件别名缺少其 basedir。
- Package03 使用了正确的 basedir，但真正缺少的运行时插件脚本搜索路径阻止了 uep_runtime 导入。可选钩子处理程序隐藏了依赖的ModuleNotFoundError，探测器从未启动，并且无上限的离屏渲染最终耗尽了视频内存。修复了运行时插件搜索和准确的依赖导入报告。测试渲染已被限制。
- 该修复的第一次游戏编译失败，因为 IPluginManager 的包含内容仍然仅限于编辑器 (Package04)。包含内容已更正。当前的编辑器和游戏构建通过。仅构建了所需的module/current游戏目标。
- Package05的UMG测试通过，但使用游戏目标`-server`无法生成专用服务器角色。然后，对于生成的 World 分区单元，Package06 的 Editor-server/cooked-clients 尝试在 MissingLevelPackage 上失败。这两种失败的拓扑都不会被提升为打包网络验收。 LyraServer干计划导出1,235冷操作和14,064生成的UHT文件。未执行服务器 C++ 编译或服务器包。这仍然是一个单独的RC债务。
- 核心预期异常和新驱动程序log-order/schema错误已在其专用fixtures/drivers中得到纠正，并具有新的结果目录。两个现有配置 CC 调用超时（20 和 10 分钟）。未收到或声明任何外部评审员的决定。

以前的托管包可以在`.build/LyraValidation/Full/PreviousPackage-*`下恢复。它们的路径记录在每个包摘要中。包展示和编辑器多人游戏是传递范围。完整版本、专用打包网络、DebugGame/Shipping、弱网、跨机器和无限制热重载尚未验证。查看新的 call/lifecycle 矩阵、运行时订阅契约和 API 库存。

<a id="010-batch-2a-pilot--2026-10-13"></a>

## 0.10 第 2A 批试点 — 2026-10-13

`20261013-batch2a/assets.json`仅作者标记阶段的弹药十字线BP和Mixin集合。原始Lyra资产SHA-256不变。两个示例拥有的持久资产被复制到覆盖中。 `reticle_ammo_mixin.py`通过现有共享观察者拥有材料ActiveRange/Segments呈现。原生库存和UMG布局保留。

`ReticleRegression03`通过了十个真实的-UMGBP/Python材料比较（两种杂志尺寸，每种5个计数），类别标识，Python -> BP -> Python，无需重建，渲染屏幕截图和零最终observer/scopes/股票。该进程退出0并带有严格日志。此试点没有执行 C++ compile/cook/package。它的第一次松散调用缺少已建立的`culture=en`标志，并以中文记录了UEUnifiedError格式测试失败。新的重点驱动程序使用与其他车道相同的声明文化，并且新的调用传递不会忽略错误日志。目视检查`02`发现所需尺寸为零，产生了黑色图像。 `03` 为两个比较小部件提供了显式相等的视口大小，并检查了实际的两个弧。对本土物质的主张从未放松过。主机示例测试现已通过83。游戏过程中实际使用的十字线，multiplayer/package证明和0.10的其余部分保持开放。该试点尚未完成 release/batch.

<a id="combat-hud-native-inputcontext-follow-up"></a>

### 战斗HUDnative-input/context后续

`fire-button-assets.json` 通过标记阶段Interface/Set/CDO 创作并保留`W_FireButton_C`。 Python 拥有原始的绑定单击条目，并注入相同的 Fire/Fire_Auto 操作和 FVector(1,1,1)。 BlueprintFallback 调用保存的BP条目。没有ammo/inventory/GAS/authority/replication写入。

保留故障及维修：

- `CombatHUDNetwork01` 超时，因为夹具错误地预期生产弹药条十字线。原始Pistol/Rifle/Shotgun默认使用其特定的reticles/counters.更正后的测试显式拥有其覆盖并从生产计数器的本机WeaponInstance初始化candidate/BP基线。项目定义没有改变。全球可达性仍然未经审查，也没有宣布缺席。
- `CombatHUDNetwork02` 在大写 R/G/B/A 访问上失败：UEP 的专用 FLinearColor 包装器使用小写通道。包装形状的主机测试保护正确的读取。
- `CombatHUDNetwork03`通过了当时的数字协议，但渲染审查拒绝了最终的视觉批准：可以看到滚动的相机和健康淘汰的UI。 UEP的FRotator顺序是Roll/Pitch/Yaw，所以旧的`(80,0,0)`没有瞄准。这符合较早的WeaponNetwork运行的天空瞄准主张，而不是他们测量的ammo/replication证据。轴现在是显式的，并且模式 4 在触发 ACKs 时需要本机 Pitch=80/Roll=0。
- 演示者可以读取 pre-ASC 0/0，然后接收 old=100,new=100 并使 OnEliminated 可见。现在它可以识别之前出现的零并恢复OnSpawned/numeric/material状态。 Health 或 max-health 可以是第一个就绪通知。普通的damage/denominator-only更新不会重新初始化。

`HealthBootstrapRegression01` 通过当前源调用方 BP 路由、八个渲染的运行状况检查点和一个单独的动画中期Profile切换过程。两种视觉过程都需要延迟-ASC 恢复。检查最初的健康图像和后来的death/respawn图像。

`CombatHUDNetwork04`通过模式4：19server/A阶段，14B0，3B1。两个渲染的客户端。 Python/BP火意图，本机reload/depletion，现有pickup-entry/slot切换，Pawn重新启动，两次切图和B0exit/B1重新加入。八个屏幕截图经过哈希处理。每个拥有者的生命值number/current目标/材料比率也与原生生命值相匹配。所有出口为0：服务器234.871s，A219.634s，B0142.821s，B138.390s。 A/B0/B1订阅余额17/17、13/13和3/3，范围3/3、3/3和1/1。每个对等点的活跃观察者、范围、代码和错误均为零。示例主机测试通过111。

游戏 PNG 保留原生 `WeaponAudioFunctions.EarlyReflections` TapIDs 警告，也存在于 `WeaponNetwork08` 下的 `-NoSound` 中。通过了严格的错误检查，而不是零警告或音频接受声明。未迁移的音频编排属于0.12范围。其警告并未在官方BP中隐藏或修复。

此后续操作未执行 C++ 编译、cook/package、防火墙更改或参考项目编辑。物理 touchscreen/gesture 调度未经过测试（绑定单击条目以编程方式调用）。弹药条默认/生产可达性、实际生产标线、新资产包证明和其他30初始0.10候选者仍然开放。旧的0.9包不是最新的script/asset证明。三个仅限家长使用的触摸外壳需要家长通话审核。初始计数保持不变。未声明release/publication 或外部 CC 批准。

<a id="world-pad-parent-pilot-and-inherited-selector-follow-up"></a>

### World 填充父pilot和继承的选择器后续

`20261013-batch2b/assets.json` 失败，因为编辑器创作助手尝试重新声明继承的 PythonMixinProfile。帮助器现在重用标量名称并仅写入默认子级 CDO，而不更改父级元数据。第一个不受限制的目标构建在编译前被`-NoEngineChanges`拒绝。仅模块UBT然后编译UEPyEditor.cpp加上lib/DLL链接（三个操作，88.99秒）。未使用引擎 C++/source 修改或cook/package。

编译后，`inherited-selector04`传递父级Python默认值，子级BlueprintFallback默认值，无需重新声明，并且使用独立反射选择器的两个相同子类实例。仅本地后备广播。尝试扩展子声明发现会击中`inherited-selector03`中现有的相关类路由器防护。它被恢复，而不是默默地允许：最终的UEPyMixin.cpp源保留了原始的运行时契约。另外两个模块构建验证了attempt/restore (7.42/7.27s)。 `CallMatrixRegression01` 通过了五个新的 signature/shared/caller/body/exception 装置以及最终的 DLL。一般的parent/child同时路由器和显式父旁路限制仍然存在。这不是层次结构拦截支持。

`parent-differential01`通过了四次真实的Actor构造比较（damage/heal/special/invalid），在推迟FinishSpawn之前选择Profile。材质父级、text/world大小、类标识、Python构造计数和无-ASC重叠无操作与BP一致。所有八个测试Actors均被销毁。原来断开连接的PrintString/attribute-read节点不会作为运行时业务进行迁移。 Level=0 和 class/all-stack 删除意图保留创作的输入。 true GAS 执行、物理重叠、子项和网络仍未验证。仅将父级 BP/Set 副本添加到示例覆盖中。孩子的分阶段实验配置是从官方参考中还原的。生成器现在仅针对父级。示例主机测试通过118。

未声明 0.10 release/complete 批次或当前源包。早期的CombatHUDNetwork04证据在此编辑器创作修复之前，并且没有重新标记为最终DLL的新调用。

<a id="effect-pad-physical-gas-and-explicit-parent-construction-adapter"></a>

### Effect Pad 物理 GAS 和显式父结构适配器

`20261013-batch2b/PhysicalGAS01` 在灯具未反映的 GetComponentLocation 名称上失败。 K2_GetComponentLocation修复了测试条目。 `PhysicalGAS02` 然后传递对先前 DLL 的仅父本机 GAS 比较。创作的damage/heal效果使用Period=1、Level=0和空的EffectContext。每个Profile的两发物理enter/leave回合会造成伤害75->65->55并治愈75->85->95。本地源效应计数变为零，外部健康状况保持稳定。处理程序永远不会被手动调用。

新的纯编辑器`blueprint_extract_construction_helper`将BP主体保留在虚拟助手中，并留下一个两节点构造转发器。仅模块UEP构建编译UEPyEditor.cpp/UEPyModule.cpp加上lib/DLL链接（四个操作，23.44s）。引擎source/builds和cook/package未受影响。通用 `construction-forwarder01` 固定装置因缺少 break_all_pin_links 参数而失败。 `construction-forwarder02` 通过显式子父级 -> 虚拟助手 -> 单父路由器，无 BP 失效、Profile切换、原始恢复和五个 invalid/duplicate/non-Actor 创作拒绝。相关类路由器拒绝和其他cached/final/direct-native绕过保持不变。

`assets-forwarder01` 返回传递的 JSON，但退出 1 并出现旧声明自动发现错误（新帮助器尚不存在）。它是**不被接受**。在标记的一次性阶段中，新的官方家长输入为`assets-forwarder02`提供了干净的exit/log.，克隆的原始BP辅助体保留为BlueprintFallback。仅父级BP/Set覆盖副本发生变化。原始子项asset/default被保留（其名称并不暗示治疗默认值）。原生创作API不会自动保存。

`parent-child-differential02` 通过了八个construction/no-ASC 案例和十六个Actor 销毁。最终DLL/serialized母资产上的`PhysicalGAS03`通过了八个parent/child案例和十六个物理原生GAS轮。所有八个padActors/delegates关闭，父路由恢复，退出后HUD/武器范围为零。 `CallMatrixRegression02` 通过七个最终 DLL 装置（前五个加上继承的选择器和构造转发器）。示例主机测试通过126。核心SubscriptionScope测试通过九项。

在第一种情况之后，`PadNetwork01`暴露了固定装置设置错误：现有的本机桥拒绝未受影响的玩家的zero/no-op健康增量。安装程序现在会跳过该无操作。 bridge/game授权契约不变。网络状态机还会停止对其服务器截止时间的主动影响，而无需等待客户端健康数字动画收敛。替换的两客户端通道`PadNetwork02`通过了十六个parent/child/effect/owner/profile案例。 Server/A/B0 在135.857/136.065/137.270s后退出0。原生健康状况与每个客户生产的实际number/target/material比率HUD一致，非目标健康状况保持75。没有原始BPfallthrough/replayedPython意图发生。所有拥有的 pad 代表和退出后 HUD/weapon 范围关闭。本机服务器传送不是物理client/manual输入、客户端预测、生产板可达性、渲染板比较或打包服务器验收。未认领 0.10 release/complete 批次。

<a id="debug-spread-native-context-follow-up"></a>

### 调试传播本机上下文后续

`20261013-batch2c/assets01` 编写示例拥有的调试widget/Set，而不更改其本机LyraReticleWidgetBase 父级或官方参考资源。 Python Tick 使用原始 HalfToEven/sign/grouping/integral/fractional 默认值调用本机 ComputeSpreadAngle 和 KismetTextLibrary。没有武器扩散、inventory/ammo或本机计算被覆盖。

`DebugSpreadNetwork01` 在当前编辑器 DLL 上通过 19 个本机 fire/reload/switch/Pawn/travel/ disconnect/rejoin 阶段以及 `-WeaponGameplay -CombatHUD -DebugSpread`。 Server/A/B0/B1退出251.456/229.197/145.608/45.652s.中的0测试拥有的覆盖层接收生产弹药计数器的本机武器实例，运行本机自动Widget Tick（不手动调用PythonTick），并比较原始BP和本机格式文本。观察到超过十度的原生扩散峰值。仅接受零武器将被明确拒绝。 Owner/item 身份和退出后范围一致。

八个屏幕截图经过哈希处理。目视检查包括切换武器和重新加入 B1。传播文字2.25，向上的目标和健康的100HUD可见。本机 NoSound EarlyReflections 和 EditorDataStorageUI 目的注册警告仍然存在 visible/logged。没有warning-free/audio接受索赔。调试覆盖不是生产可达性证明，并且 C++ 构建和 cook/package 都不会在此后续版本中运行。主机测试通过135。

<a id="typed-message-transport-and-production-reticle-differential"></a>

### 类型化消息传输和生产标线差异

`20261013-batch2d/assets01` 无法将 GetPayload 参考输入引脚直接链接到结果输入。 `assets02` 生成类型化本地临时加模式连接： ReadUI/ReadVerb 每个有四个节点，BroadcastUI/Verb 每个有两个。这个 12 节点示例 BP 适配器提供类型化 VM 通配符传输，而不是业务逻辑。 generic ProcessEvent 从不调用本机通配符占位符。无需 C++/Engine 构建、源更改或 cook/package。

`transport01` 传递未更改的 Struct_UIMessaging 和本机 LyraVerbMessage 的真实可选插件交付、控制器身份、嵌套副本保存、错误读取器和外部交付拒绝、遗留通道侦听器奇偶校验和幂等关闭（后期回调为零）。 Core 的类型化订阅API 需要提供经过验证的有效负载读取器。通过了 13 项主机范围测试。

`reticle-assets01` 生成三个保留的标线声明、序列化的 kind/decoder 类配置和 Mixin 集，无需参考资产编辑。 `reticle-differential01/02`捕获角色煽动者的初始Pythoncast/fixture假设。原版演员LyraPlayerState。 owner/suicide 过滤器和夹具已校正，而不是基线。第一次清理假设武器之间的异步变量名称相同。枚举修复了该固定装置。 `reticle-differential03` 在演员校正后验证动画，但在不存在的屏幕截图方法上失败。而是使用经过验证的本机控制台屏幕截图路径。这些失败的报告不会仅仅因为退出0而被接受。

`ReticleDifferential04`在真实装备的手枪本机实例（源生产计数器）上通过三个保留布局比较，自动Python勾选，匹配radius/width/height，本地与外国ADS，未更改断开连接ADS动画行为，本机路由器elimination/restart 和自杀过滤。动画时间匹配于0.04993333。五个创建的范围关闭，零个active/errors保留在Python退出，process/log干净退出，并且配对的PNG被hashed/visually检查。保留本机r.MotionVectorSimulation警告。这不是真正的 ADS/kill 输入、装备霰弹枪验证或 multi-client/package 批准。主机测试通过141。后来的docstring/API注释保留了与记录的脚本哈希的单独关系。

<a id="production-reticle-multiplayer-and-real-adsshotgun-input"></a>

### 制作十字线多人游戏和真实的ADS/shotgun输入

`ProductionReticleNetwork01`通过了十九个fire/reload/empty/switch/respawn/travel/exit/rejoin阶段与实际生产的Pistol/Rifle掩模版。单独的隐藏BP基线读取相同的原生weapon/camera。自动 Python 勾选，class/profile/owner/item 和 radius/size 一致。 Server/A/B0/B1退出0在269.24/247.96/157.88/52.45s.本机专用服务器不创建标线范围。 A/B0/B1 分别关闭11/11、7/7 和1/1。无法通过overlay-only/old验证通道接受删除生产检查点。这些武器阶段不会生成真正的ADS/kill消息。他们不会默默地验证此类输入或网络猎枪。

通过现有的增强型Input/native能力消息生成器，`ReticleNativeADS05`通过三十个本机IA_ADS按下和三十个释放帧。拥有production/test的四个标线接收按下和释放状态。综合测试消息不能替代此阶段。 `ReticleNativeShotgun06`然后调用original/native霰弹枪拾取入口，选择其本机QuickBar插槽，从实际弹药计数器获取其装备的WeaponInstance，发射8->5弹药并重新运行三个布局比较在那件武器上。探测器未写入任何物品栏、武器spread/ammo或能力属性。它不是物理重叠拾取测试、真杀玩法或网络霰弹枪接受度。本机警告仍然保留，不生成任何包，并且这些运行先于后续的软类转换 DLL 构建。后来的主机测试通过148。

<a id="lazy-commonui-menu-and-current-soft-class-dll"></a>

### 惰性CommonUI菜单和当前软类DLL

Unicode `FSoftClassProperty` 输入存储没有本机 FindObject/LoadObject/TryLoad. Empty/null 的软对象路径，并且现有 UClass 输入保留其含义。格式错误的路径、缺少对象名称分隔符和嵌入的 NUL 都会失败。 `soft-class01/02` 暴露的固定装置查找处理和 UE 的许可包 - 仅验证器。两人都没有晋升为及格。 `soft-class03` 传递最终的 DLL，`CallMatrixRegression04` 传递八个装置。最终增量UEP模块构建具有三个操作（13.68s）。没有运行引擎或游戏编译、Cook或包。以前的 reticle/pad 运行保留其自己的 DLL 来源，并且不是当前 DLL 的重新运行。

示例拥有的 `W_OpenMenuTouchButton` Interface/CDO 通过 `open_menu_mixin` 路由其原始绑定单击方法。 Python 保留延迟菜单加载、UI.Layer.Menu 和本机CommonUI 异步input-suspend/layer 行为。它不会预加载菜单类或重写streaming/input执行。 `menu- differential01` 捕获不正确的通用数组外参数位置。 `02` 有正确的数据报告，但没有可见的菜单，并且在视觉上不被接受。等待本机转换修复捕获。 `MenuDifferential04`通过可重用的集中驱动程序：最初卸载的类，保留按钮类型，Python/BP/Python三个本机push/deactivation周期，有序清理日志，退出0（66.461s），稳定的source/asset/DLL/reference哈希值和检查了 PNG，在模糊的游戏上显示了 Options/Quit Game/Back。该驱动程序中不会发生编译或烘焙。真实触摸、输入令牌resume/cancel行为、默认生产可达性、双客户端菜单和包仍未验证。

<a id="production-reticle-host-and-two-client-lifetime"></a>

### 生产标线主机和两个客户端的生命周期

`assets01` 失败，因为 CreateDelegate 在其签名未连接时重置事件选择。在 object/signature 连接修复生成后选择OnDeathStarted。 `assets02` 编译并保留保留主机的 Interface/CDO 以及四个仅 VM 清理节点（24.46 个，无 C++ 编译）。助手仅删除此小部件的旧 BP 委托。它不会通过繁忙的Mixin路由器执行UpdateVisibility或替换本机设备。

`HostDifferential01`通过了早期的routing/lifetime情况，但未通过固定假设：LyraInventoryItemInstance对象名称无法识别武器。读取本机ReticleConfig片段修复了拾取选择。 `Host- Differential02`在实际生产主机上传递八个original-BP/Python案例，本机自动Tick/equipment回调，保留类和精确子classes/item/weapon/fill对齐。实时Profile切换会保留已创建的子项，而不是依赖于不存在的重复本机武器事件。 Null/missing-instigator 箱子、修复体和原生手枪/ Rifle/Shotgun 装备一致。注入的 GameplayEvent.Death 执行本机死亡 ability/component: 两个包装器都会崩溃，Python 恰好收到一个死亡回调，并且不会在后续 Tick 上重新打开该侦听器。这不是致命伤害、kill/score消息或物理拾取。退出0（70.062s），严格日志，inspected/hashed生产截图和最终host/reticle范围余额3/3和9/9通过。主机测试稍后通过170。

`ReticleHostNetwork01` 通过了 19 个本机 weapon/CombatHUD/debug/production- 标线阶段，并带有新的强制主机检查点和关闭门。实际的宿主子项与未更改的本地ReticleConfig和owner/item/weapon/fill/visibility进行检查。 Pistol/Rifle 几何体有其单独的隐藏原始 BP 基线。 Missing/old 主机检查点和制造的蜱或武器事件证据失败。在249.481/228.23/147.788/42.291秒内Server/A/B0/B1退出0。主机范围余额0/0、7/7、5/5、1/1。子标线范围平衡0/0、11/11、7/7、1/1. 对八个 PNG 进行哈希处理，检查选定的 A/B1 图像，并保留已知的本机 audio/Editor 警告。没有发生 C++ 编译或 Cook/package。这不是网络霰弹枪、致命死亡、物理输入、无警告、当前打包运行时或完整的0.10发布验收。

<a id="interaction-ability-progress-implementation-only-runtime-pending"></a>

### 交互能力进度：仅实现，运行时待定

`20261013-batch2g`中的`assets01`通过编辑器资产compilation/Interface/CDO创作（27.02s）。保留的 W_AbilityProgress 现在指向其 Python Profile。添加ReadDuration/BroadcastDuration后，BP传输有6个类型为functions/eighteen的节点。前四个 UI/Verb 图的语义 pin/reference 摘要保持不变。原始异步代理由一个仅所有权存储节点公开以供取消，并且显式隐藏Profile恢复条目是仅声明外壳。 Python 使用本机游戏时间、划分、文化感知格式和 material/visibility 调用。主机测试通过179。没有发生 C++ 编译、cook 或打包。

这不是运行时、生产可达性、实际交互、暂停、多人游戏或包接受。在此初始检查点仍然需要集中的original-BP/Python夹具和电流适配器标线回归。早期的reticle/host网络证据保留其先前的适配器资产哈希值。未更改的图摘要本身并不能取代当前的运行时重新运行。

<a id="interaction-progress-production-differential-and-current-adapter-regressions"></a>

### 交互进度生产差异和当前适配器回归

`ProgressDifferential01` 失败，因为其固定装置对所有 Python 侦听器进行了计数：现有的生产进度小部件也收到了本地合成消息。更正后的装置使用实际的HUD小部件和每个实例计数器。 `ProgressDifferential02`在71.211秒内通过十一次BP/Python比较，0退出，严格排序的日志，冻结input/reference哈希值和inspected/hashedPNG。它涵盖 owner/foreign/repeated 消息、本机自动 UMG Tick、匹配 duration/text/material/visibility、本机游戏时间暂停超过 1.109 秒的挂机时间、最后一秒 precision/completion、隐藏的Profile恢复而无需生命周期重播、本机 Destruct 且无后续回调。初始StartTime不相等，因为小部件初始化的时间不同。广播在所有倒计时比较之前同步它。最终范围平衡3/3与零active/errors.这是具有合成类型持续时间生产的实际生产可达性，而不是本机交互能力或复制消息测试。

`ReticleAdapterRegression01` 在 18 节点适配器上传递六次 geometry/three 类型化消息比较、实际 ADS 输入和本机装备猎枪射击 8->5。最终标线瞄准镜平衡6/6。检查了其图像（保留了本机警告横幅）。在执行夹具之前，`TransportAdapterRegression01`在NullRHI启动时超时，并且其拥有的进程被停止。屏幕外的`TransportAdapterRegression02`传递键入的UI/Verb值、遗留信号、嵌套复制隔离、错误的reader/outside-delivery拒绝和封闭侦听器静默，具有封闭的严格日志和稳定的哈希值。这些驱动程序不构建、Cook或打包。主机测试现已通过194。

可选的`AbilityProgressNetwork01`运行时运行失败，不被接受：每个阶段都使用实际生产UI加上隐藏的BP基线，合成本地Pawn/Controller消息，可见的倒计时比较和本机完成。控制器是非Pawn外国Instigator固定装置，不是远程播放器。本机交互能力和消息复制仍然未经测试。记录了十一个阶段，但首次切图准备超时。服务器和客户端加载新地图并恢复原生健康状况。失败条件诊断需要更精细的准备证据，而不是更大的超时。所有拥有的进程都停止。 `AbilityProgressNetwork02` 添加了持久的每个客户端就绪状态 reason/actual-state 历史记录并重现了首次切图失败：本机 map/player/Health 恢复，但两个客户端都没有活动的生产进度范围。折叠的重复使用的小部件无法勾选重新装备。 OnInitialized 是一次性的，Destruct 已经取消了侦听器。 Python Construct 现在幂等地重新武装，而后备 Construct 显式恢复其取消的 BP 代理，而无需模型或生命周期重放。两次主机测试使套件达到196。 `ProgressReconstructRegression01` 通过了 12 个 BP/Python 案例，包括本机相同小部件重新安装到测试拥有的视口中。最终范围余额4/4，零active/errors，命令严格关闭日志和inspected/hashed屏幕截图。现在，相同的构造重新武装修复处于完整的十九阶段`AbilityProgressNetwork03`重试之下。超时时间不变。尚未做出完整的网络、本机交互制作者或包声明。

`AbilityProgressNetwork03` 然后与两个客户端一起通过未更改的十九相门，重新启动，两次切图并 B0 leave/B1 重新加入。 Server/A/B0/B1在288.844/266.404/155.281/71.214s退出0，命令严格关闭日志并冻结哈希。最终进度范围余额0/0、6/6、6/6、2/2与零active/errors。本地owner/foreign计数器为0/0、19/19、14/14、3/3.可见，BP/Python每个ACK都需要倒计时比较和本机完成。十二个 PNG 被散列。检查了A/B0加入和B1重新加入进度图像。已知的本机Editor/resource-preparation警告仍然存在。 Reticle/host/debug/weapon 通道还传递当前的十八节点适配器，最终订阅为零。不会发生 C++ 构建、烘焙、打包或源发布。完整的0.10，真实的交互能力，远程播放时长的制作者和打包的接受保持分离。这些消息是多个进程中的本地合成输入。

<a id="010-2h-failure-ui-prototype-startup-not-accepted-2026-10-14-local"></a>

### 0.10-2H 故障UI原型，启动不被接受（2026-10-14本地）

`ability_failure_mixin.py`，其生成器和十七个主机测试已存在。 `20261014-batch2h/host-tests01.json` 使用工作区拥有的临时根传递 213。初始 211 测试运行在受限制的默认临时目录中存在一个现有的原子重命名案例失败。这次失败的运行不会被重新标记为通过。策略测试不能证明本机FText本地化身份、实际动画回调、延迟帧计时或审核的延迟 BP 输出模型。

`Assets01` 在 5.976 秒内退出 0，stdout/stderr 为空且没有 Unreal log/fixture JSON。 `StartupDiagnostic01` 删除自定义 UserDir 标志，但也会在没有这些文件的情况下在 0.814 中退出 0。没有发生资产创作，也没有复制规范的failure/transport资产更新。未诊断原因：当前受限环境下无法读取事件日志和子模块Git元数据。不再尝试重复启动或权限更改。每个进程cache/temp路径保留在工作空间内。共享进程助手不记录环境值。本机source/BuildId检查通过，但不能替代初始化、编译或运行时验收。未发生 C++ build/cook/package、Engine/reference 编辑或源发布。

下一个有界步骤准备（不执行）十七个案例的实际生产UI/original-BP夹具和集中驱动程序。它涵盖了相同原因的无重新触发​​、pause/one-second本机Outro开始（两个观察到的游戏帧限制，最大0.15秒）、自然动画完成、隐藏的Profile恢复、销毁/重新安装、延迟最新的外部有效负载、持久回调可见结果以及工作挂起时的清理。原版OnInitialized不重播。测试拥有的基线仅恢复其侦听器。它的 FText 是合成显示文本，不是本机本地化标识或 GAS 生产者接受。死亡/无效的健康状况和multi-client/package车道仍需要额外的证据。

`20261014-batch2h/host-tests02.json`通过223，没有failures/errors/skips.十个新的gate/static检查拒绝incomplete/reordered或不匹配的报告，不受支持的声明，widened/NaN计时器界限和不平衡的最终生命周期。新的重点PowerShell驱动程序解析没有错误。 `fixture-preflight01.json` 针对 Assets01 传递实际的负面预检：在创建运行时输出目录之前拒绝失败的创作。没有启动任何UE进程，也没有留下任何进程。此检查不是运行时通过。 17 例固定装置、资产生成和网络接受仍然存在 unrun/unaccepted. Git 差异检查在此执行上下文 (`this operation must be run in a work tree`) 中不可用，因此没有声明 Git cleanliness/whitespace 门。混合变化保持不变。没有出版物或繁重的构建。

<a id="010-2h-accepted-bounded-runtime-and-native-text-checks-2026-10-14"></a>

### 0.10-2H 接受有界运行时和本机文本检查 (2026-10-14)

在这些运行之前取消了限制。之前的日志前启动结果仍然是历史故障，而不是当前的阻止者。 `Assets06` 是干净的创作门：十个传输函数/32 节点，旧的六个语义摘要不变，保留原始 script-Tick 标志和一个空的 int32 Linkage 本机延迟完成声明。没有Engine/C++构建或官方资产编辑。

`FailureDifferential01` 遇到冷隔离缓存启动超时。所有拥有的进程都被停止。运行世界时钟和手动 UI-delta 原型中的 02 和 03 公开的非等效暂停计时。两者都被删除，取而代之的是通过 RetriggerableDelay 实际的本机 UMG 潜在调度程序。运行 04 然后暴露命名输出形状 `(False,)` 被误认为是裸布尔。策略和主机现在都是假的extract/check确切的形状。这些运行都不是通过。运行05经过17比较（69.280s），第一个Outro位于两侧1.000s，观察帧0.016s/tolerance0.032s和范围4/4，零active/errors. 其早期截图不包含可见标签，无法视觉接受。运行06重复所有17，两侧可见`UEP resumed`，不透明度1.0。检查了实际的PNG。这些情况包括本机pause/animations、隐藏的Profile恢复、Destruct/remount、延迟的最新外部负载和持久的本机回调顺序。基线仅恢复其旧侦听器，从不重播原始OnInitialized。

`TextFixtureAssets01` 创建仅阶段的四节点本机实时表种子 (InputKeys/LeftMouseButton)。 `NativeCulture01` 通过了其数据门，但延迟的屏幕截图显示了交换的语言标签。 `NativeCulture02`增加分镜头等待，通过47.859s内的单播en/zh-Hans/en比较。检查了更正的 PNG（两个小部件上的鼠标左键/鼠标左键）。该测试显式取消计时器以保存接收到的文本。范围2/2，零active/errors.这证明了原生FText本地化身份，而不是原生GAS生产。已知的本机渲染线程和翻译警告仍然可见。

`host-tests08.json`通过了237，没有failures/errors/skips，包括六个新的合成网络合约负数。这些只是支持性检查。 `AbilityFailureNetwork01`没有完整的report/driver摘要，记录不完整。重试之前没有剩余任何拥有的进程。 Network02经过server/A19阶段，B014和B13，有两次切图、重新加入和四次正常退出。最终故障范围server/A/B0/B1:0/0、6/6、6/6、2/2。检查了零个active/errors.选定的A/B0/B1PNG。消息是本地合成的，外部情况使用空控制器，而不是远程玩家复制。本机weapons/GAS在现有网络通道中保持真实。当前十功能`TransportAdapterRegression01`通过原UI/Verbcopy/rejection/cancel检查（32.720s）。持续时间和失败由其他泳道执行。原生故障生产者、dead/invalid健康、打包和全版本验收保持开放。

活动的0.10-2I Dash 记录位于示例Migration/PROGRESS.md 和NEXT_DashCooldown.md 中。 Assets01通行证。 DashDifferential05通过50.422s、范围11/11、检查的PNG和0.00001材料公差中的11比较。早期的运行保留了真实的实时动画清理错误和固定装置故障。生产UI是本机UIExtension池条目。视口生命周期装置是明确分开的。 DashNetwork01 在有两个活动生产池条目的第二次切图中失败。只读共享本机成员资格清理修复程序具有支持主机检查的269，目前正在重新测试。该代码暗示没有网络通行证、本地生产者、死亡、打包或完整批次。

后来的`DashDifferential06`重复了成员修复上的所有十一个（50.297s，范围11/11，池监视2/2，零active/errors）。 DashNetwork02 达到两个 travels/B0 退出，但在 Windows 状态文件替换时在 B1 重新加入时失败。 Network03 在UE启动之前被主机预检停止。持有的读者测试表明os.replace在此文件系统上是不够的。删除共享readers/ReplaceFileW解决了该测试，将永久访问错误保留为失败。 Network04暴露了二次读取的TOCTOU。现在，每对等每帧一次快照可以避免这种情况，而无需使用前一帧数据。

`DashNetwork05` 通过所有十九个阶段，包括travels/rejoin 和四个正常出口。最终范围server/A/B0/B10/0、14/14、12/12、3/3。健康绑定0/0、7/7、5/5、1/1。池监视 0/0、4/4、4/4、1/1. A/B0 每个都显示一个本机池停用。没有检查最终的active/ticker/errors.选定的PNG。现有weapon/progress/failure/reticle/host车道并排通过。该网络通道中的持续时间是本地合成消息，而不是本地 Dash 或消息RPC。

`NativeDash01` 通过本机Dash/death 步骤，但未通过灯具的空所有者假设。 UserWidget 退回到零号玩家。 `NativeDash02`使用原生UnPossess并通过五个案例（45.141s），原始授权GA_Hero_Dash原生ASC -> 1.5s持续时间 -> 生产Python/original-BP UI，拒绝重复、完成、一次本地death/hidden包装器和缺席-Pawn失败拒绝。 Dash/failure范围4/4and4/4，池watches1/1，未检查residue/errors.PNG。无ability/Health/CDO/velocity写入、手动小部件事件、致命伤害或物理密钥索赔。本机重复发出零个面向用户的失败消息，以便生产者保持未经测试的状态。主机测试12通过282。

Respawn Assets01编译保留的class/CDO和五节点精确原始动画委托清理。无Engine/reference更改或build/package.主机测试通过290。 RespawnDifferential01 在比较之前失败，因为 TimeUntilRespawn 是 BP 局部函数，而不是 UObject 字段。策略现在使用Python本地。报告将剩余时间标记为派生的本机截止日期，而不是读取Blueprint堆栈存储。运行时重新测试正在进行中。并不意味着完全接受 2J 或版本。

<a id="2026-10-15-approved-ue-581-update-and-bounded-editor-acceptance"></a>

## 2026-10-15：批准UE5.8.1更新并有界编辑接受

证据根：`.build/LyraValidation/BlueprintPython/20261015-ue581-acceptance`。用户批准了官方 5.8.1 source/dependency 更新和匹配的编辑器构建，然后明确允许所有核心并请求进度更新。上游增量和独立备份先于EditorBuild01：4,610操作，结果在5,714.65秒、BuildId`2f7b5df8-1c9a-4414-a598-6d3b022aa38d`内成功。这不是对自定义引擎实现编辑或打包的授权。

两个完整构建弃用警告标识了UEP旧的不安全包回调。编辑器路径现在消耗已完成的OnEndLoadPackage批次。普通的非编辑器发现仍然需要安全替换和打包验收。 HostBuild02/03 和 UEPRefresh01/02 是受保护的增量 project/plugin 构建，而不是另一个引擎构建。最新的受保护引擎哈希值保持不变。

铭牌测试还暴露了一个旧的 UEP 多播错误：将 UObject 地址传递到 GetMulticastDelegate，它需要属性的值地址。 NameplateDifferential05 因虚假访问检测器状态而崩溃。保留失败证据。 UEP 现在解析值指针并处理空的稀疏委托指针（不声明稀疏运行时覆盖）。 HostBuild03/UEPRefresh02 传入 25.27/20.62s，编译器警告为零。最新的LyraUEPDLLSHA-256：`A37911F9105E33A130BE049C93F86911CAD5C2B305CEB04C702CCE8AF5B65555`。

Final-DLL 有界结果，全部带有 source/module/input 防护和关闭日志：

- CallMatrix02：11个通道，包括native/Python多播、坏参数recovery/unsubscribe、shared/standalone签名、调用者、命名输出、继承、构造转发、软路径和声明的异常。
- Lifecycle02：一个编辑器中的三个真实的PIE会话。 placed/spawned Actors，每个会话有两个 Begin/End 事件，封闭范围，本机 GC 和恢复的路由器。
- PackageLoad02：在新流程中保存Main/Companion BP包load/discover，无需注册调用。进口打包和fallback/restore证明。
- Transport02：编译后的 VM 嵌套 copy/owner 检查、错误读取器和外部传递拒绝、幂等关闭且无后续回调。
- QuickBarDifferential02：十二个production/original-BP案例，九个名为Python查询，范围12/12和经过检查的1280x720 PNG。
- NameplateDifferential06：十四个Widget/original-BP案例，范围23/23，团队代理13/13，初始化委托明确删除10/10，零残留/errors/ensures。检查了巴布亚新几内亚。早期的故障包括 CompareTeams 输出形状、已发布的夹具代码、缺少夹具 APIs、不匹配的恢复纪元、关闭管理器可用性和多播崩溃。没有一个被删除。
- Network03：十九个阶段，两个渲染客户端加上专用编辑器服务器，两次切图，B0leave/B1重新加入和四个正常退出。现有可选的HUD门通行证，以及最终的A/B0/B1快速栏范围12/12、12/12、6/6和查询15/8/2。进度范围6/6、6/6、2/2. 24 个 PNG 进行哈希处理。检查选定的交换-fire/rejoin-respawn帧。受控的陡峭瞄准架并不能证明free-camera/physical-input。本机编辑器警告横幅仍然存在。

在完成场景之前，Network01 在线束 ReplaceFileW WinError 1175 上失败。现在，有界重试包含该错误，而无需删除目标。 partial-replace/unrelated 错误仍然是致命的。 Network02然后传递前面的DLL。 Network03 是所需的最终 DLL 重复。最终的网络运行也通过了所有397主机检查。单独的主机检查并不能保证运行时。

版本保持0.10.0开发。铭牌Source/Manager组件创作、原生差异化和特定于铭牌的多人游戏保持开放。下一个计划是`Demos/UEPLyraIntegration/Migration/NEXT_NameplateComponents.md`。没有声明新的熟包、独立服务器目标、物理触摸、本机交互生成器、复制的持续时间消息或完整版本接受。不执行提交、推送、标记或发布。

<a id="2026-10-16-per-batch-local-commit-backfill"></a>

## 2026-10-16：每批次本地提交回填

用户请求一致的modify/verify/commit批次以及对早期完成的工作进行相同的回填。示例检查现在从新存档中的 Git 索引以及已提交的核心运行，因此混合工作树无法掩盖丢失的未暂存依赖项。紧凑的每批次分类账位于`Demos/UEPLyraIntegration/Migration/Acceptance/`。他们引用原始本地报告并保留本地DLL/report哈希值。模型、来源出处和原生游戏证据是分开的。不暗示任何推送、标签或发布。

核心`6fd3d79`记录了经过验证的运行时基础。后续示例提交单独的共享HUD/network基础设施、个人HUD业务、世界参与者、共享Widget/Jump/ADS/Emote家庭和其他hero/weapon能力。当前 DLL Emote/ADS/shared-Widget 报告门已通过，而旧的 Jump 和其他功能运行仍显式地保持历史记录。当前合并的原生HUD报告使用独立的分阶段模块重新检查了19个阶段、两个客户、两次切图以及十个HUD组中的leave/rejoin。四个旧的重载家庭网络门分别重新检查36权威行。这些检查不会启动新的客户端或成为当前 DLL 系列的重新运行。

旧的武器实例报告无法通过进化门，因为它缺少后来的`profile`字段。它的报告没有被修补，门也没有被削弱：而是使用了串行当前 DLL rifle/shotgun 二所有者网络重新运行，位于 `20261016-batch-backfill`。保持pending/failed收尾尝试和最终结果不同。查看 PROGRESS 以了解观察到的退出和接受情况。仅游戏标记并不能通过批次。此回填中没有新的 compile/cook/package 或官方 Lyra/Engine 实现编辑。

最终回填结果：32 有界示例分类帐和单独的本地提交。 893 隔离 438 Python 文件的示例检查和全索引闭包通过。当前-DLL步枪-Network01和霰弹枪-Network02均经过36权威试炼，二人装备观察，独立的report/log门和三个真正的零出口。 Shotgun-Network01 仍然是失败的 520 秒关闭超时运行。引擎源码明确支持NoDDCCleanup。仅添加该进程开关会产生一次新的重试，且 D3D12/cases/gates 保持不变。这并不能证明所有的关闭延迟都有这个原因。本机警告仍然有效。第三人称历史夹具哈希值和旧的正常出口重新检查，而不是新的5.8.1本机运行。不完整的持有小部件草稿仍未提交。完整的0.10/0.11/version/package-network大门仍然开放。不相关的存储库URL-所有者编辑保留在此任务的暂存提交之外。

<a id="candidate-record-template"></a>

## 候选项记录模板

这是未来所需的记录格式，而不是已实现的清单生成器或任何候选项已通过的声明。将其复制给每个候选项，并用经过衡量的证据替换每个占位符。

| 领域 | 所需记录 |
| --- | --- |
| 候选项 | Version/RC ID、UTC 测试时间和处置 |
| 核心源码 | 完整提交、branch/tag、干净树状态和任何记录的差异 |
| 示例来源 | 完全提交，branch/tag，干净树状态。核心 gitlink 必须匹配 |
| 发动机 | UE版本，源revision/BuildId和目标平台 |
| Python | 确切版本，shared/UEP-owned解释器模式 |
| 构建 | Editor/Game/server目标，Development/DebugGame/Shipping，工具链和二进制哈希 |
| 内容 | 暂存的 script/asset 哈希值和未触及的 Engine/reference 资产哈希值 |
| 支票 | 每个所需的suite/mode，运行ID，pass/fail/skipped结果和保留的日志位置 |
| 生命周期 | 活动实例计数和最终退出后callback/router/state证据 |
| 可见检查 | 场景、screenshot/video位置和input/visual验收结果 |
| 产物 | Package/source存档位置和SHA-256。与测试源的关系 |
| 局限性 | 不支持的路径、未经测试的配置和突出的阻止程序 |
| 评论 | 审查者、决定和任何所需的后续候选项 |

仅脚本重新测试必须记录实际的新脚本和兼容的本机二进制来源。候选项使受影响的结果无效后来源发生更改。不要用不相关的旧果岭跑道来填补缺失的字段。

<a id="original-calllifecycle-matrix-criterion-batch266-2026-10-27"></a>

## 原始call/lifecycle矩阵准则batch266 (2026-10-27)

签入的合约现在对 21 个调用和 12 个生命周期路径进行了分类，并具有命名的重现器：24 有界支持，六个故意拒绝，三个绕过或不支持。更正一揽子输出参数拒绝，以区分显式非引用命名输出选择加入，并包括已测试的创作的父构建虚拟帮助器路线。运行时行为没有变化。

MissingCalls01仅针对SDK236刷新九个通用案例。重用来自258的两个当前调用案例和来自257的本机拒绝。七个新的commandlet exit0。命名输出负PID39840和Mixin异常PID2440故意退出1，具有排他性预期错误，recovery/original恢复并正常关闭。 PIE01 PID39448 在三个实际的共享解释器会话之后退出0，并恢复本机 GC、封闭范围和原始路由器。十个新流程。零编译、链接、cook/package或完全回归。最终不可变选择checks22/22通过。

历史第三人称、Dash、打包重装、资源管理器和travel/rejoin参考保留自己的SDK/configuration范围。仅新接受确切的matrix/reproducer原始标准。 Overall16/22。其他原0.9条件和完整的migration/version/package/release验收保持开放。官方Lyra，保留了隔离初始化guard/binaries以及六个不相关的文件。

<a id="current-editor-candidate-components-batch267-2026-10-28"></a>

## 当前编辑候选组件batch267 (2026-10-28)

ThirdPerson01 根据 SDK236 刷新渲染的本机输入变体。 Mixin PID4068 和PythonFirst PID11468 exit0。直接检查六张1280x720图像，带有可见字符、地图和HUD。原生movement/look/jump和最终拆解通行证。PythonFirst也传输一次。无pixel/animation/hardware平价声明。现有的二进制文件和项目拥有的元数据被重用。

五个通用编辑器套件证明了 49 项检查：每个shared/standalone core21，两个独立的预期动态异常恢复检查，以及Editor/Slate5. 新的选择性驱动程序不执行构建。保留 Core01 的缺失结果独立故障和 Core02 的现有资产预检停止。仅继续进行独立复检的成功组件报告。 Core03 使用新的 UUID 后缀测试资源。原始两个文件保持字节相同。保留两个新的测试包及其副本。仍排除删除。

八个纯门检查、一个驱动程序解析和三个无效选择检查从不可变索引传递。七个原生组件经过八次尝试。两个失败的捕获摘要仍然失败。最初的通用六套件70契约仍然缺乏当前源打包21。完整候选回归，RC和完整迁移保持开放。overall16/22.无C++/productionpolicy/asset更改，compile/link、cook/package或完整回归。官方Lyra，隔离初始化guard/binaries和六个不相关的文件保留了指纹。

<a id="current-generic-package-and-clean-core70-batch268-2026-10-28"></a>

## 当前通用包和干净的 core70 batch268 (2026-10-28)

当前原始通用游戏目标需要第一个 UE5.8.1 构建：948 编译操作、一个链接、一个元数据操作、parallel2、3872.613 秒、零编译器诊断。所有生成的路径都在拥有的项目内。 NoEngineChanges 保护现有引擎输出。原生源保持不变。保留构建开始之前发生的可选库预检失败。

Package01 Cook/Pak/archive exits0，但其包装器在运行时之前失败，因为 Pak 属于 STAGE 而不是单独的完成标记。保留失败的capture/archive和确切的旧驱动程序。 Package02 更正了阶段验证，使用版本化增量入口Cook并跳过本机重建。 Real Game PID37948 exits0 并独立通过 packaged21，而没有早期的未版本化序列化警告。它的二进制文件与实际的游戏版本匹配。

CleanCandidate01 重用这些产物，并在一个无故障候选记录中运行所有六个原始套件：70/70. 仅其两个故意记录的恢复装置 exit1。所有普通进程 exit0 并正常关闭。六项新的门测试、一项驱动程序解析和三项飞行前拒绝检查均通过。全面回归仅限于GenericWin64Development核心。完整的多域候选和原始迁移条件保持开放，16/22.保留所有无关文件，官方Lyra以及已授权的隔离初始化守卫。

<a id="controlled-reloadpiegc-and-travel-cleanup-batch269-2026-10-28"></a>

## 受控重装，PIE，GC 和行程清理批次269 (2026-10-28)

仅接受原始0.9受控重装、PIE、GC和切图清理条件。 Weapon01 PID17880 在 42 个场景（38 BP/Python 状态比较）、四个实时 Profile 往返和三个 unregister/reload/re-register 周期后退出。每个周期构造一个NEW widget，收集旧的native对象并关闭所有subscriptions/scopes/tickers.恢复四个原始类路由器。本机消息callback/cancellation探测器也通过。

WeaponNetwork01的服务器38612、A22788、B037656和重新加入的B112304均退出0。十九个阶段涵盖本机fire/reload/exhaustion、插槽更改、Pawn更换、两个服务器切图、客户端exit/rejoin和持续火力。两个原始客户端都具有三个作用域生命周期。最终回调、HUD 绑定、小部件引用和武器采样器是平衡且为空的。在精确冻结source/binary检查后重用当前-SDK PIE01 PID39448：三个实际共享编辑器会话、本机GC、关闭范围和恢复的路由器。没有要求重新执行PIE。

22 个选定的不可变索引检查通过。网络驱动程序独立通过 91 个选定的主机检查及其PowerShell 合约。不会发生compile/link、cook/package 或完全回归。仅audit/index/tests 和记录发生更改。 Overall17/22。所有246个原始候选paths/order/versions和22个确切的清单文本保持不变。网络截图显示gameplay/ammo，但在NoSound夹具中保留TapIDs/invalid-tap警告。完成visual/audio并且打包标准保持开放状态。保留官方的Lyra、授权的隔离初始化guard/binaries以及六个不相关的修改文件。

<a id="visible-and-current-packaged-weapon-example-batch270-2026-10-28"></a>

## 可见且当前打包的武器示例batch270 (2026-10-28)

仅接受原始0.9可见且打包的weapon/ammo示例条件。可见01 PID17164和实际打包的LyraGame PID9996 exit0，每个经过42场景（38配对BP/Python状态），原生回调取消，四个实时Profile切换，三个新小部件reload/native-GC循环和退出前清理。直接图像审查确认了配对的弹药文本和所有三种计数器样式（1280x720 和 1440x900），无需早期的着色器准备覆盖。不要将这种初始演示者的比较推广到每个游戏的视觉过渡。

当前的原生游戏缺少已经授权的隔离英雄守卫和当前的SDK更改。 UBT 在构建前导出五个拥有的项目操作：三个编译、一个链接、一个元数据写入。首先保留旧的Game/receipt。 GameBuild01 PID39092 在 85.931 秒内退出，编译器诊断为零。 NoEngineChanges 处于活动状态，Engine/official Lyra 保持不变。没有进行新的 C++ 源代码更改。当前实际游戏SHA是BEA390FA7C42EC59349F24B14E678AE96CDED0F608DFB303479903D93BF2AEFE。

避免重新Cook未更改的数据：所有 246 个原始候选者、460 原始 Overlay 资产和 12 个运行时地图与成功的先前Cook计划完全匹配。将其不可变存档克隆到新的Packaged01/Payload，保留旧复制的游戏和Python目录，并将当前游戏plus862project/two核心Python文件放入该副本中。所有原始熟制品和源字节均受到保护。真正的内部可执行文件正在运行，而不是引导程序或编辑器。没有发生Cook或完全回归。包准备工具在复制之前拒绝更改的数据、过时的本机输入、转义路径和现有输出。

重用并重新检查batch269的当前SDK十九相本机owner/replication和slot/possession-signal协议。生产采样器原生调用被读取。演示者仅发送本地重新加载输入意图和UI更新。二十四个选定的不可变索引测试、一个驱动程序解析和两个预检拒绝通过。 Overall18/22。Batch1A游戏视觉、候选、RC和完整的两项经验标准保持开放。 Original246/22范围、现有资产和生产政策、授权的隔离初始化守卫和六个不相关的文件仍然存在。

<a id="batch1a-visual-pairs-and-native-owner-comparison-batch271-2026-10-28"></a>

## Batch1A视觉对和原生所有者比较batch271 (2026-10-28)

五个实际的本机操作检查点现在可以直接审查配对的演示者视图：开火、重装、武器切换、空弹药和Pawn更换。显式的仅测试适配器创建原始的BlueprintFallbackleft/Python右面板和活动式计数器，读取每个本地玩家的真实本机项目。它保留了实际生产HUD和未更改的十九阶段原生input/authority/replication生产者。不会发生生命周期重放、ammo/inventory写入、资产创作或正常启动更改。

Native01的四个对等点通过了功能协议，但其交换机截图中原始面板被遮挡。保留五张原始图像、所有报告和确切退役的root/stage源副本。不接受部分视觉结果。仅更改三个测试UI坐标。 Native02服务器36384，A12188，B014308和重新加入B137984都通过19个阶段退出0，两次切图和客户端exit/rejoin.小部件根close0/0，16/16，12/12and4/4.最终原始的HUD/weapon回调、范围和采样器正常关闭。直接检查所有五个 1280x720 重新捕获。配对的弹药和计数器values/styles一致。在日志中保留NoSoundTapIDs警告。无抑制、全帧像素奇偶校验、硬件输入或音频声明。

二十一项选定的不可变索引检查、一项驱动程序解析和两项预检拒绝均通过。总共八个新的网络进程：四个在保留的部分视觉运行中，四个在接受的重新捕获中。辅助资产审计是分开的。零compile/link、cook/package或完全回归。 Overall19/22。候选矩阵，RC和完整的Explorer/TopDownArena接受仍然开放。所有246个原始paths/order/versions和22个清单文本，现有生产policies/assets，官方Lyra，授权隔离guard/binaries和六个不相关的修改文件保持完整。

<a id="current-third-person-game-packages-batch272-2026-10-28"></a>

## 当前第三人称游戏包batch272 (2026-10-28)

两个实际打包的游戏变体都通过原始的behavior/lifetime合约：MixinPID432和PythonFirstPID34344 exit0，共享可执行文件SHA4559C8EDC048B6F70EFCC3F52248247417637D40E355E6978E16C9B105E99E2D。当前渲染的编辑器证据保持独立。原始迁移仍然是19/22。候选聚合、RC 和完整的Explorer/TopDownArena 标准保持开放。

旧游戏收据是5.8.0。 UBT 使其缓存无效，因为 Build.version 和 UBT 较新。保留旧的Game/receipt，使用拥有的项目内所有生成的路径检查934个操作，然后在parallel2/NoUBA/NoEngineChanges.Build01 PID4880在3616中退出0进行一次构建。429秒：932编译，一个链接，一个元数据写入，零诊断。没有 C++ 源代码更改。两个包都重用此目标。

MixinPackage01 在运行前失败 Cook，因为编辑器缺少 ResonanceAudio。保留失败的输出和完全相同的旧控件。应用重点第三人称编辑器验证已使用的相同作用域插件禁用。 MixinPackage02 完成了Cook/Stage/Archive 和实际的runtime432，但其包装器保留了失败状态，因为原始断言引脚UEP0.7.0。未更改的编译描述符是0.8.0。 MixinReview01 仅将版本谓词绑定到该确切的描述符。所有原始的behavior/lifetime断言都可以通过，无需其他本机进程或厨师。 PythonFirstPackage01则直接通过。包不编译本机代码。

修复规范演示控件以在所有四个 smoke/package 调用站点传递暂存描述符版本。retain0.7.0 仅作为直接传统调用默认值。保留所有其他断言。六次不可变索引检查使用实际报告并证明错误版本和清理失败仍然拒绝。存档原始运行程序、26原始构建负载输入和每个变体的可变阶段文件。保留所有先前失败的捕获和先前的候选矩阵。保留游戏代码、资产、官方Lyra、已批准的guard/binaries以及六个不相关的修改文件。

<a id="original-candidate-matrix-aggregate-batch273-2026-10-28"></a>

## 原始候选矩阵聚合batch273 (2026-10-28)

**原始候选矩阵接受batch273 (2026-10-28):**原始0.9Generic/both接受第三个Person/Lyra候选标准。 overall20/22. 聚合现有的干净通用six-suite70/current11call/ 三个-PIE 证明，均呈现当前-SDK 第三人称编辑器捕获以及实际的当前游戏包。 Lyra保留了正常的无探针启动、当前十九阶段二客户端owner/travel/rejoin协议、五个直审Batch1A配对视图以及visible/actual打包的42场景武器示例。

重新检查实际源、二进制、报告、日志和图像指纹。从记录的示例 Git 父级中恢复三个未选择的 ability/weapon 测试模块的确切旧字节。将此识别为执行后重建。根和阶段输入引用都保持明确。只有这些指定的测试探针可以使用确切的存档。 Normal/focused 武器生产投入仍必须匹配。通过了 32 项不可变索引检查，包括缺失系列、陈旧SDK、缺失游戏、ownership/visual/package 单元和生产存档拒绝。没有新的本机流程、构建、Cook或广泛的回归。完整的Explorer/TopDownArena和RCAPI审查仍然是单独的原始要求。保留所有246条路径，22原始文本，先前的19个接受标准，官方Lyra和不相关的污垢。

<a id="supported-api-freeze-review-batch274-2026-10-28"></a>

## 支持API冻结审核批次274（2026-10-28）

**原始支持API冻结接受的batch274（2026-10-28）：**原始0.9APIinventory/migration/deprecation标准被接受。 overall21/22. 所有七个原始0.9 标准现在都有范围证据。检查 12 个清单表面，保留实验排除并将当前注册表与继续检查点 e1199d2 进行比较：213 模块 plus462 UObject 方法名称、函数表达式和标志未更改。这并不验证每个遗留包装器、参数行为、ABI、平台或配置。

保持兼容性形式，显式的fallback/exception行为，受控的重新加载，游戏线程所有权，本机GC帧边界和签名重新启动规则。弃用使用兼容性路径命名旧的 API、替换、示例和删除版本。 SDK236修复了引导转换生命周期缺陷。 Lyra候选者需要经过批准的隔离八线英雄守卫246。官方Lyra仍未修补，其原始发现仍处于开放状态。保留原始0.11NetShooter原生组件discrepancy97及其边界。在这些处置之后，已审核的受支持API中不存在当前已识别的发布阻塞缺陷。未知缺陷不会被证明不存在。二十个不可变索引检查通过。没有新的本机进程、构建、Cook、标记或发布。完整原件0.14Explorer/TopDownArena接受仍然开放。保留原始246paths/22文本，prior20接受的标准，官方来源和不相关的污垢。

<a id="final-original-migration-acceptance-batch275-2026-10-28"></a>

## 最终原始迁移验收批次275 (2026-10-28)

**原始迁移范围接受batch275（2026-10-28）：22/22，246候选版。**所有原始0。9-0.14标准在UE5.8/CPython3.11内接受Win64Development。保留491个原始审计资产，246候选paths/order/versions，182配置shell，63保留资产和11项范围审查不变。这接受商定的Python替换范围。其他platforms/configurations，更广泛的原生游戏-C++迁移，RC标签和发布保持分开。

最终的0.14标准涵盖了所有四十个Explorer/TopDownArena候选者。 Recheck49 原始组件捕获以及针对当前生产代码和原始语义报告的共享GetReady Cue 父级。当前的六种original/Python积分对通过：库存菜单、放置交互、follow/navigation/cancel/travel、两客户端预测collect/sit、两本地玩家可变帧自然bombs/death/refund/HUD、对手death/kill/team归因。 All16 接受本机进程 exit0。六个实际的竞技场图像显示owner0 炸弹1->0->1，而owner1 保持1。保留原生debug/warning文本和死亡过渡模糊。

保留5个较早的网络组：1个较早的阳性组和4个失败组，总共15进程。31新的UE进程，包括final16。第一个 Python 故障是过度指定的服务器本地剪辑结束计数器。共享读取器更正保留了Windows共享违规中断。确切的 callback/native-end-observer 等待在未更改的 70 秒阶段界限内失败并保持保留。最终证据表明，相同的原生能力在进入时处于活动状态，然后在规范count0/no任务中处于非活动状态。仍需要客户端蒙太奇完成。 Original/Python 权威拾取，车主复制，进度与清理结果一致。没有声明通用的本机 C++ 事件拦截。

保留初始的 SDK-status 和引用的 helper-root 预启动失败。控件使用SDK236，通过显式变量绑定辅助路径，并使用现有的共享 JSON 读取器进行网络监视器。存档确切的退役测试/控制输入。只有两个指定的测试模块和包装器可以使用它们。不会发生生产策略、资产、正常引导、C++ 源、构建或烘焙更改。三十三次不可变索引Python检查和十六次精确索引PS控制检查通过。仅在输入、Git 生产增量、原始库存和仅元数据清单更改经过验证后，才能重用之前的 21 个标准。一起提升所有 22 条标准和 246 条候选倾向。历史上的每次捕获范围限制保持不变。官方Lyra保持不变。仍需要经过批准的隔离英雄guard246。所有六个不相关的修改文件均被保留。
