[English](Wrapper_Audit_0.3.0.md) | [简体中文](Wrapper_Audit_0.3.0.zh-CN.md)

<a id="ue5-wrapper-audit-for-030"></a>

# UE5 0.3.0 的包装审核

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

0.3.0 审计将实际的 UE5.8 调用与仅编译覆盖区分开来。该表记录了每个目标包装区域的自动释放测试。

| 面积 | 运行时证据 | 范围边界 |
| --- | --- | --- |
| Editor/UObject | 在编辑器世界中生成、调用并销毁`UEPValidationActor` | 无人值守NullRHI编辑器 |
| 资产 | 创建、保存和重新加载材质和关卡序列 | 测试文件仅存在于受保护的暂存项目中 |
| 动画 | 构造`AnimSequence`，查询其骨架并通过反射深拷贝往返`BlendSpace`参数 | 不主张导入的骨骼动画创作平价 |
| Slate | 创建list/tree/combo小部件并验证准确的Python项目引用acquire/release | 无头ownership/lifetime，非视觉造型 |
| 音序器 | Create/save 关卡序列。 add/list/remove 主音轨。 add/list 一段。 create/list 文件夹。设定范围 | 编辑器资产API，而不是playback/render输出 |
| 网络 | 将非阻塞UDP套接字绑定到环回，start/stop其接收者线程，关闭两次并拒绝关闭后重新启动 | 无外部网络、复制或Python接收回调声明 |

对应的案例在`Validation/UEP58Host/Tests/core_validation.py`和`Validation/UEP58Host/Tests/editor_validation.py`。 Compile/link 验证仍然涵盖所有插件模块，但上面未列出的模块不能仅通过编译获得行为支持声明。

这里的网络意味着旧版 `FSocket` 包装器的本地生命周期。虚幻多人游戏权威、RPC语义和复制是独立的系统，并且仍然是Lyra时代作品的一部分。

组合打包审核还在动态`FString`调用帧压力之前运行动画往返。此顺序是有意为之：它在关闭期间将旧的浅层`FBlendParameter`副本复制为退出代码`777003`。固定门需要进程退出代码 0 加上 `Object subsystem successfully closed`、`Goodbye Python` 和 `Log file closed` 标记，因此预关闭 JSON 传递无法隐藏析构函数时间损坏。
