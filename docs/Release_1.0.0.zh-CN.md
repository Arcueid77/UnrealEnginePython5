[English](Release_1.0.0.md) | [简体中文](Release_1.0.0.zh-CN.md)

<a id="unrealenginepython-100"></a>

# UnrealEnginePython 1.0.0

稳定版面向 Unreal Engine 5.8.1、引擎自带的 CPython 3.11.8，以及 Win64 Development/Shipping。它基于已通过验收的 [1.0.0-rc.1 候选版](Release_1.0.0-rc.1.zh-CN.md)转为正式发布。

SDK 实现及匹配的 Examples 源码采用已验收候选版的内容。转正时将插件版本设为 `1.0.0`，数字版本升至 1001，并清除 Beta 标志。正式产物及打包运行时的版本检查标识了最终标签对应的源码组合。

支持的 API、所有权、线程及重载规则由[受支持 API 清单](Supported_API_Inventory.zh-CN.md)、[Mixin API](Mixin_API.zh-CN.md)、[生命周期契约](Lifecycle_Threading_API.zh-CN.md)及[运行时订阅](Runtime_Subscriptions_API.zh-CN.md)规定。

源码发布包含插件及匹配的 Examples 归档、验证证据和 SHA256SUMS。各构建配置的结果及候选版负载边界记录在关联的候选版报告中。

正式版验证于 2026-11-06 通过。Shipping 游戏包通过 13 项异常恢复、正常前端流程、实际包内 Python 来源及 4,578 项依赖检查。两种带渲染的 Third Person 游戏包均报告 `1.0.0`，生成全部 6 张预期图像，并完成生命周期恢复后退出。完整记录见 [validation.json](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/Releases/1.0.0/validation.json)。

通过实现一致性核验后，稳定版承接候选版已通过的 5,866 项源码检查、70 项通用原生检查、11 条 Mixin 调用路径、3 次 PIE 会话及 16 份独立 Lyra 客户端观测。受保护的引擎和参考工程产物具有与验收记录一致的指纹。
