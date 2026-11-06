[English](ROADMAP.md) | [简体中文](ROADMAP.zh-CN.md)

<a id="roadmap"></a>

# 路线图

能力里程碑，而不是交付日期。审查基线：2026-10-16。实施、保留的测试证据和发布的版本是不同的状态。插件描述符中的版本号不是发布批准。

目标是Unreal Engine5.8（当前验证：上游5.8.1），带有引擎捆绑的CPython3.11，无需修改引擎源代码或官方第三个Person/Lyra参考项目。引擎和通用插件 C++ 保持原生。 Python 调用这些功能。游戏项目运行时Blueprint业务，包括ShooterCore、ShooterExplorer和TopDownArena游戏插件，小批量转移到Python。 ABPs，动画系统，editor/test工具，接口声明，component/default-data外壳和UMG布局仍然存在。游戏项目C++业务迁移是单独的后期范围。

<a id="current-status"></a>

## 目前状态

确认的迁移范围通过所有原始Blueprint标准、三十个游戏C++候选者和H01-H05被接受。稳定版1.0.0在`dev/release-1.0.0`上推广已接受的1.0.0-rc.1，目标为UE5.8.1 / CPython3.11 / Win64。其发布记录区分了Development和Shipping证据、source/archive安装和确切的源对。请参阅[发行说明](docs/Release_1.0.0.zh-CN.md) 和[迁移完成](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/completion_status.json)。下面的里程碑描述保留了其捕获时间范围。

实施节奏：修改一个一致的批次，验证该批次，然后进行本地提交。以同样的方式回填先前接受的工作。每个示例批次都有一个独立的 Git-index 测试记录和`Migration/Acceptance/`下的紧凑证据快照。在其依赖项存在后，将其核心子模块指针和验证入口点配对。共享 BP assets/Profile 集与其所有相关实现保持一致。失败或未完成的批次保持未提交状态。保留旧的binary/report出处并记录跳过的检查。不要将历史传递或后来的源冻结提升为新的当前 DLL 接受。 Publishing/pushing/tagging 需要单独的权威。

| 版本 | 交付范围 | 地位和保留资格 |
| --- | --- | --- |
| 0.1.0 | UE5.8绑定基础与兼容性演示 | 已标记。确切来源包确认被推迟 |
| 0.2.0 | Python-第一个第三人称模板奇偶校验 | 已标记。保留46-检查核心、演示和可见证据 |
| 0.3.0 | API/lifecycle硬化 | 已标记。保留67-检查Win64证据，Linux未经验证 |
| 0.4.0 | Lyra积分和authority/replication观察 | 已标记。保留通用70/70和Lyra打包证据 |
| 0.5.0 | 有界 Python 驱动 Lyra GAS 游戏切片 | 已标记。最终的选择器强化进行了运行时测试，但没有新的确切源包 |
| 0.6.0 | 可玩的Python-第一个第三人称和示例分开 | 已标记。保留无头、包裹和可见证据 |
| 0.7.0 | 保留级Mixin第三人称 | 已标记。保留headless/package证据，可见客户端门仍未记录 |
| 0.8.0 | Lyra Python 健康棒粉底 | 在开发中实施。审查收尾和发布大门保持开放 |

历史标签和交付范围不会被重写。 0.1/0.5确切源包差距和0.7可见客户差距仍然记录债务，未追溯通过检查。一个新的候选矩阵必须覆盖1.0之前的当前行为。它不能改变旧版本中测试的内容。原始结果IDs和里程碑详细信息保留在[验证历史记录](docs/Validation_History.zh-CN.md)中。

<a id="runtime-blueprint-migration-sequence"></a>

## 运行时 Blueprint 迁移序列

完整的静态审计包含491Blueprint-家族资产：471非ABPs和20保留ABPs。范围审查留下了246运行时逻辑候选、182仅配置资产和63保留资产。这些是候选图表，并不能证明每个资产在所选体验中均可访问或已迁移。 11 名诊断、原型或欢迎地图候选者在其批次被接受之前需要进行reference/scope 审查。

| 版本 | 运行时 BP 范围 | 初始候选项数 |
| --- | --- | --- |
| 0.8.0 | 仅现有生命值栏清空 | 现有切片 |
| 0.9.0 | 第 1A 批：生命条饰面、weapon/ammo 面板、三个弹药计数器 | 5 |
| 0.10.0 | 剩余战斗HUD/nameplates，拾取和世界互动 | 32 |
| 0.11.0 | 角色、输入、英雄能力和武器 | 37 |
| 0.12.0 | Effects/audio编排、phases/scoring/notifications和AI | 75 |
| 0.13.0 | 通用UI、前端、设置、会话和重播 | 57 |
| 0.14.0 | ShooterExplorer、TopDownArena 和库存调节 | 40 |
| 1.0.0-rc.N / 1.0.0 | 冻结支持的API并验证识别的源对 | 接受范围 |

每个版本通常包含五到十个Blueprint批次，针对父类进行调整并共享functions/macros.完成的批次列出了确切的替换方法和Python所有者，剩余的BP/native依赖项和证据。当发现无法访问或保留的资产时，不要默默地更改计数。记录原因。初始库存和批次分配属于`UEPLyraIntegration/Migration/batches.json`的示例。

在每个行为批次之后，使用相同的输入运行原始 BP 基线和Python候选。使用声明的容差比较状态、return/out值、事件顺序、副作用和呈现。证明Python所有权，无需隐式第二次执行原始BP。在接受批次之前添加受影响的实际UE和one-server/two-client场景，包括respawn/rebind和清理。主机假货和孤立的UMG装置是支持证据，不能替代真实的游戏玩法或复制。通过、失败和跳过的检查保持独立。失败的检查会被修复并重新运行，而不会通过削弱断言而转换为通过。

<a id="080--finish-the-lyra-python-health-bar"></a>

## 0.8.0 — 完成Lyra Python 生命条

状态：未发布。目前已实施，验收尚未完成。

目标：在 Lyra 现有的 `W_Healthbar_C` 上创建一个事件驱动的健康栏演示者，具有正确的视觉效果和可证明的生命周期所有权。 CommonUI，游戏功能操作，GAS 权威和复制保持本机。

2026-09-03`All`结果`20260903-033426`通过了当时实施的检查，但它使用了NullRHI，具有`hud_audit: null`，并且没有建立视觉奇偶性，恰好是一个活动演示者或关闭后零拥有的回调。它也早于最终的纯源引导修复。通过主机测试并不能取代新的实时运行证据。

收尾实施现在通过审核路由HUD启用的`All`，需要一名活跃的演示者，并延迟HUD成功，直到Python退出清理证据可用。 29Python测试和40PowerShell合约测试通过，包括真实的CPythonexit/skip-finalizer案例。新的严格的 HUD 审核和当前脚本 NullRHI 独立版传递给 2026-09-07：一个活跃的演示者，然后零最终引用和平衡的 3/3 控制器和 6/6 健康订阅。 UBT 修复了早期的 BuildId 与两个仅元数据操作的不匹配。在 2026-09-10 上，animation/interpolation 修复了在隔离装置中传递的真实 UMG 渲染，并且预编译的交叉 Actor 调用方通过了所有五个路由阶段。额外的实时Profile切换覆盖发现了零大小的本机回退帧缺陷。仅UEP修复需要四个增量插件构建操作，而不是引擎重建或打包。现在，动画中期清理可以避免在路由器不可用时完成重新进入。集成的完整`All`和电流源封装栅极保持开放。请参阅[验证历史](docs/Validation_History.zh-CN.md)。

2026-09-12范围澄清使得0.8网络网关必须有两个独立的客户端。 `Network/All` 现在路由到两个客户端接受驱动程序。旧的单客户端通道名为`NetworkPrecheck`，无法满足登机口的要求。显式的World/Player代币、每个玩家health/restart、20阶段ACK障碍以及所有四个流程出口都是新合约的一部分。集中的`20260912-network-run-05`传递UE5.8.0/Python3.11.8：A/B隔离，两次切图和B0leave/B1重新加入，所有四个出口都是干净的。它是一个环回NullRHI传递，未渲染或打包网络接受。参见【网络验收方案】(docs/Lyra_Network_Acceptance_Plan.md)。

所需的退出门（仅主机检查不会关闭运行时门）：

- [x] 恢复damage/heal/death演示和数字插值。初始设置和随后的运行状况更改必须使用适当的保留视觉基元，而不是在每次更新时重置栏。
- [ ] 将`HUDAudit`整合到`All`及其成功条件中。丢失或无效的Interface/selector/profile/action配置必须使门失败。
- [ ] 在活动时，测试的本地播放器只需要一名演示者，零个专用服务器演示者，以及在破坏、路由器清理和解释器关闭后零个演示者拥有的delegates/state。最终接受必须在清理证据后决定，而不是根据退出前的快照来决定。
- [x] 添加针对重复演示者、缺失清理证据和无效审核数据的负面测试。每个都必须使验证失败。现有的清理日志消息是保留的证据，而不是观察到的泄漏的证据。
- [x] 添加聚焦的调用者 BP 回归：另一个 Blueprint 调用针对同一 BP 类的两个实例的 Actor 引用。一个profile实现了Python中的功能。另一个忽略它并到达保留的BP。两者都通过共享路由器并按目标UObject进行选择。断言类标识，每个实例counters/side效果，Python成功后无隐式原始调用，注销后恢复。
- [x] 记录渲染的damage/heal/death/respawn验收运行。使用原生Lyra游戏玩法或孤立的死亡装置。不要仅仅为了推动这项测试而扩大现有的非致命健康三角洲桥梁。
- [x] 通过dedicated-server/two-independent-client网络门：明确的每个玩家command/snapshot/respawn目标，隔离本地HUD所有权，交错命令幂等性，第二个玩家加入和单人leave/rejoin而不干扰其他玩家。保留模糊目标拒绝并为每个开始的process/connection一代收集最终证据。适配器、驱动程序和发布验收项合约已实现。集中运行`20260912-network-run-05`有20服务器阶段、20A、13B0和4B1ACKs。
- [ ] 修复后，重新运行当前源主机测试、HUD审核、独立、同步server/client、Win64Developmentcook/package和打包运行时，以及渲染的检查。保留存储库修订、二进制和参考哈希、严格日志和最终清理证据。

非目标：其他战斗HUD面板、通用GAS/RPC表面、广泛的热重装、新平台支持或新的本地网络权威模型。电流源组合runtime/network/package验收尚未完成。非建设重点车道是支持证据，而不是联合运行的替代品。

<a id="090--mixin-engineering-and-one-reusable-hud-chain"></a>

## 0.9.0 — Mixin 工程和一条可重复使用的 HUD 链

状态：正在开发中。 0.8 释放平仓保持独立开放。

目标：使保留类模型在正常项目开发中可预测，然后通过一条weapon/ammoHUD链来锻炼可重用的部分。

第 1A 批由 `W_Healthbar`、`W_WeaponAmmoAndName`、`W_AmmoCounter_Pistol`、`W_AmmoCounter_Rifle` 和 `W_AmmoCounter_Shotgun` 组成。第一个实现门是正确的BP/reflected/native调用入口和return/out-parameter写回。实验性就地函数体网关现在通过一个预编译的caller/ProcessEvent整数和布尔输出夹具。它与生产Mixin路由器保持分离，并且在Lyra业务中未启用。这不是全面回报、委托、RPC 或潜在支持。将正常的可玩启动与选择加入验证探针分开，并在解释运行时结果之前验证暂存的 script/asset 哈希值。

2026-10-13记录的进度：四个武器小部件保留持久的Interface/CDO资产并通过42original-BP/Python真实UMG比较。共享只读帧采样器取代了每个小部件的本机轮询，并仅在 values/ownership 更改时发出呈现更改。本机QuickBar/Pawn信号触发立即刷新。 Lyra StatTags没有公共弹药更换委托。未声明复制事件订阅。

`WeaponNetwork08`通过专用编辑器服务器和两个渲染客户端的19实际输入阶段：本机firing/GAS重新加载，空弹药，本机拾取条目，插槽切换，Pawn重新启动，两次切图和Bexit/rejoin.本机每玩家弹药， Python HUD 与原始BP基线一致。所有四个流程实例均以封闭范围退出0。拾取装置调用现有的native/BP生成器条目。实际走进皮卡车不属于索赔。

`WeaponScopeRegression05` 通过本机消息取消、四个实时Profile往返（无需构造重放）以及三个受控reload/native-GC 周期。 `PIERegression05`在一个编辑器中通过placed/spawnedActors、Construction/BeginPlay/EndPlay、封闭范围、收集旧的Actors并恢复UFunctions三个真实的PIE会话。 `CallMatrixRegression`，渲染的第三人称变体和standalone/shared核心回归均通过。主机测试总计82示例案例、9核心订阅案例、45现有HUD/network合约和16武器合约。

当前的Win64游戏存档通过了渲染的武器演示和相同的原生message/profile/reload/GC固定装置。打包暴露并修复了丢失的运行时插件脚本搜索路径并抑制了依赖导入错误。熟网络尝试仍然失败：LyraGame不是专用服务器目标，并且混合未熟Editor/cookedWorld分区对等体拒绝丢失生成的关卡包。真正的LyraServer干计划有1,235冷行动。专用打包网络仍然是显式的RC矩阵债务，而不是通过的0.9检查。 CC 审核两次超时，未做出审核决定。该批次的有界gameplay/presentation证据允许0.10开发。释放publication/0.8平仓，更广泛的目标矩阵保持开放。

- 定义并测试调用入口矩阵：跨ActorBP调用、反射name-lookup/ProcessEvent路径、普通事件、显式原始调用、支持的return/const-reference签名和拒绝签名。单独记录保留原始指针、Final/explicit-parent路径和直接本机C++调用作为拦截边界，而不是一揽子承诺。
- 覆盖放置、生成和延迟加载的物体。首次调用登记时间。 BeginPlay/Construction/EndPlay。每个实例选择、回退、重入、Profile切换、GC、重复 PIE 和世界切图。已经运行的事件永远不会通过注册重播。
- 提供受控的unregister/reload/re-register工作流程，并为生成的类型或函数签名更改提供明确的重启要求。不承诺任意实时Blueprint重新编译或状态迁移。
- 使诊断识别UObject、类别、Profile、功能和生命周期阶段。从导入、选择器和Python回调错误中恢复文档。
- 添加一个有界可重复使用的游戏消息subscription/lifetime表面，并将其用于weapon/ammo演示，无需将库存、设备、GAS、复制或评分权威移出Lyra。
- 在插件中保留通用的binding/message/lifetimeAPIs。在示例中保留Lyra特定的适配器、演示策略和资产。

出口闸门：

