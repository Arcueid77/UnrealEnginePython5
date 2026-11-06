[English](RC_API_Review_0.9.md) | [简体中文](RC_API_Review_0.9.zh-CN.md)

<a id="09-api-freeze-review"></a>

# 0.9 API 冻结审核

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

状态：已准备好在支持的库存中冻结原始 0.9 API。 Batch273 接受独立候选矩阵。此评论不会创建标签或出版物。支持的候选者是 UE 5.8 / CPython 3.11、Win64 Development。

[支持的清单](Supported_API_Inventory.zh-CN.md) 描述了其测试范围内的功能。该清单之外的旧版包装器不会从此审查中获得兼容性或正确性认证。

| 表面 | 证据与边界 |
| --- | --- |
| 解释器 | Batch268：干净的通用shared/standalone，预期异常，编辑器和真实打包的运行通过70次检查。仅最终确定拥有的解释器。 |
| UObject反射 | 每个受支持的 interpreter/runtime 模式下的 Batch268 core21 涵盖了记录的属性和反射调用案例。这是一个 fixture/type 库存，而不是所有可能的 UFunction 签名。 |
| 惰性软类输入 | Batch266 当前调用装置区分 null、加载的类和经过验证的路径输入，拒绝格式错误的路径并避免隐式加载。没有新的软引用 getter 承诺。 |
| 动态类型 | 通用核心和batch266重复PIE涵盖了记录的瞬态类型和生命周期。进程的名称保持唯一。重新启动以生成signature/type替换。 |
| 生产Mixin | Batch266 对 33 个 call/lifecycle 路径进行分类。 Batches269/271 验证受控恢复、本机 GC 和两个所有者切图。 Cached/direct 原生调用和任意重新编译仍然是显式绕过。 |
| 代表和增强输入 | 当前的通用边界运行258、三个PIE会话266和可见的第三人称267覆盖了有界可调用、句柄、输入和清理路径。 UObject 操作保留在游戏线程上。 |
| 运行时订阅 | Batches269/270/271 涵盖原生slot/possession 信号、只读采样更改和取消。类型化消息传递需要其提供的经过验证的 VM 阅读器。没有通用通配符ProcessEvent访问。 |
| Actor、World 然后退出 | 通用核心，范围ability/world比较和batch271实际本机travel/rejoin保留本机权威并请求有序关闭。没有普遍的网络稳定性声明。 |
| World查找方便 | 库存明确将get_world限制为World、Actor和ActorComponent。 Explorer 的反射上下文操作不会将这种便利性 API 扩展到任意 UObject 类型。 |
| 编辑、资产和Slate | Batch268 的新 Editor5 保留了其实际的仅限编辑器的边界。独特的测试资产与其证据一起保留，而不是删除或重复使用以前的文件。 |
| 构造提取 | Batch266 的编辑器创作的零参数 Actor clone/virtual 帮助程序是显式创作支持。它不会拦截每个父路径或本机路径。 |
| 实验性 BP 主体脚本 | Batch266 测试单独的有界 int/bool 夹具。它不包含在生产Mixin 支持和RC 稳定性承诺中。 |

编号账本位于 [Migration/Acceptance](https://github.com/Arcueid77/UnrealEnginePython5Examples/tree/dev/release-1.0.0/UEPLyraIntegration/Migration/Acceptance)。每个都保留自己的执行配置、source/binary指纹和限制。此处的引用不会将旧的捕获转换为新的运行时运行。

<a id="source-table-compatibility-check"></a>

## 源表兼容性检查

将连续检查点 `e1199d2b02937bbddb947d660916a2c5c6b55464` 与 [UEPyModule.cpp](../Source/UnrealEnginePython/Private/UEPyModule.cpp) 中的当前源表进行比较。模块表保留 213 个条目，UObject 方法表保留 462 个条目。两个表中的名称、函数表达式和方法标志均未更改。

这会检查源注册表，包括它们的条件条目。它并不验证每个遗留包装器、C++ ABI、参数转换、行为或平台。本地回归证据提供支持的行为检查。仅靠来源比较并不能取代它们。

<a id="migration-and-deprecation-decisions"></a>

## 迁移和弃用决定

将 register_mixin 和 mixin 装饰器保留为兼容的单Profile形式。命名Profile和 Mixin 设置添加选择而不替换生成的 BP 类。成功或异常的Python回调不得默默地落入原始BP主体。调用矩阵分别记录显式组合、后备、有意拒绝的签名和本机绕过。

在受控重新加载或资产创作之前关闭订阅并取消注册。当需要新的生命周期事件时重新创建小部件。注册永远不会重播事件。在测量生命周期之前，本机 GC 请求会穿过引擎帧。生成的类型或签名需要重新启动进程。

该候选者没有删除任何公共方法表条目。未来的弃用必须命名旧的 API、替换版本、受影响的示例和删除版本，并提供该版本之前的兼容性路径。实验表面不能默默地成为受支持的游戏依赖项。

<a id="known-correctness-findings-and-disposition"></a>

## 已知的正确性结果和处置

引导程序临时 UTF-8 转换生命周期缺陷已在 SDK236 中修复。当前候选单元使用其确切的编辑器SDK，或从相同的当前本地源构建的游戏。两个实际的第三人称游戏变体都在batch272中进行了验证。旧5.8.0产品仅保留作为历史证据。

Lyra 模拟代理初始化竞赛是一个外部游戏 C++ 发现。接受的候选者需要来自batch246的用户批准的隔离八行Hero初始化防护。该批次记录了 12 次守卫等待、40 次权威交互、80 次查看者检查，并且没有空绑定的规范就绪Pawn。当前本地weapon/network接受保留了守卫。官方Lyra源仍未修补，其原始发现仍然开放。这篇评论并不声称未打补丁的检出目录可以满足要求。

原始NetShootermulticast/replicated-component差异保留在batch97和候选配置中。这是一个原始的0.11原生游戏基线差异，具有显式保留的原生边界。它不会改变生产Mixin/API冻结契约或获得一揽子修复索赔。

在这些明确的处置之后，经过审查的受支持的API目前没有发现任何阻碍发布的正确性缺陷。这是一个范围审查，而不是证明未知缺陷或不受支持的遗留包装器不可能存在。完全接受Explorer/TopDownArena，其他platforms/configurations和发布出版物保留自己的大门。此处未创建 RC 标签或版本。
