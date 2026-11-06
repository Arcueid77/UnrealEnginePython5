[English](Lyra_Integration_0.4.0.md) | [简体中文](Lyra_Integration_0.4.0.zh-CN.md)

<a id="lyra-integration-boundary-for-040"></a>

# Lyra 0.4.0 的积分边界

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

<a id="current-status"></a>

## 目前状态

使用引擎捆绑的 CPython 3.11.8 来实施和验证源集成Unreal Engine 5.8.0。 `F:\LyraStarterGame\LyraStarterGame.uproject`完整的外部项目通过了严格的source/content准备，真正的单机游戏，dedicated-server/client权威和复制，Win64cook/package和打包的游戏。版本 0.4.0 保持 Lyra 的权威性，并且仅公开下述的狭隘观察结果。

`UEPLyraBridge` 与此存储库的 demo/validation 材料一起存在，并复制到`.build` 下的一次性项目中。 Unreal Engine 源和 Lyra 参考树均未编辑。一次性描述符仅禁用桌面`AndroidFileServer`。编译完整的编辑器目标后，runtime/package通道还会禁用仅测试的`ShooterTests`和`RuntimeTests`，因此游戏证据涵盖了生产功能。 ShooterTests 内容仍处于上演状态并经过准备验证。生产Lyra游戏功能仍然启用。运行时启动使用确定性英语文化，因为UE5.8的启动核心冒烟测试会比较源语言UnifiedError字符串，并在中文本地化后虚假失败。 Fatal/assert/`Log*: Error` 过滤仍然严格。

<a id="capability-audit"></a>

## 能力审核

| Lyra边界 | 原住民业主 | Python 0.4 中的扩展 | 规则 |
| --- | --- | --- | --- |
| 经验负荷 | `ULyraExperienceManagerComponent` 及其本机多播委托 | 桥发出`OnExperienceReady`并报告当前的体验 | Python观察完成。它从不调用`SetCurrentExperience` |
| 游戏特色 | 体验行动和`UGameFeaturesSubsystem` | 快照列表功能names/states | Python 不加载、激活、停用或卸载功能 |
| 模块化游戏玩法 | `UGameFrameworkComponentManager`、Pawn/Hero 初始化状态 | Python等待世界桥和Lyra就绪信号存在 | 无轮询写入或强制初始状态转换 |
| 增强输入 | `ULyraHeroComponent` 和 Lyra 输入配置 | 快照报告`IsReadyToBindInputs()` | Lyra拥有mappings/bindings。验证不会注入权威的游戏输入 |
| 游戏能力系统 | PlayerState ASC 和 `ULyraPawnExtensionComponent` | 快照报告 pawn 是否有初始化的 ASC | 能力授予、效果和游戏标签仍然由权威拥有 |
| 资产管理 | `ULyraAssetManager`，主要资产和经验包 | 运行前准备情况检查关键资产 | Python 不同步制造或替换缺失的主要资产 |
| 多人游戏 | GameMode/GameState/PlayerState 复制 | 快照报告local/remote控制器计数、PlayerStatecount/readiness、网络模式、权威和典当角色 | 服务器保持权威。桥梁场源自当地观测结果，不会被复制 |

几个重要的 Lyra 回调是本机 C++ 委托，而不是反映的动态委托。通过猜测 Python 的内存布局来绑定它们是脆弱的。该桥在 C++ 中绑定那些 APIs，遵循 `UWorld` 生命周期，仅公开反射的 values/events，并且不会添加从 Lyra 返回到 UEP 的依赖关系。

<a id="thread-lifetime-and-reload-contract"></a>

## 线程、生命周期和重新加载合约

- 桥接调用和UObject访问仅发生在Unreal的游戏线程上。
- 每个受支持的Game/PIE/GamePreview世界都存在一个桥接子系统。
- 桥会观察`GameStateSetEvent`，因此在世界开始播放后收到其`GameState`的客户端仍然会连接到体验管理器。
- Experience 回调使用 UObject 绑定的原生委托，因此无法通过悬空原始对象调用已销毁的子系统。
- Python 存储其确切的可调用对象，在世界替换或关闭之前将其解除绑定，并且不将任何字节码缓存写入暂存内容。
- `ClearPythonListeners` 仅影响桥拥有的动态事件。它不会改变Lyra委托或游戏状态。
- 没有桥属性被复制，也没有桥函数执行权威敏感的修改。

<a id="automated-evidence"></a>

## 自动证据

