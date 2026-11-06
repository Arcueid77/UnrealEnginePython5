[English](Mixin_API.md) | [简体中文](Mixin_API.zh-CN.md)

<a id="blueprint-mixin-api"></a>

# Blueprint Mixin API

[1.0.0 受支持 API 清单](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)及调用/生命周期矩阵共同规定发布契约。

UEP 1.0.0 可将既有 Blueprint 生成类中的选定函数路由到 Python。已放置或生成的对象保留原有 `BP_*_C` 身份。类级路由保存各原始 UFunction，每个 UObject 实例可独立选择命名的 Python Profile。

Python 子类化会创建临时派生 `UClass`，需要调整生成或类选择入口。Mixin 则对已经加载的 Blueprint 类配置路由，使地图中已有的实例也能参与。

<a id="named-profiles-and-per-instance-routing"></a>

## 命名 Profile 与按实例路由

在玩法开始前，注册该类可能使用的所有 Profile。

```python
import unreal_engine as ue
from unreal_engine import FRotator


character_class = ue.load_class(
    "/Game/ThirdPerson/Blueprints/"
    "BP_ThirdPersonCharacter.BP_ThirdPersonCharacter_C"
)


@ue.mixin(character_class, profile="Python", make_default=True)
class PythonCharacterProfile:
    def __init__(self):
        self.python_move_events = 0

    def Move(self, right, forward):
        self.python_move_events += 1
        rotation = self.get_control_rotation()
        yaw = FRotator(0.0, 0.0, rotation.yaw)
        self.add_movement_input(ue.get_forward_vector(yaw), forward)
        self.add_movement_input(ue.get_right_vector(yaw), right)


@ue.mixin(character_class, profile="BlueprintMove")
class BlueprintMoveProfile:
    def Aim(self, yaw, pitch):
        self.add_controller_yaw_input(yaw * 0.35)
        self.add_controller_pitch_input(pitch * 0.35)
```

路由器安装所有Profile声明的反射函数的并集。在此示例中，并集为 `Move` 加 `Aim`。使用`Python`的对象为`Move`调用Python。使用 `BlueprintMove` 的对象未实现 `Move`，因此路由器通过原生属性到属性参数帧自动调用保留的 Blueprint 实现。这保留了本机返回值和 const 引用输入，而无需 Python 转换往返。回退是针对每个函数的，不需要转发存根。

在同一 Blueprint 类的两个对象上独立选择Profile：

```python
ue.set_mixin_profile(player, "Python")
ue.set_mixin_profile(training_dummy, "BlueprintMove")

assert player.get_class() is training_dummy.get_class()
assert ue.get_mixin_profile(player) == "Python"
assert ue.get_mixin_profile(training_dummy) == "BlueprintMove"
```

`clear_mixin_profile(object)` 删除显式选择并使实例缓存无效。下一个混合调用解析Blueprint接口选择，然后是类默认值。 `set_default_mixin_profile(class, name)` 更改回退并使缓存的默认选择无效，而不会干扰显式实例选择。

直接非装饰器API是：

```python
ue.register_mixin_profile(
    character_class,
    "Python",
    PythonCharacterProfile,
    make_default=True,
)
```

原始的 `register_mixin(class, python_class)` 和 `@mixin(class)` 形式仍然兼容。他们用一个名为 `Default` 的Profile替换了整个路由器。当多个实现必须共存时，使用ProfileAPI。

<a id="blueprint-interface-and-mixin-set"></a>

## Blueprint Interface 与 Mixin Set

对于资产创作的工作流程，将 `UEPPythonMixinInterface` 添加到 Blueprint 并创建 `UEPPythonMixinSet` 数据资产。该集合声明每个允许的Profile：

- `ProfileName`;
- 可导入`PythonModule`。和
- `PythonClass`（该模块中的类名或点属性路径）。

将一个声明的名称设置为 `DefaultProfile`. Python a 引用的类 Mixin Set 是简单的类定义。不要单独装饰它们。

