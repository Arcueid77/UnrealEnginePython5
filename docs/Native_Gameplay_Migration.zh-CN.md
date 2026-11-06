[English](Native_Gameplay_Migration.md) | [简体中文](Native_Gameplay_Migration.zh-CN.md)

<a id="lyra-native-gameplay-migration"></a>

# Lyra 原生游戏迁移

用户在2026-11-01通过CPP-015批准了CPP-001。进度和每批次验收情况位于[示例分类账](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/cpp_batches.json)中。这扩展了之前接受的Blueprint范围。它不会重新打开或替换它。

[综合完成指数](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/completion_status.json)涵盖了所有三个随后批准的C++阶段和H01-H05。所有 30 个 C++ 候选项均在已确认的范围内实施和接受：29 个生产替换项和 1 个功能案例。 CPP09 通过了 14 次实际的 Escape 按键、本机菜单输入转换以及用户解锁桌面后 2026-11-05 上可见的原始 UI/restoration。完成索引验证源绑定报告和捕获。两个早期的实时编译器中间体保留单独的historical/current指纹。下面的批次注释保留了其原始捕获边界。

CPP01将连胜、快速淘汰链、辅助规则移至Python。四个本机回调接缝是 `BlueprintNativeEvent` 函数。原始 C++ 主体仍然可以通过 `NativeFallback` 选择。原生 Gameplay Message注册、权威角色和侦听器关闭保留其现有所有权。 UEP 绑定源和引擎二进制文件未更改。

[源补丁和实施说明](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/README.zh-CN.md) 和 [CPP01 接受](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP01-acceptance.json) 确定了精确的范围。验证通过了native/Python有效负载和广播排序比较、精确的4.5秒时钟边界、嵌套辅助广播以及本机EndPlay/listener清理。每个Profile中的一台专用服务器和两个实际客户端随后通过了六个本地GAS伤害申请、五个本地健康死亡、一个协助、本地分数复制和所有者通知检查。客户端使用NullRHI：该批次未建立可见渲染或新包。批准的阶段目标仍然是UE5.8.1/CPython3.11/Win64Development。

验证针对从现有已接受、已编译的Lyra 阶段复制的独立一次性项目运行。官方`F:/LyraStarterGame`参考保持不变。这些本地验证入口点重用该阶段的编译器响应文件和本机依赖项。它们需要公认的基线，并且不是通用的清洁机器SDK安装程序。

```powershell
$root = 'F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/20261101-CPP01'
# Initial stage preparation, before applying the native patch:
& 'F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe' -B -X utf8 `
  Demos/UEPLyraIntegration/Tools/prepare_native_gameplay_stage.py `
  --source .build/LyraValidation/Full/Stage/Lyra `
  --stage .build/LyraValidation/CppGameplay/Stage/Lyra --result "$root/stage-copy.json"

# Use a new output directory for every attempt; never overwrite earlier evidence.
& Validation/Run-UEP58NativeMessageBuild.ps1 -OutputDirectory "$root/Build02"
& Validation/Run-UEP58NativeMessageAuthoring.ps1 `
  -BuildEvidenceDirectory "$root/Build02" -OutputDirectory "$root/Assets03"
& Validation/Run-UEP58NativeMessageValidation.ps1 `
  -BuildEvidenceDirectory "$root/Build02" -AssetEvidenceDirectory "$root/Assets03" `
  -OutputDirectory "$root/Runtime01"
& Validation/Run-UEP58NativeMessageNetworkValidation.ps1 `
  -BuildEvidenceDirectory "$root/Build02" -AssetEvidenceDirectory "$root/Assets03" `
  -OutputDirectory "$root/Network03"
```

仅需要ShooterCoreRuntime标头生成、一个模块编译和链接。没有完整的引擎编译或Cook运行。未来批次将按照批准的顺序和受影响的回归范围进行。在每个接受的批次之后，首先推送示例，然后推送主存储库的验证入口点和 gitlink。

CPP02也通过并记录在[其团队验收账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP02-acceptance.json)中。它将玩家团队选择和人口最少团队计算移动到Python，使用原始的two/four-team配置类。精简的反射设置器可以保持本机团队通知的完整性。每个配置通过了六个分支比较，临时夹具状态完全恢复。四队案例使用三名临时本土PlayerState演员和一名自然所有者。它没有声称有四个实际的网络所有者。

