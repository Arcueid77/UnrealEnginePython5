# Lyra 联机验收方案

基线日期：2026-09-12。适用范围：UEP 0.8.0 候选版本、UE 5.8、引擎自带 CPython 3.11、Win64 Development。

本文定义执行契约；实际通过记录另见 [Validation history](Validation_History.md)。2026-09-12 已按用户授权补齐多玩家 Bridge、探针和免构建驱动，并开始真实运行；不修改引擎源码或官方 Lyra 工程，不打包。多客户端属于 0.8 联机专项的必验项，最低基线为一服两客；对应门槛同步记录在 [Roadmap](../ROADMAP.md)。

执行结果：`20260912-network-run-05` 已通过 A 层，20 阶段与四个进程最终清理完整，`multi_client_acceptance: true`。前四轮失败及修复保留在 Validation history；`full_acceptance` 仍为 false，B/C 层未跑。

## 1. 验收目标与边界

完成“一台本机独立服务器 + 两个独立客户端 A/B”的自动验收。两个客户端必须是独立 UE 进程，不是同一进程里的两个 Pawn、AI bot 或分屏玩家。必须证明：

- 客户端真正加入 Lyra 对局，具备正确的网络角色、Pawn、PlayerState、ASC 和 Health。
- Python 在服务器上通过受限桥接接口精确选择 A/B 驱动 Lyra GAS，各客户端通过 UE 原生复制收到自己的血量变化；另一人的 Health 和本地 HUD 不被串改。
- 两个客户端的 Python HUD 分别只订阅自己的当前 Pawn；重生、Experience 更换和切图不会重复创建 presenter 或遗留订阅。
- 一人退出时另一人继续正常运行；重新加入的玩家使用新连接身份，旧目标、旧 ACK、旧订阅不能误作用于新连接。
- 本轮所有启动过的进程真实退出后，Python presenter 所有的回调、状态和持有的 widget 引用归零。

这里不证明“Python 重写了 Lyra 网络层”。GAS、Health 存储与复制仍由 Lyra 原生代码负责；Python 方法调用、普通 Python 字段和 Mixin Profile 不因为本测试而获得自动 RPC 或复制能力。

验收分层如下，不能用前一层的结果替代后一层：

| 层级 | 范围 | 本方案定位 |
| --- | --- | --- |
| P：单客预检 | 本机 Dedicated Server + 1 Client，复用现有测试排除基础问题 | 可先跑的诊断，不是联机专项完成条件 |
| A：多客户端基线 | 本机 Dedicated Server + 2 Clients，目标隔离、交错命令、加入/退出/重连、HUD 生命周期 | 0.8 联机专项必须完成；缺少任一客户端证据都不通过 |
| B：补充验收 | 可见联网客户端、连续重复运行 | 独立安排，不替代 A 层 |
| C：网络环境 | 延迟、丢包、跨机器 LAN/WAN、长时间稳定性 | 有具体支持声明时再安排，当前不承诺覆盖 |
| 发布矩阵 | 同一候选版本的通用绑定、Standalone、联机、渲染和打包 | 另按 Roadmap 执行；A 通过不代表整个 0.8 可发布 |

现有 `Package` 跑的是打包后的 Standalone，不是打包后的服务器/客户端对；即使 `All` 通过，也不能宣称已验证“打包联机”。`Network/All` 已接入双客户端门槛；旧单客入口改名 `NetworkPrecheck`，其绿色结果不足以通过多客户端门槛。

## 2. 当前状态与阻碍

### 2.1 现有能力

