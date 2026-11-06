[English](Third_Person_Mixin_Demo_0.7.0.md) | [简体中文](Third_Person_Mixin_Demo_0.7.0.zh-CN.md)

<a id="third-person-blueprint-mixin-demo-for-070"></a>

# 第三人称 Blueprint Mixin 0.7.0 演示

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

0.7演示从Unreal Engine5.8的官方Blueprint第三人称模板开始，并保留其对象路径和运行时类标识：

- `BP_ThirdPersonGameMode_C`;
- `BP_ThirdPersonPlayerController_C`。和
- `BP_ThirdPersonCharacter_C`.

角色EventGraph仍然接收增强输入操作。示例覆盖包含项目拥有的 `BP_ThirdPersonCharacter` 副本，仅添加了 UEP 接口配置：`GetPythonMixinSet`、`GetPythonMixinProfile`，以及名为 `PythonMixinProfile` 的可实例编辑的 `Name` 变量。其原始游戏玩法图表保持不变。一个 UEP 类路由器在同一字符类上公开两个 Python Profile：

| 公司简介 | Python功能 | `Move`行为 |
| --- | --- | --- |
| `Python`（默认） | `ReceiveBeginPlay`, `Move`, `Aim` | Python运动实现 |
| `BlueprintFallback` | `ReceiveBeginPlay`, `Aim` | 自动调用保存的BP`Move` |

运行时生成第二个`BP_ThirdPersonCharacter_C`，并仅针对该实例选择`BlueprintFallback`，而玩家保留`Python`。这证明Profile选择属于UObject，而不是CDO或UClass。烟雾通道还将实时玩家切换到`BlueprintFallback`，通过原始的Blueprint函数发送映射的`W`输入，然后切换回Python而不改变pawn类型。

Jump/StopJumping、相机组件、控制器映射设置和`ABP_Unarmed_C`保留Blueprint/native.Python还重用了来自0.6的六拾取器轮、移动伴侣和Slate视口HUD。

该实现位于`UEPPythonThirdPerson/Mixin`下的示例存储库中。运行程序将其放置在官方模板和当前插件的一次性副本上。正常游戏加载角色的`DA_ThirdPersonCharacterMixin`声明。Profile类是普通的Python类，而不是在启动时秘密绑定BP的装饰器。烟道单独执行显式注册API作为回归，然后将实时类返回到其声明的Mixin集合。

示例覆盖层还包括 `/Game/UEPTests` 下的一个由资产编写的小型探针：一个 `UEPPythonMixinSet`、一个直接声明 `UEPPythonMixinInterface` 的 Blueprint，以及一个继承路由器的子项 Blueprint。所有五个生成的资产都是示例拥有的。生成器在将其复制到此叠加层之前仅修改一次性暂存角色副本。它永远不会编辑`F:\UnrealEngine`、已安装的模板或Unreal Engine源。

<a id="prepare-without-compiling"></a>

## 无需编译即可准备

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Variant Mixin `
    -Mode Prepare `
    -Incremental
```

<a id="automated-runtime-proof"></a>

## 自动运行时间证明

在 reflection/API 更改后生成或刷新已提交的 Interface/Mixin 设置回归资产：

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Variant Mixin `
    -Mode GenerateMixinAssets `
    -Incremental
```

这仅构建编辑器目标，在一次性暂存项目中生成五个资产，验证它们的 report/log 并将这些 `.uasset` 文件准确复制到示例叠加中：可播放的角色 BP 及其 Mixin 集，以及三个回归资产。它不会烘焙、打包或修改引擎source/template资产。

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Variant Mixin `
    -Mode Smoke `
    -Incremental
```

烟道需要满足以下所有条件：

- UE 5.8 和引擎捆绑CPython 3.11。
- 三个原始的`BP_*_C`运行时类。
- 从其 BP 接口和`DA_ThirdPersonCharacterMixin`注册的可玩角色，具有上面显示的精确的每个Profile功能子集。
- 后期包加载发现真实的Interface/Mixin集Blueprint，其继承的子节点恰好共享一个路由器所有者。
- `AddInstances(const TArray<FTransform>&, ...)`的本机自动回退，包括其`TArray<int32>`返回和未触及的常量数组输入。
- `BatchUpdateInstancesTransforms(..., const TArray<FTransform>&, ...)`的本机自动回退，包括其标量`bool`返回。
- 同一角色BP类的两个同时对象通过`PythonMixinProfile`选择不同的Profile，包括显式选择器优先级和重新读取Blueprint变量的缓存失效。
- 当`BlueprintFallback`没有`Move`时自动原始BP回退。
- 注册时拒绝无效签名而不干扰活动路由器。
- 一个混合的BeginPlay和一个显式的原始BeginPlay调用。
- 映射`W`，鼠标轴到达PythonMove/Aim，真实的movement/look。
- 保留了Blueprint/native跳跃和有效的官方动画实例。
- 所有六个Python拾音器、配套运动和attached/updatedSlateHUD。
- 在实时 pawn 上显式取消注册，通过原始 Blueprint 实现不同的恢复 Move UFunction 和真实运动。
- 直接-API在已经生成的pawn上重新注册两个Profile，然后从声明的Mixin集恢复和重新注册，在两个阶段都有新的路由器generation/function和Python驱动的移动。
- 拒绝来自 Python initialization/teardown 回调的注册表修改以及不同对象的成功嵌套初始化。和
- 平衡每个Profileinitialization/teardown，最终类映射恢复，帮助程序删除，HUD/runtime清理和干净的进程退出。

重复生成结果`20260831-012003`和模式-4无头独立结果`20260831-012054`传递UE5.8.0和CPython3.11.8。无头运行时报告将`DA_ThirdPersonCharacterMixin`和`PythonMixinProfile`标识为角色声明的选择源。两个活的`BP_ThirdPersonCharacter_C`对象独立选择`Python`和`BlueprintFallback`。 Blueprint后备移动350.876虚幻单位。完全注销恢复Blueprint移动245.374单位，直接-API重新注册移动480.133单位，并声明-Mixin设置重新注册移动520.127单位。该报告还记录了 3 个被拒绝的初始化器修改、3 个被拒绝的清理修改、1 个嵌套对等初始化、不同的 injected/restored/ direct/declared 函数标识以及平衡的 `5/5` 角色生命周期事件。

Win64 打包结果 `20260831-014230` 构建编辑器和游戏目标、烘焙、阶段和存档 0.714 GiB，然后在打包的可执行文件中传递相同的模式 - 4 合约。保留`BP_ThirdPersonCharacter_C`，记录自动Blueprint回退的358.246单位，直接注册后的480.46单位和声明后的484.185单位-Mixin-设置重新注册，平衡`5/5` 角色生命周期事件和最终路由器计数为零。 Cook 发出 `UEP_MIXIN_COMMANDLET_BOOTSTRAP_SKIPPED` 且不包含 Mixin 注册，证明瞬态路由函数未序列化为熟资产。测试的可执行文件SHA-256是`99BFA1CC83C89CB0E5A8898839547802CAE3CBFAA87B81BB277BA8EF3B775DB5`。构建、生成、Cook和运行时日志不包含compiler/linker、致命、断言或`Log*: Error`诊断。对于该树，仅需要记录可见客户端手动门。

<a id="play"></a>

## 玩

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Variant Mixin `
    -Mode Play `
    -Incremental
```

按照模板中的方式使用 WASD、鼠标和空格键。左上角的HUD标识保留的Blueprint类模型。 `Overlay` 和 `PythonFirst` 仍然是单独的变体，以便并排比较。
