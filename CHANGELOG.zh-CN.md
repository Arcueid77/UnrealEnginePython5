[English](CHANGELOG.md) | [简体中文](CHANGELOG.zh-CN.md)

<a id="changelog"></a>

# 变更日志

该文件记录了此存储库中维护的UE5端口。历史 UE4 项目历史记录在 Git 中仍然可用。

<a id="100---2026-11-06"></a>

## [1.0.0] - 2026-11-06

- 将已接受的1.0.0-rc.1实施提升为稳定的元数据、数字版本1001和清除的Beta标志。
- 重新验证正式的 Shipping 包、十三个恢复案例、前端、打包的 Python 位置以及渲染的第三人称游戏包。
- 验证运行时版本`1.0.0`、源等效候选出处、校验和source/Examples存档和匹配的存储库标签。

<a id="100-rc1---2026-11-06"></a>

## [1.0.0-rc.1] - 2026-11-06

- 冻结第一个 1.0 候选版本的记录的 UE5.8.1 / CPython3.11 Win64 API 表面和支持矩阵。
- 集成已接受的原始Blueprint迁移，三十个选定的游戏-C++候选者和H01-H05。保留与完成记录相关联的源绑定native/runtime证据和实际Escape/Menu验收。
- 添加受保护的 Shipping build/package 控件、source/archive 安装来源和特定于候选者的 runtime/dependency 检查。
- 正确的源测试快照依赖性、本地化的PowerShell错误解码和完整的RC套件发现的历史completion/bootstrap断言。
- 通过5,866源检查、70个检查通用矩阵、11个Mixin调用通道、三个PIE会话、渲染的PythonFirst/Mixin游戏包、当前Lyra两个客户端通道和完整的Shipping package/runtime 门。
- 将选择加入Shipping验证适应本机前端到游戏切图，并在密钥传递后开始渲染运动烟雾计时。

<a id="0110---development-batches-not-a-release"></a>

## [0.11.0] - Development 批次，而非版本

- 保留级Python决策现在已经为共享Jump/Widget/ADS/Emote系列、快速栏事件、死亡、化妆品、自动重新加载、英雄治疗、drop/reload政策、设备演示、生成效果和设备颜色软件评估提供了有限的本地证据。原生GAS，运动、动画、库存、复制和通用插件保持原生。
- 共享 Widget parent/Profile 资产及其所有相关实现均已提交。每批次证据记录准确的范围、隔离的分阶段树测试、本机二进制哈希值和报告哈希值。历史结果不会提升到当前 DLL 重新运行。整个0.10/0.11迁移和发布大门保持开放。请参阅示例进度和验收分类帐。
- 回填之前接受的工作作为单独的本地modify/verify/commit批次。保留失败的运行并保留未完成的持有小部件草稿未提交。此工作流程不授权推送、标记、发布或新引擎构建。

<a id="0100---development-pilots"></a>

## [0.10.0] - Development 飞行员

- 修复原生稀疏`TMap`读取：遍历占用的槽范围而不是活动元素计数，因此Blueprint`Map_Remove`不再使UEP省略后面的有效对。六个原生原始BPremoval/export比较传递UE5.8.1以及当前的19阶段网络和重复的核心生命周期门。整个版本的接受和发布仍然开放。
- 将原始健康栏`Health Changed`、`OnPosessedPawnChanged`和`EventOnEliminated`入口点路由到Python，包括原生委托和动画完成入口。重复19-stage/two-client回归和单独的真实UMGanimation/Profile-switch测试通过。没有资产重新调整。
- 保留级弹药条十字线和触摸 FireButton Profile，具有持久的 Interface/CDO 配置。消防意图调用本机增强输入。没有ammo/inventory/GAS/replication重写。
- 更正了双客户端本机 weapon/HUD 回归过程 19 阶段、行程、Pawn/weapon 替换、exit/rejoin 和零最终范围。弹药条是一个明确测试拥有的覆盖层，而不是声称的原始默认十字线。物理接触和新资产包证明仍然开放。
- 从ASC0/0恢复健康UI，然后发出100/100属性通知。渲染的health/Profile回归和111示例主机测试通过。
- 测试目标使用显式的FRotator字段。架构4验证Pitch=80/Roll=0和每个所有者的实际numeric/material健康状况。之前的纯数字通行证不会追溯升级为经过校正的视觉校样。
- 效果垫parent/unchanged子通行证构造和真实collision/nativeGASdamage/heal差异。显式父级构造使用一个父级路由器到达虚拟助手。保存下来的英国石油公司尸体仍然是后备措施。
- 仅编辑器构造提取和继承标量名称选择器重用。仅模块UEP构建和七个当前DLL调用装置通过。示例主机测试通过126。没有为这些世界飞行员构建引擎或运行cook/package。
- 其他0.10资产、networking/package大门和发布审批保持开放。官方参考资产和武器定义保持不变。
- 保留类调试扩展 Tick 使用本机扩展和精确的本机文本格式。 19-phase/two-client回归，自动Tick，非零价差，travel/rejoin和四个干净的退出通过。覆盖层明确是测试拥有的。本机audio/Editor警告和packaging/reachability间隙仍被记录。
- 生产十字线layout/geometry并键入ADS/elimination业务转移到Python。本机 VM 通配符传输使用仅示例的瘦 BP 适配器。三布局本机上下文比较、PlayerState/owner/suicide过滤、消除动画奇偶校验和最终订阅关闭过程。生产Pistol/Rifle双客户端回归，原生ADS和装备霰弹枪射击（8->5）也通过。真实击杀、网络霰弹枪、实物拾取和包裹仍然开放。后期主机测试通过148。核心订阅测试通过13。
- 保留的菜单按钮单击现在通过本机 CommonUI 异步层推送使用惰性软类路径。三个 Python/BP/Python open/close 比较，最初卸载的菜单类，干净退出和 inspected/hashed 屏幕截图传递。 Soft-class Unicode 输入具有path/NUL 验证，无需预加载。八个当前 DLL 调用装置通过。增量UEP模块仅构建，而不是引擎、游戏或打包。物理touch/input-token/cancel/network大门保持开放。
- 量产武器-十字线主机创建，clear/visibility/death业务现使用Python。八个原始 BP 比较、未更改的原生类、实时Profile保存、原生Pistol/Rifle/Shotgun 装备并注入原生死亡事件通行证。一个仅包含四节点 VM 的助手会删除旧的 BP 委托。 Nineteen-phase/two-client travel/rejoin 回归通过，最终 host/reticle 范围为零。主机测试通过170。未发生 C++ build/cook/package。物理拾取、致命伤害、网络霰弹枪和释放门保持打开状态。
- 生产能力进度将类型化的持续时间所有权、本机游戏时间countdown/text/material和完成可见性移动到Python。十二个BP/Python案例包括暂停游戏时间、隐藏Profile恢复、破坏和本机相同小部件重新安装。切图后构造幂等重新武装。原始 BP 回退会在重新启动已取消的侦听器时保留模型。 Nineteen-phase/two-client restart/travel/rejoin 和四个干净出口通过，最终 progress/reticle/host 范围为零。仅 VM 适配器现在有六个类型为 functions/eighteen 的节点。 UI/Verb、ADS 和霰弹枪回归通过。示例测试通过196。无 C++ build/cook/package 或版本。真实的交互能力产生和远程玩家持续时间消息不被声明。

