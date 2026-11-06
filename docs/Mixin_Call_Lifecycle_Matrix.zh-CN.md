[English](Mixin_Call_Lifecycle_Matrix.md) | [简体中文](Mixin_Call_Lifecycle_Matrix.zh-CN.md)

<a id="mixin-call-and-lifecycle-matrix"></a>

# Mixin 调用和生命周期矩阵

UE5.8 / CPython3.11、Win64Development。该矩阵涵盖了生产保留级Mixin路由器。经过测试的路径不验证其他 UE VM 操作码、签名、构建配置或直接 C++ 调用。

<a id="calls"></a>

## 通话

| ID | 入职或契约 | 分类 | 可重复的证据 |
| --- | --- | --- | --- |
| C01 | 注入前编译的调用者BP -> Actor参考 -> 虚拟目标函数 | 已测试支持 | `Validation/UEP58Host/Tests/mixin_callsite_validation.py`。两个同类目标独立使用Python或缺失方法回退。证明组`callsite` |
| C02 | 不执行原BP，重复Python成功 | 已测试支持 | 同一调用者装置检查单独的BP/Python计数器before/afterProfile交换和取消注册。证明组`callsite` |
| C03 | 反射名称查找 / `call_function` / 本机 ProcessEvent 条目 | 已测试支持已识别的签名 | `mixin_signature_validation.py`：整数返回、const 结构输入、结构返回、原生事件。证明组`signature` |
| C04 | 返回加上const数组输入，包括继承的Blueprint所有者 | 已测试支持 | Mixin第三人称`interface_probe`：AddInstances和BatchUpdateInstancesTransforms，Python和本机后备。证明组`third-person` |
| C05 | 显式`call_mixin_original` | 已测试支持 | 签名夹具和Mixin第三人称：保留原生返回值和BP输入运动。证明组`signature` |
| C06 | 具有同名保留原件的显式 parent/child 路由器 | 在有界 0.11 夹具内进行测试支持 | Dash `generate_mixin_inheritance_probe.py`：文字对象BP，都是registration/unregister订单，owned37/inherited23原始，类限定嵌套父返回，initializer/teardown和后备。并不意味着拦截所有显式父 VM 操作码。证明组`inheritance` |
| C07 | Profile省略了路由器联合中的一种方法 | 已测试支持 | Caller/signature/Third 人员固定装置。原来的执行一次。证明组`callsite` |
| C08 | Python 回调加注 | 测试支持的异常边界 | `mixin_exception_validation.py`：无隐式本机广播，稍后Profile恢复，注销时恢复原始。需要预期的错误日志。证明组`exception` |
| C09 | Python `object.broadcast` -> 反射的本机多播 -> Python 订阅者 | 测试支持普通反射多播，Mixin拦截之外 | `delegate_broadcast_validation.py`：空内联委托，native/Python交付，错误参数rejection/recovery并取消订阅。需要修复5.8.1属性值地址。无稀疏代表覆盖范围主张。证明组`delegate` |
| C10 | Blueprint 增强输入 -> 字符 Move/Aim -> Python | 已测试支持 | 渲染Mixin第三人称原生输入烟雾，movement/rotation状态和截图。证明组`third-person` |
| C11 | 静态函数 | 故意拒绝。运行时测试 | 签名装置拒绝KismetSystemLibrary.IsValid并保留活动路由器。证明组`signature` |
| C12 | 非常量引用参数，或没有显式命名输出选择的输出 | 故意拒绝。运行时测试 | 签名夹具拒绝未标记的ComputeOutputs。非常量引用仍然被拒绝。显式非引用输出扩展是 C19，带有 C20 rejection/recovery 检查。证明组`signature` |
| C13 | 错误的 Python 参数签名 | 故意拒绝。运行时测试 | 签名夹具和第三人称无效轮廓夹具。主动注册仍然可用。证明组`signature` |
| C14 | RPC和委托签名功能 | 故意拒绝。已测试本机编辑器注册 | `Validation/UEP58Host/Tests/mixin_rejection_validation.py`：真正继承的ServerRestartPlayerRPC和编译后的BP调度程序签名在回调入口之前被拒绝。有效的路由器仍然可用并恢复原始路由器。不暗示 RPC invocation/network 测试。证明组`rejection` |
| C15 | 本机服务器RPC -> 显式创作的非RPC主体网关 | 通过编写的Lyra网关进行测试支持。 RPC 拦截仍然被拒绝 | 示例 ledger63：未更改的SendInfoNet/reliable/server标志，八个真正的二所有者本机RPC入口和两个original/Python输入存储。 Python仅绕过那些存储，然后重新加入保留的Commit/tasks。无接收器重播、原始data/velocity固定装置写入或完整的达世币迁移声明。证明组`rpc-gateway` |
| C16 | 潜在功能 | 被本机编辑器元数据验证故意拒绝 | 相同的拒绝装置测试测试拥有的 BP 函数上的实际潜在元数据。不承诺一般的打包潜在拦截、熟元数据拒绝或协程语义。证明组`rejection` |
| C17 | 缓存原始UFunction指针，explicit-parent/finalVM调用，直接原生C++调用 | Bypass/unsupported拦截 | 他们可以避免被替换的类映射条目。源边界，不是通用运行时拦截声明。证明组`source-boundary` |
| C18 | 实验性就地 BP 身体网关 | Bypass/unsupported 按生产Mixin。单独测试实验API | `blueprint_script_body_validation.py` 检查一个预编译调用程序以及 integer/bool 出地址写回。 Lyra 生产Profile不使用它。证明组`experimental` |
| C19 | 保留类 Mixin 函数上的显式非引用命名输出选择 | 测试支持指定的装置签名 | `mixin_named_output_validation.py`使用布尔值`uep_named_outputs=True`标记、预编译BP调用、本机条目、显式原始、缺失方法后备、本机返回加上命名输出和取消注册恢复。这不会放松RPC/latent/reference拒绝或证明打包布尔布局。证明组`named-outputs` |
| C20 | 无效的命名输出标记、字典、缺少输出或额外的键 | 故意拒绝。运行时测试 | 同一灯具的负模式需要实际的conversion/rejection诊断、有效Profile恢复和原始恢复。在糟糕的Python结果之后，没有隐式的原始BP回退。证明组`named-outputs` |
| C21 | 编写子Parent构建 -> 虚拟身体助手 -> 父Mixin路由器 | 测试支持显式转发装置 | `mixin_construction_forwarder_validation.py` 保留原始主体和类，通过编写的虚拟助手进行路由，拒绝无效的助手名称并恢复 Profile/router. 它不会拦截任意显式父虚拟机调用。证明组`construction-forwarder` |