专用服务器和两个实际客户端在两个Profile中都通过了：十一个自然player/bot分配产生了群体6/5，并且CPP01本机伤害、评分和所有者通知检查仍然通过。本机编译仅限于两个受影响的 LyraGame 统一单元。此批次不需要引擎编译或Cook。

CPP03 通过了机器人计数、名称和删除选择。请参阅[机器人接受账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP03-acceptance.json)。两种生产生成器配置都通过了native/Python创建、计数优先级、命名、九个本机self-destruct/removal操作和清理。原生spawn/initialization/destruction和原生RNG仍在使用中。性能测试Blueprint保留其自定义创建图。这并不要求精确的 RNG 序列或单独的 PIE 编辑器覆盖接受。

专用服务器和两个实际客户端自然通过了creating/naming九个机器人，启用了CPP01damage/score/notification和CPP02团队门。仅重新编译了LyraGame单元1/2。已接受的团队对象被重用。

CPP05通过快捷栏cycling/free-slot选择并领取授权订购。见【存货验收台账】(../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP05-acceptance.json)。十四个native/Python边界案例和具有两个实际所有者的专用服务器通过了本机event/RPC/equipment、库存堆栈复制、OnRep通知、所有者隔离和恢复。仅重建共享标头中包含的三个LyraGame统一单元。原始的原生现有实例清单AddEntry仍未实现。此迁移保留了该限制，并且不声明对其的运行时支持。

CPP06通过原生spawnerpickup/reset/completion编排。参见[其承兑账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP06-acceptance.json)。原始的 C++ 参考和 Python 实现保持了之前接受的 Blueprint Python 层的固定。五个守卫、实时计时器完成、固定重叠重试和挂起计时器销毁已通过。然后，原始关卡参与者通过两个实际客户端的36场景，包括不变的十秒冷却时间、inventory/equipment/health复制和所有者隔离。保留原生timer/replication所有权。仅重建了LyraGame 单位1/3。

CPP04通过了TDM和通用玩家启动策略迁移。参见[生成接受账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP04-acceptance.json)。十一个native/Python案例使用真实的碰撞几何体进行空拟合、部分拟合和完全拟合，检查距离和声明首选项，保留观众行为，并输入实际的原生RestartPlayer。启动发现、弱缓存、PIE启动偏好、物理，并声明计时器保留本机所有权。对等运行每个Profile输入选择 22 次，并启用 CPP01–CPP03 回归门。受影响的base/derived模块编译重用未更改的LyraGame单元。

CPP07通过了荣誉通知、注册顺序、取消、计时器和清理策略迁移。参见[其承兑账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP07-acceptance.json)。十一个配对的 native/Python 案例包括跨 destruction/rebuild. 待处理的本机资产和注册表回调，两个所有者的本机伤害通道通过了两个Profile，具有相同的四奖 queue/presentation 结果，并且没有为其他所有者提供任何奖励。 NullRHI 客户各自搭建一套原创的业主绑定主机灯具。自然的HUD创造和可见渲染不属于这个证据范围。仅重建ShooterCore。官方Lyra参考和SDK保持不变。

CPP08通过原生交互indicator/option/first-choice编排。参见[其承兑账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP08-acceptance.json)。类型化本机适配器保留接口调用、软类路径、负载定制、ActorInfo汇编和GAS执行。 Native/Python 边界矩阵和现有的 Explorer 回归通道。在这两个Profile中，两个实际所有者各自发出三个本地输入，并产生两个匹配的本地预测和权威交互。空投入和外国目标仍然不活跃。本地见证人使用 UE5.8.1 实际适用的 ASC owner/avatar。引擎忽略的 ActorInfo 参数被保留为现有行为。仅编译受影响的LyraGame单位。 SDK、桥、ShooterCore和引擎二进制文件被重用。没有物理键盘或可见渲染声明。

CPP09 实现了 Escape 菜单请求接缝及其 Python 策略，保留本机 CommonUI 操作绑定、流式加载和 input/lifetime 所有权。其四个原始HUD shell 和共享 Set 通过了资产检查。编译了LyraGame单位1/3。单元2和其他module/engine二进制文件被重用。审查补丁会重现那些已编译的源代码，而无需再次构建。