- 能力失败反馈使用类型化不透明FText传输、Pythonowner/reason策略和具有显式int32链接回调的本机小部件RetriggerableDelay。十七次original-BP/runtime比较和本机en/zh-Hans/en文本身份往返传递。检查了更正的屏幕截图。实际的差异故障修复了暂停的调度和命名的布尔输出元组处理。主机检查通过237。本机GASproducer/dead-health，两个客户端完成，当前适配器回归，打包和完整批次保持开放。不暗示任何外部代码、新脚本 Tick 或 C++/Engine 构建。
- 达世币冷却政策在保留的生产类别上运行。十一次有界比较和完整的19-phase/two-client车道通行证。本机UIExtension池释放不是破坏：共享只读成员资格采样器解除非活动条目并关闭，没有最终callbacks/ticker.Windows利用reader/replacement和每帧快照竞赛进行了修复和测试。原始原生GAS Dash 提供1.5 秒的持续时间。本机death/absent-Pawn反馈检查单独通过。在该原生通道中没有ability/Health/CDO写入或合成达世币持续时间。重复的本机 Dash 不会发出面向用户的故障。它的生产者尚未经过测试。主机检查在该登机口通过了282。
- 重生计时器duration/completion策略和示例拥有的Interface/CDO资产已实施。原生0.25秒定时器，CommonNumeric，原始素材网选和音频保持原生。资产创作和290支持主机检查通过。 runtime/lifetime/network 验收仍在测试中。

<a id="090---development"></a>

## [0.9.0] - Development

- 四个保留级Pythonweapon/ammo演示器，持久的Interface/CDO选择，原始BP比较，本机QuickBar/Pawn信号和共享只读弹药采样器。 Lyra inventory/equipment/GAS/replication 保持原生。
- 通用`uep_runtime.SubscriptionScope`，用于拥有的委托和可选的游戏消息通道通知，包括disarm/cancel/error清理。
- 真实输入专用编辑器server/two-client武器接受，原生firing/reload/emptyammo/switch/respawn/travel和Bexit/rejoin。退出后需要范围平衡。打包的专用网络仍未得到验证。
- 四个实时武器Profile往返、三个reload/native-GC循环、三个PIE会话、生产signature/rejection/exception固定装置、渲染的第三人称回归和签入的call/lifecycle/API库存。
- 在 UE 的本机断言之前拒绝抽象 UClass 构造。运行时插件Content/Scripts目录现在参与打包导入。 ue_site 中缺少的依赖项保留其实际的回溯。
- 增量第三人称变体准备可恢复模板 BP shell 并删除过时的仅变体固定资产，因此 Mixin 导入不会泄漏到 Python 首次启动中。
- Win64 游戏存档和渲染的 UMG 演示通行证。失败的打包和混合的cooked/uncooked-network尝试将被保留。 CC 调用超时且没有外部审核决定。未提出release/publication索赔。

<a id="080---unreleased"></a>

## [0.8.0] - 未发布

实施已在`dev/release-0.8.0`上进行。 0.7.0 仍然是最新的标记版本。隔离渲染和交叉Actor检查通过。电流源组合release/package重新运行保持开放状态。重点关注的2026-09-12环回两个客户端网络运行通道。它不是渲染或打包的网络认证。有关释放出口的信息，请参阅[ROADMAP.md](ROADMAP.zh-CN.md)。

<a id="added"></a>

### 已添加

