[English](Release_1.0.0-rc.1.md) | [简体中文](Release_1.0.0-rc.1.zh-CN.md)

<a id="unrealenginepython-100-rc1"></a>

# UnrealEnginePython 1.0.0-rc.1

候选版面向 Unreal Engine 5.8.1、引擎自带 CPython 3.11 和 Win64。候选版保留 Beta 标志，Development 和 Shipping 分别记录验证结果。

已验收的迁移基线包含原定 22 项 Blueprint 条件、30 个游戏 C++ 候选组，其中 29 组为生产替换、1 组为能力验证，另有 H01–H05 及真实 Escape/Menu 输入。候选版增加了受支持 API 冻结、当前 Core/解释器测试、Shipping 源码构建及 Cook 运行验收、源码归档安装与发布产物校验。

候选版验证于 2026-11-06 通过，完整证据见 [validation.json](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/Releases/1.0.0-rc.1/validation.json)。

| 验收项 | 已通过结果 |
| --- | --- |
| 索引源码 | 5,866 项宿主检查，检查 2,027 个 Python 文件 |
| 受支持 API | 保留 213 个模块及 462 个 UObject 注册名 |
| 通用运行时 | 6 组原生测试、70 项检查，覆盖共享及独立解释器、异常、编辑器与实际游戏包 |
| Mixin | 11 条调用矩阵路径，连续 3 次 PIE 及最终清理 |
| Third Person | PythonFirst 与 Mixin 均通过带渲染的编辑器及游戏包运行，共 6 张包内截图 |
| Lyra Development | 重新 Cook，每条 Damage/Pawn 路径有两个远端客户端，共 8 次权威端试验及 16 份独立客户端观测 |
| Lyra Shipping | 从源码归档安装，1,151 个构建动作，实际 Cook/归档，13 项异常恢复和正常前端流程 |
| 运行时来源 | 核验实际包内 Python DLL/home 及 4,578 个收据文件 |

Shipping 源码构建耗时 11,524.80 秒，各受核对的构建输出均位于隔离工程。受保护的引擎二进制、清单及官方参考输入具有与记录一致的指纹。

Editor 工具及 Development Lyra 游戏产物复用经过原生源码一致性核验的既有产物。Development 的候选内容重新 Cook，并实际重跑联机路径。Shipping 从安装后的源码归档完整编译该配置。

Git 源码归档使用 LF，Windows 检出文本可使用 CRLF。安装记录了 139 处严格的纯换行差异，并对二进制及其他内容采用严格哈希核验。最初失败的归档落地尝试也保留在证据中。

Shipping 按引擎默认策略启动已配置前端，地图切换通过前端调用原生 `GameplayStatics.OpenLevel` 完成。显式启用的玩法验证采用该流程，原先等待地图的尝试也已留档。最终游戏包通过全部 13 项恢复检查并正常退出。

首个带渲染的 Mixin 游戏包暴露了 smoke 夹具对启动渲染卡顿的计时缺陷。观察窗口改为从原生按键送达后开始，并跨过原生帧，同时采用原有移动阈值。修正后，编辑器与游戏包渲染检查均通过。完整源码检查还修复了缺失的快照文档、本地化 PowerShell 错误解码和历史完成状态及启动断言。失败捕获也保留在记录中。

发布产物由插件源码归档、Examples 归档、验证清单和 SHA256SUMS 组成，两个仓库的标签标识最终源码组合。

限定为 20 分钟的 H02 运行记录了约 207 MiB 私有内存增长，位于预先声明的 256 MiB 预算内。H05 合成负载每帧额外执行 200 次规则查询，测量 Python 的额外 GameThread/CPU 成本。关联迁移账本记录了时长、负载及结果，平台矩阵列出了本次接受的构建配置。

支持契约见[受支持 API 清单](Supported_API_Inventory.zh-CN.md)、[Mixin API](Mixin_API.zh-CN.md)、[生命周期与线程](Lifecycle_Threading_API.zh-CN.md)及[运行时订阅](Runtime_Subscriptions_API.zh-CN.md)，其中规定了可调用签名、所有权、重载及游戏线程边界。