| 能力 | 当前实现 | 使用限制 |
| --- | --- | --- |
| 一服一客预检 | [主验证脚本](../Validation/Run-UEP58LyraValidation.ps1) 的 `NetworkPrecheck` 模式 | 会先 staging、调用 UBT；`-Incremental` 不等于跳过构建 |
| 多客复制与生命周期探针 | [uep_lyra_network.py](../Demos/UEPLyraIntegration/Overlay/Content/Scripts/uep_lyra_network.py) | 20 个阶段、A/B0/B1 独立回执；旧 `uep_lyra_probe.py` 保留单客流程 |
| HUD 计数、最终清理与日志契约 | [LyraHUDContracts.ps1](../Validation/LyraHUDContracts.ps1) | 本轮四个进程退出后才能验收；`All` 强制检查双客专项结果 |
| 免构建联机入口 | [Run-UEP58FocusedNetworkValidation.ps1](../Validation/Run-UEP58FocusedNetworkValidation.ps1) | 要求已匹配的 stage；不执行 UBT/UAT、不修 BuildId、不生成资产 |
| HUD 资产语义审计 | [audit_hud.py](../Demos/UEPLyraIntegration/Tools/audit_hud.py) | 可由已有 Editor 执行只读审计；主脚本的 `HUDAudit` 入口仍有构建前置 |
| 多玩家伤害目标 | [UEPLyraWorldSubsystem.cpp](../Demos/UEPLyraIntegration/Plugins/UEPLyraBridge/Source/UEPLyraBridge/Private/UEPLyraWorldSubsystem.cpp) | `ApplyAuthorityHealthDeltaToPlayer` 使用当前 World 的不透明 PlayerToken；旧 local/remote API 保留歧义拒绝 |
| 多玩家快照与重生 | `CapturePlayerSnapshots`、`RequestPlayerRestart` | 每个真实 PlayerController 的身份、Pawn/Health 路径；重生也按 token 精确选玩家 |

双客入口每轮自动运行只读 HUD 审计，并将实际使用资产的前后哈希关联到本轮报告。它不直接加载有 staging/build 顶层副作用的主脚本。

### 2.2 2026-09-12 实施前的只读核对快照（历史，不是当前 BuildId）

- Core HEAD：`980587e4bf2d449a4154a7ba2b25ef500829cdc3`。
- Examples HEAD：`0395f360136070d96dd3ad17e1fb1023c4cc2595`。
- 两个工作树均有未提交修改；上述 HEAD 不能单独标识实际被测源码。
- 当前 Engine BuildId：`038ca067-a15c-47cf-a35d-073bd334643e`。
- Lyra stage、UEP 和 UEPLyraBridge 的模块 BuildId：`347adf8a-0e10-4046-9bb4-c7a62877a03a`。
- `UnrealEditor-NetCore.dll` 与 9 月 10 日证据中的哈希不同；LyraGame、UEP、UEPLyraBridge 三个 DLL 哈希仍相同。
- 对照仓库检查的 408 个 native 源文件、8 个 Python 脚本与 stage 一致。但源码一致不证明旧 DLL 与新引擎兼容。

这份实施前快照阻止了直接复用旧二进制。随后官方 UBT 完成 Bridge 的增量编译与元数据更新（5 个动作，51.06 秒）；引擎 NetCore DLL 哈希不变。编译成本独立记录，不能因后续 runner 免构建而隐去。每轮仍动态读取 BuildId 和源码/DLL 哈希，不硬编码旧值。

历史证据：

- `20260903-033426` 的旧版 server/client 均退出 0，观察到 90 和恢复 100；但缺少当前要求的审计关联及最终 `shutdown` 证据。
- `20260910-hud-native-closeout` 与 `standalone-native-final-20260910-summary.json` 覆盖最新修复的专项及 Standalone，不是联机通过记录。
- 原始记录保留在 `.build/LyraValidation/Full/Results`；解释见 [Validation history](Validation_History.md)。

## 3. 前置检查与操作边界

### 3.1 固定输入