- 使用 0.7 保留类 Mixin 路由器和 BP 声明的 `UEPPythonMixinSet` 现有 `W_Healthbar_C` 类上的 Lyra 健康栏演示器。
- 事件驱动的Python小部件Construct/Destruct所有权，当前Pawn重新绑定，`ULyraHealthComponent.OnHealthChanged`/`OnMaxHealthChanged`，标准化运行状况和刷新时间。
- 一个`BlueprintFallback`健康栏Profile，执行保留的Blueprint构造每个实例回滚而不更改类型。
- 对同路径生命条副本和`DA_LyraHealthbarMixin`进行干净基础的分阶段创作，加上对Lyra生命条、默认/射手布局和射手HUD动作集的只读审核。
- 机器可读的HUDcounters/events用于注册、构建、销毁、委托余额、演示、Pawn替换、切图、体验拥有的游戏功能动作替换和专用服务器零UI证据。
- 无头分阶段资产注册主要步骤，其缓存文件和字节计数保留在完整内容验证摘要中。
- 二十九个主机端presenter/bootstrap/shutdown测试纯源资产缺失、精确委托身份、事件驱动渲染、Pawn替换、Blueprint回退、破坏、注册表清理和最终Python退出证据。
- 四十次PowerShell验收契约检查涵盖重复的演示者、absent/invalid清理证据、有序退出日志、无效的Mixin审核和`All`/skip-mode路由，无需启动Unreal。
- 预编译的调用者Blueprint回归路由跨Actor对两个同类实例的引用，涵盖每个实例选择、缺失方法回退、重复的Python调用（无BP失败）、Profile交换和注销后恢复。夹具仅在内存中编译。
- 专注于无构建的验证器重用标记的阶段，检查本机源和模块奇偶性，记录哈希值，并捕获 damage/heal/death/respawn. 的八个真实的 UMG 帧。仅测试运行状况读取器不会更改 GAS 或加宽非致命桥。完整的`All`包括两个新的门。
- 一个无构建的one-server/two-clientLyra网络验证器，具有显式World/Player代币、本机GAS目标选择、单独的Pawn重启、新的每个客户端委托ACKs、两次切图和B0 leave/B1 重新加入。所有四个流程实例都需要干净的Python-退出报告。 `Network/All`现在需要这个门。之前的单客户端通道保留为`NetworkPrecheck`。
- 对抗网络identity/ownership/message测试和有界Windows原子消息共享重试。选择加入探针会停止机器人大脑逻辑以隔离测试健康变化，而不改变玩家免疫力或GAS政策。

<a id="changed"></a>

### 改变了

- Lyra 叠加层现在暂存完整的内容，而不是单独的脚本，而参考 `F:\LyraStarterGame` 和 Unreal Engine 树保持不变。
- 0.5 `100 -> 90 -> 100` authority/replication 序列现在等待 Python 健康栏来观察两个真实的健康组件事件。
- 运行时commandlet会跳过 Lyra HUD/bootstrap 注册，因此瞬态路由函数无法序列化为熟资源。
- 可选的 HUD 引导程序现在将缺少内容支持的 Healthbar 视为不可用，而不是中止仅源探测，并且 HUD 审核现在验证演示者使用的确切接口、选择器、Mixin Profile、反射状态和 ShooterCore `Add Widgets` 形状。
- 启用HUD的`All`现在调用`HUDAudit`。它的 `full_acceptance` 标志需要两个切片、通过的审核、跨Actor 回归以及渲染的 HUD 检查该调用。 Skip/narrow 车道不能声称完全接受。
- 运行时报告架构5保留活动快照，写入`awaiting_shutdown`，并从纯状态Python退出回调中完成。驱动程序需要一名活跃演示者、零个最终拥有的callbacks/widget参考、单调证据计数器和有序的最终退出日志标记。
- 只读的HUD清单可以导出编写的健康栏节点引脚默认值以进行视觉原始检查，而无需编译或保存资产。
- 普通的健康变化不再重新初始化该栏或捕捉其数值。 Python 选择保留的动画，使用实际最大生命值缩放材质，根据显示值进行插值，并通过现有反射的 `OnAnimationFinished` 事件进行链式消除。取消会在停止动画之前解除旧的 Pawn/death 回调。
- 路由器清理会暂停拥有的动画，而不将其完成事件触发回不可用的路由器。实时Profile切换回归涵盖了这个边界，与普通的小部件破坏分开。
- 本机回退帧为无参数事件分配至少一个字节。 `UUserWidget::Destruct` 不再将空目的地传递给`UStruct::InitializeStruct`。跨Actor测试还执行缺失Profile无参数原生事件。

<a id="supported-boundaries"></a>

### 支持的边界

- Lyra仍拥有`ALyraHUD`、Experience/Game功能激活、CommonUIlayout/widget创建、GAS权威、游戏效果和复制。 Python 仅拥有健康呈现并重用Blueprint 视觉原语。
- 0.8 不包括QuickBar、weapon/ammo、十字线、团队得分、淘汰提要、荣誉演示或一般游戏消息订阅API。 0.9的范围为Mixin工程加上一条weapon/ammo链和有界可重用消息订阅表面。其他战斗HUD面板是1.1+积压。候选发布冻结在1.0之前。

<a id="validation"></a>

### 验证