实现Blueprint中的两个接口函数：

1. `Get Python Mixin Set` 返回该类的相同数据资产。常量返回值是正常的CDO配置。
2. `Get Python Mixin Profile` 返回`Name`。它可以读取实例可编辑的Blueprint变量，允许相同`BP_*_C`的两个放置的实例选择不同的Profile。

普通派生Blueprint继承其父级的路由器和选择钩子。单独继承接口不会创建第二个路由器。在最高相关性 Blueprint 上共享设置的 Mixin 仍然是最简单的安排。

路由器还支持显式配置的子级及其自己的 `GetPythonMixinSet` 覆盖。 UE 5.8.1 的编译器删除了重复的继承接口描述符，并将其函数提升为重写，因此发现接受拥有的提供者加上本机接口实现，而不仅仅是直接的接口描述符。没有自有覆盖的继承提供者仍被排除。最初的子提供者固定装置是由编辑主持的。特定于配置的包证据记录在1.0.0发布记录中。

UEP 在项目启动导入后扫描已加载的 Blueprint 类，并观察编辑器、游戏和打包构建中的包完成情况，因此在后续Mixin调用之前注册由地图或软引用稍后加载的类。它导入完整的Mixin集并为每个显式声明的类构建一个路由器。 `register_declared_mixin(class)` 强制为一名已加载所有者注册。 `register_loaded_mixin_interfaces()` 重新扫描所有加载的类并返回新注册的路由器的数量。

UE 5.8.1 编辑器构建（包括 `UnrealEditor -game` 和编辑器托管的服务器）观察 `OnEndLoadPackage` 并处理已完成批次中的每个包。旧的异步每包委托在 5.8.1 中因不安全而被弃用。编辑器路径不再读取其潜在不稳定的包指针。非编辑器版本在加载后使用 `OnHotfixableAssetLoaded` 并注册 Blueprint 类通知所需的本机 UClass 元类。模块加载事件刷新该元类注册。线程外或可重入通知遵循具有弱 UObject 引用和发现纪元的游戏线程，因此禁用发现会使排队工作无效。关闭会删除回调并取消注册跟踪的元类。 1.0.0发布记录包括渲染的Mixin游戏包和单独的Development/Shipping证据。

Cook commandlet 被故意排除在发现之外，并且在 Cook 运行时拒绝Python 注册表修改。打包游戏仅在运行时进程启动后才会注册其声明的Mixins。这可以防止临时路由的 `UFunction` 地图条目被序列化为熟的 Blueprint 资产，同时保留实际游戏过程中的后期包加载发现。

编辑器自动化可以创建界面图，而无需手动编辑Blueprint。传递三个参数以获得常量Profile：

```python
ue.blueprint_configure_mixin(
    blueprint,
    mixin_set,
    "BlueprintMove",
)
ue.compile_blueprint(blueprint)
```

传递第四个参数来创建或重用标量 `Name` 变量，使其实例可编辑，设置其默认值，并将Profile结果连接到该变量：

```python
ue.blueprint_configure_mixin(
    blueprint,
    mixin_set,
    "Python",
    "PythonMixinProfile",
)
ue.compile_blueprint(blueprint)
```

`blueprint_configure_mixin` 仅限编辑器使用。它将接口直接添加到该项目Blueprint，设置常量`GetPythonMixinSet`结果，并设置常量Profile结果或将其连接到请求的变量。它旨在用于确定性资产创作和测试，而不是运行时修改。它拒绝替换它无法识别为请求的变量 getter 的现有Profile表达式。

接口结果在实例第一次分派后被缓存。通过`set_mixin_profile`更改，或者更新Blueprint变量并调用`clear_mixin_profile`重新读取接口。这可以防止 `Tick`、输入和其他热调用在每次调度时执行 Blueprint 接口图。

<a id="dispatch-and-lifecycle-order"></a>

## 分派与生命周期顺序