| 项目 | 本机默认值 |
| --- | --- |
| 引擎 | `F:\UnrealEngine` |
| 只读参考工程 | `F:\LyraStarterGame\LyraStarterGame.uproject` |
| 可写验证工程 | `F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject` |
| 运行地图 | `/ShooterMaps/Maps/L_Expanse?NumBots=3` |
| Experience | `B_ShooterGame_Elimination` |
| 监听与连接 | `127.0.0.1:7788`；端口被占用时停止或显式选择空闲端口 |
| 客户端数量 | 2 个独立客户端 A/B；3 个 AI bot 只用于正常推进 Warmup，不计作网络客户端 |
| 默认运行方式 | 已有 `UnrealEditor-Cmd.exe`，服务端 `-server`，客户端各自 `-game`，三方 `-Multiprocess -NullRHI` |
| 重连子场景 | B 的首次连接 B0 正常退出，再启动 B1；最多同时 3 个 UE 进程，但整轮需要核验 4 个进程实例的退出证据 |

确定性隔离：三个 bot 仍参与原生 Warmup，但测试探针通过现有 `BrainComponent.StopLogic` 停止它们的自主战斗，避免随机开火混入 Health 断言。每阶段记录三个 brain 均未运行；不改真人 Pawn 血量、伤害免疫或 GAS 复制。该行为仅由 `-UEPLyraMultiClient` 开启，不进入普通 demo。

只使用带 `.uep-lyra-full-stage.json` 标记的验证副本；每轮创建全新结果和同步目录，再按 client/connection/phase 分区，不复用旧的 ACK 或 release 文件。

### 3.2 启动前必须完成

1. 记录两个仓库的 commit、分支、dirty 状态、相关 diff 和未跟踪测试文件的内容哈希；发布记录不能只记录 HEAD。
2. 核对 UE 版本、CPython 3.11、Engine version/modules、Lyra/UEP/Bridge 的模块记录、依赖 DLL 存在性。构建来源不清楚也必须停止，BuildId 一致只是必要条件。
3. 校验 staged native 源码、Python 脚本、配置及 overlay 资产与候选版本一致；记录实际 DLL、脚本和资产哈希。未变的资产不重新生成。
4. 检查参考 Lyra 资产哈希；不把 overlay 写回参考工程，不读取或引入内部参考绑定代码。
5. 运行当前 host tests 和契约负例，包括多客身份、旧 ACK、订阅归属和发布门槛负例。数量之外还要保留用例名、失败项和退出码。
6. 用匹配的已有 Editor 运行只读 HUD 审计，检查 Interface、Mixin Set、Profile、selector 和 AddWidgets 配置。审计结果必须对应实际使用的资产哈希。
7. 缺少资产注册表缓存时，由一个 Editor commandlet 顺序准备，再启动三个共享只读缓存的运行进程。此步骤会写 stage 缓存，不是编译或打包，也不是纯文件读取。
8. 核对端口、可用内存、磁盘与已有 UE/UBT 任务，避免共享引擎在本轮被更新；不终止其他项目进程。

测试前后再次比较引擎、插件 DLL、脚本、配置与资产哈希。运行期间发生变化则该轮来源不再可靠，不能计为通过。

### 3.3 多玩家身份与接口前置

以下能力在 Examples Bridge 与双客探针中实现，不改变 UEP 的通用复制语义：

- 为 A/B 建立可核查的身份映射：测试标签、服务端实际连接、PlayerState 标识、当前 Controller/Pawn、connection epoch 和 world generation。A/B 标签只是测试编排标签，不作为生产鉴权凭据；映射要由服务端实际对象及客户端的本地 PlayerState 共同确认，不能依赖连接先后顺序、对象名称或 controller 数组下标。
- 在 Examples 的 `UEPLyraBridge` 中增加显式目标的受限接口，优先以经过校验的服务端 Controller/PlayerState 或解析后的玩家身份定位。伤害、快照和重生都使用同一目标；必须检查对象有效性、所属 World、当前连接、Authority 和原有幅度/非致死规则。
- 现有按 local/remote 唯一匹配的接口保留；双客户端时仍应返回 `RejectedAmbiguousTarget`。不得改成“取第一个玩家”来消除歧义。
- 服务端报告改为逐玩家记录；客户端只用自己的本地玩家驱动本地 HUD。不能把服务端第一名玩家的 Health 广播填进所有客户端报告。
- command ID 包含 run/phase/peer/operation；对应 packet 同时固定 WorldToken、PlayerToken 和目标 Pawn，二者共同确定 world/connection/target 命名空间。相同 ID 重试不得再次应用；将已消费 ID 换一个目标提交也不能成为新的写入。幂等状态仍只在当前 World 内保留。
- ACK 包含 run ID、scenario、phase、world generation、connection epoch、玩家映射和关联 command ID，且写入各自目录。迟到、错端、旧 World、B0 连接遗留的 ACK 都不能满足 B1 或当前阶段的 barrier。
- 重连默认按“新连接、新 Pawn”验收，不要求恢复旧血量或保留旧 PlayerState ID。当前固定 Experience 的新 Pawn 基线要求为 100；失效 B0 目标不能被自动解析为 A 或 B1。