- 2026-09-10：29 Python 和 40 PowerShell 检查通过。真正的NullRHILyra独立通过damage/heal、Pawn替换、游戏功能替换、切图和最终的零拥有状态断言。另外，预编译的交叉Actor回归和渲染的UMG夹具传递给UE5.8/CPython3.11.8.捕获的数值包括伤害`100 -> 93 -> 60`、治疗`60 -> 67 -> 100`、死亡和全生命值重生。初步检查重用的二进制文件。随后的Profile切换覆盖需要四操作增量UEP构建以实现零帧修复（24.15秒，一个CPP文件）。没有引擎源或cook/package更改。生成的模块记录是通过官方UBT修复的，而不是手动BuildId编辑。这不会关闭完整的组合释放门。
- 结束主机检查通过：17Python测试（包括实际的CPython子进程退出、泄漏绑定和跳过终结器情况）和28PowerShell检查。新的严格HUD审核和当前脚本NullRHI独立版也传递2026-09-07。活跃的HUD计数为1。最终计数为0presenters/references、3/3控制器和6/6运行状况binds/unbinds，以及有序的Python退出标记。 UBT 使用两个仅元数据操作解决了初始 BuildId 不匹配问题。无需手动 GUID 覆盖、C++ 编译、cook/package 或资产保存。 Reference/staged Healthbar 和检查的 DLL 哈希值保持不变。这是集中的证据，而不是整合的`All`、network/package或视觉接受。
- Clean-base生成结果`20260903-033001`和`20260903-033049`都生成了`W_Healthbar_C`，默认为`Python`，两个Profile和`PythonMixinProfile`。参考小部件仍然是SHA-256`7AD30080E82AF2BB2FB40DD132F632A35E3429076ABAD49A37FDFD657895CF66`。
- HUD审核结果`20260903-032632`识别真实的`LAS_ShooterGame_StandardHUD`操作集：一个`GameFeatureAction_AddWidgets`，具有1布局和11小部件条目。
- 历史`All`结果`20260903-033426`通过了当时对UE5.8.0/CPython3.11.8和`full_acceptance: true`实施的检查。单机、网络客户端和打包游戏各自观察运行状况`100 -> 90 -> 100`、Pawn替换、3构造、2破坏和平衡退出前回调快照。专用服务器创建了零HUD状态。 BuildCookRun 退出 0，严格日志已通过，且 archived/tested 可执行文件 SHA-256 值匹配。
- 该Development运行使用了NullRHI并且具有`hud_audit: null`。独立的audit/generation记录不属于`All`的覆盖范围。它早于最终引导程序fix/seventh主机测试，并且不强制执行一个演示者或关闭后零拥有的回调。 Damage/heal/death 动画和数字插值已在 2026-09-10 上单独校正和渲染。历史日志包含清理事件。这不是观察到泄漏的声明。 DebugGame 和 Shipping 未经验证。请参阅[验证历史记录](docs/Validation_History.zh-CN.md)了解保留的证据和候选项出处要求。

<a id="070---2026-08-29"></a>

## [0.7.0] - 2026-08-29

<a id="added-1"></a>

### 已添加

- 可逆的Blueprint类Python通过`register_mixin`、`mixin`装饰器、`unregister_mixin`、`unregister_all_mixins`和`get_registered_mixins`进行Mixin。
- 具有命名Profile的类级Mixin路由器，每个实例`set_mixin_profile`/`clear_mixin_profile`选择和自动保留-Blueprint后备活动Profile省略的功能。
- `UEPPythonMixinInterface` 和 `UEPPythonMixinSet` 用于带有实例选择的Profile名称的 CDO 声明的Profile集，以及加载的类发现和显式重新扫描 APIs。
- 每个UObjectMixininitialization/state和按需帮助器方法绑定，同时保留对象的原始Blueprint生成的`UClass`。
- `call_mixin_original()` 用于显式执行被混合 Python 函数隐藏的 Blueprint/native 实现。
- 将反射的 `FInputActionValue` 参数本机转换为 Python bool、float、`FVector2D` 或 `FVector` 值。
- 注册时Python签名验证。被拒绝的替换会保持当前活跃的 mixin 生成完好无损。
- 第三人称`Mixin`演示变体，保留官方Blueprint角色、控制器、GameMode、输入图和AnimBP，而同一角色类的两个实例使用不同的PythonProfile。一个Profile省略了`Move`以证明自动原始-Blueprint后备。
- 一个真正的资产创作的 Interface/Mixin 设置回归夹具，具有一个直接的 Blueprint 所有者和一个继承的子项，通过仅编辑器的 `blueprint_configure_mixin` 帮助程序确定性地生成。
- 可播放的 `DA_ThirdPersonCharacterMixin` 声明和示例拥有的同路径角色 BP 副本，其实例可编辑的 `PythonMixinProfile` 变量选择Profile而不更改 `BP_ThirdPersonCharacter_C`。

<a id="changed-1"></a>

### 改变了

- Python mixins 在 Python housekeeper/interpreter 关闭之前恢复，因此注入的函数映射不能比它们的 Python 可调用函数寿命更长。
- 第三人称运行程序现在独立地阶段和验证`Overlay`、`PythonFirst`和`Mixin`，并拥有专用的Mixinsmoke/package报告合约。
- 接口发现现在使用全构建包完成委托，并仅注册直接声明接口的Blueprint类。
- 自动缺失Profile回退会在直接分派之前将兼容的原生属性复制到保留的 UFunction 自己的帧中，即使链接偏移量不同，也保留 scalar/array 返回和常量数组输入。
- 跨越选择器、初始化器、清理、混合可调用和原始调用回调边界的注册表修改被拒绝。实例状态在回调后重新解析，而不是保留无效的容器引用。
- 编辑器创作助手现在可以使用create/reuse标量`Name`变量并将`GetPythonMixinProfile`连接到它。正常的第三人称启动从 BP 的 Mixin 集中注册普通Profile类，而直接注册仅保留为显式回归阶段。
- Cookcommandlet跳过Mixindiscovery/bootstrap并拒绝注册表修改，防止瞬态路由的`UFunction`条目被序列化为熟的Blueprint资产。注册发生在打包的运行时启动之后。

<a id="supported-boundaries-1"></a>

### 支持的边界

- 版本0.7仅允许一台路由器在Blueprint生成的类和普通实例functions/events上具有多个互斥Profile。拒绝RPC、latent 函数、static/delegate 函数、非常量output/reference 参数和有序Profile链接。
- 相关 base/derived Blueprint 类的同时注册将被拒绝，因此恢复的功能不能依赖于另一代。
- Blueprint 资产应在编辑器重新编译之前取消注册。该实现既不会更改Unreal Engine源，也不会更改已安装的第三人称模板。示例覆盖有意拥有角色 BP 的配置副本。其原始游戏玩法图表保持不变。

<a id="validation-1"></a>

### 验证

