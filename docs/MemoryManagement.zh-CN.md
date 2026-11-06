[English](MemoryManagement.md) | [简体中文](MemoryManagement.zh-CN.md)

<a id="managing-memory"></a>

# 管理内存

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

<a id="uobject"></a>

## UObject

UObject是Unreal Engine的基本部分之一。它代表由 Unreal Engine 垃圾收集器跟踪的 engine/editor 对象。

每个UObject都会被不断跟踪，并且每当垃圾收集器运行时（通常每60秒或在engine/editor循环的非常特定部分，例如进入PIE模式时），它都会检查UObject是否仍然引用其他UObjects，在负面情况下（无引用）它将被销毁。

您可以使用以下命令触发从 python 运行的垃圾收集器：

```python
import unreal_engine as ue
ue.console_exec('obj gc')
```

<a id="py_ueobject"></a>

## py_UEObject

这是低级 C 结构体，表示 PyObject（表示 Python 对象的 C 结构体）和 UObject 之间的 Python 映射。每当您创建py_UEObject（来自UE python api）时，另一个GC（与python插件相关）将开始跟踪它。

每当 UE GC 运行时，UnrealEnginePython GC 也会运行，检查映射到 py_UEObject 的 UObject 是否仍然存在。

如果映射到Python对象的UObject死了，将会触发异常。

这是一个例子：

```python
import unreal_engine as ue

from unreal_engine.classes import BlueprintFactory

factory = BlueprintFactory()
texture = ue.create_transient_texture(512, 512)
# run GC
ue.console_exec('obj gc')

print(factory)
# this will raise an exception as the UObject mapped to factory has been destroyed by the GC ru
print(texture)
```

通过运行此脚本，您将得到如下结果：

```
PyUObject is in invalid state
Traceback (most recent call last):
  File "<string>", line XX, in <module>
Exception: PyUObject is in invalid state
```

在这里我们看到工厂和纹理之间有两种不同的行为。第一个在 GC 运行中幸存下来，第二个已被销毁。

这是因为只有 UObject 由 Python 使用经典构造函数（如 BlueprintFactory()）显式创建，才会绑定到相关的 ue_PyUObject。所有其他都遵守 Unreal GC 规则。这是一个相当复杂的选择，旨在提高性能并避免两个 GC 之间的过多竞争。

非常长的脚本，要做很多事情，经常触发 UE4 GC，可能会在执行过程中被此类错误阻塞。在这种情况下（就像在 C++ 中所做的那样），您需要通知 UE GC 如何处理它们（以避免它们被破坏）。

请注意，一旦您告诉 UE GC 不要销毁 UObject，UObject（及其 python 映射）将保留在内存中（因此您将以泄漏结束）

<a id="strategy-1-setting-uobject-flags-to-govern-the-gc"></a>

## 策略1：设置UObject标志来管理GC

当您创建 UObject （从 C++ 端，通过 ```NewObject<T>``` api 调用）时，您可以指定标志位掩码。默认情况下，python api 仅使用 RF_Public 标志：

https://api.unrealengine.com/INT/API/Runtime/CoreUObject/UObject/EObjectFlags/index.html

您可以使用 set_obj_flags() python 函数更改此位掩码：

```python
import unreal_engine as ue

texture = ue.create_transient_texture(512, 512)
# assign mask 0x00000001|0x00000002
texture.set_obj_flags(ue.RF_PUBLIC|ue.RF_STANDALONE)
# run GC
ue.console_exec('obj gc')
# this will normally print the UObject repr
print(texture)
```

RF_Standalone 标志（Python api 中的RF_STANDALONE）会将 UObject 标记为“独立”，因此它将永远驻留在内存中。

最终你可以reset/set标志：

```python
import unreal_engine as ue

texture = ue.create_transient_texture(512, 512)
# assign mask 0x00000001|0x00000002
texture.set_obj_flags(ue.RF_PUBLIC|ue.RF_STANDALONE)

ue.console_exec('obj gc')

print(texture)

# the second True argument will reset the flags (otherwise set_obj_flags will work in append mode)
# eventually you can call factory.reset_obj_flags()
texture.set_obj_flags(ue.RF_PUBLIC, True)

ue.console_exec('obj gc')

print(texture)
```

第二次打印将引发错误。

这是一种非常原始的方法（除非您确定需要一个常驻对象）。为了拥有更多的控制权，第二种策略会更好......

<a id="strategy-2-the-root-set"></a>

## 策略2：根集

根集是 GC 树的一个非常具体的部分。如果你想有效地控制UObject生命周期，你可以使用相关的python api：