测试标签 A/B0/B1 来自独立进程的启动参数；客户端本地 PlayerState ID 与服务端实际 PlayerController/PlayerState 交叉匹配，不能依赖 `?Name=`（在线子系统可能覆盖昵称）。PlayerToken 映射到带 serial 的弱 Controller 引用，并在每次解析时核对当前 World 和实际 Controller 集合；World 重建、离线后旧 token 失效。这些 token 是测试定位凭据，不是客户端业务鉴权协议。

### 3.4 构建与系统设置

- 首选补一个明确不调用 UBT 的联机专项入口，复用已匹配的程序；发现不匹配立即退出，不自动修复元数据。
- 必须经官方 UBT 处理的情况，先说明预计范围：仅元数据、插件/Lyra 增量，还是涉及引擎重编译。需要扩大范围时暂停确认，不直接运行总入口试探。
- 不手改 BuildId/GUID，不把 `-WriteOutdatedActions` 当成绝对无副作用 dry-run；UBT 生成动作记录也可能删除过期产物。
- 受控构建可使用 `-NoEngineChanges` 限制引擎产物变更，但不能据此声称 UBT 整体只读。当前主脚本的构建参数尚未提供这个硬限制。
- 不改 UE 源码和官方模板；本次联机专项不调用 Cook、UAT 或 Package。发布打包是另一项事先告知的工作。
- 不全局关闭 Windows 防火墙或通知，不自动开放公网/LAN 入站。先检查实际测试 exe 的现有规则；缺少策略时说明精确目标、影响和恢复方式后再处理。
- 辅助进程隐藏启动。可按已有验证约定禁用 AndroidFileServer、UdpMessaging、TcpMessaging 和 tracing 等无关监听，但不能禁用游戏 NetDriver 来“避免弹窗”。是否可连接必须由真实握手证明。

## 4. A 层：一服两客自动验收

### 4.1 确定性时序