- UE5.8 重复生成结果 `20260831-012003` 和模式-4 无头 Mixin 独立结果 `20260831-012054` 传递给引擎 CPython 3.11.8。它们涵盖了可玩角色的 BP 声明的 Mixin Set/profile 变量、相同 BP 选择、Blueprint 后备、直接和声明的重新注册、最终恢复、包加载接口固定装置、本机 const-array/return 后备和带有 clean 的回调重入防护build/runtime 日志。
- 官方模板审核`20260829-225525`和现有0.6Python-首次运行时回归`20260829-225336`通过。
- Win64 打包结果 `20260831-014230` 构建编辑器和游戏目标，cooks/stages/archives 0.714 GiB 并在打包的可执行文件中传递 schema-4 合约。其Cook日志有一个命令行引导程序跳过标记、零个Mixin注册和干净严格的诊断。测试的可执行文件SHA-256是`99BFA1CC83C89CB0E5A8898839547802CAE3CBFAA87B81BB277BA8EF3B775DB5`。
- 尚未记录此树的可见客户端手动门。

<a id="060---2026-08-24"></a>

## [0.6.0] - 2026-08-24

<a id="added-2"></a>

### 已添加

- 模块化的`uep_third_person`运行时包将生成的角色、PlayerController和GameMode类型与动画、可收藏游戏、视口HUD、世界生命周期和选择加入烟雾自动化分开。
- 六人拾取的可玩回合，具有累积分数、完成倒计时、重复回合和Python驱动的同伴演员。
- 命中测试不可见的 Slate HUD 直接附加到游戏视口。 Python 更新目标、得分、计时器、速度和运动状态，无需使用屏幕调试消息或游戏玩法Blueprint。
- 主机端测试独立于虚幻的评分和回合转换状态。
- 运行时访问`get_discovered_plugins()`、`get_enabled_plugins()`、`find_plugin()`和`unreal_engine.IPlugin`，允许打包进程检查它们实际加载的插件的描述符。

<a id="changed-2"></a>

### 改变了

- `PythonFirst` 现在是演示驱动程序的默认变体。 0.1.0 Blueprint 覆盖仍然显式地可用为 `-Variant Overlay`。
- `uep_python_third_person.py` 现在是兼容性导入。正常启动加载`uep_third_person.bootstrap`，而烟雾自动化仅在其结果命令行参数存在时启动。
- 第三人称烟雾合约现在收集真实生成的回合，验证HUDconstruction/update，执行相同地图切图，验证新会话并显式检查HUD/input/runtime拆解。
- 输入门现在通过 PlayerInput 和官方映射上下文发送 `W`、`MouseX`/`MouseY` 和 `SpaceBar`，而不是直接注入 InputAction 值。
- 共享模板包现在保留其声明的 `Input`、`Characters` 和 `LevelPrototyping` 挂载根。增量暂存拒绝遗留扁平资产，因此Python和映射上下文无法静默加载不同的InputAction对象。
- 包构建直接使用`-NoUBA`调用Game目标，然后使用`-skipbuild`运行UAT。打包的 Smoke 启动内部目标可执行文件，而不是短暂的存档引导程序。
- 演示描述符禁用不可用的本地 `PlatformCrypto` 程序插件进行打包，驱动程序现在拒绝来自 UAT 和运行时日志的致命、断言、未处理的异常和 `Log*: Error` 诊断。
- 演示游戏目标禁用 Unreal Trace，防止带有时间戳的 Development 包打开 TCP 1985 控制侦听器或重复获取新的 Windows 防火墙应用程序身份。引擎源和共享UnrealEditor目标保持不变。
- 演示历史记录和工作文件现在位于`AvaloNero/UnrealEnginePython5Examples`。该存储库将该公共存储库固定为`Demos`子模块，而不是复制插件源代码树中的项目。

<a id="validation-2"></a>

### 验证

- UE 5.8 捆绑的 CPython 3.11.8 通过了所有四个纯回合状态测试，所有 16 分阶段 Python 文件解析，PowerShell 驱动程序解析和`git diff --check` 报告没有空格错误。
- 无头 UE 5.8 独立结果 `20260824-211718` 通过映射的 `W`、`MouseX`/`MouseY` 和 `SpaceBar` 传递 schema-5 合约输入：313.91运动单位，28外观度数，127.551跳跃位移单位，所有动画状态，6/6拾音器，HUD，同伴，行程和显式HUD/input/runtime释放每个键时的清理。
- UE 5.8 Blueprint 审核结果`20260824-211829` 通过了四个蓝图、27 图表和173 节点的保留参考基线。
- Win64打包结果`20260824-203312`在显式`-NoUBA`游戏构建之后在UAT中记录`Build=False`，存档1754Pak条目并在打包内传递相同的模式-5契约可执行的。严格的UAT和运行时诊断扫描均报告零释放阻塞条目。可执行文件SHA-256是`04A9CF37D82F31B6A9D6255E99841FD3D2BEEEE30BAB797F83D11C6C2F8272FD`。
- 可见的1280x720播放结果`20260824-044028`渲染PythonHUD和游戏玩法，接受物理鼠标外观和SpaceBar跳跃，并完成jump/fall/land动画序列。然后，最终禁用跟踪的包重新启动，其中有零个TCP侦听器，并且没有Windows安全选择器。没有扩大防火墙权限。

<a id="050---2026-08-13"></a>

## [0.5.0] - 2026-08-13

<a id="added-3"></a>

### 已添加

- `FUEPLyraGameplayCommandResult` 和反映的 `ApplyAuthorityHealthDelta` 命令，用于一个有界 Python 驱动的 Lyra 游戏玩法写入。 Python 拥有命令IDs、值、目标角色和排序。适配器调度 Lyra 配置的 SetByCaller Damage/Heal 游戏效果，而不是直接写入属性。
- Health/MaxHealth 和Lyra 运行时快照中的损伤免疫观察，因此Python 可以等待真正的游戏阶段，而不是绕过GAS 策略。
- 游戏线程、服务器权威、明确的玩家目标、命令格式、有限幅度、非致命伤害、非过度治疗和命令幂等性防护。
- 机器可读的Standalone/packaged状态机证明伤害、重复拒绝、后期观察、修复和恢复。
- dedicated-server/clientPython握手证明本地客户端写入被拒绝，服务器GAS更改复制到客户端，并且仅在客户端确认损坏的值后才进行恢复。