- [x] 签入的call/lifecycle矩阵将每条路径标记为测试支持、有意拒绝或bypass/unsupported，并具有可重现的夹具。
- [x] 受控重装和清理测试通过重复的PIE、GC 和行程。清理后检查状态、回调和路由器恢复。
- [x] 一个可见且打包的weapon/ammo示例证明了本机信号加上只读采样更改更新、安全订阅删除和本机权威所有权。
- [x] 第 1A 批次具有original-BP/Python 武器切换、射击、重装、空弹药和Pawn 更换的状态和视觉比较。一台服务器和两个客户端证明ammo/UI状态永远不会跨越本地玩家所有权。
- [x] 正常可玩启动不会自动运行验证或请求退出。显式启用的测试模式保留有限的超时和清理证据。集中渲染的武器模式干净地退出。 no-test-flag Lyra 观察仅受其所属的测试驱动程序限制和停止，而不是受探针限制和停止。
- [x] 通用，第三人称变体和Lyra都通过候选回归矩阵。失踪的Mixin第三人称可见门已关闭。
- [x] 支持的 API 库存和 migration/deprecation 规则已准备好用于 RC 冻结，没有已知的发布阻塞正确性缺陷。

[call/lifecycle矩阵](docs/Mixin_Call_Lifecycle_Matrix.zh-CN.md)、[订阅合约](docs/Runtime_Subscriptions_API.zh-CN.md)和[API库存](docs/Supported_API_Inventory.zh-CN.md)定义了这些有界声明。生产Mixinout/RPC/delegate/latent限制和原生调用绕过仍然是明确的。不暗示发布标签或独立 CC 批准。

非进球：满分QuickBar、十字线、球队得分、淘汰赛和荣誉。 RPC/latent 支持。任意C++拦截。无限制的热重载。这些运行时 BP 组分配在下面，而不是放大0.9。

<a id="0100-combat-hud-and-world-interactions"></a>

## 0.10.0战斗HUD和世界互动

状态：HUD且世界飞行员已经有界native-input/context证据。完整的batch/version仍然开放。从弹药十字线呈现和touch/inputHUD开始，然后分组世界交互。仅当所选资产需要时才添加类型化消息负载和异步支持。

第一个`W_Reticle_AmmoBar`试点保留了Interface/CDO资产和Python拥有的共享观察者演示者。 `ReticleRegression03` 通过十个真实的 BP/Python 材质比较、保留类、实时Profile往返、渲染的 PNG 和零最终 scope/ticker 状态。 `W_FireButton` 现在通过 Python 将其编写的绑定单击条目路由到相同的两个增强输入操作。原生GAS，弹药和复制保持不变。

`CombatHUDNetwork04` 通过专用编辑器服务器、两个渲染客户端、B0 exit/B1 重新加入、八个屏幕截图和四个干净退出，完成了 19 阶段。检查Python/BPFireButton意图、实际弹药consumption/reload、weapon/Pawn更换、两次切图和零最终拥有的observer/scopes。原生目标现在被断言为 Pitch=80/Roll=0，并且健康的 UI numeric/material 值必须与原生 Health 匹配。 `HealthBootstrapRegression01` 还验证已修复的前ASC 0/0 -> 第一个 100/100 通知、八个渲染的运行状况检查点和动画中期Profile清理。不需要build/cook。

可达性审核发现原始Pistol/Rifle/Shotgun定义使用自己的reticles/ammo计数器，而不是`W_Reticle_AmmoBar`。它的多人游戏证据明确是从生产计数器的本机WeaponInstance初始化的测试拥有的覆盖层，而不是发货的HUD替换或全局不可达判决。物理接触、新资产的打包运行时间和其他30初始候选者仍然开放。在这些 Python/asset 更改之后，0.9 包不是当前的证明。

下一组：触摸HUD父逻辑和菜单意图，然后进行世界交互。三个明显的候选者仅包含家长电话。保留其 BP shell，但在排除任何内容之前在父迁移后验证parent/child路由。类型化消息有效负载、惰性软类异步输入和世界RPC调度在使用时需要显式有界support/tests。 Cached/final 父调用和网络函数不得被默认为可拦截。

`BP_GameplayEffectPad`父级和未更改的子级现在通过八个延迟生成构造比较（每个类damage/heal/special/invalid），保留Actor类型，无ASC重叠无操作和十六个Actor破坏。 `PhysicalGAS03`还经过八个真实LyraPawn例/十六个原生enter/leave轮：伤害75->65->55，治愈75->85->95，活性效果去除，离开后健康状况稳定，与BP一致。原生Pawn传送触发物理碰撞。这些不是玩家手动输入或网络接受的。编辑器创作助手现在重用继承的标量名称选择器，无需重新声明它们或更改父级CDO/metadata。 `inherited-selector04` 和七个当前 DLL 调用矩阵装置通过。此修复仅执行了 UEP 编辑器模块构建。相关类并发路由器仍然被拒绝。一次尝试的儿童声明扩展在警卫发现后被恢复。仅限编辑器的构造提取助手将 BP 主体保留在`UEPConstructEffectPad` 下，并留下一个两节点虚拟构造转发器。因此，该子进程的显式 Parent 调用到达单父路由器。没有通用的cached-pointer/Parent拦截或第二个子路由器。 `PadNetwork02` 在编辑器专用服务器和两个渲染的离屏客户端上传递 16 个 parent/child x damage/heal x A/B x BP/Python 案例。 Native Health复制，未改变的非目标Health与实际numeric/materialHUD一致。所有三个进程都以零最终范围退出0。测试拥有的服务器pads/teleports不强制pad复制、客户端效果预测、生产可达性、rendered/manualpad输入或包接受。

迁移剩余的战斗HUD、QuickBar插槽、标线和铭牌，然后迁移拾取器、授予垫、发射器和传送器。保留UMG布局、inventory/equipment设施、冲突、本机复制和权威检查。范围是BP业务，不是Lyra的C++库存系统的重写。

`DebugSpreadNetwork01` 在原生武器回归中添加了保留类 Python 调试扩展 Tick。十九个阶段，两个客户端加上重新加入，自动 Tick，非零本机传播和精确的 BP/Python/native 格式化文本传递。四个进程退出0。它的调试覆盖层是测试拥有的。保留本机audio/Editor警告，并且生产reachability/package仍然不被接受。

三个生产标线副本现在使用 Python Tick 和自有类型 ADS/elimination 订阅。 `ReticleDifferential04`使用相同的真实装备的手枪实例，键入owner/PlayerState/suicide过滤器，重新启动消除animation/time和五个封闭的最终瞄准镜来比较它们的几何形状。原始断开连接的ADS动画分支仍然是空操作。 12 节点示例 BP 适配器提供类型化本机 VM 通配符转换。它不包含subscriber/gameplay业务，并且不添加本机插件依赖项或引擎编辑。传输证明包括嵌套复制隔离、wrong-reader/outside-交付拒绝和幂等取消。 `ProductionReticleNetwork01`通过实际生产的十九个真实武器阶段Pistol/Rifle十字线，四个出口和A/B0/B1最终范围平衡11/11，7/7，1/1.`ReticleNativeADS05`然后验证真实IA_ADS press/release 通过原生 ability/message 制作者。 `ReticleNativeShotgun06` 通过原始拾取条目装备原生霰弹枪，发射 8->5 弹药，并重新运行与该原生武器的所有布局比较。物理拾取、真杀玩法、网络霰弹枪和包保持分离。仅在一种武器上的几何形状并不能证明三种武器的游戏玩法。

`MenuDifferential04` 验证跨 Python/BP/Python Profile保留的菜单按钮绑定单击条目、本机异步推送和停用、最初卸载的菜单类以及 rendered/inspected/hashed 菜单屏幕截图。 Python 传递经过验证的软类字符串，无需预加载。流式传输、输入暂停和层插入保留在CommonUI中。八个当前 DLL 调用装置包括新的惰性软类转换。仅增量构建了UEP编辑器模块。此菜单驱动程序不执行compilation/cook/package.物理触摸，输入suspension/resumption令牌，取消，生产可达性和multiplayer/package接受不是从此有界测试推断出来的。

`HostDifferential02`迁移实际生产`W_WeaponReticleHost`：原生LyraWeaponUserInterfaceTick仍然检测设备变化。 Python 清除旧子级，读取原始项目片段，initializes/adds 具有填充对齐的相同 reticle/counter 类，并管理死亡可见性。八个BP/Python案例包括自动默认HUD可达性、无需重新创建子项的实时Profile往返和Pistol/Rifle/Shotgun本机装备。注入的 GameplayEvent.Death 到达本机 ability/component 委托：两个打包器都崩溃，Python 处理它一次，并且不会重新订阅相同的死组件。这不是 lethal-damage/kill 或物理拾取测试。四个 VM 清理节点仅删除旧的 BP 委托，避免在清理期间路由业务重新进入。 `ReticleHostNetwork01` 然后在当前 DLL 上经过十九个武器/生命周期阶段，两个客户端加上重新加入和四个退出。主机范围server/A/B0/B1平衡0/0、7/7、5/5、1/1.本机子配置、player/item所有权、自动路由、覆盖清理和生产Pistol/RifleBP几何一致。网络霰弹枪、致命死亡、打包和完整的0.10批次仍然开放。不需要 C++ 构建或cook/package。

`ProgressDifferential02`将现有生产`W_AbilityProgress`消息订阅、所有者过滤器、游戏时间countdown/text/material和完成可见性移动到Python。十一个BP/Python案例通过，包括真正的自动UMGTick、暂停原生游戏时间、重复消息、显式隐藏Profile恢复和Destruct/no-late-delivery。最终范围余额3/3. 原始异步代理有一个仅所有权存储节点用于取消。隐藏的简历条目是仅声明的 BP shell，而不是生命周期重放。 ReadDuration/BroadcastDuration 将仅 VM 传输扩展到 6 个功能/18 个节点。 `TransportAdapterRegression02` 在该适配器上传递类型化的 UI/Verb/nested-copy/ wrong-reader/outside-delivery/cancel 回归。第一次 NullRHI 启动尝试超时，未执行其固定装置。受影响的`ReticleAdapterRegression01`通过了实际的ADS和本地装备霰弹枪射击8->5以及所有geometry/message比较。检查了屏幕截图。前两次能力进度网络运行在Destruct/travel:一次性OnInitialized无法恢复取消的范围之后暴露了隐藏的小部件重用缺陷，并且折叠的小部件无法勾选。现在构造幂等重新武装。 BP 回退恢复而不重置 model/lifecycle. `ProgressReconstructRegression01` 通过十二个 cases/final 范围 4/4. `AbilityProgressNetwork03` 通过所有十九个阶段，两个 clients/rejoin/two travels/four 退出和最终进度范围 server/A/B0/B1 0/0、6/6、6/6、2/2. 对 12 个屏幕截图进行哈希处理并检查选定的进度图像。合成本地持续时间消息不是本机交互能力生产、远程玩家交互或GameplayMessage复制。

能力故障反馈现在有一个干净的十功能传输资产和十七个production-widget/original-BP比较，包括暂停期间的本机潜在延迟、持久动画回调、隐藏的Profile恢复和本机remount/cleanup.世界时钟原型失败并被具有显式int32链接回调的本机RetriggerableDelay取代。在真正的差分故障后修复了名为 BP 布尔输出元组的处理。一张本地直播表FText能够在en/zh-Hans/en文化变化中幸存下来，无需重播。检查了更正的屏幕截图。两客户端故障反馈通过所有19phases/twotravels/rejoin/four出口，范围为0/0、6/6、6/6、2/2，无最终结果active/errors. 它使用本地合成 owner/null-controller 消息，而不是本机 GAS 失败或消息 RPC。当前适配器UI/Verb回归也通过了。 FailureNative03另外通过了五个真正的原版手枪全弹匣ASC拒绝检查点：本机MagazineFull/FText交付，重复原因，自动latent/Outro完成，真正的秒LocalPlayer/Controller自己生产UI和第一所有者过滤，然后本地第二玩家删除和待处理的Profile清理。 Inventory/ammo/健康状况保持不变，最终范围平衡3/3，严格logs/normal退出和1,102冻结哈希通过。检查了分屏本机图像。它的Slate用户引导程序是显式的合成输入环境设置，而不是硬件输入。一个向后兼容的可选 FCharacterEvent 用户索引参数需要一个有界的 THREE-操作 UEP-仅编译，无需引擎重建。 Dead/invalid-health，跨进程原生GAS失败生产，打包和剩余候选保持开放。 Dash 冷却时间 (2I) 有 11 个有界比较，加上 5 种原始原生 GAS Dash/death 检查。其1.5s持续时间不是由灯具注入的。修复不活动的 UIExtension 池订阅和 Windows 报告竞争后，两个客户端 travel/rejoin 通过。最后scopes/pool手表已关闭。检查选定的图像。在这种情况下，本机重复的 Dash 不会发出面向用户的故障。生产者和致命损失仍然无人认领。重生计时器 (2J) 现在已复制资产和使用原生 timers/audio. 十二个有界比较通道的 Python 策略（生产比较加上隔离视口生命周期），原始 5 秒原生GA_AutoRespawn -> UI -> 真正的新Pawn/完成顺序。 Blueprint 针对实际运行时结果修复了局部变量和两种材料推理错误。共享池监视可以显式恢复折叠的条目，而无需重放生命周期。两个客户端travel/rejoin通过，并在重叠的短灯具UI关闭后检查“1重生”A/B0/B1图像。实际的非活动池重新插入和acoustic/package证明仍然开放。

Quickbar 插槽 (2K) 保留原生 inventory/equipment 并替换插槽、selected/empty/ammo 和鼠标到输入编排。十二次有界比较和十九阶段二客户端travel/rejoin通过。显式命名输出Mixin选择加入现在将IsThisTheActiveQuickbarSlot路由到Python，包括真实的BP/native输出传播和原始回退。十车道调用矩阵通过。当前DLL查询计数为9独立和15/8/2网络A/B0/B1.仅增量编译UEP插件模块，而不是引擎模块。 Packed-bool 对抗性布局，原始 BP OnInitialized，物理鼠标和封装门保持开放。

铭牌 (2L) 现在具有 Widget/Source/Manager Python 实现和类型化 VM 创作。批准的上游5.8.1更新和匹配Editor/modules解决了以前的共享二进制拦截器，无需重新标记清单或自定义引擎编辑。仅NameplateAssets01 accepts/copies Widget/Set。 NameplateDifferential06通过了十四个本机Widget/original-BP案例，并检查了PNG，最终范围23/23，团队代理13/13和初始化委托10/10，零residual/errors/ensures.组件资产01接受Source/Manager 和扩展的 19-function/59-node 类型传输。 Differential02/03和ComponentReleaseRegression01通过十一个original-BP/native组件案例。 WidgetReleaseRegression01 使用经过检查的 PNG 通过所有 14 个 Widget 案例。显式的 QuickBarAssets19 修订链保留了所有 19 个旧的传输语义摘要。 Network14 现在通过了所有 19 个本机输入环回阶段、两次切图和 B 重新加入、四次正常退出、最终拥有的 scope/root 清理和 415 未更改的输入哈希。本机资产检查确认这两个组件仅限客户端：需要零专用服务器范围。主机检查通过451，不能替代本机门。低质量渲染和拥有的灯具old-Pawn/Source宣布退役。不暗示预测、原生死亡能力和包裹接受。早期失败的实验仍在进行中。 UEP 广播属性地址修复仅需要插件增量构建。新的十一车道调用矩阵通过5.8.1。并不意味着接受新的软件包或版本。原始副本-Pawn描述符保留根据本机BP进行确认。声明了仅固定装置的孤儿清理，而不是生产策略修复。接下来是0.10-2M 库存垫original-BP/native 物理重叠差异。 0.10，所有后续迁移批次和完整发布验收仍然开放。