1. 驱动启动绑定 loopback 的服务器，等待监听日志和 `UEP_LYRA_BRIDGE_ATTACHED`；启动 A，待其就绪后再启动 B0，覆盖第二玩家加入时 A 不被重置。
2. 三方建立并核对 A/B 的身份映射。各自等待真实 Experience、Pawn、ASC、Health 就绪，等待原生 Warmup/伤害免疫正常结束；不强行改写游戏阶段。
3. A、B 分别从客户端请求写入，必须返回 `RejectedNotAuthority`；两人的本地 Health 均仍为 100。服务端调用旧的歧义接口应拒绝，随后才测试显式目标接口。
4. 服务端仅对 A 减 10 血并重试同 ID。A 必须收到复制的 90 及 Python `health_changed`；B 的自身 Health/HUD 保持 100，不能订阅 A 的 Health。
5. 收到 A 的伤害观察 ACK 后恢复 A；A 观察到 100。B 为自己的未变化状态提供独立证据，不能只查看 A 的报告推断 B 正常。
6. 交换目标：仅对 B 减 20 血并恢复，B 为 100 → 80 → 100，A 保持 100。不同伤害值用于暴露错目标/错报告路由，不扩宽接口已有的 25 点上限。
7. 再交错提交 A -10、B -20，在任一恢复之前让两端分别观察到 90/80，重试各自 command ID。按各自有效 ACK 分别恢复；交换 ACK 到达顺序也不能提前放行或重复伤害。这里是 game thread 上的交错命令，不宣称多线程调用受限接口。
8. 分别对 A、B 发起 Pawn restart。目标客户端移除旧订阅并绑定新 Pawn；另一端继续就绪，自己的 Pawn/HUD 不因对方重生而被替换。
9. 服务端第一次同地图 travel 驱动 Experience 的真实 AddWidgets action 销毁/重建；第二次独立 travel 再检查一轮。A/B 都必须跟随服务器、确认新的 world generation，并各自保持唯一 presenter。
10. 保存 A/B0 已完成双客基础场景的快照后，通过 B0 专用阶段退出信号让它正常退出，并检查其最终清理。服务器和 A 继续运行，客户端数应从 2 变 1。
11. 在 B 离线期间，对 A 再做一次受限伤害/恢复，验证 A 仍正常；对旧 B0 目标的操作必须拒绝，不能误落到现在唯一剩下的 A。
12. 启动 B1 重新加入，分配新 connection epoch。确认新的 Pawn/HUD 和订阅后，再只对 B1 执行伤害/恢复；A 保持正常。旧 B0 对象与 ACK 均不能作用于 B1。
13. 服务器、A、B1 满足所有当前阶段条件后，驱动才写最终 release 信号。B0 是已经结算的旧参与者，不能拿它的 ready 替代 B1，也不能一直等待已经退出的 B0。
14. 检查本轮全部 4 个进程实例的真实退出和最终报告，再汇总三方状态及全部场景；不能只检查最后留下的服务器和某一个客户端。

同步目录的 JSON 只用于测试编排和记录“另一端已经观察到什么”。它不能写入客户端 Health，不能代替 UE 网络复制，更不能替代业务 RPC。每次 ACK 都必须由该端对真实 UObject 的读取和 delegate 事件触发。

这里通过 Experience 更换触发 AddWidgets action 的生命周期，不宣称验证了 ShooterCore 插件在原地完整热卸载/重载；两次同地图 travel 也不等于所有跨地图、seamless travel 路径均已覆盖。

### 4.2 用例与通过标准

以下是硬性目标标准；实现存在不等于当前候选已通过。实际结果必须来自同一轮报告，不能根据代码存在自动算通过。