<a id="changed-3"></a>

### 改变了

- 完整的Lyra验证器默认启用0.5游戏切片，请求三个AI机器人推进Lyra的真正预热阶段，并保留`-SkipGameplaySlice`用于非发布诊断。禁用切片的情况下运行`All`无法报告`full_acceptance: true`。
- 除了固定的 UDP 端口之外，专用服务器验证还绑定到 `127.0.0.1`，从而使自动侦听器远离 LAN。
- 运行时 JSON 架构版本 2 保留了 0.4 就绪快照，并添加了严格的 PowerShell 断言使用的完整游戏玩法 command/event 证据。
- 通用 Win64 发布驱动程序现在将其有界并行操作设置和 `-NoUBA` 策略转发到 UAT 的嵌套游戏构建中，并为低内存源引擎工作站提供两小时的包超时。

<a id="validation-3"></a>

### 验证

- 增量独立结果`20260812-233341`在尊重Lyra热身伤害免疫力后通过了UE5.8.0和CPython3.11.8。它记录准确的运行状况`100 -> 90 -> 100`、`Applied`、`RejectedDuplicateCommand`、`Applied`、干净关闭和零严格错误诊断。
- 增量网络结果`20260812-233801`通过了真正的环回专用服务器和客户端。两个报告都记录了客户端的`RejectedNotAuthority`、权威应用服务器Damage/Heal命令、重复拒绝以及90和100健康状况的客户端复制观察。
- 正式`All`结果`20260812-234501`通过了完整的0.5游戏切片候选者`full_acceptance: true`。准备就绪、编辑器构建、单机、专用服务器、客户端、UAT和打包游戏全部退出0。 UAT 报告了 `BUILD SUCCESSFUL`，已存档 1.89 GiB，并且 internal/tested 可执行文件 SHA-256 值匹配。所有四个运行时日志都包含游戏过程和有序关闭标记，具有零严格的fatal/assert/`Log*: Error`诊断。
- 在目标选择器被强化以拒绝多个匹配的人类控制器后，精确源网络结果`20260813-005436`仅重建`UEPLyraBridge`并通过客户端拒绝、服务器权威、重复命令拒绝、复制和恢复。独立结果 `20260813-005835` 重用该构建并传递本地 `100 -> 90 -> 100` 序列。所有三个运行时日志均正常关闭，严格错误为零。
- 最终选择器强化后，没有启动新的Cook/package。结果`20260812-234501`仍然是最新的包级证据，而两个2026-08-13增量结果是确切来源的运行时证据。

<a id="supported-boundaries-2"></a>

### 支持的边界

- Lyra继续拥有Experience/Game功能激活、能力授予、输入、GAS执行、健康存储和复制。版本0.5不公开任意游戏效果启动器、原始属性设置器或自动客户端RPC。 Unreal Engine 和外部Lyra 参考项目保持不变。

<a id="040---2026-08-12"></a>

## [0.4.0] - 2026-08-12

<a id="added-4"></a>

### 已添加

- 一次性项目端`UEPLyraBridge`世界子系统，将Lyra的本机体验完成回调转换为反映的动态事件，并公开只读游戏功能、增强输入、能力系统、权威和网络模式快照。
- Python 生命周期探针，具有显式回调解除绑定、游戏线程检查、角色感知断言、机器可读结果和有序进程关闭。
- `unreal_engine.request_exit()` 用于优雅的游戏、commandlet和专用服务器关闭，无需本地`PlayerController`。
- 在参考项目之外运行的Lyrasource/readiness驱动程序需要UE5.8和引擎捆绑的CPython3.11，并将源兼容性与内容相关的接受区分开来。
- 严格的全内容Lyra驱动程序，涵盖隔离暂存、编辑器构建、真实Experience/Game功能就绪、独立pawn/input/GAS状态、dedicated-server/client权威和复制、Win64cook/package和打包CPython 运行时。
- local/remote 控制器、PlayerState、pawn control/roles 的网络观察字段以及显式双进程 ready/release 握手，因此在满足两个合约之前，两个网络角色都无法终止。

<a id="changed-4"></a>

### 改变了

- `PythonEditor` 项目树所有权现在使用`TObjectPtr`。一个单独的非反射原始指针视图提要Slate。这满足了Lyra严格的UE5.8本机指针目标策略而不削弱它。
- 打包验证将 `UEP58Host` 写入受保护的固定输出路径，并在每个带时间戳的结果中记录测试的可执行文件哈希，从而防止 Windows 防火墙将每次运行视为新应用程序，而无需额外的包大小的镜像副本。
- 全内容Lyra打包使用与`LyraGame`相同的受保护固定输出模型。驱动程序记录UAT的原始内部可执行文件，将其项目二进制树同步到稳定的防火墙身份，验证匹配的可执行文件SHA-256值并使用UE的`-basedir=`覆盖，以便未修改的包布局保持权威。
- 完整的 Lyra 编辑器目标编译后，gameplay/package 暂存将禁用仅测试的 `ShooterTests` 和 `RuntimeTests`，将运行时证据范围限制为生产 Lyra 功能，同时其内容保持就绪状态验证。
- Lyra Python 探针现在使用单调挂钟超时，记录其最终快照和失败时的待处理要求，并记录更改的待处理条件，而不是仅依赖于 Unreal 代码增量时间。
- 网络探针在等待共享释放门之前锁定其完全就绪的快照，从而防止一个对等点的快速关闭使另一个对等点已观察到的复制状态无效。
- Lyra 游戏功能断言现在可以区分活动游戏代码 (`ShooterCore`) 和已注册的内容所有权 (`ShooterMaps`)，匹配其实际插件描述符并观察到的UE5.8 生命周期状态。
- 运行时验证引脚`-culture=en`所以UE5。8的启动核心冒烟测试在本地化的Windows安装上保留其源语言字符串契约。严格fatal/assert/`Log*: Error`拒绝保持不变。
- 增量 Lyra 分段保留 UEP/bridge 构建输出，跳过未更改的文件并修剪过时的拥有的源。编辑器和包构建默认使用两个非UBA操作来绑定验证主机上的内存使用。