```python
import unreal_engine as ue

texture = ue.create_transient_texture(512, 512)
texture.add_to_root()

ue.console_exec('obj gc')

print(texture)

texture.remove_from_root()

ue.console_exec('obj gc')

print(texture)
```

和以前一样，第一次 GC 运行不会销毁 UObject （因为它位于根集中），而第二次 GC 将从内存中删除 if，因为它不再位于根集中。

Python 中的 UObject 内存管理的一个有趣方法是使用 Tracker 对象：

```python
class Tracker:

    def __init__(self):
        self.uobjects = []

    def track(self, uobject):
         uobject.add_to_root()
         self.uobjects.append(uobject)
         return uobject

    def __del__(self):
         for uobject in self.uobjects:
             uobject.remove_from_root()

tracker = Tracker()
```

现在您可以从 python 创建 UObject 并自动跟踪它们。当python GC销毁跟踪器对象时，它跟踪的所有UObject也将被销毁：

```python
texture = tracker.track(ue.create_transient_texture(512, 512))
```

例如，多次运行脚本时，“tracker”id 将被覆盖，从而触发映射的 python 对象（及其 ```__del__``` 方法）的销毁

<a id="low-level-uobject-creation-api"></a>

## 低级UObject创建API

到目前为止，您已经了解了如何以非常 Pythonic 的方式创建新的 UObject：

```python
from unreal_engine.classes import BlueprintFactory, Material, MaterialFactoryNew

bp_factory = BlueprintFactory()
material = Material()
# the first argument here (None) is the outer UObject
material_with_a_name = Material(None, 'FooBar001')
mat_factory = MaterialFactoryNew()
```

虽然 automagic python UObject 创建 api 非常方便，但有时您需要对 ```NewObject<T>``` C++ api 进行较低级别的访问：

```python
import unreal_engine as ue
from unreal_engine.classes import Material

material = ue.new_object(Material, None, 'DumbMaterial001', ue.RF_PUBLIC|ue.RF_STANDALONE)
```

或者对于更动态的类规范：

```python
import unreal_engine as ue

# you can reference to Unreal classes with a string
material = ue.new_object(ue.find_class('Material'), None, 'DumbMaterial001', ue.RF_PUBLIC|ue.RF_STANDALONE)
```

<a id="owning"></a>

## 拥有

我们已经看到了 UObject 如何根据其创建方式进行不同的管理：

```python
# owned by python
material = Material()


# owned by unreal
material2 = ue.new_object(Material)
```

有趣的是，我们可以使用 .own() 和 .disown() 方法更改所有者：

```python
# owned by unreal
material2 = ue.new_object(Material)

# now owned by python
material2.own()

# owned again by unreal

material2.disown()
```

您可以使用 .is_owned() 方法（返回 bool）检查对象是否被拥有

<a id="ustruct"></a>

## UStruct

UStruct 是低级 C/C++ 结构的 UE 表示。它们既可以作为 POD（普通旧数据，如 C 语言）工作，也可以作为类对象（具有方法，但没有封装）工作。从Blueprint来看，UStruct都是POD（一般是User Defined Structs的形式），而在C++ api中，大部分都有常规方法。

```python
from unreal_engine.structs import StaticMeshSourceModel, MeshBuildSettings
lod1 = StaticMeshSourceModel(BuildSettings=MeshBuildSettings(bRecomputeNormals=False, bRecomputeTangents=True, bUseMikkTSpace=True, bBuildAdjacencyBuffer=True, bRemoveDegenerates=True))
```

在此示例中，我们使用 StaticMeshSourceModel UStruct (https://api.unrealengine.com/INT/API/Runtime/Engine/Engine/FStaticMeshSourceModel/index.html) 为 StaticMesh 生成新的 LOD

您现在可以修改 lod1 的 bRecomputeNormals：

```python
lod1.BuildSettings.bRecomputeNormals = True
```

这是非常Python和用户友好的，但请注意，如果您正在使用的结构不是由Python创建的，它们可能会变得无效，因为内部内存指针变成了悬空指针。

因此，更清楚地说，存在 2 类型的 UStruct：拥有和不拥有。拥有的结构是由 python api 创建的结构，通常是安全的。无主的UStruct是由UE4本身创建的，因此它可以随时销毁它们（尽管这种情况很少发生，因为虚幻中的绝大多数结构都是按值传递的）

如果您想从无主结构构建一个有主结构（或者您想制作一个简单的副本），您可以调用 .clone() 方法：

```python
mesh_build_settings = lod1.BuildSettings.clone()
mesh_build_settings.bRecomputeNormals = True
lod1.BuildSettings = mesh_build_settings
```