`Run-UEP58NativeEscapeValidation.ps1` 添加的 `-Headless` 模式直接在隔离的 CommonUI 世界中比较策略和小部件停用。它使用临时零持续时间运行时堆栈转换并检查恢复。该通道与实际键盘和可见窗口接受是分开的。后来的[CPP09实际窗口账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP09-acceptance.json)关闭了十四个真实的Escape输入，七个周期和两个本机HUD切图。现已接受所有九批和十五名第一阶段候选项。

[CPP09进度账本](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP09-progress.json)记录了七个经过的native/Pythonopen/close循环和两次本机行程，包括菜单class/layer/owner、所需菜单配置、输入状态equivalence/restoration、本机HUD destruction/rebuild，以及夹具清理。屏外输入路由器停留在`All`。其实际的`Menu`接管仍然是待定窗口接受的一部分。无头报告会被那扇门拒绝。

原始的未煮熟的射手关卡在未更改的步枪资产中存在单独的尼亚加拉图故障。孤立的UI世界不要求完全接受射击渲染或修复该资源。可选的CPP-019到CPP-030组仍然在批准的实施范围之外。

CPP-016到CPP-018的只读预检现已在[下一批审核](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/CPP16_18_PREFLIGHT_REVIEW.md)中提供。本机commandlet检查了44原始Lyraitem/ability定义和两个现有的舞台固定装置，发现五个初始统计片段，五个项目成本，并且在该普查中没有玩家成本消费者。当前Python字典转换无法读取GameplayTag结构体键。该提案使用类型化统计快照和现有的 Blueprint 所有者，同时保留本机实例对象、权威、预测和原始调用者的仅命中过滤。预检本身并不建立运行时验收。球员成本赛程验证必须与生产迁移区分开来。现有的 CPP09 源代码、资产和二进制文件仍然可供其等待实际窗口接受。

然后用户通过CPP-018选择了CPP-016。他们的独立进度存在于[扩展跟踪器](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/cpp_extended_batches.json)中。 CPP10/CPP-016通过了[本机初始统计验收](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP10-acceptance.json)。两个 Const 所有者事件和类型化统计快照保留本机实例化片段和映射迭代顺序。 Definition/boundary 创建、丢失所有者回退、无本机重播以及实际的两个所有者标记堆栈复制已通过。之前的 inventory/quickbar Python 行为在 native/Python 比较中保持固定。仅编译受影响的LyraGame单位。 SDK、桥、ShooterCore、引擎被复用。 unused/prototype 定义和异常注入限制在账本中仍然明确。

CPP11/CPP-017 通过三种类型的能力所有者事件来路由项目成本决策。原始实例成本、本机curve/level评估和截断、故障标签写回、AdditionalCosts排序、仅命中过滤、权威和复制堆栈写入仍然是本机的。三个 mixin 集保留了早期的 weapon/heal/net Python 方法，并为新规则添加了 `NativeCostFallback`。保留原始`BlueprintFallback`Profile和能力Blueprint字节。

CPP12/CPP-018 使用相同的二进制文件并保持仅功能：预检发现没有原始配置的玩家成本消费者。一次性的纯成本能力和真实拥有武器的临时额外玩家成本行使了这种能力。生命周期通道应用实际致命的GAS伤害和原生Avatar破坏，观察用相同的PlayerState/stacks和原生ASC绑定替换Pawns，然后从新的Avatar发射。强制阿凡达破坏保留了之前记录的原生快捷栏恢复。这并不要求修复原始库存。恢复会比较原生生命周期后库存基线及其副本。

重点通道涵盖两个Profile中每种成本类型的18边界场景、所有五种配置的物品成本、具有两个实际客户端的三种武器类型以及附加的respawn/Avatar通道。之前的武器Python政策保持不变，但成本概况发生变化。诊断历史记录仅限于128条目。 320 本机回调执行该绑定。仅在验证了准确的单行诊断更改后，才会重复使用早期的矩阵。不添加SDK/bridge重建、完整引擎构建、cook/package、新平台或物理输入接受。