<a id="lifecycle"></a>

## 生命周期

| ID | 场景 | 分类 | 可重复的证据 |
| --- | --- | --- | --- |
| L01 | 已放置的 BP Actor 和新生成的 Actor 保留其类别 | 已测试支持 | 重复的PIE夹具会创建一个编辑器放置的Actor，然后在每个PIE世界中创建第二个Actor。证明组`pie` |
| L02 | 新生成的Actor的建设 | 通过预先注册进行测试 | PIE 夹具见 Python UserConstructionScript。已经运行的构建事件不会重播。证明组`pie` |
| L03 | BeginPlay 和 EndPlay | 已测试支持 | 一个编辑器中的三个真实的PIE会话。每个会话有两个 BeginPlay/two EndPlay 事件。证明组`pie` |
| L04 | 每个实例Profile，继承Interface/CDO，后备，initializer/teardown重入防护 | 已测试支持 | Mixin 第三人称运行时及其 parent/child 接口探针。证明组`third-person` |
| L05 | 编译器删除重复的接口描述符后，子级拥有接口提供程序覆盖 | 在有界 0.11 夹具内进行测试支持 | Dash 创作控件接受拥有的GetPythonMixinSet加上本机接口实现，拒绝普通继承的兄弟。恢复原版class/signatures。证明组`inheritance` |
| L06 | 实时武器ProfilePython -> BP -> Python | 经测试支持在武器固定装置中 | 无构造重播。拆解会删除观察，并且首先 Python 勾选将其恢复一次。证明组`weapon` |
| L07 | 受控注销 -> 模块重新加载 -> 注册 -> 新小部件 | 已测试支持 | 武器夹具，三个循环。显式本机CollectGarbage和陈旧包装检查。证明组`weapon` |
| L08 | PIE 会话之间的原生 UObject GC | 已测试支持 | PIE Actors失效，订阅范围关闭，恢复原功能标识。证明组`pie` |
| L09 | Blueprint `CollectGarbage` 从 Python 调用 | 测试支持作为延迟请求。等待穿过发动机机架 | 资源管理器跟随模式在断言旧的 task/Actor 版本之前记录不同的 request/check 帧。调用本身并不是同步 GC 保证。证明组`follow` |
| L10 | 在原始图延续之前观察布尔网关 | 测试支持返回的布尔值保留和下一帧采样的输出 | follow-map 观察者将现有的 handler 转发一次。它的下一个控制帧读取原始回退图更新的位置。证明组`follow` |
| L11 | Pawn更换，两次世界切图，客户exit/rejoin | 经测试支持真实Lyra武器通道 | 专用服务器+两个独立客户端，19协议阶段，本机inventory/GAS和每个玩家HUD比较。证明组`travel` |
| L12 | 任意实时 BP 重新编译、更改反射签名、生成类替换、自动状态迁移 | Bypass/unsupported | 在受控 BP 创作之前取消注册。重新启动以生成type/signature更改。证明组`source-boundary` |