通过接口声明的类按以下顺序工作。

1. 加载 Blueprint 类。
2. CDO 返回 Mixin Set，UEP 导入各个声明的 Profile。
3. 对象第一次进入 Mixin 调用时，解析并缓存其 Profile。
4. 该 Profile 自身的 `__init__(self)` 在这一轮 object/profile 生命周期中执行一次。
5. 执行选中的 Python callable。Profile 缺少对应方法时，调用保留的 UFunction。
6. Profile 切换或缓存失效时，先调用旧 Profile 自身可选的 `__uep_mixin_teardown__(self)`，再初始化新 Profile。
7. 注销或解释器退出时，清理已初始化的实例并恢复类函数映射。

选择器图、Python 初始化器、清理钩子、Mixin Python callable，以及显式调用原 Blueprint 的过程均属于回调边界。在这些回调中修改注册状态会触发 `RuntimeError`，以保护当前 router/profile 引用。不同对象间可以嵌套分派。对象正在解析、初始化或清理时，对同一对象的递归分派会明确报告 busy-state 错误。

`ReceiveBeginPlay`、`ReceiveEndPlay` 和普通构造脚本 UFunction 在签名满足契约时使用同一路由。注册时序决定能够接收哪些事件。需要覆盖构造流程时，应在地图加载或生成前，从早期项目导入或 `ue_site` 路径加载并注册类。延迟发现能接收注册完成之后才发生的 BeginPlay 等调用。

Mixin EndPlay 处理 Unreal 生命周期事件，可以回退或显式调用原实现。`__uep_mixin_teardown__` 则在 router/profile 切换或移除时释放 Python Profile 状态，两者具有各自的触发时机。

<a id="helpers-and-state"></a>

## 助手和状态

对于在编辑器可执行文件（包括`-game`）中写入的游戏玩法，更喜欢使用现有的`object.set_property("Duration", value)`形式来反映字段。遗留的 `object.Duration = value` setter 在对象构造之外发出编辑器属性更改通知。 `UUserWidget` 可以重新运行 `PreConstruct` 并重置材料。本机 Blueprint 运行时变量写入不会发出这些编辑器通知。这种区别是通过0.10动作触摸BP/Python差异来实现的。无需更换发动机。仅Python `_uep_*` 实例状态不受影响。

UObject 的 Python 包装器作为 `self` 传递。Profile助手根据需要进行解析和绑定：

```python
class ExampleProfile:
    def __init__(self):
        self.samples = []

    def _remember(self, value):
        self.samples.append(value)

    def SomeBlueprintFunction(self, value):
        self._remember(value)
```

`self` 仍然是 `unreal_engine.UObject` 包装器，而不是Profile类的 Python 实例。 `isinstance(self, ExampleProfile)`、合作式Python多重继承和零参数`super()`不是合约的一部分。

<a id="explicit-parent-and-child-routers-011-development"></a>

<a id="explicit-parent-and-child-routers"></a>

### 显式父路由器和子路由器

显式配置的子节点可以与其父节点的路由器一起拥有一个路由器，包括同名功能。每个路由调用、初始化程序和清理都有一个游戏线程、弱对象词法路由器上下文。 `call_mixin_original` 和 Python 辅助查找使用该上下文：父级 Python 对子级 UObject 进行回调，到达父级保留的原始内容，而不是子级的同名主体。嵌套子级 -> 类限定父级 -> 子级返回会恢复子级上下文。继承的注入父函数在存储子函数的原始函数之前会被解包。注销任一路由器不会保留已丢弃的路由器。

在回调之外，实例ProfileAPIs寻址最近的注册类。在回调期间，read/helperAPIs使用其活动路由器。修改仍然被拒绝，直到调用解除。每个路由器都有自己的Profile缓存。保持Blueprint选择器的Profile名称对每个参与集都有效。选择子Profile不会隐式选择或链接父Profile。 Python 成功仍然会替换所选方法，而无需自动原始调用或父调用。类限定`ue.call_function_by_class`可以故意输入父级的反射函数。它并不使每个 cached/final 或本机 C++ 调用都可拦截。