库存垫（2M）：Assets01 保留 parent/mesh 类身份和原始业务块，位于由一个父级 Mixin 拥有的四个虚拟布尔门后面。所有四个旧的图语义摘要都在编译中幸存下来。 Differential02 通过了十二个本地construction/Tick/Profile/physical-pickup/rejection/破坏比较并清理了六十个固定演员。 Player01添加了四个真实的Lyra玩家比较对：物理拾取->原生QuickBar装备煽动者->增强的Input/GAS手枪射击（12->11），全槽拒绝，以及原生库存身份/位置/移动/目标回滚。本机控制器 K2 销毁属于无操作，仅在装置清理中处理。 Network03 通过了所有 16 个双客户端本机 inventory/equipment/fire 复制案例，具有目标隔离和按案例本机回滚、三个正常退出、严格日志和 1,012 未更改 input/reference 哈希值。主机检查通过464。垫保留其原始复制标志。没有声称强制复制。远程音频、本机异常门控、生产图放置、客户端垫Profile奇偶校验和包保持开放。接下来的2N是B_GrantAbilityPad_ApplyGE，保留原生的GAS和时间轴曲线。

Grant-GE pad (2N)：Assets01 保留原始 Actor 类、两个业务图摘要和原生 Timeline/curve 数据。六个布尔门将业务路由至Python。四节点FText传输保留本机文本历史记录，而无需将业务决策转移到VM粘合中。 Differential02 通过了六种原生 original-BP/Python 比较，包括真正的即时修复、离开触发充电、暂停 Actor 与持续的原生时间轴和恢复的视觉效果。实际默认冷却时间为15.004688/15.005099s。不使用持续时间覆盖。赛程actors/subscriptions和球员health/position/movement均恢复。 Network04 通过四个 BP/Python x A/B owner-isolation/inactive-reentry/default- 冷却案例以及两个客户端的本机复制健康 HUD。所有三个对等点均正常退出，并且 1,019 冻结 input/reference 哈希值保持不变。通过在写入当前材料之前刷新停止的UMG动画来修复早期伤害的排队生成动画重置。 HUDRegression01（包括普通清理和动画中期Profile切换）和 WeaponHUDRegression01 传递共享演示者更改。主机检查通过482。文化、客户prediction/Profile平价、安置和套餐保持开放。

启动器 (2O)：Assets03 保留 base/Push/Up 类，具有一个继承的接口集、七个调度门、原始多播 signature/flags 和原始 bReplicates=false。 Differential04 使用拥有的零重力角色装置传递八个本机BP/Python对：16实际重叠、36演员和16封闭范围，未更改1,045input/reference哈希值。原来的 Push Y 钳位有意保留为零。主机测试通过
509. Network05 通过了12真实玩家双客户端案例，具有原始引力、本机启动请求奇偶性、实际所有者动作和其他所有者隔离、验证了player/observer恢复、三个干净退出和1,037冻结输入哈希。保留原生CharacterMovement/collision/RPC。客户端垫Profile/VFX奇偶校验、生产布局和打包未声明。

Spawners (2P)：Assets02 保留 weapon/ability 类、六个原始图、八个门、一个继承 Set、原始故障multicast/FText 传输和一个四节点本机重载接口适配器。 Differential03 通过了九个真实玩家BP/Python对，包括原生步枪射击（30 -> 29）、重复的ammo/full/reload守卫、治疗、原始重生曲线和四个自然10秒冷却时间。 Network02 使用原始 L_Expanse Rifle/small-heal 参与者及其序列化定义传递 36 A/B x BP/Python 案例。没有新的网络字段或测试派生类。本机清单身份、运行状况、position/movement/aim和参与者configuration/Profile恢复、36范围关闭、三个对等点正常退出且1,059input/reference哈希值保持不变。主机测试通过534。 InventoryRegression01 还通过旧的 16 案例双客户端通道。 PostGame/culture/all 定义、确切的客户端构造函数Profile奇偶校验和包尚未验证。本机游戏项目 C++ 生成器机制并未声明在此 BP 阶段已迁移。

Teleporter（2Q）：Audit02/Assets01保留原始的actor类，五个图摘要（包括它的两个宏），五个调度门，签名和非复制。 Differential04 通过七个物理角色BP/Python 与原生 Niagara 设置、传送、direction/launch 标志、原始世界空间相对offset/clamps 和无控制器行为配对。所有54演员和14范围关闭。严格日志、正常退出和1,059冻结输入通过。严格的日志门捕获并修复了丢失的隐藏本机 Owner 参数，用于破坏接收器 Box。实时组件列表证明取代了陈旧的SCS参考。 Network02 通过12真实玩家A/B x BP/Pythonlaunch/no-launch/相对偏移案例、本机requests/transforms、实际所有者飞行和其他所有者隔离、24portal/12范围清理、玩家状态恢复和三个正常退出。自然Lyra制动保持启用状态。主机检查通过559。声音奇偶校验、客户端门户Profile/prediction、原始关卡放置、手榴弹/多目的地运行时、无效配置奇偶校验和包保持打开状态。

操作触摸 (2R)：Assets02 保留 base/MobileOnly 类和五个原始图，使用直接函数 Mixin 和一个继承的父集，并且仅公开类型化 message/proxy 清理传输。 Audit03证明原始原生脚本-Tick元数据为base=true/MobileOnly=false。它不是强制启用的。 Differential05 通过30安装的UMG检查点，包括本机CommonUI状态更改、材质、owner/foreign/repeated持续时间、暂停、基础冷却完成、原始子级无勾选行为、teardown/reconstruct和Profile往返。四根八域近。检查了两个原生 PNG，严格的 logs/normal 退出通行证和 1,078 input/reference 哈希值保持不变。运行时反射写入使用set_property来避免编辑器通知重新运行PreConstruct。 WeaponHUDRegression01 通过了 42 之前的 UI 案例。 Click01 通过 4 个原生 CommonUI -> 增强输入 -> 现有 GAS 具有实际所有者 rise/velocity 的跳转案例和 1 个原生跳转事件，恢复了 observer/player 并释放了 root。这些是合成激活，而不是触摸硬件。 Network02 通过了八个双客户端 owner/lifetime 阶段，具有显式客户端本地类型生产者、实际复制的外部 Pawns 和正常的三点退出。每个客户端最终范围余额8/8，活跃状态为零。两个现场制作HUD听众将被保留，直到本机拆解。 GameplayMessageSubsystem 未声明复制。 TouchRegionsAudit01保留empty/base和三父转发器left/rightBP壳：那里不存在BP业务，原生游戏C++仍然是一个单独的阶段。主机检查通过586。生产触摸位置、物理硬件、本地持续时间能力生产者和打包仍未得到验证。

治愈拾取能力（2S）：原生依赖闭包达到FiringRange，尽管其目录名为HealthPickup_Unused。不排除它。 Assets03 保留原始类、图摘要、本机设备AbilitySet 源、InstancedPerActor/LocalPredicted 策略和原始Montage/GE 引用。 Python 拥有 cost/commit 决策、原生 Montage 任务委托、即时 GE 和相同的 1s 原生 TimerManager 以及显式 timer/scope 清理。四个本机终端通知保护节点可防止清理路由器重新进入。已编译的K2_OnEndAbility所有权和运行时本机端计数器证明了该条目。 Differential05 通过七对BP/Python：自然完成、本机取消、中断、原始 1 秒计时器、暂停的世界时间、活动Profile开关和外部本机EndAbility。原生项目identities/Health恢复，严格日志，正常退出和1,083冻结哈希通过。主机检查通过607。 Network03通过了所有12二所有者原生ASCLocalPredicted试验，精确的一次性原生成本，复制的Health/HUD/owner隔离和inventory/aim/movement回滚。三个节点干净地退出，最终scopes/timers余额6/6 + 3/3 + 3/3，active/errors为零，并且1,075输入哈希保持不变。这是有界证明。原生cost/commit拒绝，原FiringRange放置和包裹保持开放。此批次不需要 Engine/plugin C++ changes/builds。

- [ ] 每个小批量都通过original-BP/Python比较，没有BP失败。
- [ ] 拾取failure/success、cooldown/respawn和交互效果与基线匹配。两个玩家不能共享另一个玩家的 UI 或声明状态。
- [ ] Widget 和 Actor 生命周期测试在清理、切图或Profile切换后不会留下任何自有订阅。

<a id="0110-characters-abilities-and-weapons"></a>

## 0.11.0 角色能力和武器

状态：正在开发中。第一个GA_Hero_Jump/shared能力UI试点是在一次性Lyra副本中保留的BP类上编写的。原生CommonUI点击烟雾针对新默认Python跳转通过了四种情况。独立的hold/release、取消、状态结束和活动Profile切换BP/Python比较通过具有平衡范围、独立报告验证和1,248冻结哈希的七个本机对。本机UIgrant/remove在实际生产扩展点条目上传递八个原始/Python案例，包括两个相同标签注册、empty/invalid配置和跨Profile清理。第一个有界试点还通过了两个真实客户端、十四个BP/Python客户端对、独立报告验证、严格的logs/normal服务器最后退出和1,256冻结哈希的28本机权威试验。本机范围在服务器 14/14 和每个客户端 7/7. 预热 Pawn 上保持平衡，周转和专用服务器准备情况均被明确控制。 GA_QuickbarSlots还通过了十个原生BP/Python对和四十二个所有者试验：原生GAS事件到达original/Python三任务编排，原生QuickBarRPC/equipment/replication保留，外国所有者状态保持不变，并且原始库存身份恢复。正常服务器最后退出、独立报告验证和1,265冻结哈希通过。这些是原生 GameplayEvent API 输入，而不是 hardware/EnhancedInput 或复制的 GameplayEvents。 GA_Hero_Death camera/cue/delay 编排通过了五个本地致命损害BP/Python 对、独立报告门、严格日志、正常退出和1,281 冻结输入。使用显式恢复的每实例重生延迟固定装置分别测试原始的五秒重生抢占和两个实际的八秒等待完成（没有死亡Duration/CDO更改）。源观察者平衡10/10，策略范围5/5.其专用服务器/两个真实客户端通道还通过了二十个权威试验和每个客户端二十个独立Cue观察，本地所有者activation/camera/payload/respawn，外国所有者隔离，独立门，正常服务器最后退出和1,284冻结输入。服务器范围10/10，客户端5/5。四、实际权威等待完成，而客户端通过保留本机复制端等待结束。记录进程本地线程加载切换。后固定重构单进程回归还传递了五对具有1,287冻结输入的数据。化妆品选择组件通过四个原生独立对和十六个随机试验，真正的原生儿童演员spawn/attachment/no-collision和原始身份回滚，独立门，严格的日志和1,304冻结输入。他们的原生FastArray/two-viewer车道还通过了48权威考验和48真体/delegate/cleanup对每个客户端的观察，零客户端策略重放，精确的外国所有者部分，独立的gate/normal退出和1,308冻结输入。查看器范围每次关闭48/48.后帮助器重构独立回归也通过。 AutoReload的retained-class/public-signature/graph/default创作和六个原生弹药谓词，真正的fire-to-empty/original重新加载和生命周期对通过独立验收项，严格的日志，正常退出和1,313冻结输入。其双客户端通道还通过了24权威考验、实际打空重装、owner/authority弹药协议、外方所有者不变并保留非活动远程LocalOnly权威能力、独立门禁、严格日志、三台服务器最后退出和1,317冻结输入。六个后辅助独立对也通过了。其LocalOnly策略和原生GAS/replication、库存、实际重新加载逻辑和动画保持原始状态。保留本机RandomBool，观察到两个分支而不是种子流重播声明。 Character_Default/B_SimpleHeroPawn 是经过源码审查的 empty/parent-forwarding shell。他们的继承运行时正在等待。独特的GA_Hero_Healoriginal-class/default/graph创作和八个原生input/state/montage/effect/movement-lifecycle对通过，具有实际原始健康75->80，平衡范围，独立gate/strictlog/normal退出和1,327 冻结输入。其每个所有者的七对预测权威通道通过28权威试验，实际GE/Health/task观察，复制和精确player/spec恢复，独立的gate/strictlogs/three服务器最后退出和1,331冻结输入。其声明的本地权威输入装置可恢复确切的暂停计数。原始BP的重复解锁会消耗外部锁，因此自然的原始BP锁保留不会被声明。早期结束测试等待第一个实际权威修复，而不是延迟保证。后帮助程序独立八对回归和三个 Python 外来锁保存案例也通过了平衡的 11/11 范围、严格的 logs/independent gate/normal 退出和 1,331 冻结输入。它不是 之前迁移的旧版GA_HealPickup。 ADS保留类/defaults/signatures/graphs创作和六对实际输入，camera-mode/speed/mapping/source-message/reticle与一个共享父路由器的差分传递，6/6任务范围，13/13根助手，独立gate/strict logs/normal 退出并1,342 冻结输入。共享父UI生命周期还传递了八个具有独立门和1,342冻结输入的本机grant/remove案例。两个客户端ADS还通过了20权威试验、实际本机speed/camera/task状态、本地UI/reticle观察、外国所有者隔离、10/10服务器和5/5所有者范围、gate/strict logs/three 服务器最后退出和 1,346 冻结输入。最终的六对独立回归也通过1,346冻结输入。未声明网络暂停。原生camera/movement/input/audio和动画保持原生。 DropWeapon retained-class/default/signature/graph 创作通行证。四对实input/native库存deletion/cycle/restore差分传递，具有独立的gate/strictlogs/normal出口和1,353冻结输入。两个所有者16-试验authority/replication验证和后网络帮助器四对独立回归也通过，每个都有1,357冻结输入。保留delete-not-world-pickup 和本机索引重置规则。整个37-候选版本保持开放。继续执行设备、消防等hero/weapon政策批次。杂志重新加载保留class/defaults/originalgraphs/public签名和受保护的终端适配器创作通行证。十对本地装备手枪输入/实际蒙太奇通知/授权弹药/拒绝标签/终身差异通行证，具有独立的gate/strictlogs/normal出口和1,367冻结输入。两个所有者36-试验网络验证也通过了1,371冻结输入，权威14/14和所有者7/7范围，本机非权威所有者通知分支，独立的gate/strictlogs/three服务器最后退出。十对后钩手枪回归也通过1,371冻结输入。 Rifle 和 Shotgun 各自传递十个独立的继承父策略对、原始 inventory/item/AutoReload 恢复和 1,381 冻结输入。然后两者都通过36-试验性双主网络通道。 NetShooter还通过了十个独立对和36本地权威网络试验，其中1,391冻结了输入，保留了其原始容量 - 一本杂志和零AutoReload赠款。最终系列pistol/Rifle/Shotgunstandalone/network回归传递相同的最终实现。只读原始家族审计通行证。原型参考closure/defaults不能确定它未被使用。本机AutoReload，当被授予时，明确地paused/restored作为夹具隔离。不使用任务回调或ReloadDone事件重放。网络暂停未测试。设备实例保留Interface/CDO创作和四族活着original/Python差分通行证。 Native GC 移除每个真实的回调代理，而不改变暂停的动画状态。没有脚本回调被订阅或强UObject保留。这些有界的独立车道经过独立的大门、严格的原木、正常的出口和1,387冻结的输入。步枪、霰弹枪和原型owner/authority整合通过36重装权威试玩，实际装备add/remove/source/role并修复。本地本地标签和链接层必须与每个对等点的本地选择相匹配：专用服务器没有装饰子演员，并且女性客户端合法地选择女性层。共同montage/dead-state结果一致。原型原始BP控制和Python都通过了1,419冻结输入。本机标签映射弱所有者警告仍然存在（服务器 BP=3/Python=4，客户端=0），因此播放并非没有警告。五个original/Python真正致命的Death/respawn与声明的本机空槽死亡手枪配对也通过，没有动画更改和精确的Profile/source/respawn库存模型恢复，1,403冻结输入。自然破坏无装备、四户人家死亡和远程设备查看证明仍然是分开的。 SpawnEffect现已通过保留的原始class/fullCDO/signatures/graph证明，十个本机original/Python生命周期对以及立即BP到Python重新激活。保留原版-零级自身免疫效果、2.75-秒蒙太奇、75%动作解锁以及原生EndAbility潜伏清理。不存在任何推测性的额外延迟门。当前的独立和28试用二主ServerInitiated网络通道通过独立验收项，严格的error/ensure日志，精确的state/spec/fraction/input-stack恢复，正常退出和1,412冻结输入。范围平衡19/19独立、24/24权威和9/9每个所有者。客户从不直接activate/replay能力，各自验证14自己和 14 未更改的外部行。原始的spawning-Cue active-timeline回收警告仍然存在（网络客户端13/12）。这不是无警告播放或网络pause/fraction-boundary/immediate-handoff证明。整个版本保持开放。继续角色、表情、火焰、近战、手榴弹和其他英雄政策。 Team-color 设备软件现在可以通过六个本机 original/Python 对、默认本机工厂发现、repeat/loop/Profile/pause/invalid-public-user 边界、精确的自有句柄清理和 15/15 临时根。物理 LED 输出、网络、二级用户和同实例本机重新激活未测试。它的 return-before-out Blueprint 传输暴露了 UEP VM 参数解码器缺陷，通过有界三动作插件刷新修复。没有引擎实现编辑或完整构建。在新的 DLL 上，有 11 个通用调用通道、3 个 PIE 循环、6 个稀疏映射案例和真正的 28 试验二所有者 SpawnEffect 网络回归传递。结合十九阶段，two-travel/rejoin/HUD回归也通过了757冻结输入和四个实际正常退出。早期批次保留其记录的旧二进制出处。构建在 0.10 已要求的有限支持的基础上，并仅引入其场景所需的附加 asynchronous/RPC 表面。

