[English](Subclassing_API.md) | [简体中文](Subclassing_API.zh-CN.md)

<a id="native-subclassing-api"></a>

# 本机子类化API

UnrealEnginePython 1.0.0 支持Python Unreal Engine 5.8.1 的运行时子类生成。从导入的 Unreal 类派生的 Python 类会生成瞬态 `UClass`。声明的字段变成 UE5 `FProperty` 对象，带注释的方法变成反射 `UFunction` 对象。

这个 API 在 Unreal 的 Python 解释器中运行。它无法从独立的 Python 进程导入。经过验证的配置是 Win64 上的 UE 5.8.1 以及引擎捆绑的 CPython 3.11 运行时，并且不需要更改引擎源。

<a id="defining-a-class"></a>

## 定义一个类

```python
import unreal_engine as ue
from unreal_engine.classes import Character, FloatProperty, StrProperty


class FloatingCharacter(Character):
    RiseSpeed = FloatProperty
    State = StrProperty

    def __init__(self):
        self.RiseSpeed = 100.0
        self.State = "ready"

    def PythonTick(self, DeltaSeconds: float):
        location = self.get_actor_location()
        location.z += self.RiseSpeed * DeltaSeconds
        self.set_actor_location(location)

    PythonTick.override = "ReceiveTick"


# Transient generated classes must be rooted for as long as Unreal may load,
# spawn or reference them by class object or path.
FloatingCharacter.add_to_root()
```

Python`__init__`函数在Unreal创建类默认对象（CDO）之前安装，因此它可以设置反映的默认值并创建默认子对象。它也适用于随后构建的实例。

<a id="reflected-properties"></a>

## 反映的属性

通过在 Python 类上分配导入的 Unreal 属性类型来声明属性：

```python
from unreal_engine.classes import Actor, BoolProperty, FloatProperty, IntProperty, StrProperty


class PropertyExample(Actor):
    Enabled = BoolProperty
    Count = IntProperty
    Weight = FloatProperty
    Samples = [FloatProperty]
    Tags = {StrProperty}
    Target = Actor
    Scores = {StrProperty: IntProperty}
```

UE 5.8 路径支持标量属性、数组、映射、对象引用、结构和枚举。单元素Python集合声明`TSet<ElementProperty>`。运行时读取返回Python`set`，而写入则接受`set`或`frozenset`。设置元素和映射键必须映射到具有值哈希的 UE 属性类型。

<a id="reflected-functions-and-overrides"></a>

## 反射函数和覆盖

当公共 Python 方法的参数和返回值使用受支持的注释时，就会得到反映。没有支持的注释的参数将从反射签名中省略。

```python
class FunctionExample(Actor):
    def Add(self, Left: int, Right: int) -> int:
        return Left + Right
```

替换父反射事件时，使用显式 `override` 属性。这是推荐的 UE5.8 形式，因为它使 Unreal 事件名称明确，并允许 Python 实现使用不同的名称：

```python
class EventExample(Actor):
    def PythonBeginPlay(self):
        ue.log("begin play from Python")

    PythonBeginPlay.override = "ReceiveBeginPlay"
```

父函数必须是可重写的反射函数。特别是，0.3.0验证套件执行真正的`BlueprintNativeEvent`覆盖，而不仅仅是新声明的Python函数。

旧的元数据标志仍然可用于新的反射方法：

```python
FunctionExample.Add.pure = True
# Other supported flags include static, event, multicast, server, client and
# reliable where Unreal's corresponding function rules allow them.
```

<a id="default-subobjects"></a>

## 默认子对象

默认组件可以在 `__init__` 中创建并在 Actor 生成之前附加：

```python
from unreal_engine.classes import CameraComponent, Character, SpringArmComponent


class CameraCharacter(Character):
    CameraBoom = SpringArmComponent
    FollowCamera = CameraComponent

    def __init__(self):
        self.CameraBoom = self.create_default_subobject(
            SpringArmComponent,
            "CameraBoom",
        )
        self.CameraBoom.setup_attachment(self.RootComponent)

        self.FollowCamera = self.create_default_subobject(
            CameraComponent,
            "FollowCamera",
        )
        self.FollowCamera.setup_attachment(self.CameraBoom, "SpringEndpoint")
```

`setup_attachment(parent, socket_name=None)` 镜像构建时场景组件附件。注册后的运行时附件应使用适当的虚幻附件功能。

<a id="lifetime-and-redefinition-rules"></a>

## 生命周期和重新定义规则

- 生成的类是暂时的。当类必须在 Unreal 垃圾回收中幸存或稍后从 URL/class 路径解析时，调用 `add_to_root()`。
- 当类将它们存储为默认值时，出于同样的原因，请保持引用的瞬态资产为 root。
- 在一个进程中定义具有相同 Unreal 名称的第二个生成类将被拒绝。 0.3.0 不支持热类redefinition/reload。重新启动该进程以重新创建它。
- UObject 访问属于 Unreal 的游戏线程。 Python 工作线程不得变异 UObjects。
- Python 反射回调引发的异常将报告至 Unreal 日志。游戏代码应保持回调较小并处理可恢复的错误。

有关完整的解释器、回调、异常和工作线程契约，请参阅`Lifecycle_Threading_API.md`。

请参阅`Demos/UEPPythonThirdPerson/Overlay/Content/Scripts/uep_third_person`下完整的Python-第一个角色、控制器和GameMode实现。旧的 `uep_python_third_person.py` 路径仍然是兼容性导入。