| ID | 场景 | 必须满足的结果 | 自动化现状 |
| --- | --- | --- | --- |
| N01 | 来源与资产 | 第 3 节检查通过；审计与实际资产匹配；测试前后无来源漂移 | runner 的动态 BuildId、源码/资产/DLL 哈希及本轮 audit |
| N02 | 连接与角色 | 双客阶段 Server 为 DedicatedServer、恰有 2 个远端人类玩家及各自 Authority Pawn；A/B 各为 Client、1 个本地玩家与 AutonomousProxy；逐玩家就绪且身份不重叠 | CapturePlayerSnapshots + 每阶段 roster/ACK |
| N03 | 客户端越权 | A/B 分别得到 `RejectedNotAuthority`，accepted/applied 均 false，无 RPC 代发；两人的 Health 未变 | authority 阶段 |
| N04 | 服务端伤害与幂等 | 明确目标后一次 Applied；相同 ID 重试不能再次减血或改到另一玩家 | 每次伤害/治疗记录原始命令和两种重复提交 |
| N05 | 客户端复制与恢复 | A 观察 100 → 90 → 100，B 观察 100 → 80 → 100；均有自己的 snapshot 和 `health_changed`，恢复晚于各自伤害 ACK | 新事件序号 + 本地 HealthComponent 路径 |
| N06 | HUD 唯一性与所有权 | A/B 各自 active presenter/reference 恰为 1/1，只绑定本地当前 Pawn；Server 始终为 0/0，无 UI 事件 | 每阶段 HUD 所有权和回调差值契约 |
| N07 | 重生/换 Pawn | A/B 分别重生；目标旧订阅移除，另一人 Pawn/Health/HUD 不被替换 | respawn_a / respawn_b |
| N08 | 两次生命周期切换 | A/B0 在两次 travel 后均至少 3 次 Construct、2 次 Destruct，活跃 presenter 仍为 1；新的 World 下身份重新确认 | travel_one / travel_two |
| N09 | 最终清理与退出 | server/A/B0/B1 所有进程实例退出 0，各自最终 `shutdown.hud` 为 0/0、绑定/解绑相等；不能跨进程拼接计数 | atexit 报告 + 进程实际退出 + 有序日志 |
| N10 | 严格失败处理 | 无 fatal/assert/unhandled exception/unexpected `Log*: Error`；缺某客户端报告、超时或异常退出都不能通过 | 共用日志断言；失败只回收本轮进程 |
| N11 | 双向目标隔离 | 只伤害 A 时 B 自身始终保持基线，反向同理；旧 role-only 接口仍拒绝歧义；过期/跨 World 目标拒绝 | 逐玩家期望值 + authority/travel/rejoin token 负例 |
| N12 | 交错命令与 ACK | 90/80 同时存在，各自幂等；反序 ACK 仍正确；错玩家、旧 World/connection、错误 command 的 ACK 不放行 | damage_both / heal_both + host 契约负例 |
| N13 | 第二人加入 | B0 加入已就绪的 A；服务器人数从 1 到 2，A 不被重置，B0 独立初始化一份 HUD | join_a / join_b |
| N14 | 单人退出不影响他人 | B0 正常退出并清理，服务器人数从 2 到 1；A 仍能完成伤害/恢复，旧 B0 目标不被重定向到 A | exit_b / damage_a_solo / heal_a_solo |
| N15 | 重连及旧状态隔离 | B1 新连接/新 Pawn，HUD 恰为 1；基于新 Pawn 初值可完成伤害/恢复；B0 的对象、ACK、回调不能被复用 | rejoin_b / damage_b1 / heal_b1；旧 token 再次拒绝 |
| N16 | 完整参与者 barrier | 每阶段预先声明参与者；少一个当前参与者就失败；所有启动过的进程实例均有最终证据 | 固定 20 阶段参与者、独立 ACK 路径、四报告交叉校验 |

计数按当前实现的账本定义核验：

- 运行期：`controller_bind_count - controller_unbind_count = active_widget_count`，Health 计数同样成立。
- 最终退出：两组差值均为 0；这里是“presenter 所有的资源归零”，不是宣称 UE 全进程内存已全部释放。
- 血量比较沿用现有契约的 0.05 容差；A 减/加 10，B 减/加 20。基线和期望值逐玩家、逐场景记录，不因失败而放宽容差或更改序列。
- 不要求跨进程 UObject 路径字符串完全相等。关联玩家、连接代次、角色、Pawn 更换和命令目标，保留各端自己的对象路径，防止误把 bot、对方或旧 Pawn 当目标。
- N08 的至少 3/2 次 Construct/Destruct 适用于经历两次 travel 的 A/B0。B1 是新进程，在没有额外 travel 时只要求完成自身初始化、唯一性与最终清理，不能借用 B0 计数充数。

最终日志顺序必须包含：

```text
UEP_LYRA_AWAITING_SHUTDOWN
  → Goodbye Python
  → UEP_LYRA_HUD_SHUTDOWN_PASSED
  → Log file closed
```

任一端只写出 `awaiting_shutdown`，或先输出 PASSED 后崩溃，都不能通过。

### 4.3 超时与失败规则