Emote 现有的共享能力小部件路由器现在具有类型激活、移动检查和本机端门。当前的创作保留了完整的CDO，原始公共signatures/business图和现有的ADSProfiles/defaults.九个original/Python独立对通过实际的EnhancedInput激活，本机蒙太奇completion/interruption， crouch/uncrouch，取消，Profile清理和暂停，以及18/18范围清理和1,435冻结输入。本机LaunchCharacter产生外部运动。普通AddMovementInput中断未经认证（故障夹具在两侧产生零速度）。原BP的ClearAll删除了一个外来运动监听器。 Python 仅删除其自身的。这种有意的隔离差异是独立断言的，而不是报告为确切的听众奇偶校验。最终输入Emote九对，共享Widget八例，ADS六对standalone/twenty-trial网络回归通过。第一个 Emote 每个所有者五对网络通道还通过了 20 个权威测试，每个所有者具有 20/20 服务器和 10/10 范围以及 1,439 冻结输入。网络移动、蹲伏中断和暂停尚未执行。整个0.11保持开放。

保留输入 Widget 根现在使用 Python activation/create/remove/native-End 编排，保留记分板子types/configuration 和本机GAS/async streaming/CommonUI 层。 `20261016-widget-held/Assets02`保留完整的CDO、公共签名和原始业务图。类型化的软类传输和显式的仅清理状态保护避免了急切加载和路由器重入。 Elimination03 和 ControlPoint01 各自在其实际本机体验中传递了 7 个 original/Python 对，加上 3 个 canceled/replaced/pending Profile切换 GC 回归，并恢复了 21/21 范围和原始状态。暂停正确地使原始非暂停记分板输入无效：本机WaitInputRelease在游戏时间冻结时删除了UI，而不是发明的暂停时保持活动规则。 Network02通过24消除LocalOnly所有者试验，每个客户端十二个独立的外国-UI观察，不活跃的本地权威，0/0+12/12+12/12范围，严格的日志，独立验收项， 1,453 冻结输入和三个真实服务器最后零退出。仍记录有五次失败的固定/清理尝试。 Python 有意清除已取消的代理引用并取消先前拥有的待处理请求。这些是安全改进，而不是与原始陈旧参考行为完全一致。 CP 网络、travel/rejoin、物理输入、记分板pixel/text 奇偶校验和软件包此处尚未测试。记分板Widget自己的BP业务还是后期的UI/scoring批次。整个0.11保持开放，不需要引擎build/cook/package。

按下输入的 Widget 根现在将 activation/deactivation/native-End 路由到 Python，而不更改任何 Inventory/Map 子项。原生创作保留了完整的原始CDO、类型、三个签名以及保留的业务图。类型化的软类传输和精确的原始委托清理避免了急切的加载和外部侦听器的删除。实际的库存经验为每个切换类授予两个实例。固定装置保留两者并发出单个真实的EnhancedInput新闻。 Differential01 通过 14 个 original/Python 对、6 个本机待处理 GC 回归和 4 个相同 BP 混合Profile案例，以及 74/74 策略和 28/28 固定范围和 1,465 冻结输入。普通端保留 UI 拥有的面板，活动的 Profile 拆解将其关闭，非活动的拆解无法关闭池化的 UI。与保持输入不同，按下UI可以保留暂停状态。

Network01 的 UI 报告已通过，但其严格日志门在所有者启动时在 SpawnEffect 的可空缓存控制器上正确地FAILED。修复是一个单独接受的批次（示例 fb1b13d）：不拥有丢失控制器锁，并且更高版本的控制器无法导致无主解锁。真正的本地缓存空/外部锁探针和十个SpawnEffect对加上28两个所有者权威试验通过最终的Differential02/Network02门，1,468冻结输入和正常退出。保留其先前的 Network01 探测失败。现在，比较禁止新的本机tasks/effects，而不假设旧的本机任务不存在。没有声称精确的 BP 空接收器警告奇偶校验。

然后，受压的 Network02 通过48所有者试验、24每个客户的外国所有者观察、未更改的本地拨款和无效的LocalOnly权威。所有严格日志、独立报告门、1,469冻结输入和三个实际服务器最后零退出通过。策略范围关闭 0/0 + 48/48 + 48/48. 待处理 completion/stale 回调解除是有意的安全改进，而不是确切的原始陈旧参考奇偶校验。 Inventory/Map Widget BP业务在后续UI批次中仍保持不变。无 UI 复制、物理输入、pixel/text、过滤器令牌、数据包丢失、travel/rejoin 或打包运行时声明。这些仍然是两个有界的本地批次，而不是整个版本的接受或发布。无引擎build/cook/package或官方源修改。

AutoRespawn现在有一个单独接受的三助手试点：Python实现了GetOwningPlayerState，阿凡达死了还是快要死了和EndDeathAbilities。其保留的BPidentity/fullCDO，十二个签名以及完整的原始业务图被保留，没有添加任何业务传输。现有的命名输出绑定处理原始非引用 IsDeadOrDying 输出引脚。最终`20261016-auto-respawn-helpers/Differential06`通过了四对BP/Python，八个实际致命的GASdeaths/restarts，原生五秒延迟，暂停和中死轮廓切换。 Network05 通过了十二次authority/owning 试验和每个客户的六次独立外国所有者观察、精确持久的AutoRespawn/Death 处理和本地设备类别多样性。两次运行都通过严格的日志、独立的语义门、正常退出和1,479冻结输入。网络服务器在实际客户端退出后退出。

原来的K2_HasAuthority检查激活模式，而不是Pawn角色。原生非活动客户端能力保留默认权威模式0，因此原始BP和Python都会调用EndDeathAbilities。每次试验的三个测量快照验证行为与实际角色3/2/2和GameMode存在true/false/false.客户没有施加任何伤害或能力激活。本机重启保留在服务器上。 Network04 不正确的客户端辅助零门和所有早期失败的尝试仍然保留，而不会被重新标记为通过。原来的avatar/death/EndPlay监听器，激活，重置消息，UI，潜在的延迟和重启业务仍然是BP。接下来迁移监听器绑定/清除编排，然后分批验证剩余的event/delay/restart业务。整个AutoRespawn、0.10和0.11保持开放。

下一个接受的侦听器批次将BindDeathListener/ClearDeathListener编排移动到Python，并显式重用每个Profile本地字典中的三个辅助函数对象。当普通继承使当前收集器未注册这些帮助程序时，Differential01 会正确失败。其正常退出不算接受。无需更改或重建 C++。四个精确命名的原生委托传输（16节点）保留外部订阅者和原始缓存的 Avatar 规则，完整的CDO/twelve签名/业务图。最终`20261017-auto-respawn-listeners/Differential02`经过四次pairs/eight实际死亡并重新开始，repeated/cross-Profile清晰且有约束力，暂停和中死亡切换。独立原生Death/EndPlay每次触发回调一次，固定范围关闭8/8，并且在显式探测计数器被快照后原始原生事件遍历Python。 Network01 通过十二个权威和所有者行、每个客户端六个外国所有者观察、夹具范围12/12 + 6/6 + 6/6、严格logs/independent gates/restore 和实际服务器最后零退出。两次最终运行都会冻结1,489输入。生产策略不拥有Python委托回调、范围、计时器或能力生命周期。激活、reset/UI、death/avatar事件决策和delay/restart/completion业务仍是下一步的实施工作。这五种方法并没有完成整个资产或发布。

AutoRespawn death/Avatar/restart 决策现在已在 `20261017-auto-respawn-events` 中限制了本机接受：七个原始方法加上两个新的延续门路由到Python。 Assets01 在四个声明的延续端点周围保留 class/full CDO/twelve 签名和原始业务摘要。它复用了原来的五秒和0.1秒Delay节点，增加了两个entries/fourdispatch/four门体节点，并保留了16个精确监听传输节点。 Final Differential02 通过了四个真正的死亡对以及一个 original/Python live-Pawn K2_DestroyActor 对。真实的持续时间和完成负载、原生restart/RPC调用、暂停、中延迟Profile切换和独立的Death/EndPlay传递过程。两个夹具范围分类账都关闭10/10. Differential01 被保留为失败：裸露破坏在原始 BP 和Python 中失去了相同的三把手枪授予。现在，单独探测原始本机行为的 records/compares，然后使用本机 QuickBar empty/original 插槽 RPC 恢复设备，并需要原始 QuickBar 插槽项标识、逻辑类和持久句柄。生产行为不变。

Network01 通过了 12 次authority/owner 试验，并为每个客户进行了 6 次独立的国外可靠完成有效载荷观测。专用服务器没有本地装饰完成。客户端没有GameMode重启路径。本机侦听器范围关闭 12/12 + 6/6 + 6/6。消息范围在所有三个对等点上均关闭12/12。两次最终运行都通过了严格的日志、独立验收项、恢复、1,499冻结输入和正常退出，服务器最后在网络中。强制阿凡达破坏在这里仅是独立的。待Reset/removal取消，travel/rejoin，实际输入、丢失和包裹未经过认证。接下来是剩下的AutoRespawn激活、重置subscription/filter、UI注册和结束/移除业务。整个资产和版本保持开放。

下一个有界AutoRespawn批次现在将剩余的entry/reset/UI/生命周期业务移动到`auto_respawn_activation_mixin.py`：十二个原始方法通过十一个原始条目和一个保留父端门（总共十六个路由函数）具有脚本业务。它保留了原始类型化的本机 Reset 侦听器、潜在节点、委托、GameMode 重新启动和可靠的 GameState RPC。显式的Python/BP启动变体通过自然grants/Added/AvatarSet/OnSpawn，四个死亡对，一个真正的阿凡达毁灭对和十二次试验的二拥有者自然回归。本机End/observe-original-deadline/Clear/Give传递三对，具有精确的资源清理和明确的新授权句柄。 Native End 删除潜在操作。该装置不会重播取消的回调或根垃圾标记的GAS实例。

`20261017-auto-respawn-activation/ResetDifferential02` 传递四个真正的原生重置对，包括重复、挂起的死亡和中期挂起的Profile切换。 `ResetNetwork02`通过了十六个authority/owner试验和十六个被动的外部客户端观察，16/16每个对等点的范围关闭，键入的确切所有者，外部权威过滤和服务器最后三个正常退出。仅阶段的四节点VM读取器独立观察Reset。生产消息适配器不变。外部客户端通过本机可靠的RPC接收完成，而不是复制的重置路由器有效负载。 UI 有效性保留测量的角色基线：false/false 在专用服务器上，true/true 在拥有的客户端上。最终重置运行冻结1,525输入。 Lifecycle03 冻结1,513。早期失败的 fixture/driver 运行仍然失败并保留。 End/removal 的显式 listener/UI 取消是两个Profile中有意的生命周期改进，而不是关于未修改的 BP 过时回调行为的声明。

该批次接收账本38和孤立索引验证。完整主机型号通过1,096。原来的运行时业务现在由脚本拥有，但整体资产/版本接受保持开放：主动清除，没有前面的明确结束，travel/rejoin，丢失，物理输入和包未经过认证。本机警告仍然存在。无 Engine/official 项目更改、C++ 构建或 cook/package.

下一个字符批次仅将`B_Hero_ShooterMannequin.ClearInventory`迁移到`uep_lyra_characters/inventory_clear_mixin.py`。 Native C++ death/Reset 输入未更改的原始 BP 事件，然后调用相同的保留帮助器类型。 Python 保留权威、QuickBar 有效保护、复制项列表删除之前的每个槽以及本机 QuickBar/inventory 操作和复制。仅添加两个Mixin接口声明。完整的原始图表，完整的CDO和六个公共签名保持不变。 Controller/missing-inventory 处理是故意安全的，而不是原始的空警告奇偶校验。