<a id="validation-4"></a>

### 验证

- 干净的源结果`20260811-165230`构建`LyraEditor`和所有分阶段的UEP模块，加载`UEPLyraBridge`，运行12独立游戏世界在CPython3.11.8上勾选并退出0 具有零编译器、致命和 `Log*: Error` 诊断。 Unreal Engine 来源保持不变。
- 最终的源回归`20260811-183357`重建了UEP以及通过UBT反射的网络快照，通过了Standalone Gate，然后证明了真正的`DedicatedServer`监听UDP7789可以干净地退出`unreal_engine.request_exit()` 零致命或`Log*: Error` 诊断。
- 完整通用UE5.8回归`20260811-184425`通过了所有70所需的共享、独立、异常边界、Editor/Slate、cook/package和打包运行时检查。打包的进程使用了​​CPython3.11.8并暴露了新的出口API。
- 最终通用UE5.8回归`20260812-043408`在发布驱动程序更改后重复所有六个套件：70/70检查通过，完整的DevelopmentBuildCookRun报告`BUILD SUCCESSFUL`和ExitCode0，稳定的打包可执行文件运行CPython3.11.8，致命或错误诊断为零。
- 准备情况结果`20260811-184203`报告源已就绪，但内容被阻止：本地LyraGit示例包含零个assets/maps并且缺少所有五个必需的GameFeatureData资产。
- 完整的外部项目就绪结果`20260812-005352`和`20260812-013646`通过了UE5.8.0、CPython3.11.8、所有五个游戏功能和每个关键的虚幻包，而无需修改参考项目。
- 全驱动器负面结果`20260811-184148`在使用11机器可读内容拦截器进行分级之前停止，证明仅源证据不能意外满足完全接受通道。
- 预发布`All`结果`20260812-025232`通过了严格的准备，增量`LyraEditor`构建，真正的单机游戏，同步的dedicated-server/client权威和复制，以及完整的Win64BuildCookRun。 UAT与`BUILD SUCCESSFUL`和ExitCode0完成了冷DDCCook、阶段和归档。然后，在启动包之前，驱动程序正确地停止在错误的假定内部可执行路径上。
- 更正该受保护的路径后，严格打包的结果`20260812-042711-packaged-resume`与原始UATBaseDir运行位相同的稳定侦听器。它通过了CPython3.11.8、经验、`ShooterCore`活动、`ShooterMaps`注册、Pawn/Input/ASC和有序关闭，且零fatal/assert或`Log*: Error`诊断。
- 命名的发布代码提交`c797d56`然后通过一个正式的`All`结果`20260812-051532`和`full_acceptance: true`中的完整通道。运行重复准备，编辑器构建，独立和同步网络角色，烘焙4,046包，存档Win64，并通过打包的游戏。每个进程都退出0、UAT，并且所有运行时日志都包含零错误诊断，并且internal/tested可执行文件SHA-256值匹配。

<a id="supported-boundaries-3"></a>

### 支持的边界

- 发布级运行时验证仅在 UE 5.8.0 上保留 Win64 以及引擎捆绑的 CPython 3.11.8。 Lyra 桥遵守本地所有权边界。它不会激活功能、授予能力、替换输入映射或改变复制的权威敏感状态。参考Lyra项目和Unreal Engine源保持不变。

<a id="030---2026-08-11"></a>

## [0.3.0] - 2026-08-11

<a id="added-5"></a>

### 已添加

- 通用反映了虚幻属性与Python`set`/`frozenset`之间的`TSet`转换，包括动态`{ElementProperty}`声明和哈希性验证。
- `unreal_engine.is_in_game_thread()` 用于显式线程策略检查。
- 单独的shared/standalone异常边界套件、动态函数压力覆盖、重复类重新加载契约检查和回调弱引用生命周期测试。
- 针对动画参数往返和本地UDP接收器生命周期的运行时包装器测试，以及针对关卡序列轨道、部分、文件夹和资产持久性的编辑器测试。
- UE5.8 平台就绪探针和自托管 Linux build/runtime 通道。在该车道出现绿色神器之前，Linux 的支持仍然无人认领。
- 提交寻址的源档案、SHA-256清单和可选的UE5.8`BuildPlugin`二进制打包。

<a id="changed-5"></a>

### 改变了

- 显式委托和增强输入解除绑定现在立即释放相应的可调用的Python，而不是保留它直到所有者垃圾回收。
- 动态Pythonconstructors/functions现在可以安全地替换可调用引用。重要的调用帧是通过反射实现的initialized/destroyed，返回值使用`FProperty::CopyCompleteValue`而不是字节副本。
- 动态类标志检查不再泄漏临时 Python 引用，并且重复的类创建仍然是需要重新启动的显式错误。
- UDP套接字包装器验证地址、端口和缓冲区，初始化其本机指针，保护关闭的套接字并支持幂等关闭。
- `BlendSpace.set_blend_parameter()` 现在深度复制反射的 `FBlendParameter`，而不是字节复制其 `FString`，从而消除了堆别名以及组合包装器和动态字符串压力运行发现的打包关闭损坏。
- 核心验证将`TSet`从已知排除中提升，并将预期的Python异常保留在专用的、严格过滤的处理通道中。