[CPP11生产验收](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP11-acceptance.json)和[CPP12能力验收](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP12-acceptance.json)关闭选定的扩展范围：两个生产组和一个仅能力组。第一阶段CPP09实际窗口大门仍悬而未决。

用户现在已经选择了所有剩余的CPP-019到CPP-030并请求继续执行。 [剩余进度](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/cpp_remaining_batches.json) 跟踪该范围。 [CPP13 input/physics进展](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP13-progress.json)通过了28真正的本机网络跳转试验和12准入边界调用。 Death/respawn CPP14 的交叉检查仍然明确。用户推迟了桌面操作，因此 CPP09 实际窗口输入在其他工作继续进行时仍处于待处理状态。

[CPP13](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP13-acceptance.json)、[CPP14](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP14-acceptance.json) 和 [CPP15](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP15-acceptance.json) 现在关闭原生跳转、死亡和重置替换。增量证据包括四个death/new-Avatar跳转检查、24原生lethal/self-destruct网络案例、两个原始竞技场死亡任务和12原始原生重置请求。当新的本机策略发生变化时，现有的 Blueprint Python 规则保持不变。 Reset 使用世界拥有的 Blueprint 运营商，因为 SDK 拒绝原生 UClass mixin。本机GAS处理、等待、取消、类型化有效负载和传输保持。载体构建编译LyraGame单元1/2加上UHT并重用单元3、SDK、桥和引擎。初创公司选择通过46重点测试。 CPP16-24继续。 CPP09 实际桌面输入仍然是用户延迟的。

[CPP16](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP16-acceptance.json)、[CPP17](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP17-acceptance.json) 和 [CPP18](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP18-acceptance.json) 接受前端、控制器外观选择和相机优先级。证据包含 106 类型化边界、native/Python 实际运行时路径、默认启动烟雾和带有八个独立装饰actor/mesh 视图的四次网络重置试验。原生GAS相机ownership/end清理、装饰快速数组、流句柄和异步小部件生命周期仍然存在。前端在线提供商的成果不被声明。提供的回调结果和键入的取消选择保持明确。仅编译了LyraGame单元1/3加上UHT。单元2、SDK、桥梁和发动机被重复使用。初创公司选择通过48测试。 CPP19-24继续。 CPP09 物理桌面输入仍然是用户延迟的。

[CPP19](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP19-acceptance.json) 到 [CPP24](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP24-acceptance.json) 关闭剩余的设备通知、重放保留、音频选择、团队伤害、竞技场属性和GameMode选择策略。他们的默认Profile保留所有早期的 Python 替代品。证据包括600类型边界，实际native/Python回调和效果，具有八个权威试验和十六个独立客户端视图的两个网络通道，两个本地玩家本机GAS夹子和原始炸弹input/refund.最终组合前端，Pawn和Arena烟雾通过。四个原始手枪射击证明了原生prediction-key/target-data 一致性和八个复制的伤害观察结果。初创公司选择通过51重点测试。

设备回调输入由固定装置提供。物理断开未经测试。重放使用临时内存流，在类型化上下文中检查keep/live标志，并由Python拒绝无效的负保留。现有的录音和游戏回放保持不变。音频验证本机resource/state参数，而不是声音输出。属性写入属于显式恢复固定阶段。后续输入仍保留原来的增强输入路径，不受操作系统桌面控制。

增量编译涵盖LyraGame单元1/2/3、1个TopDownArena单元和LyraGameUHT。车身修复重用UHT和成功单元1/2.引擎的陈旧未注册5.8.0内存流DLL不被使用：仅在前进阶段构建和注册一个当前源测试模块。发动机manifest/binaries、SDK、桥和保留的CPP09阶段保持不变。 972 受保护的哈希值匹配。未添加完整引擎构建、cook/package、新平台或hardware/audio 验收。所有30选定的候选者均已实施，29在其规定的范围内被接受（CPP-018仅限能力）。 CPP09 实际桌面输入仍然是用户延迟的。