`20261017-character-inventory/Differential02` 通过四对死亡对和一对裸露的阿凡达，在替换 Pawn 和本地物品重新创建之前独立观察空库存。 `Network02`通过了十二个authority/owner试验和十二个被动的外部观察：没有客户端删除，合法的客户端回调角色1/2而不是假设的固定角色2，未更改的外部库存和本机复制的项目定义恢复。库存观察员关闭10/10独立和12/12+6/6+6/6联网。 `Reset01` 使用 8/8 库存观察器闭包通过原始角色 BP 传递八个现有的本机重置请求。所有严格原木、独立大门、正常出口通行。网络服务器最后退出。冻结的输入为 1,540 / 1,544 / 1,551。

这揭示了旧版裸阿凡达证明中的一个资格：检查了原始插槽identities/specs，而不是每个InventoryManager条目。 BP 和 Python 都在直接破坏时绕过 ClearInventory，并且原生初始拨款添加了一把新的无槽手枪。新探测器记录原始增量，并在需要精确的原始 item/slot 身份之前使用本机 API 仅删除新的孤儿。它不会改变生产行为或将之前失败的运行重新标记为通过。 Ledger 39 记录此有界辅助批次。所有1,134主机型号均通过。其他角色业务、原生多项目/nullable-controller/Character-Profile-switch探针、针对此角色更改重置网络、travel/rejoin、物理输入、包和全版本验收保持开放。 ABPs/animation 和 Engine/official 项目保持不变。

下一个有界字符助手批次将 Get/SetEmoteAudioComponent 添加到 `uep_lyra_characters/emote_audio_mixin.py` 中，显式保留接受的 ClearInventory 别名。原始字符类型，完整的graphs/fullCDO/eight签名和ANS_EmoteSound动画通知字节保持不变。仅阶段的第二个 BP 发送实际类型化的接口消息。 Python getter 返回命名的 AudioComponent 对象 out pin，setter 只更新原始字段。 Software02 通过 12 个 original/Python/cross-Profile nullable/object/repeat/ 替换往返、两个同类混合实例案例、具有保留引用的本机 GC、非接口默认值和实际组件 destruction/restoration. Network01 在 server/two-client 原生世界中传递相同的本地软件矩阵（36 轮） Trips)、owner/foreign 角色和服务器最后三个零退出。严格的logs/independent门通过，每个最后通道都有1,562冻结输入。所有1,162主机型号均通过。 Ledger 40 记录此仅帮助程序范围，而不是实际的动画通知制作、音频 playback/hardware 或复制引用。剩余的角色业务、travel/rejoin/packages和完整版大门仍然开放。无 Engine/official 项目更改或 C++ build/cook/package.

下一个保留的字符方法ChangeQuickbarSlot现在由`uep_lyra_characters/quickbar_input_mixin.py`中的脚本拥有。接受的三个助手是显式本地别名。原始占用时隙条件，提供GameplayTag，并且保留双时隙索引大小。没有发明有效负载对象字段。 Assets01保留原始type/fullCDO/ninesignatures/all完整图。仅阶段的第二个 BP 在类型化的 Actor 引用上调用原始方法。 Differential01 通过了六个original/Python 对以及两个Python（仅无效）索引安全案例。原生GAS观察者验证准确的有效负载。本机设备与独立预期的项目定义相匹配。 Network01通过原QuickBar服务器RPC，通过28拥有客户端calls/28权威设备结果，精确的外主隔离和服务器最后三个正常退出。本地GameplayEvents未声明为已复制。每个所有者关闭 14 个本地观察者tasks/scopes，同时原来的 3 个 Quickslot 任务仍然处于活动状态。原始库存identities/field/Profile/CDO恢复。严格的日志和门通过1,568standalone/1、572网络冻结输入。 1,192主机型号通过。 Ledger 41 是这个有界辅助版本。安全缺失Controller/QuickBar和无效索引处理故意与BPreceiver/array警告不同。只有无效索引安全性具有本机探针。物理键盘、可为 null 的本机探针、travel/loss/packages 和剩余的字符业务保持开放。

AddInitialInventory 是第五个保留的角色助手，在 `uep_lyra_characters/initial_inventory_mixin.py` 中实现，具有四个可接受的本地别名。 Authority/Controller/InventoryManager 守卫，原始有序本机授权（堆栈一）/slot 尝试和最终非空零槽激活仍然存在。它保留了 occupied/overflow 插槽的原始本机无插槽额外内容。缺少QuickBar是故意安全的。本机空接收器奇偶校验无人认领。 Assets01 保留原始 type/full CDO/nine signatures/all 图，仅添加仅阶段类型的 BP 调用者。 Differential01 通过六个 original/Python 配置对和自然的第一个Pawn Python 授权。 Natural02 通过了四个死亡对/两个阿凡达案例，十个实际的新PawnPython拨款和原始清除/重生前空回归，10/10观察者。 Network02 通过24权威grants/owner副本观察加上24真实客户端BP无操作调用、本机FastArray/QuickBar复制和外国所有者隔离。两个客户端的自然启动助手条目均为零。没有发明自然的客户端执行。原始item/slot身份和config/Profile/CDO恢复，而不是旧设备实例身份。客户端观察者范围各自关闭1/1。恢复的本机状态在单向释放之前被冻结，并且在断开连接后仅读取 POD 出口。所有严格关闭的logs/independent门和服务器最后三个零出口都通过。冻结输入为1,584manual/1、588natural/network。 1,236主机型号通过。 Ledger 42 排除失败的 Natural01 （过早包装错误标记）和 Network01 （发布后本机所有者重读）。修复具有可执行的回归和完整的重新运行。剩余的字符业务、可为 null 的本机探针、hardware/travel/loss/packages 和全版本验收仍然开放。

CreateOrUpdateOutlineIfNeeded 是`uep_lyra_characters/outline_mixin.py` 中第六个保留的角色助手，有五个可接受的显式别名。原来的local-control/create-if-missing/attach-once/scalar-then-vector决定仍然存在。现有分离的 MID 保持分离并重复重用同一对象。原生材质、相机TScriptInterface、渲染和GC保持不变。 Assets01 保留 type/full CDO/ten signatures/all 图表。 Software03 传递八个真实的 BP/Python 对、完整的 camera-setting/field/Profile/CDO/inventory 撤消、signed/HDR 参数、真正的未占有 Actor 和保留引用的本机 GC。自然启动进入Python 3 次，creates/adds 1 次MID/blendable 并更新3 次scalar/vector 对。 Network01 在实际的 server/two-client 世界中通过 48 情况 trials/54 BP 调用：自己的玩家服务器非本地无操作，两个客户端所有者都是本地create/update，所有未占有的装置都是非本地的。每个世界都会观察到两次自然的Python启动，并产生zero/one/one材料创造。所有夹具材料和调用者级根平衡。生产根本没有什么。清理在发布之前冻结，最后三个零退出完成服务器。严格关闭的logs/independent门通过1,600最终standalone/1、602网络输入。 original/staged 父材料哈希值匹配。所有1,270型号均通过。 Ledger 43 排除失败的 Software01（由 GC 收集的无主测试调用者类）并记录显式测试类生命周期所有权后完整的新重新运行。无 rendered-pixel/material-replication/all-transient-MID-reclamation 或完整的 Character/version 索赔。剩余team/cosmetic编排等业务，hardware/travel/loss/packages保持开放。 animations/ABPs 保持不变。

OnTeamOrCosmeticsChanged 是`uep_lyra_characters/team_cosmetics_mixin.py` 中第七个保留的角色助手，有六个可接受的显式别名。它的两个函数参数和原始 color/outline/stencil -> 可选本机显示应用程序 -> platform/device 序列仍然保留。 Inherited parent stencil business is still BP. Assets01 preserves class/full CDO/eleven signatures/every graph. Final Differential03 passes eight BP/Python pairs/twenty real BP calls, actual material/stencil state, three natural Python startup callbacks and sixteen naturally evaluated/removed device properties. Network02 在实际的 server/two-client 世界中传递 48 trials/60 BP 调用，每个世界有两个自然回调。 The Engine deliberately has no device subsystem on the dedicated server。 zero activation there, sixteen actual scheduled properties per client. Native disabled color marker handles bracket synchronous calls for bounded read-only public handle queries。 only handle POD copies change, never native allocation/sets or production handles.标记自然完成，根平衡0/0 + 48/48 + 48/48，并完全恢复释放前的visual/camera/Profile/CDO/inventory状态。严格关闭日志、独立门、每次最终运行的1,618输入和服务器最后三个零退出通过。 Ledger 44 preserves failed Differential01 (unhashable native-set observation) and Network01 (fixture assumed a server device subsystem) as failures。 both fixture fixes have executable regressions and fresh runs.所有 1,307 独立索引模型和 558 文件全索引 syntax/import 检查均通过。无hardware/pixels，复制团队changes/material状态，travel/loss/packages，整个角色或释放声明。剩余的运行时 BP 业务继续以独立实施、验证和本地提交的批次进行。

UpdateCustomStencilFromTeamID adds the eighth retained Character helper in `uep_lyra_characters/stencil_mixin.py`, explicitly aliasing seven prior helpers.它仅在保留的射手角色上隐藏此继承方法。原始父类asset/function和其他子类家族保持不变。 Local AND player control selects zero。否则TeamId到达原生设置器不变。本机递归原始发现和0..255钳位/渲染状态行为仍然存在。 Assets01 保留 class/full CDO/twelve 签名/所有图表。 Final Differential02 has eight team plus twelve direct BP/Python pairs (40 trials/52 BP calls), true ChildActor/extra primitive, native negative/ overflow clamps, unchanged render-depth enable flags, repeats and 24 actual GC calls.原始和Python嵌套团队到模板的调度计数都是准确的。自然的Python启动有3个calls/queries和16个组件写入。 Network01在三个实际世界中有120trials/156BPcalls/72实际GC调用。 natural stencil enters twice/world. Native role/control/device-subsystem differences, nonreplicated parent/child fixture destruction, two caller-class root scopes/world and full visual/camera/Profile/CDO/inventory restore pass.严格独立的gates/closed日志，1,636inputs/final运行和服务器最后三个零退出通过。所有 1,336 独立索引模型和 567 文件全索引 syntax/local-import 检查均通过。 Ledger 45 从最终独立证明中排除了较早的门 Differential01 通证。 No pixels/stencil/team/material replication, hardware/travel/ loss/package, whole Character/parent-family/version or publication claim.

K2_OnDeathFinished和K2_OnReset在`uep_lyra_characters/lifecycle_mixin.py`中添加两个保留的Character事件体，显式地为八个先前方法（总共十个路由方法）别名。原始原生CPP事件仍然会触发它们。 Python转发一次到选定的ClearInventory，回退仅调用其保存的BP事件。保留原生authority/GAS/destruction/respawn/replication。 Assets01 保留 type/full CDO/twelve signatures/every 原始图。 Natural01 通过了四个真正的死亡对加上两个裸阿凡达试验、精确的event/helper计数、独立的空库存窗口以及使用新的本地项目标识恢复的定义。 Bare Avatar 仍然拥有原始的无槽手枪三角洲。只有新观察到的孤儿才会接受仅固定装置的本机清理。 Reset01 传递八个实际存在的重置请求和精确的 Reset-not-death 条目。 Network01通过了十二个authority/twelve所有者事件试验和十二个被动外部观察：真实所有者复制，零客户端删除，实际回调角色1（合法非权威角色1/2），不变的外部库存AND事件POD。库存范围关闭10/10、8/8、12/12 + 6/6 + 6/6。旧的Actor证据只需要其保留的字典，不需要Actor/GAS根或死包装读取。专用选择器可防止导入的旧设备启动第二条车道。严格关闭logs/independent门，1,648/1,652/1,648冻结输入和服务器最后三个零出口通过。所有 1,363 独立索引模型和 575 文件全索引 syntax/import 检查均通过。 Ledger 46 有四个通过的 runs/thirteen 匹配的范围输入。其余组件callbacks/teamlistener/init/input/health业务和parent/sibling家庭，物理input/hardware/travel/loss/packages和完整版本大门保持开放。

原始的PawnCosmeticsComponentOnCharacterPartsChanged绑定接收者在`uep_lyra_characters/parts_changed_mixin.py`中添加了第十一个保留的Character方法，具有十个显式别名。 Native FindTeamFromObject(Self,false) 控制虚拟团队助手的调用。组件有效负载保持未使用，与 BP 匹配。 Assets01 保留了 type/full CDO/thirteen signatures/every 图，并且实际上在两个 Profile 上注册了 11 个函数，然后是 unregisters/restores 签名。 Final Differential03有六个原生部分cycles/eighteenAdd/Remove/repeated-removeoperations/twelve独立代表，未分配团队noop和add/removeProfile切换，真正的临时部分Actor生命周期，原始entry/Actor/visual/camera/Profile/CDO/inventory恢复，一关闭scope/two 绑定和 44/44 设备根。自然启动进入Python一次。 Network02 通过本机 FastArray 复制拥有 18 个实际权威 operations/thirty-six 客户端 Actor observations/twenty-four 独立代表。两个相同类型的Pawns使用相反的Profile然后交换。无头权威正确地产生没有渲染parts/broadcasts零这样的回调。在稍后的刻度到期之前，客户端会观察本地角色 2 和外部角色 1 以及本机多播内的实际一次性设备对象。每个客户都有十二个代表、六个生产属性和36/36根。本机原始部分，Actoridentities/visual/Profile/CDO/inventory，观察者范围和服务器最后三个零退出恢复。严格独立的gates/closed日志通过1,665inputs/final运行。 Ledger 47 保持 Network01 失败（夹具有效性导入），添加可执行的 cleanup/cached-POD 回归和全新的完整重新运行。早期的Differential01/02不是最终的独立证明。所有1,399独立索引模型和584文件全索引syntax/local-import闭包通过。无回调replay/property-array重写，文件传递的游戏状态，pixels/hardware/travel/loss/package/whole-version声明。 listener/health/init/input和parent/sibling团队业务保持开放。

原来的HealthComponentOnHealthChanged接收者在`uep_lyra_characters/health_changed_mixin.py`中添加了第十二个保留的Character方法。十一个先前的方法是显式别名。本机 authority/PlayerState/self/AI 控制器防护和原始旧新，零 HitLocation/default 标签保留。 Assets01 保留了 type/full CDO/fourteen signatures/every 图，并且实际上在两个 Profile 上注册了 12 个方法。 Differential04有十个实际的GAS初级试验，二十二个本地primary/prime/restore健康代表和四个真实的AI损害刺激与匹配的本地感知记忆，包括原始的负治疗强度。 Network01 有十四个权威主要trials/twenty-eight客户端主要观察，三十个本地健康delegates/world和4/0/0authority/client伤害刺激。本地role2/foreign角色1，本机空副本煽动者，opposing/swappedProfile，原始health/inventory/Profile/CDO，每个世界一个范围和3/4,3,3封闭绑定通过。一个单独的未注册的测试拥有的机器人生产者调用本地SpawnOneBot，因此正常的本地团队分配和真正的对手来源遵守伤害规则。原始机器人列表不变，拥有的Pawn/Controller/PlayerState/producer被销毁。三个服务器最后零退出，严格关闭日志，独立门和1,684冻结inputs/final运行PASS。 Differential01/02/03 保留失败的夹具历史记录（未反映的名称设置者，未分配的团队spawn/negative 伤害restore/Controller BP 破坏 noop，然后团队拒绝源）。修复具有可执行的回归模型。所有1,451独立索引模型和593文件全索引syntax/import闭包通过。 Ledger 48 恰好有 3 个接受的本机运行和 13 个匹配的作用域输入。有效的non-PlayerState/missing-Pawn边缘仅限于主机。没有健康property/delegate重播或夹具注入AI报告，物理input/pixels/travel/loss/package/whole-Character/version索赔。 listener/init/input和parent/sibling团队业务保持开放。