<a id="validation-5"></a>

### 验证

- Win64快速矩阵通过47检查：20共享核心、20独立核心、两项异常边界恢复检查和五项editor/Slate/Sequencer检查。
- 完整的Win64门另外在熟打包的可执行文件中运行20核心检查，总共需要检查67。完整结果`20260811-153622`通过，有序CPython/object-subsystem关闭和退出代码0。独立扫描未发现致命、编译器或意外错误诊断。
- UE5.8.0 报告本地 Linux 平台未就绪，因为未安装 `v26_clang-20.1.8-rockylinux8`。这被记录为平台限制，而不是通过的Linux结果。
- Unreal Engine来源保持不变。

<a id="known-limitations"></a>

### 已知的限制

- 动态`UClass`重定义需要重启。不支持进程内类热重载。
- UObject/reflection 操作仅在 Unreal 的游戏线程上受支持。
- Linux 有自动通道，但还没有发布级别的绿色产物。
- Lyra权威、复制和游戏功能集成从0.4.0开始。

<a id="020---2026-08-11"></a>

## [0.2.0] - 2026-08-11

<a id="added-6"></a>

### 已添加

- 基于UE5`FField`的动态Python`UClass`，反映scalar/container/object属性和`UFunction`生成，包括父事件覆盖。
- 增强的输入适配器，用于映射上下文所有权、操作绑定和删除、绑定检查、操作值转换和确定性输入注入。
- 运行时访问权威的GameMode和安全的延迟服务器切图。
- 单独上演的Python-第一个第三人称变体，其动态PythonGameMode、PlayerController和角色拥有自己的相机、移动、外观、跳跃和运动状态行为。
- 一个最小的无游戏性 C++ 示例主机目标，因此打包的源插件可以确定性地构建链接和阶段UnrealEnginePython。
- 自动化参考-Blueprint库存、无头游戏input/travel烟雾和打包Win64游戏烟雾工作流程。

<a id="changed-6"></a>

### 改变了

- 仅在安装了 Python properties/functions 和构造函数后，才重新启用 UE 5.8 的动态类生成并最终确定生成的类。
- 配置UEP拥有的隔离解释器，使其不在暂存项目或引擎脚本旁边写入字节码缓存。
- 更新了 UE5 `FFieldClass` 声明、UFunction return/input 顺序的属性发现和转换顺序，并支持 array/map/object、结构和枚举声明。
- 在 UObject 构造期间抑制编辑器属性更改通知，以便 Python 构造函数可以安全地初始化默认子对象。
- 添加了增强输入plugin/module作为显式运行时依赖项。
- 将动态class/function和增强输入生命周期案例提升到所需的核心套件中。只有通用的`TSet`编组仍然是已知的核心排除项。

<a id="validation-6"></a>

### 验证

- 共享和UEP拥有的CPython3.11核心套件通过动态反射类构造、两个输入返回函数和真正的`BlueprintNativeEvent`覆盖。
- Python-第一个第三人称烟雾验证三个活动的Python类、两个映射上下文、五个绑定、注入的movement/look/jump、相机组件、动画状态更改和相同地图切图。
- 未更改的UE5.8参考资产被审计为带有27图和173节点的四个蓝图。关卡和内容资产保持不变。
- Unreal Engine来源保持不变。

<a id="known-limitations-1"></a>

### 已知的限制

- 未实现通用 `TSet` 属性编组。
- Win64 keyboard/mouse 是发布级游戏合约。移动触摸、非Windows发布通道、网络和Lyra集成仍然是后续的里程碑。

<a id="010---2026-08-11"></a>

## [0.1.0] - 2026-08-11

<a id="added-7"></a>

### 已添加

- 可重复的UE5.8验证主机和PowerShell驱动程序涵盖编辑器、独立解释器和打包运行时执行。
- 针对核心反射、属性、容器、函数、委托、垃圾收集、Actor生命周期、资产持久性和Slate所有权的机器可读报告。
- 上演的UE5.8第三人称模板演示，带有可见的Python驱动的拾音器、乐谱波、HUD输出和移动伴侣。
- 用于发布文档、验证项目和演示源的插件打包过滤器。

<a id="changed-7"></a>

### 改变了

- 将运行时和编辑器模块从旧版UE4APIs移植到UE5.8APIs，包括`FField`/`FProperty`反射模型和当前编辑器、动画、音序器、 Slate以及插件使用的资源接口。
- 将外部Python发现和链接替换为UnrealBuildTool引擎提供的`Python3`模块和CPython3.11运行时。
- 添加了解释器所有权处理，因此 UEP 可以共享 Epic 初始化的 Python VM，或者在禁用 Epic Python 时初始化并关闭 VM 本身。
- 延迟编辑器配套模块直到引擎初始化后，以便两种解释器所有权模式加载一致。

<a id="validation-7"></a>

### 验证

- UE 5.8.0 Development 编辑器和游戏目标在 Win64 上构建和链接。
- 完整的验收运行通过了40跨共享、独立、编辑器和打包模式所需的检查CPython3.11.8。
- 第三人称烟雾测试到达游戏世界，创建所有六个拾取器，移动同伴并完成其所需的Python刻度。
- 无需修改Unreal Engine源。

<a id="known-limitations-2"></a>

### 已知的限制

- 动态Python生成的`UClass`和`UFunction`合成在为UE5的`FField`模型重建时被禁用。
- 未实现通用 `TSet` 属性编组。
- 仅Windows/Win64在0.1.0中具有发布级别验证。
- 第三人称示例在原始模板上叠加了Python游戏玩法。它尚未取代模板的 Blueprint 控制逻辑。