用户在【加固追踪器】（../Demos/UEPLyraIntegration/Migration/hardening_batches.json）中选择了异常恢复、timing/long-run稳定性、新鲜阶段复现以及实际打包交付。 [H01](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H01-acceptance.json)通过了13个实际的原生failure/recovery案例，包括原始装备的物品成本、真实原生广播后的1个奖励回调和3个GAS重置aborts/recoveries.不完整的世界策略在没有引擎保证的情况下拒绝其输出。不完整的重置计划仅采取最终的EndAbility操作。正常的默认前端和52启动选择测试通过。仅以LyraGame单位3更改主体，然后1编译。 UHT，其他units/modules，SDK和Engine被复用。 H02-H04验收如下。 CPP09 桌面输入仍然是用户延迟的。

在最初的 12 分钟比赛结束后，H02 的第一次长跑暴露了过期的Mixin 选择器目标，无缝切图摧毁了缓存的世界。 [增量选择器修复](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H02-selector-guard-acceptance.json) 在使用该指针之前检查跟踪的弱所有者。一个SDK源文件和两个链接重建。引擎、game/bridge DLL 和 CPP09 检查点保持不变。九十秒的活跃游戏时间、实际的早期切图、三个被拒绝的过期选择器、三个本地重生和4,250查询通过。现在，安全带重新绑定到就绪世界，切图等待时间不包括在活动持续时间中。

[H02](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H02-acceptance.json) 然后传递1,200活动秒数、58本机重生、57,250本机查询和自然无缝切图。预热后私有字节中位数增长207.16MiB，并在预先声明的256MiB/32预算内增长四。本地参与者数量范围为 1，路由器数量保持不变，静态本地上下文峰值为 2。这种有限的观察包括内存增长，并且不会建立无限的稳定性或泄漏自由度。当前SDK时序涵盖14,400交错调用：伤害中位数6.18/17.22微秒native/Python和Pawn4.70/15.43.范围与桥接准入的反映入口点相同，而不是帧速率。 [H03](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H03-acceptance.json) 在独立阶段再现十五个版本配方的所有63当前生产输出。所有11,341最终暂存文件均与其original/versioned组成相匹配。 23 项目模块使用该阶段范围内的 289 操作进行构建，并且 13 个实际的 exception/recovery 案例传递新的 DLL。不导入旧项目编译器输出。生产描述符现在始终禁用RuntimeTests/ShooterTests，并且项目本地清单使用未更改的引擎BuildId。请参阅[复制入口点](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/REPRODUCE_NATIVE.zh-CN.md)。 [H04](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H04-acceptance.json) 关闭当前游戏构建、cook 和实际打包执行。其冷游戏配置编译1,190动作，包括所属项目内的引擎运行时依赖项。 4,105 编译器生成的路径停留在该阶段。安装的引擎发行版和原始项目保持不变。 Cook 处理 4,707 包，其中包含存档中存在的所有 246 原始候选、493 覆盖资产、十二个地图和三个类型验证观察者。

打包的可执行文件通过了 13 个本机 exception/recovery 案例、正常前端启动和 Damage/Pawn listen-authority/two-remote-client 通道：8 个权威试验和 16 个独立客户端视图。所有八个进程均正常退出，加载打包的CPython DLL、home 和4,578 收据文件。恰好一个测试INI仅允许UAT的BOM/newline转换。所有其他哈希仍然严格。单独的纯审查保留了原始依赖关系和dedicated/listen门故障，而无需重复成功的本机运行。监听检查器保留所有原始游戏断言并显式检查稳定的UI/local装饰消息。

所有四个选定的后续小组均在此 Win64 Development 范围内接受。实际桌面Escape/Menu随后传递给2026-11-05。 H04 未添加打包专用服务器、Shipping、其他平台、渲染图形或hardware/audio 声明。

稍后的[H05 frame/CPU后续](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/RENDERED_PERFORMANCE.zh-CN.md)确实在当前包上启用了实际的D3D12离屏渲染，具有1080p中等设置和16个平衡的20秒块。改变的只是共同的本土世界政策载体。其他迁移的层保持不变。正常固定场景Native/Python结果为120.56/120.39FPS和36.92%/36.72%整机CPU，无明显配对局部效果。在每帧200额外反射Damage/Pawn查询时，GameThread从4.54增长到8.25毫秒，CPU从37.28％增长到39.85%，FPS从120.23下降到118.26。完整的分类账保留了探查器捕获、CPU交叉检查、低帧结果和范围限制。这不会增加桌面、战斗、hardware/audio或其他目标的接受度，并且不会改变地重用游戏构建和烘焙包。