- 单客 P 层仍采用原脚本边界；A 层 server probe 的每阶段固定上限 180 秒，总运行上限 900 秒，包含进程退出等待。驱动可缩短总上限，不在测试过程中自动续期；资产 prime 上限 600 秒、audit 上限 300 秒，均在启动联机进程前串行执行。
- 准备资产缓存可能另耗时；事先记录配置，不在失败后静默延长。发现机器负载或冷启动问题，保留失败轮次，明确调整理由后开新轮次。
- 失败先保存当前状态、参与者集合、pending requirements、最后日志和各进程结果，再回收本轮记录的 PID/子进程；不按进程名批量结束所有 UnrealEditor。
- 重跑使用新目录和新 run ID；历史失败不删除，不通过无限重试掩盖问题。
- 原生伤害免疫/目标歧义属于正常安全边界，不能为了通过测试而绕过。正常 Warmup 后仍不能完成时，记录阻塞阶段并定位。

## 5. 已实现的执行入口

首轮启动之前需要匹配的 native 构建。之后用免构建入口执行 A 层：

```powershell
.\Validation\Run-UEP58FocusedNetworkValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\Full\Results\Network-NewRun `
    -ClientCount 2 -ServerPort 7788
```

它只接受 ClientCount=2；不调用 UBT/Cook/UAT、不自动生成资产、修改防火墙或修复 BuildId。公共进程助手在 `Validation/UEPValidationProcesses.ps1`，纯报告契约在 `uep_lyra_network_protocol.py`，离线交叉检查入口是 `Tools/validate_network_reports.py`。Windows 同步消息采用原子替换，分享锁异常最多 10 次有限重试；永久访问错误或坏 JSON 仍失败。

主入口 `Network` 和 `All` 也调用这一专项，其中 `All` 缺少双客通过结果时不再允许 full_acceptance。主入口仍有 staging/build 前置，`All` 还会打包；本次不执行它。

已有带构建的单客预检入口如下，仅供后续确认执行范围后使用；它只跑 P 层，不是多客户端验收命令，也不是免构建命令：

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -OutputRoot F:\UnrealEnginePython5\.build\LyraValidation\Full `
    -Mode NetworkPrecheck `
    -Incremental `
    -ServerPort 7788 `
    -MaxParallelActions 2 `
    -RuntimeTimeoutSeconds 180