原生达世币资产创作探测涵盖了自有与继承的原始资产、同名嵌套、initialization/teardown、后备、注册和注销订单、兄弟排除和签名恢复。它使用私有文字对象 BP，而不是游戏回调重放。有关相应的 runtime/regression 状态，请参阅示例 ledger62 和 `Migration/PROGRESS.md`。

<a id="calling-the-original-explicitly"></a>

## 显式调用原件

当活动Profile实现某个功能时，Python 完全取代它。当两者都应该运行时显式调用保留的实现：

```python
def ReceiveBeginPlay(self):
    self.call_mixin_original("ReceiveBeginPlay")
    self.started_from_python = True
```

这与自动回退不同：仅当活动Profile无法调用该路由函数时，才会发生回退。自动回退在注入和保留的UFunction的本机布局之间复制值，然后直接调用保留的函数。 `call_mixin_original` 是显式的 Python 面向 API，因此遵循正常的 UEP argument/result 编组。

<a id="introspection-restore-and-reload"></a>

## 自省、恢复和重新加载

`get_registered_mixins()` 每个类路由器返回一项。每一项包括`target_class`、`registration_id`、`default_profile`、路由函数联合，以及包含每个Python类、Profile生成和函数子集的`profiles`映射。旧的 `python_class` 关键点位于默认Profile中。

```python
ue.unregister_mixin(character_class)
ue.unregister_all_mixins()
```

取消注册恢复目标拥有的函数名称和映射条目，删除瞬态分派函数，清除派生类查找缓存，调用Profile清理挂钩并释放Python引用。 UEP 还会在解释器关闭之前恢复所有路由器。

在编辑器中有意编译目标Blueprint之前取消注册，然后调用`register_declared_mixin`或再次导入直接注册。当观察到正常的 Blueprint 重新实例时，UEP 会修剪被取代的生成类，但在修补其活动类时编辑函数签名不会被视为支持的就地迁移。

<a id="call-entry-boundary-and-planned-hardening"></a>

<a id="reflected-call-entry-boundary"></a>

## 反射调用输入边界

路由器更改选定的类功能映射条目，而不是对象的类。解析这些条目的调用可以到达Python。目标UObject选择活动Profile。因此，同一 Blueprint 的两个实例可以通过共享路由器采取不同的路径：可在一个实例上调用匹配的 Python，当另一个Profile省略该方法时保留原始函数。成功的 Python 调用和 Python 异常都不会隐式调用原始调用。使用`call_mixin_original`进行显式组合。

这并不是对每个原生调用的通用拦截。先前保留的原始`UFunction*`、某些Final/explicit-parent调用路径或直接的本机C++调用可以绕过替换的映射条目。这些是源代码级边界，而不是每个操作码或调用站点的运行时覆盖范围声明。 [call/lifecycle矩阵](Mixin_Call_Lifecycle_Matrix.zh-CN.md)标记测试的路由、拒绝的签名和绕过。 0.9 装置包括重复真实的 PIE、本机 GC、受控重装和实时武器Profile切换。 [路线图](../ROADMAP.zh-CN.md) 将packaging/release 的批准分开。

<a id="explicit-parent-construction-adapter-editor-only"></a>

### 显式父构造适配器（仅限编辑器）

`ue.blueprint_extract_construction_helper(bp, "MyConstructionBody")` 将已编译的Actor BP 的零参数构造图克隆到虚拟助手中，并将`UserConstructionScript` 作为入口 -> 助手。显式编译、验证和保存。 API 不保存。 Invalid/duplicate 名称、非Actor BP 和嵌套构造图将被拒绝。在资产创作之前取消注册。它只改变传递的BP副本。切勿无意中传递参考模板。