<a id="running-the-fixtures"></a>

## 运行装置

重点驱动程序重用标记的、已构建的阶段并检查source/module奇偶校验。使用 PowerShell 7 和新的输出目录运行它们：

对于受影响的子集，调用矩阵接受`-TestName`。省略它保留原来的十一个案例。未知或重复的名称在暂存或启动本机进程之前会失败。例如：

```powershell
& .\Validation\Run-UEP58FocusedCallMatrixValidation.ps1 `
  -StageProject F:\UnrealEnginePython5\.build\Validation\UEP58Host\UEP58Host.uproject `
  -OutputDirectory F:\UnrealEnginePython5\.build\Validation\Results\Calls-NewRun `
  -TestName @('signature-standalone', 'delegate-broadcast')
```

```powershell
.\Validation\Run-UEP58FocusedLifecycleValidation.ps1 `
  -StageProject F:\UnrealEnginePython5\.build\Validation\UEP58Host\UEP58Host.uproject `
  -OutputDirectory F:\UnrealEnginePython5\.build\Validation\Results\PIE-NewRun

.\Validation\Run-UEP58FocusedThirdPersonValidation.ps1 `
  -NativeProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
  -OutputDirectory F:\UnrealEnginePython5\.build\Validation\Results\ThirdPerson-NewRun
```

Signature/body/caller 固定装置通过 Py commandlet 及其所需的结果参数运行。异常装置使用单独的进程：UE可能会退出1，因为它会计算故意记录的回溯。仅接受声明的异常标记、完整报告、恢复证据和正常关闭。

<a id="proof-groups-and-scope"></a>

## 证明组和范围

稳定的C01-C21/L01-L12行恰好使用三个合约类别。有界支持行仅承诺其命名签名和固定装置。故意拒绝的行证明拒绝和恢复。 bypass/unsupported行记录排除合约。它不承诺通用拦截装置。

`audit_call_lifecycle_matrix_acceptance.py` 将每个证明组映射到精确的、签入的固定路径和哈希值。通用组使用 `Validation/UEP58Host/Tests/`：`callsite` -> `mixin_callsite_validation.py`、`signature` -> `mixin_signature_validation.py`、`exception` -> `mixin_exception_validation.py`、 `delegate` -> `delegate_broadcast_validation.py`、`rejection` -> `mixin_rejection_validation.py`、`experimental` -> `blueprint_script_body_validation.py` 和 `pie` -> `mixin_pie_validation.py`。 `named-outputs`在正负模式下使用`mixin_named_output_validation.py`。 `construction-forwarder` 使用`mixin_construction_forwarder_validation.py`。

补充组保留其原来的执行范围：

- `third-person`：Mixin`interface_probe.py`、`smoke.py`和`character_mixin.py`。 ledger217 NativeFixed05。这是历史第三人称SDK证据。
- `inheritance`：`generate_mixin_inheritance_probe.py`和`dash_selector_probe_policy.py`。 ledger62 资产06。路由器命令和原始恢复都与那些owned/inherited函数有关。
- `rpc-gateway`：`generate_dash_rpc_input_assets.py`和`dash_rpc_input_contract.py`。 ledger63网络02。 RPC 本身保持原生状态。
- `weapon`：`weapon_validation.py`、`Run-UEP58PackagedWeaponHUDValidation.ps1`和`LyraHUDContracts.ps1`。 ledger211 PackagedWeaponHUD01。受控重新加载构造新的小部件。其打包的可执行文件是历史的，不是当前的编辑器候选者。
- `follow`：`explorer_follow_validation.py`和`explorer_follow_contract.py`。 ledger231 Python03DeferredGC。延迟 GC 和下一帧读回保持显式的引擎帧边界。
- `travel`：`uep_lyra_weapon_protocol.py`以及武器网络驱动。十九阶段CombinedNetwork01记录涵盖两次切图和业主重新加入。
- `source-boundary`：`UEPyMixin.cpp`和`PythonFunction.cpp`实现反射类映射路由器。调用站点夹具提供保留的原始控制。缓存的原始pointers/direct C++/other VM 调度仍被排除。任意recompile/signature更改需要受控注销或重新启动。

Batch266 将来自 ledger258 的两个当前SDK调用案例与`20261027-call-lifecycle-matrix/MissingCalls01`中仅缺失的九个当前-SDK案例结合起来。同一批的PIE01在一个当前SDK编辑器中记录了三个会话。不需要新的编译或Cook。补充历史记录是固定参考。它们没有被重新认证为当前的SDK/configuration执行。该矩阵标准本身不接受其他0.9发布标准。