```

不要为了联机专项改用 `-Mode All`，也不要传 `-SkipGameplaySlice` 或 `-SkipHUDSlice` 后仍声称 A 层通过。单客 `NetworkPrecheck` 保留旧诊断行为，不会满足双客门槛。

## 6. B/C 层：不替代多客基线的补充场景

这些场景先记录为未执行，不作为 A 层已经具备的能力宣传。

| 场景 | 额外准备 | 通过标准 |
| --- | --- | --- |
| 可见联网客户端 | 保留一服两客拓扑，将至少一名 client 改为非 NullRHI；记录截图、对象值和事件时序 | 本地血条及数字对应自己的复制值，不串入另一玩家；截图不能只取隔离 fixture |
| 连续重复运行 | 同一冻结来源连续 3 轮 A 层，每轮新进程/目录 | 三轮均通过，无计数增长和残留测试进程；单次通过不称为重复稳定性证明 |
| 弱网 | 查证当前 UE 的网络模拟入口，固定延迟/抖动/丢包参数、种子或可复现设置，保留无模拟对照组 | 在事先声明的环境和时间预算内恢复一致；只承诺已测参数，失败不临时放宽门槛 |
| 跨机器 / WAN | 第二台获授权机器、同源程序与内容、非共享目录的测试协调方式，以及明确的网络/防火墙策略 | 两台真实机器的角色、复制和清理证据闭合；本机 loopback 不能替代 |
| 打包联机 | 明确服务器/客户端构建配置和目标，另行批准构建/打包成本 | 实际打包 exe 组成一服两客并重复 A 层；现有 packaged Standalone 不能代替 |

双客户端、目标隔离、第二人加入、正常退出与重连已经是 A 层必验项，不再列为扩展。4 个或更多客户端、Listen Server、分屏、异常断网恢复与压力测试仍需要独立场景和支持声明。

移动、开火、命中、死亡、计分属于更完整的多人玩法验收，不由当前血条专项自动覆盖。若安排真实死亡，使用 Lyra 原生玩法或另行设计的隔离 fixture，不放宽现有非致死桥接来制造死亡。

0.8 必需的伤害/治疗/死亡/重生渲染回归仍按 [HUD 专项文档](Lyra_Python_HUD_0.8.0.md) 执行；当前隔离 UMG fixture 不接入真实 Pawn/ASC，不能作为联机复制证据。

## 7. 证据、结论与交付

### 7.1 每轮证据

分别保留 `server`、`client-A`、`client-B0`、`client-B1` 的 JSON、Unreal log、stdout、退出码与耗时，以及各自的 ACK、阶段 release、就绪和最终清理快照。PID、启动参数、run ID、连接/World 身份映射和哈希写入统一 manifest，关联 host tests、HUD audit 与各轮输出。单个 `client.json` 不能充当两个客户端的结果。

专项汇总及其关联的逐端报告记录：

- `scope: loopback-dedicated-two-clients`、`required_client_count: 2`；protocol_validation 在全部交叉检查通过后列出 N01–N16，具体证据按第 4.2 节映射到 server/A/B0/B1 的阶段记录。P 层没有多客通过标志。
- 两仓库 revision + dirty 内容标识、UE 版本/BuildId/构建来源、Python 版本、配置、脚本/资产/DLL 哈希。
- `cpp_compile_executed`、`cook_package_executed`、是否执行缓存准备、是否显示客户端窗口。
- 前置阻塞、失败轮次、未执行的 B/C 场景。
- `full_acceptance: false`；联机专项不得设置整个发布通过标志。
- 逐阶段 expected participants、实际连接人数、B0/B1 代次和所有已启动进程的最终结算；不能仅保存最后一刻的 A/B1 roster。

截图只在可见联网补测中产生，并保留原图与 SHA-256。没有渲染的 NullRHI 结果明确记为“未检查联网画面”，不借用其他运行的图片。

### 7.2 结论分类

- **Passed**：同一候选来源的一次完整 A 层，N01–N16 全部有可核查证据，A/B 独立参与，server/A/B0/B1 各进程实例退出后的契约均满足；此时才可设置 `multi_client_acceptance: true`。
- **Blocked**：启动前发现二进制不匹配、构建来源不明、端口/资源/授权条件不足；不能标成产品通过，也不直接归因为 UEP 功能缺陷。
- **Failed**：开始运行后出现断言失败、超时、异常退出、缺关键证据或来源漂移；保留原因，定位后另起新轮次。
- **Not run**：尚未执行的场景；不能用 host tests、旧报告、Standalone 或截图填补。

开发期可以记录 dirty-tree 的 Passed，但发布前必须关联到可复现的代码/资产内容；变化后的相关用例需要重跑。只有文档变化且运行输入哈希未变时，可以保留原运行证据并说明关系。

### 7.3 实施顺序与完成定义

1. 按用户授权从方案进入实现与运行；保留每次失败和后续修复的来源关系。
2. 补多玩家 Bridge/probe、免构建 Network 入口与失效负例；先验证显式目标和驱动会拒绝不可信输入。
3. 解决引擎/stage 不匹配并构建必要的 native 适配，UBT 开始前说明范围；重新固定候选来源。
4. 完成 host checks、同源 HUD audit 和缓存准备；可先跑 P 层排障，但必须继续执行完整 A 层。失败先定位，再新开轮次。
5. 输出专项报告：N01–N16 逐玩家结果、所有进程退出证据、未执行项、实际编译/打包情况。
6. 另行安排可见联网、弱网或发布矩阵；不把两客户端降级为可选，也不在执行中悄然扩到更大的压力测试。

**A 层完成的唯一结论是：该候选版本通过 Win64 Development、本机一服两客的 Lyra Health 复制、玩家目标隔离、加入/退出/重连与 Python HUD 生命周期验收。** 一服一客只能预检；A 层通过也不等于跨机器、更多客户端压力测试或打包联机通过，不自动关闭整个 0.8 发布门槛。