使用`.override = "MyConstructionBody"`路由Python构造方法。 BlueprintFallback Profile调用 `call_mixin_original("MyConstructionBody")`。克隆的 BP 主体保持完整，因此子显式父构造可以执行保留的父构造，然后虚拟地解析助手。该设备为其子设备使用一个父路由器。它不执行单独的 0.11 显式子扩展。此有界图形适配器不是缓存 UFunction 指针、其他显式父级调用或直接 C++ 调用的通用挂钩。

<a id="safety-boundary-07-baseline-with-identified-development-extensions"></a>

<a id="supported-signatures-and-bounded-extensions"></a>

## 支持的签名与扩展边界

- 注册、选择及 UObject 访问在 Unreal 游戏线程执行。
- 目标为 Blueprint 生成的类。
- 每个目标类只有一个路由，可以包含多个互斥选择的 Profile。各 Profile 独立执行。
- 显式配置的父子路由使用前文的词法上下文，各自解析保留的原函数与 Python helper。
- 类必须直接声明 `UEPPythonMixinInterface`，或自行覆盖 `GetPythonMixinSet`。普通派生类继承路由。
- Profile 方法接收 `self` 及反射输入参数。
- 静态函数、RPC、latent 函数和委托签名会被拒绝。
- 默认拒绝非常量 out 参数。单个 Python 方法可通过 `method.uep_named_outputs = True` 显式启用命名输出，该属性要求 bool 值。可写引用和 in-out 参数仍会被拒绝，返回值及 const 引用输入按既有契约处理。
- `GetPythonMixinSet` 和 `GetPythonMixinProfile` 是保留的路由方法。
- 选择器、初始化器、清理、Mixin callable 和原函数回调边界中，注册状态修改会被拒绝。
- 运行时路由只管理加载后的函数映射。可选 Editor 资产工具按调用方传入的项目 Blueprint 进行显式编辑，资产保存遵循相应工具契约。

保留类和多 Profile 的运行证据见 `Third_Person_Mixin_Demo_0.7.0.md`，动态生成类型见 `Subclassing_API.md`。

<a id="explicit-named-outputs-010-development"></a>

<a id="explicit-named-outputs"></a>

## 显式命名输出

启用后，非常量 out 参数从 Python 方法的入参中省略。方法返回字典，以反射名称为键，为每个输出提供且仅提供一个值。如果签名也有返回值，请包含`ReturnValue`。例如，保留的QuickBarBP查询为：

```python
def IsThisTheActiveQuickbarSlot(self):
    return {"IsActive": bool(self.native_active_slot == self.SlotIndex)}

IsThisTheActiveQuickbarSlot.uep_named_outputs = True
```

在复制任何调用者输出之前，完整的输出字典将转换为单独初始化的本机存储。 Missing/extra 键、非字典或转换失败均为错误。他们不会默默地调用原始BP。省略该方法的Profile仍然使用保留的原始实现，包括传播到实际的BP/native调用者的输出地址。 Python 反射命名输出函数的调用者接收现有的输出元组形状，e.g。 `(False,)`，不是字典或裸布尔值。

当前的接受包括在路由器注册之前编译的 BP 调用程序、多个输出、本机返回加输出、explicit-original/missing-method 回退、拒绝的字典（具有未更改的种子调用程序输出存储）、恢复和取消注册恢复。十一通道聚焦调用矩阵和生产 QuickBar single/two-client 比较通过。 Packed-bool 布局尚未被对抗性装置明确证明。这并不是声称支持可变引用、RPC、潜在或委托签名。

反射返回存储可以在普通输出属性之前。 VM 参数解码器在步进参数表达式之前会跳过 `CPF_ReturnParm`：返回槽没有要使用的参数表达式。保留的设备颜色路由在`bCallNativeParent`之前有`ReturnValue`。六个实际的BP/Python软件比较和当前的十一通道原生调用矩阵通过此布局。这不会扩大支持的可变引用或RPC签名。
