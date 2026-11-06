[English](Android.md) | [简体中文](Android.zh-CN.md)

<a id="deploying-on-android-devices"></a>

# 在Android设备上部署

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

从版本20180723和引擎4.20开始，您可以在Android设备上部署UnrealEnginePython插件（用于启动和打包）。

python 发行版来自“Crystax NDK”项目 (https://www.crystax.net/android/ndk)，但您不需要下载它，因为此存储库已包含所需的共享库和标头以及压缩在 zip 文件中的 python 标准库：

https://github.com/20tab/UnrealEnginePython/tree/master/android/armeabi-v7a

https://github.com/20tab/UnrealEnginePython/tree/master/android/python35

尽管存储库包含 python2.7 的文件，但目前唯一支持的版本是3.5。

显然，您需要 UnrealEnginePython 源代码分发来重建 Android 的插件。

<a id="the-first-project"></a>

## 第一个项目

我假设您的项目已经可以在 Android 上部署，现在您想向其角色之一添加一个简单的 Python 组件：

```python
import unreal_engine as ue

class AutoJump:

    def begin_play(self):
        self.timer = self.uobject.set_timer(3, self.jump, True)

    def jump(self):
        self.uobject.get_owner().Jump()
```

一旦脚本在编辑器中运行，您需要准备好 Android 友好的环境。

第一步是配置打包系统以包含 /Content/Scripts 目录（其中包含 Python 文件，当前是您之前为角色创建的文件）：

![android_packaging](https://github.com/20tab/UnrealEnginePython/raw/master/docs/android_packaging.png)

只需将 Scripts 目录添加为“要复制的其他非资产目录”中的新项目即可。

最后得到https://github.com/20tab/UnrealEnginePython/blob/master/android/python35/stdlib.zip并复制到Scripts目录中。

这是 libpython 正确引导自身所需的 python 标准库。 （不要FORGETTHISSTEP，如果没有IT，您的ANDROIDAPP将运行但崩溃AFTER THESPLASHSCREEN）。

stdlib.zip 文件名是硬编码的，因此不要重命名它（除非您想修改 UnrealEnginePython 源）。

现在您可以通过Android设备启动您的项目。

在启动之前，将为arm架构构建UnrealEnginePython插件，然后上传一个apk以及您的Content目录。如果一切失败，您应该会在Android设备中看到您的角色自动跳跃。

<a id="packaging"></a>

## 打包

打包有点复杂，因为 Unreal 会沿着 .apk 文件生成一个假的 .obb 文件。

此 .obb 文件是一个简单的 .zip 文件，其中包含 .pak 文件以及脚本目录。由于这不是真正的 android .obb 文件，我们无法将其挂载为文件系统（使用 android StorageManager api），因此我们需要将其视为简单的 zip 文件。

幸运的是，Python 支持从 zip 文件获取模块，因此只需将 .obb 文件添加到其模块搜索路径就足够了（UnrealEnginePython 插件会自动执行此操作）。

问题是Python不支持将zip文件转换为zip文件（stdlib.zip转换为.obb文件），因此为了允许打包的游戏运行，我们需要在Scripts目录中解压stdlib.zip。这将导致我们的 Scripts 目录被额外的 .py 文件破坏（请随意提出更好的解决方案）。

stdlib.zip 文件解压后，您可以打包项目并将其上传到设备。

<a id="note"></a>

## 注意事项

即使对于编辑器也尝试使用 python 3.5，否则从 stdlib.zip 提取的文件可能会导致问题（在这种情况下，您应该首先遇到 SRE 异常）

Python 3.6，虽然未经测试，但应该可以工作。

任何从 Crystax NDK 构建的 python 3 版本也应该可以工作。只需编译它，将相关文件复制到存储库 android/ 目录中，并相应地更改 https://github.com/20tab/UnrealEnginePython/blob/master/Source/UnrealEnginePython/UnrealEnginePython_APL.xml 和 https://github.com/20tab/UnrealEnginePython/blob/master/Source/UnrealEnginePython/UnrealEnginePython.Build.cs 即可。