五个原始的QuickSlotEnhancedInput接收器在`uep_lyra_characters/enhanced_input_mixin.py`中添加了17个保留的字符路由，以及12个显式接受的别名。 Assets04 保留 type/full CDO/nineteen 逻辑签名/每个图和五个 action/Triggered 绑定语义。 UE 重新编译确实对生成的接收器符号进行了重新编号。可调用描述符在每次注册时解析当前本机名称，而不是硬编码编译器后缀。 Python实现十七个功能，BlueprintFallback十二个：现有的原生原始调度保留完整的输入帧。手动 Python bool/vector -> FInputActionValue 往返仍不受支持，未声明由 C++ 构建修复。 Differential02 通过 16 个实际输入 injections/eight BP-Python 对、12 个本机 GAS 事件和精确设备。五个动作，重复选择，空selection/default-zero-cycle noop和原来的零事件震级匹配。十六个scopes/tasks和原始的item/slot/Profile/CDO恢复。 Network01 有两个本机输入 owners/sixteen 试验 each/thirty-two 权威 RPC 设备 comparisons/twenty-four 所有者 GAS 事件。实际客户端角色2，外部Actorinput/helper/Profile不变，其他权威库存不变且零服务器角色input/helper调用PASS。释放前清理冻结，服务器最后退出，三个零退出。严格关闭logs/independent大门并1,710冻结inputs/final运行PASS。 Ledger 49 恰好有三个接受的本机 runs/thirteen 匹配的范围输入。所有1,495独立索引模型和602文件全索引syntax/import闭包通过。保留Assets01/02和Differential01失败，Assets03仅作为早期原型证明。没有直接输入接收器调用、映射更改、物理 keyboard/hardware/pixels/travel/loss/package/whole-version 声明。团队listener/init/possession准备就绪，parent/sibling业务保持开放。

生成的ObserveTeamColors结果接收者在`uep_lyra_characters/team_observer_mixin.py`中添加第18条字符路由。十七个接受的别名保留可调用的输入描述符。 Assets01 保留原始类型/完整CDO/everygraph/twenty-one逻辑签名，Python18/BlueprintFallback13.最终差分03通过六个BP/Pythoncomparisons/eight实际本机观察者激活，assigned/unassigned初始结果和重复的工厂调用，六个实际设备延迟引擎 GC 后的属性、精确恢复和零拥有观察者。 Differential01 的相同报价收集门仍然失败。 Differential02 研究的是延迟 GC，而不是最终更严格的验收。 Native BP-frame retention was not observed. Network01 通过每个 world/thirty-six 总计 12 个本机回调，实际 DedicatedServer/Client/Client、role3/local2/foreign1、opposite/swapped Profile和每个客户端的 6 个实际设备属性，server/foreign Actors 为零。原始代理保留，拥有的代理全部收集，根平衡22/22独立和0/0+30/30+30/30网络，清理在发布前冻结，服务器最后三个零退出通过。严格封闭原木，独立大门和1,728冻结inputs/final运行PASS。 Ledger50 有 3 个接受的运行和 14 个匹配的范围输入。所有1,546独立索引模型和612文件全索引syntax/import闭包通过。这是初始观察者激活，而不是真正复制的团队更改、侦听器工厂迁移、取消后的所有未来显示回调、hardware/pixels/travel/loss/package/fullCharacter/version接受。接下来仅迁移具有精确原生委托传输的 ListenForTeam factory/bind/activation 决策，不保留 Python 回调或发明重复调用取消。

ListenForTeam 现在在 `uep_lyra_characters/team_listener_mixin.py` 中添加了第 19 个保留路由，为 18 个接受的方法起别名。一个四节点精确本机命名的多播传输仅拥有绑定。工厂/bind/activate决定是Python，没有closure/proxyroot/deduplication/added取消。 Assets01/02 仍然存在失败的创作证据：将借用的 MemberReference 视图分配给自身会失去成员所有者。单独的结构值可修复类型化连接，而无需绕过架构或修改 C++。 Assets03 保留原始 type/full CDO/all graphs/twenty-one 逻辑签名，并实际注册 Python19/BlueprintFallback14. Differential01 通过 6 个 comparisons/eight 真正的本机创建和回调，assigned/unassigned 和重复调用，六个本机设备属性和 zero owned observers after GC.自然BeginPlay在两个灯具Actors上进入Python创建。 Network01 通过了所有三个实际世界中的两个Pawn身份的自然Python创建，三十六个测试回调，六个本地properties/client，其中foreign/server输出为零，GC后拥有零个观察者。精确原版state/live代理集，roots22/22独立和0/0+30/30+30/30网络，冻结cleanup/server-last三个零出口，严格关闭日志，独立门和1,742冻结inputs/final运行PASS。 All 1,577 host models PASS.真正的团队变更复制、取消后显示更新和剩余initialization/possession/legacyOnRep/parent/sibling/version接受仍然开放。无 Engine/official Lyra/animation 更改、C++ build/cook/package 或发布声明。 Ledger51 列出了 3 个接受的本机运行和 19 个匹配的范围sources/assets。所有1,577独立索引模型和622文件全索引syntax/import闭包通过。

旧版OnRep_PlayerInfo在`uep_lyra_characters/legacy_player_info_mixin.py`中添加了第二十条角色路线。保留其确切的文字OnTeamOrCosmeticsChanged(0, null)，而不是发明的当前团队查询。十九个原始 Python aliases/fourteen 后备别名保留描述符。 Assets01通行证Python20/BlueprintFallback15，二十二个原始逻辑签名，type/fullCDO/every图形和文字默认，没有新增业务节点。当前类没有名为 PlayerInfo 的属性。这是一个遗留的助手合约，而不是真正的复制通知传递。 Differential01 通过六个comparisons/eight手动键入的第二个BP调用、实际zero/null本机outline/software结果、六个设备属性、未更改的本机teams/live观察者和原始restoration/owned裸Actor启动观察者GC。 Network01 在三个实际世界中传递 36 个类型调用、相反/交换的Profile、role3/local2/foreign1 和六个本地properties/client，零个foreign/server 输出。 Roots22/22独立和0/0+30/30+30/30网络，零拥有代理保留，冻结cleanup/server-last三个零出口，严格关闭logs/independent门和1,757冻结inputs/final运行PASS。 All 1,606 host models PASS。 Host01 错误的未分配 noop 固定装置仍然失败。报告明确披露了手动助手重放，但没有实际的RepNotify或团队更改复制认证。接下来仅迁移ExperienceReady生成的库存就绪延续。保持BeginPlay/possession/visibility初始状态，parent/sibling/full-version门打开。无 C++ build/cook/package、Engine/official Lyra/animation 更改或发布声明。 Ledger52 有 3 个已接受的本机运行和 15 个匹配的范围sources/assets。所有1,606独立索引模型和632文件全索引syntax/import闭包通过。

ExperienceReady生成的OnReady延续在`uep_lyra_characters/inventory_ready_mixin.py`中添加了第二十一个角色路线。只有立即就绪的Controller -> InventoryManager -> Quickbar路径变为Python。缺失的分量仍然进入原来的三延迟BP宏。 Native grants/authority remain. Assets03 保留原始的 type/full CDO/every graph/twenty-three 签名，Python21/BlueprintFallback16. 四节点精确命名委托传输和仅五节点阶段的实际体验工厂生产者从不直接重播回调。针对原始探针预加载相关探针，并在编译器工作后执行临时路由器验证。 Assets01/02 remain failed. Differential01 在验证之前因运行时夹具语法错误而失败。主机现在解析实际工作树runtime/tools/tests.最终差分02通过六个库存对/十二个真实延迟本机信号、两个丢失控制器原始等待控件、不同的items/overflow/occupied插槽和精确本机identity/configuration/Profile/CDO恢复。没有early/late授予周围拥有的Actor破坏和十四个收集的经验proxies/callerroot1/1通行证。 Network01 的异步重新捕获会在撤消后覆盖测量的授权并保持失败。在恢复阶段冻结该捕获并添加 AST 回归。 Network02 通行证24权威/24所有者replica-noop试验与实际FastArray/Quickbar复制，自然权威经验delivery/zero发明了客户端启动和外部库存隔离。所有拥有的proxies24/12/12收集，调用者roots1/1每个世界，库存观察者范围关闭，原始状态恢复和清理在服务器最后三个零退出之前冻结。严格关闭logs/independent大门并1,776冻结inputs/final运行PASS。仅网络夹具修复在 Network02 中执行。未更改的独立production/fixture证明仍保持Differential02。 All 1,640 host models PASS.完全延期的waits/factory/initialization/Character/version、hardware/pixels/travel/loss/package大门保持开放。无 Engine/official Lyra/动画更改、C++ 构建或发布声明。 Ledger53 包含三个接受的本机runs/seventeen匹配范围sources/assets。所有1,640独立索引模型和643文件全索引syntax/import闭包通过。

Batch54 替换了 `uep_lyra_characters/inventory_wait_mixin.py` 中的三个 Controller/InventoryManager/Quickbar 待决决定。调度保持本机DelayUntilNextTick，具有三个稳定的每ActorUUIDs和一个空的两节点int32恢复声明。没有 Python 等待 ticker/callback 根或全局潜在取消。不要承诺整个引擎帧延迟：保留实际的本机下一滴答后端。 Assets01 保留原始 type/full CDO/all graphs/twenty-three 逻辑签名，Python22/fallback17. Differential04 通过六个立即库存对、两个销毁等待控件和六个延迟 readiness/single/repeated-request BP/Python 对。实际占有增加第二个独立的准备信号。本地合并和两个授予匹配 BP。所有 32 个拥有的经验代理和角色拥有的观察者收集，root1/1. 失败的 Differential01-03 仍然失败：广泛的观察者所有权包括原始池化的 GCNL_Spawning 句柄。诊断参考搜索本身也发出了引擎确保。最终测试分别识别确切的本机 Cue 句柄和拥有的目标，每行记录一个 inactive/unrooted 池化观察者，字段和 hidden/ownerless Cue，而不是假装它已被收集或改变池。 Network01 PASSes24 authority/24replica-noop 试验，实际库存复制，所有者隔离和恢复本机状态。 proxies24/12/12收集，roots1/1每个世界。严格关闭日志，独立闸门，服务器后三零退出和1，796冻结inputs/final运行PASS。所有1、702host/isolated-index模型和653文件全索引检查均通过。 Ledger54 是有界的：工厂creation/ReceivePossessed 是下一个，初始化和parent/sibling/full-version 门保持打开状态。没有本机挂起的Profile切换或延迟组件复制，hardware/pixels/travel/loss/package声明。无 Engine/official Lyra/animation 更改或 C++ build/cook/package/publication.

Batch55 通过 `uep_lyra_characters/possessed_mixin.py` 路由 ReceivePossessed：Actor 权威 -> 本机体验工厂（自） -> 现有的确切命名委托传输 -> 激活。 NewController 仍然是未使用的业务输入（记录其实际身份），没有添加父事件、重复原始执行或Python 回调根。资产03通证Python23/fallback18和原始type/fullCDO/all图/二十三个签名。实际ActorMacros：Switch Has Authority 语义和源资产被冻结。 Assets01/02 猜测失败 macro-name/library 守卫并保持失败。 Differential01 未能超出原始AI Controller BP 的独立体验引导程序。分别对准确的本机身份进行分类，实时捕获路径，关闭构造函数故障并要求收集所有任务。 Differential02 PASSes24 个实际拥有的 Pawn possessions/Character 任务，12 单独的原始 Controller-BP 引导任务，所有 32 个类型的体验请求以及完整的先前 wait/inventory 回归。自然的主要参与者恰好执行一条Python工厂链。 Network01 PASSes24权威/24所有者复制noop试验，每个服务器玩家一个自然的Python工厂和零发明客户端拥有回调，库存identity/replication/撤消，代理cleanup24/12/12和roots1/1每个世界。严格关闭日志，独立大门，服务器后三零退出和1，817冻结inputs/final运行PASS。所有1、741host/isolated-index模型和662文件全索引检查均通过。 Ledger55 是有界的。接下来是InitState的延迟可见性，然后是BeginPlay编排和parent/sibling覆盖。没有完整的 Character/version、延迟组件复制、待定的Profile切换、hardware/pixels/travel/loss/package 声明。无 Engine/official Lyra/animation 更改或 C++ build/cook/package/publication.

Batch56 将ShowPawnAgainNextFrame的原生InitStatecallback/delayed-show业务移至`uep_lyra_characters/visibility_mixin.py`。 GameplayReady仍以原BeginPlay开始报名。调度保持本机DelayUntilNextTick，具有命名的int32恢复，没有Python等待ticker/root.Actor本地潜在站点分配器保证不相交的稳定Pythoninventory/visibility密钥。 Assets01 通证Python25/fallback20、原始type/fullCDO/allgraphs/twenty-four签名、空的两节点延续声明和四节点精确本机InitState注册传输。 Differential01 通过实际的本机回调有效负载身份、六个后期就绪可见性对和四对single/repeated/immediate-destroy/both-direction待定的Profile切换试验，无需手动重播回调。原始标记和 Python 隐藏标记同意 before/after 原生刻度。即将发生的破坏仍然安静，之前的possession/inventory/resource/pool大门仍然严格。自然启动记录received/delay隐藏在6438，本机resume/show在6439。保留实际的后端，而不是通用的全帧延迟承诺。 Network01 在权威和拥有客户端 Pawns、24 authority/24 副本-noop 库存试验上都通过了一个自然callback/delay/resume/show，准确的原始状态和收集的proxies24/12/12，每个世界的roots1/1。严格关闭日志，独立闸门，服务器后三零退出和1，838冻结inputs/final运行PASS。全部1、788host/isolated-index模型和673个文件全索引检查通过。 ledger56 是有界的。接下来是ReceiveBeginPlay编排，然后是ancestor/sibling和完整版本的门。无网络repeat/destroy/Profile-switch可见性、物理像素、hardware/travel/loss/package/full-version声明。无引擎/官方Lyra/animation更改或C++build/cook/package/publication.