`Validation/Run-UEP58LyraSourceValidation.ps1` 创建一个受标记保护的阶段，仅复制 source/config/plugin 文件，注入 UEP 和桥，并在阶段内应用仅源配置覆盖。产生干净的结果`20260811-165230`：

- `LyraEditor` 在 192.502 秒内构建退出 0。
- 运行时在38.914秒内退出0。
- CPython3.11.8，独立游戏世界，游戏线程快照和12刻度。
- bridge/script/pass 标记，后跟对象子系统闭包、`Goodbye Python` 和日志闭包。
- 零编译器，fatal/assert和`Log*: Error`诊断。和
- 运行期间Unreal Engine源代码修改为零。

最终源结果`20260811-183357`重建UEP，反映的网络快照和后期`GameState`生命周期到UBT。它通过了12-tick独立门，然后在UDP7789上运行第二个30-tick`DedicatedServer`并证明`unreal_engine.request_exit()`产生退出代码0，对象子系统和Python关闭，以及零致命或`Log*: Error`诊断。通用回归`20260811-184425`通过了70/70跨两种解释器模式、编辑器、UATcook/package和打包的CPython3.11.8运行时所需的检查。

仅源阶段有意使用 `/Engine/Maps/Entry`，基础资产管理器，并且没有 Lyra 内容支持的游戏功能插件。这是兼容性测试，而不是游戏证据。

历史`Validation/Test-UEP58LyraReadiness.ps1`结果`20260811-184203`报告本地Git源示例已被正确阻止：

- UE 5.8.0 和 CPython 3.11.8 准备就绪。
- Lyra project/targets/config 和五个显式注册游戏功能插件描述符已准备就绪。
- 零项目assets/maps。和
- 缺少基础GameData、front-end/editor/gameplay地图和所有五个根GameFeatureData资产。

完整项目结果`20260812-005352`和完整驱动程序就绪结果`20260812-013646`现在报告`status: ready`针对UE5.8.0、CPython3.11.8，所有五个显式注册游戏功能插件， 2,837 基础项目资源、三个基础项目地图和每个关键的虚幻包。游戏功能内容添加了另一个5,746资产和17地图。

`Validation/Run-UEP58LyraValidation.ps1` 将发布接受编码为单个 `All` 通道：严格准备、隔离的完整项目暂存、干净的编辑器构建、真正的独立 Experience/Game Feature/pawn/input/GAS 准备就绪、专用server/client 权威和具有明确两个角色的复制玩家生命周期ready/release握手，Win64做饭打包，打包CPython玩法。负面结果`20260811-184148`在暂存之前拒绝了本地源样本，所有11内容拦截器都保存在JSON中。

<a id="040-acceptance-contract-and-evidence"></a>

## 0.4.0验收契约及证据

在 Unreal Engine 源签出之外使用完整的 Launcher/Marketplace Lyra 项目。请勿将 Marketplace 内容复制到 `F:\UnrealEngine`。完整的外部项目可用。发布契约要求：

1. 严格准备真实基地和游戏特色内容。
2. 清理编辑器build/startup，参考内容不变。
3. 真实体验完成，`ShooterCore`活跃且仅限内容`ShooterMaps`至少已注册。
4. 具有 Lyra 增强输入和 ASC 就绪状态的本地 pawn。
5. 单独的server/client结果证明正确的网络模式、权威和复制的玩家生命周期。
6. Win64 cook/package 并打包UEP拥有的CPython 3.11执行。和
7. 有序关闭，没有编译器、fatal/assert 或意外错误诊断。

就绪结果`20260812-013646`通过了项目1。预发布`All`结果`20260812-025232`通过了项目1–5并完成了完整的Win64BuildCookRun和UATExitCode0。然后，在打包启动之前，其受保护的存档后检查会暴露出错误的假定内部可执行目录。更正驱动程序以使用UAT的真实`LyraStarterGame`布局加上经过哈希验证的稳定防火墙身份后，严格打包的结果`20260812-042711-packaged-resume`在同一产物上通过了项目6–7：CPython3.11.8，预期的体验， Pawn/Input/ASC、active/registered 游戏功能状态、有序关闭和归零 fatal/assert 或 `Log*: Error` 诊断。

最终命名的发布代码门是提交`c797d56`，结果`20260812-051532`。一次`All`调用重复了所有七个项目并写入`full_acceptance: true`：UE5.8.0，CPython3.11.8，4,046熟包，独立和打包Input/ASC 准备就绪，同步客户端和DedicatedServer authority/replication，零进程失败或严格日志错误，并匹配archived/tested可执行文件SHA-256值。