Batch57 迁移 `uep_lyra_characters/begin_play_mixin.py` 中的 ReceiveBeginPlay 编排：确切的原始父级 -> ListenForTeam -> 隐藏 -> PawnExt GameplayReady 注册（立即调用 true）。空的两节点静态父调用传输保留原始祖先调用。不会重播现有的 Actor 的 BeginPlay。资产01通证Python26/fallback21，原始type/fullCDO/allgraphs/twenty-four签名。 Differential01 通过了整个前面的 wait/possession/visibility 回归以及两个新的 Actor pending/ready BP/Python 对。同步一次性仅测试普通CDOProfile覆盖选择每个新基线。最后立即恢复，在本机 GC 后再次检查，并且从不保存默认值。等待Actors保持隐藏，不会提前InitState交付。准备好的原生Actors展示具有相同的原生库存和平衡的拥有资源。 Network01没有CDO固定装置：权威和拥有客户端Pawns自然地输入恰好一个订购的PythonBeginPlay，一个InitState延迟显示，24authority/24复制品-noop库存试验和精确的原始恢复。 proxies24/12/12收集和roots1/1每个世界。严格关闭日志，独立闸门，服务器后三零退出和1，856冻结inputs/final运行PASS。所有1、812host/isolated-index模型和683文件索引闭合通行证。 ledger57 是有界的。接下来审核继承Hero-defaultequipment/death业务。 Character_Default的parent-only构造和空的BeginPlay是结构转发，不是发明业务。 Animation/ABPs 和原生物理保留。无完整的ancestor/sibling/版本，更广泛的网络生命周期，hardware/pixels/travel/loss/package声称。无 Engine/official Lyra/animation 更改或 C++ build/cook/package/publication.

Batch58 迁移了`uep_lyra_characters/equipment_hide_mixin.py`中继承的HideEquippedWeapons决策循环，保留原生设备instances/spawnedActors和SetActorHiddenInGame。原始缺失管理器无操作，无额外权威检查，原始父级bytes/roottype/fullCDO/graphs/twenty-five签名和Python27/fallback22PASS Assets01。三节点第二个 BP 调用者仍然仅处于阶段。 Differential01-04 是保留的故障：不活动的观察者 collection/global 代理差异仅在控制器 BP 的异步 ExperienceReady 引导之前暴露了构造函数 AI 隔离。共享拥有的机器人准备就绪现在可以在实时时观察准确的本地 Cue 身份，并重新应用本地AI隔离。完整的装置还可以在每次更新时隔离机器人，而无需 Health/immunity 写入。 Differential05 通过了所有先前的回归和六个新的BP/Python对：equipped/already-hidden/repeat/empty/missing-manager/real致命的GAS。原版随机原生死亡延迟等待（BP0.567/Python0.542游戏秒），不重玩。真正的武器Actors隐藏。三个原始机器人identities/100健康状况和每行完整的原始主动代理集保持准确。在接受的运行中不需要提示生命周期豁免。原生拥有的资源和调用者roots1/1余额。 Network01通过了八个本地实际武器-Actorhide/undo调用（server4/A2/B02），精确的visibility/inventory/Profile撤消，自然的startup/visibility和24个权威/24副本-noop库存回归。工厂proxies24/12/12收集并扎根1/1每个世界发布。严格关闭日志，独立语义门，正常服务器最后退出和1，873冻结inputs/final运行PASS。所有1，865host/isolated模型和694文件索引关闭先于ledger58/local提交。隐藏标志复制、网络死亡入口、像素、Ragdoll/death编排、同级和整个版本接受保持独立。接下来迁移Ragdoll的项目调用ordering/impulse选择，而不是原生物理或动画。没有引擎/官方Lyra/animation更改，C++build/cook/package或发布。

Batch59 迁移`uep_lyra_characters/ragdoll_mixin.py`中继承的 Ragdoll 项目编排：原生碰撞Profile -> 原生骨骼模拟 -> 原生 bVelChange 脉冲。原始十四节点父图dataflow/literals，根type/fullCDO/allgraphs/twenty-six签名和Python28/fallback23PASS Assets03。原始物理资产保持字节相等。 Differential01 是保留的失败立即速度假设：BP 和Python 都对脉冲进行排队，而不立即更新可读速度。 PhysicsCore来源证实了积累。 Assets02 保留了未反射的 getter 失败。 Assets03 添加了仅深度复制阶段的单个骨盆body/no 约束控制。定量moving/zero-strength/repeat案例仅使用拥有的测试网格、原生gravity/damping/known-velocity设置，并在至少两个引擎帧后进行观察。 Differential02 通过了所有八个直接案例，包括自然死亡概况和整个前面的回归。最大实际速度分量误差0.0000578486保持在不变的0.02门之下。静止和真正的死亡保留了完整的原始装备。它的耦合轨迹/姿态未经单体控制的数值认证。拥有资源，原始机器人identities/Health，严格关闭日志，独立门，exit0和1,897冻结输入PASS。 Network01 是一个保留的 A-early/B0-still-testing 全局代理平等失败。 Network02 在共享启动屏障之前等待所有 24 个库存恢复和两个hide/undo 令牌。六个实际的本地类型 BP/Python Ragdoll 调用跨越server/A/B0，完整的身体状态，每个Actor收集一个拥有的观察者，安静地销毁Actors和精确的原始代理集通过。调用者roots1/1每个世界，八个先前的hide/undo调用，24authority/24副本库存回归，独立的gate/strict关闭logs/server-last零退出和1，897冻结输入通过。仅网络屏障修订并不是新的独立重新执行。所有1，912host/isolated-index检查和704文件关闭先于ledger59/local提交。无所有者ragdoll/death复制、物理像素、全装备轨迹、Engine/animation实施、打包或version/release声明。接下来迁移真实的Health.OnDeathStarted绑定接收者的montage/sense/native随机延迟和后延迟Ragdoll/Hide/Death调用。将空的死亡端点、animations/physics本机门和更广泛的ancestor/sibling/version门分开。没有 C++ build/cook/package/publication.

Batch60 迁移实际继承的Health.OnDeathStarted在`uep_lyra_characters/death_started_mixin.py`中生成的接收器：本机随机配置蒙太奇，PlayAnimMontage，本机视线注销，本机随机延迟（0.1..0.6），然后虚拟Ragdoll/HideEquippedWeapons/empty死亡。 Assets01 保留了原始的十四节点死亡跨度、委托绑定、父bytes/rootCDO/all图/二十八个签名和寄存器Python30/fallback25.Differential04通过了所有先前的场景和十个新的致命-GASdefault/single/empty-montage，销毁待定和双向轮廓开关案例。原始接收者之后的只读实际健康代表见证记录montage/senses。后来的原生HitReact覆盖当前蒙太奇仍然是单独的证据。实际视力的去除保留了听力。本机 game-clock/frame 延迟、无前缀重放、超过 0.6 秒的弱所有者取消以及拥有的资源清理都是门控的。保留失败的 Differential01（初始化）、02（UUID 报告）、03（伤害后蒙太奇计时）和 Network01（早期挂起的启动快照）。 Network02 仅等待出色的本机启动显示操作。最终可见性门不变，24authority/24副本库存行，8hide/undo和6个本地非复制Ragdoll调用PASS。最后两条车道均经过严格封闭的logs/independentgates/normal零出口和1、915冻结输入。所有1，963主机/独立索引模型和714文件关闭先于ledger60/local提交。这个网络通道是回归，而不是真正的死亡入口或物理复制。下一批61验证实际的authority/owner/foreign死亡和本地重生。没有回调重放、animation/physics实现更改、C++ 构建、打包、整个版本接受或发布。

Batch61 通过了实际的本地死亡入口，而不是前面的本地身体回归。 `death_replication_network_validation.py` 组成原生致命 GAS / 死亡 OnRep / 带有只读健康信号和延迟后 body/weapon 见证人的原始重生。 Network04记录12个权威，12拥有和12个外国死亡复制品观察，本地roles3/2/1，双方所有者轮流和BP/PythonProfile，匹配本地PlayerState身份和未更改的外国所有者inventory/lifecycle.本地蒙太奇，随机延迟， Ragdoll/hideorder/state、empty/rebuilt库存及安静无效旧ActorsPASS。最短的实际销毁后安静窗口是2.7321385游戏秒。每个流程和先前库存范围余额中的死亡scopes12/12/0。该测试在试验前明确使用了 13 个经过本机碰撞检查的相关性传送 baselines/damage。没有相关性property/CDO写道。读取反映World.AISystem.PerceptionSystem：服务器有1，客户端0。因此，它们原来的本机取消注册保留了配置的 Sight。独立gate/strict闭合logs/server-last三个零出口和1、921冻结输入PASS。所有1、992host/isolated-index模型和719文件关闭先于ledger61/local提交。保留Network01（worldless/unsupportedget_world查询），02（渲染器RDG异步任务访问violation/exit3），03（伤害前丢失的外部副本）。 Network04 使用未更改的渲染设置，而不是引擎修复。早期的渲染器崩溃仍然是一个开放的稳定性观察，以供更广泛的接受。没有新的assets/compile、姿势复制、独立重新执行或版本升级。接下来启动 Dash 的 direction/montage 决策助手，然后 migrate/accept 其实际激活、本机 task/cancel 和 RPC 编排。

Batch62 仅启动保留的 Dash SelectDirectionalMontage 帮助程序。它的42个原生BP/Python对和three-world/two-owner辅助通道PASS，具有原始的class/fullCDO/graphs/signatures，空蒙太奇，严格的角度边界，命名输出，同帧本机状态不变性和恢复的Profile/configuration.实际的继承接口发现失败暴露了UEP先决条件：在本机编译器接口一致性之后接受拥有的子提供程序，并支持具有词法弱对象调用上下文和未打包原始内容的显式parent/child路由器。六个私有对象 BP 控制 PASS 同名嵌套parent/child 原件、生命周期挂钩、后备、注册和注销订单、普通同级排除和签名恢复。这不会改变RPC/final-call拦截或自动调用原件。最终审查的纯插件版本编译了 4 个UEP CPP 和22.299s 中的DLL/LIB，-NoEngineChanges，未更改检查Engine/official 引用和BuildId。早期的账本保留其实际较旧的二进制来源。没有完整的引擎构建。当前-DLL实际death/respawn回归PASSes36个本地死亡证人。 ADS 6 个和 Emote 9 个独立对，加上 ADS 和 Emote every20 权威试用/两个所有者网络回归通过。 All2，038独立索引模型，729文件syntax/import闭包和ledger62的八个传递的runs/sixteen匹配的范围文件支持本地有界批量提交，而不是版本升级。保留失败的资产尝试、严格日志失败的第一个选择器运行以及发布后控制器读取网络故障。 Dash激活、navigation/movement决策、task/cancel和服务器RPC主体业务保留后续批次。 animation/GAS/movement/RPC 实现保持原生。没有完整版本、打包或出版声明。

Batch63 仅在本机可靠服务器SendInfo 入口之后移动Direction/Montage 存储。四节点类型非RPC网关在Python之后跳过这两个BP存储，然后重新加入原来的Commit。 RPC signature/flags、完整的CDO 和所有其他业务语义均保留。 Assets01 和 42 对选择器回归通过。 Network02 通过来自两个本机 ASC 客户端的八个实际 RPC 入口，包括必须更改两个旧本机字段的四个 Python 行。向前/向左original/Python有效负载匹配。所有者roles/identity，国外地点/velocity/Health/spec/config/data/Profile，本地montage/RootMotion/end任务，冷却拒绝和20帧安静窗口通过。八个本机碰撞检查姿势重置和Pawn运动意图是显式固定装置，而不是原始速度或输入数据写入。严格独立的gates/closedlogs/server-last三个零退出和1，868冻结输入传递。2,081模型和735文件关闭门本地提交。初始 Network01 仅保留初始证据：匹配陈旧字段可能会掩盖无操作存储。更强的原生重播是最终的。没有新的 C++ 构建、整个 Dash activation/task 迁移、量化运动平价、物理/增强输入、网络 pause/travel/loss/package 或版本升级声明。接下来迁移本地direction/navigation和激活决策，然后在有界比较中迁移剩余的本机任务orchestration/Cue/UI业务。

Batch64将本地方向准备移动到Python，使用原生Actorfacing/raw输入，相机前移*（1,1,1.2）或原始AI导航projection/flatten/Normal.五个传输节点保留所有原始图、class/fullCDO/four签名和未使用的正输出。实时的 Direction getter 避免了跳过的不纯 setter 的缓存输出。 Assets01 和 42 对选择器回归通过。 Standalone01 PASSes10 个原生 ASC 跨original/Python无输入、向前、向左、倾斜相机和实际授予的空闲机器人的请求：零方向像以前一样取消，非零方向保留原生montage/RootMotion/end/cooldown/20-tick清理。原生音高20 产生缩放后的Z0.4104241883。两位演员的Profile/spec/config/control旋转恢复。经过碰撞检查的姿势重置被声明为固定装置。 Nonzero/failed AI 投影是模型覆盖的，未声明为原生非导航 AI 运行。最终 Network02 PASSes8 两个拥有者可靠的RPCs/local准备，无远程权威本地准备，外来不变量，本机任务，严格的gates/closed日志和服务器last3零退出。最终运行 freeze1，878 输入。2,132 模型和 743 文件关闭门有界本地提交。没有 C++ build/cook/package 或完全接受 Dash/version。接下来进行本地激活，zero/cancel/Commit/蹲伏决策，然后native-task/Cue/UI编排。原生GAS、RPC，动画、导航和移动实现仍然是原生的。

Batch65 会覆盖实际的保留类 K2_ActivateAbility 事件，不会自动失败。 Python拥有IsLocallyControlled，本地制备，原生near-zero/cancel，Commit/cancel，crouch/UnCrouch和K2_HasAuthority/unchanged可靠的SendInfo订单。远程授权等待原始RPC。一个非Net事件进入未触及的原生task/Cue/UI/延迟合并。 class/full CDO/five signatures/all 现有图表和四方法Profileregistration/restoration 保留。 Standalone02 PASSes12 原生 ASC 激活，包括实际蹲伏、控制 inputs/output 奇偶校验、选定事件一次、tasks/end/cooldown/quiet 以及精确的双参与者恢复。 Native Controller 抑制微小的角度变化。该装置仅在需要时使用公共偏航+1/original调用来精确恢复，而无需扩大其门。 Standalone01 仍然是失败的恢复证据，而不是重新标记接受。 Network01 PASSes8 owner/8 远程权威实际事件调度和跨 2 个所有者的 8 个原始可靠 RPC，无远程本地工作、外部不变量、本机任务清理、独立 gates/closed 日志和三个服务器最后零退出。最终运行 freeze1,888 输入。本机 GameplayTag 属性映射无效所有者警告会重复之前的 ADSRegression01 警告。 cause/stability 保持开放状态，没有 warning-free/Engine-fix 声明。2,168 models/751-file 关闭本地提交。 Native Commit-失败分支，剩余task/Cue/UI/Delay业务、物理投入、量化移动、全版本验收保持开放。没有 C++ build/cook/package/push/tag/release.

Batch66 将原生 montage/RootMotion 任务创建、权威 Cue 参数、类型化冷却 UI 生产、原始 root-finish/Kismet Delay/script-End 延续和每能力委托清理转移到 Python。原生可靠RPC主体还从脚本调用原生Commit/task开始，无需第二个BP主体。原来被忽略的服务器Commit返回被保留。 Assets03 保留原始 class/CDO/accepted signatures/graphs 除了 15 个声明的传输节点、12 旧调度端点和 zero/false duration/teardown 字段。每个Profile有七个方法使用真正的 Dash 拥有的 BP End 覆盖和本机清理防护。早期的直接端路由错误和未绑定的覆盖尝试仍然是失败的证据。 Standalone04 PASSes12 本机控件。 Network04 PASSes8 使用实际客户端 Cue 和本地类型的 UI 有效负载进行真实的 RPC/owner 试验。 Lifecycle03 PASSes10 原生 BP/Python root/Delay 暂停、剪辑中断、原生取消和活动Profile切换控件、测量的游戏时间边界 and5/5 范围关闭。 NetworkLifecycle03 实际权威RPC/task确认后，可通过8次二主取消/活动档案干预。范围余额为server/A/B0=4/4，2/2，2/2，所有inactive/error-free.选择器回归PASSes42对。独立gates/closedlogs/real出口通行证。 normal/lifecycle 运行 freeze1、908 输入、两个所有者生命周期 1、912。原子退出发布修复了部分 JSON 协调竞争，而不隐藏格式错误的消息。 Original/Python 原生取消可以中断两个世界的蒙太奇。复制的 End 可以取消其他世界的挂起延迟，因此门检查实际的每个世界观察而不是重放回调。2,247主机models/765-file关闭门本地提交。先前存在的本机GameplayTag弱所有者警告仍未解决。无Engine/C++build/cook/package，本机提交失败，定量movement/physical输入，网络暂停/travel/rejoin，完整的Dash/version或暗示发布接受。

Batch67 以原始公共 `Slelect Hit Montage` 助手开始近战，保留其创作的拼写、反射间隔 inputs/named 蒙太奇输出、原始命中正常、原生 Actor basis/Dot/InRange 和四个原始动画资源。保留右点[-0.5,0.5]和严格符号>0。本机MakeVector避免了传统包装构造函数在相邻双边界处的浮动变窄。 Assets01 保留 class/full CDO/three signatures/all 图和 24 节点帮助程序，registers/restores 每个 Profile 一个方法，并仅添加一个 3 节点阶段类型的外部 BP 调用程序。 Differential01 PASSes32 使用自有身份Actor和实际玩家Pawn进行原生配对，无辅助游戏状态修改，恢复Profile/specs/root/control-Actor和安静检查。 Network01 PASSes 32对，每个3个真正的本地worlds/two所有者，roles3/2/2，外国权威Health/spec不变性，发布前清理和三个服务器最后零退出。两个独立的gates/strict关闭日志都通过。本机冻结是 1、901/1、903 输入。2,284 主机models/772-file 关闭门有界本地提交。此助手不接受近战激活、trace/team/occlusion/damage/tasks/Cue 和实际的 null-Actor VM 行为。无 C++ build/cook/ package/full-version 或出版声明。继续剩下的近战身体。

Batch68 将 Melee 的实际激活移动，忽略原生 Commit 返回，首先选择equipment-index/cast/MeleeAttackMontage，并将原始原生蒙太奇task/Completed/BlendOut/Interrupted/Cancelled生命周期移动到Python。三个Profile方法保留了67 helper。七个本机传输节点添加实际受保护的结束覆盖和非网络权威跟踪条目，而不更改原始class/CDO/three接受signatures/graphs.原始native/BP跟踪，目标/team/occlusion，根运动，伤害和提示业务保留在该条目后面，明确不迁移。 Assets01和8实际独立ASCnatural/interrupt/cancel/active-Profile使用配备的AM_MM_Pistol_Melee，4/4作用域控制PASS，所有Pawn健康不变且精确的Profile/spec/config/pose/control恢复。 Network01 PASSes12 所有者requests/12 跨 2 个本地所有者的远程权威激活、干预前实际蒙太奇确认、natural/cancel/active Profile清理、外部location/velocity/active/spec/config/Profile/equipment 和所有Pawn 健康不变量。范围余额server/A/B0=6/6、3/3、3/3，不活动/无错误。辅助回归 PASS32 对独立，并且在 3 个原生世界中各有 32 个。严格独立的gates/closedlogs/real服务器最后退出通行证。独立输入1，911，网络1，915.2,324主机models/781-file封闭门有界本地提交。无 C++ build/cook/package、本机 Commit failure/no-weapon 警告奇偶校验、正版 hostile/friendly/occluded trace/damage/Cue、网络 pause/travel/rejoin/loss、完整 Melee/version 或发布声明。继续原权威trace/damage主体作为下一个业务批次。

Batch69 将权威capsule/target-ASC/team/occlusion业务移至Python，保留本机查询、GAS、根动议和所有者Cue。一个新的权威调度节点保留原始BP主体仅用于显式回退。原始的class/fullCDO/six接受的签名and4/4方法仍然存在。 Differential04 PASSes10 跨miss/no-ASC/friendly/occluded/敌对BP/Python控制的实际独立ASC请求：拒绝分支导致零damage/root/Cue。敌对造成 100 点实际生命值损害和 1 个原生根task/observed 所有者提示。原生强制options/formula，原始空的HitResult上下文和默认Cue字段被保留。现有的 const 数组本机输出 ABI 使用反射标志进行调整，而不是 Engine/C++ 更改。失败的尝试01–03 和只读ABI 诊断仍然存在。当前版本8个激活生命周期试验，32辅助对和12个二所有者无伤害requests/authority激活PASS独立gates/closedlogs/real退出。1,927每个运行时通道冻结输入。2,375主机模型和全索引关闭门有界本地提交。没有两个所有者敌对伤害、物理输入、定量运动平价、networkpause/travel/rejoin/loss、C++ build/cook/package/full-Melee/version 或出版物声明。下一批70证明了实际的两个所有者权威伤害和重复观察，然后再继续剩余的hero/weapon BP业务。

Batch70 添加了两个所有者本机权威damage/two-viewer 功能比较，而不是一般稳定性或发布验收项。当前最终的Network08/09每个PASS20真实客户端requests/authority激活，40查看器行和跨original/Pythonmiss/no-ASC/friendly/occluded/hostile路径的4个实际100伤害敌意点击。观察到本机预测mode2/authority-only跟踪、根configuration/query-derived方向、空命中上下文、唯一复制的机器人名称和激活时的零本机免疫力。两个客户都获得健康。原始的GAS本地预测键过滤准确地产生0owner/1外国Hit Cue，而不是发明的本地重播。仅阶段复制本机楼层，before/after原始处理程序读取一次，恢复observers/Profile/spec/config/poses，安静20个刻度和scopes10/10，5/5，5/5传递独立的gates/strict关闭日志/真实服务器最后退出。1,936 每次网络运行的输入。 StandaloneRegression02 PASSes10 个控件。2,423 模型和 793 文件闭包控制有界本地提交。失败 Network05/07 在友好激活之前暴露 UNRESOLVED 准备情况差异：authority/one 查看器 Health100，另一个查看器 Health0。新的本机HealthSet/ASC/canonical-Pawn诊断和两次重复的成功并不能证明修复。继续70b将initialization/replication与原始角色行为隔离。不要扩大 timeout/write 运行状况或将完整资产/版本标记为稳定。实体input/PvP头像turnover/quantitativemovement/loss/travel/rejoin/packages保持开放。没有Engine/C++构建或发布。

迁移character/input BP决策、英雄能力、fire/reload、武器实例和手榴弹。动画assets/ABPs、运动预测、物理、GAS执行和原生RPC/replication机械仍然存在。 Python 游戏决策必须保留server/client 角色和取消行为。

- [ ] 射击、重装、弹药耗尽、切换、死亡和重生通行证BP/Python在单机游戏和one-server/two-client游戏中的比较。
- [ ] 支持的能力任务、委托、取消和潜在边界具有call/lifetime回归。不支持的签名显式失败。
- [ ] 没有替换更改UObject类标识或绕过所需的权威、预测或复制检查。

<a id="0120-effects-audio-match-rules-and-ai"></a>

## 0.12.0 效果音频匹配规则和AI

状态：计划中。每个组内都会审查依赖顺序。

迁移BPeffects/audio编排和共享业务macros/functions，然后匹配阶段、scoring/notifications和ShooterAIBPtasks/services/EQS逻辑。保持 rendering/audio 引擎、动画、导航、行为树和 EQS 执行设施原生。匹配规则和表示所有权保持独立，包括专用服务器零UI行为。

- [x] Effect/audio触发，warmup/play/postgame，评分和通知与相同输入下的原始BP检查点匹配。
- [x] AI task/service 结果和取消是可重现的。长时间运行的任务不会保留已销毁的Pawn或World。
- [x] 多客户端score/phase状态，本地通知和清理一致。

<a id="0130-frontend-settings-sessions-and-replays"></a>

## 0.13.0 前端设置会话和重播

状态：计划中。 UI 父类和共享函数在子类之前迁移。

迁移游戏拥有的CommonUI小部件逻辑、前端、设置、会话浏览/托管和重播演示。 CommonUI、online/session 和重播设施仍然是原生的。欢迎地图和运行时诊断候选者收到明确的scope/reachability决策。 editor/test 公用事业仍然被排除在外。

- [x] 导航、focus/back 行为、设置持久性、会话结果和重播控制通过 original-BP/Python 比较。
- [x] 重复屏幕open/close和切图恢复订阅和状态。
- [x] Failures/cancellations经过测试，仅在成功路径上不被接受。

<a id="0140-explorer-topdownarena-and-coverage-closeout"></a>

## 0.14.0 Explorer TopDownArena 和覆盖范围结束

状态：计划中。每个额外的体验都有其自己的接受场景。

迁移资源管理器interaction/inventory/StateTreeBP业务和TopDownArena炸弹、拾取物、运行时级别生成、匹配组件和UI。运行时映射生成属于此范围。编辑器几何工具没有。将完整的初始库存与实际参考和接受的替代品进行核对。

- [ ] 两种体验都通过了original-BP/Python游戏玩法、演示和适用的multi-client/local-player比较。
- [x] 每个经过审核的候选者都会被迁移、显式保留、通过检查的引用无法访问或指定的阻止程序。不存在无声的覆盖差距。
- [x] 仅配置 BP shell 和animation/editor/test 排除已记录原因。游戏项目 C++ 迁移仍然是一个单独的阶段。

[当前候选配置](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/candidate_dispositions.json)将所有246个候选者和963个原始条目与哈希绑定的本机类普查进行协调，当前declaration/dependency源和显式保留的transports/shells.原始候选者paths/order/versions保持固定。指定的 Pawn/ASC 问题和原始 NetShooter 组件差异仍然可见。这样就完成了库存处置标准，包括指定的未决问题。它不接受所有游戏分支或任何剩余版本要求。

[每个资产范围原因](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/static_scope_dispositions.json)记录了所有182个配置shell和63个保留资产。来源审查重建了原始的 491 项资产分类，并根据官方参考资料验证了所有 245 项排除的阶段文件。这仅完成了文档标准。运行时候选者和两种体验仍然需要剩余的semantic/gameplay/presentation和适用的多人游戏证据。

<a id="100-rcn--freeze-and-prove-a-release-candidate"></a>

## 1.0.0-rc.N — 冻结并证明候选版本

状态：1.0.0-rc.1于2026-11-06接受。链接的候选记录保留了确切的源对、产物、门和特定于配置的证据。

目标：验证已识别的plugin/Examples对，而不是旧的绿色报告和新来源的混合。

- [x] 冻结API和声明的支持矩阵，包括确切的UE修订版/BuildId、CPython版本、Win64目标和构建配置。
- [x] 对候选者运行完整的通用矩阵、PythonFirst、Mixin和Lyra矩阵。通过严格的诊断保留editor/standalone、同步网络、包、可见和退出后生命周期证据。
- [x] 将Development证据与Shipping分开。制作游戏1.0声明需要专用的Shippingsmoke/package门。当前的驱动程序和旧的Development运行不提供它。 DebugGame 在被宣传为经过验证之前也需要自己的证据。
- [x] 使用其固定的示例修订版和测试source/archive安装来重现干净的检出目录。验证Engine/reference资产保持不变。
- [x] 记录[候选清单](docs/Validation_History.zh-CN.md#candidate-record-template)、产物哈希、已知限制和迁移说明。验证后的code/asset更改会使受影响的证据无效并需要新的候选者。

失败的释放阻塞门意味着另一个RC，而不是成功的定义发生了变化。无需重新烹饪即可验证仅记录的更正。它们与保留的运行时产物的源关系必须保持明确。

<a id="100--stable-ue58-runtime-binding"></a>

## 1.0.0 — 稳定 UE5.8 运行时绑定

状态：于2026-11-06接受。正式的源档案和版本化包保留了已接受的RC实现以及经过验证的稳定元数据。

目标：为声明的 API 和配置提供受支持、记录的 Win64/UE5.8/CPython 3.11 绑定，并以接受的运行时 BP 迁移范围作为验证示例。这并不保证所有Lyra游戏项目C++都是Python。

退出门：每个RC要求通过，support/limitations和迁移指南与保留的产物匹配，源档案和任何可选的精确引擎二进制文件都有校验和，并且两个存储库标签都识别测试对。在已发布的表面中保持 1.x API 兼容性，并使用记录的弃用路径。额外的platforms/configurations需要自己的绿色build/runtime证据。

<a id="validation-cost-and-release-discipline"></a>

## 验证成本和发布纪律

这些是工作流程要求，而不是声称驱动程序已经自动化了每一层。

| Change/risk | 最低开发验证 |
| --- | --- |
| 仅文档 | Diff/format/link和跨文档一致性检查。没有虚幻构建 |
| 仅限Python行为 | 使用经过验证的匹配本机二进制文件进行主机测试以及受影响的实时运行场景。记录新的脚本哈希值 |
| C++/reflection/engine变化 | 受影响的增量Editor/Game构建加调用、生命周期和运行时回归 |
| Blueprint/Mixin声明变更 | 一次性阶段generation/compile，语义审计和受影响的运行时测试 |
| 发布候选版本 | 完整的相关矩阵，cook/package，对已识别的源对进行检查和退出后证据 |

迭代时选择狭窄的车道。在开始之前宣布繁重的工作。每个行为批次运行自己的BP/Python差异场景并仅更新受影响的装置。重用经过验证的匹配二进制文件进行仅限Python的更改。本机更改需要受影响的plugin/module增量构建。不要启动完整的引擎构建或cook/package作为例行迭代。候选发布package/configuration 门与批次验收保持分离。跳过标志、旧的 `full_acceptance: true` 或仅仅启动客户端都不是发布批准。不要重新生成未更改的资产或启动包进行文档审查。

插件存储库拥有通用的binding/runtimeAPIs。示例拥有演示、资产和Lyra适配器。未来的版本首先记录示例提交，然后记录核心 `Demos` gitlink，并根据测试的清单验证这两个标签。存储库分离不得引入对Lyra的核心依赖。

<a id="11-backlog"></a>

## 1.1+积压

游戏项目C++业务迁移、更广泛的platform/configuration覆盖范围和额外的reflection/networking/hot-reload功能是独立提案。每个都需要具体的用户场景、有限的所有权和接受合约。 1.0 未暗示任何内容。
