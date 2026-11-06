[English](Third_Person_Demo_0.6.0.md) | [简体中文](Third_Person_Demo_0.6.0.zh-CN.md)

<a id="python-first-third-person-demo-for-060"></a>

# Python-0.6.0的第一个第三人称演示

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

<a id="scope"></a>

## 适用范围

版本0.6.0将早期的模板奇偶校验证明变成了一个小的可播放样本。 Unreal Engine的UE5.8第三人称地图、人体模型、增强输入和动画资源保持数据不变。 Python拥有生成的GameMode、PlayerController和角色、相机构造、输入回调、运动状态选择、可收集的循环、伴随运动和视口HUD。

该演示被上演到`.build/Demos/UEPPythonThirdPerson`。它不会编辑引擎模板或Unreal Engine源。运行时使用引擎捆绑的CPython3.11。

规范样本历史记录和工作树发布在 [`UnrealEnginePython5Examples`](https://github.com/Arcueid77/UnrealEnginePython5Examples) 中。该存储库将该项目固定为`Demos`。非递归克隆后，请在使用以下命令之前运行`git submodule update --init Demos`。

<a id="runtime-layout"></a>

## 运行时布局

运行时和自动化不再共享一个大模块：

| 模块 | 责任 |
| --- | --- |
| `bootstrap.py` | root 生成的类并启动 runtime/optional 烟雾代码 |
| `character.py` | 角色组件、运动、外观、跳跃和动画状态 |
| `controller.py` | 本地增强输入映射-上下文所有权 |
| `game_mode.py` | 选择生成的角色和PlayerController |
| `state.py` | 不真实的独立计分和回合转换 |
| `gameplay.py` | 可收藏的演员和同伴演员以及可玩的回合 |
| `hud.py` | 附加到游戏视口的一棵命中测试不可见 Slate 树 |
| `runtime.py` | 每个活动世界和清理有一个 gameplay/HUD 会话 |
| `smoke.py` | 选择加入自动输入、收集、切图和清理测试 |

`uep_python_third_person.py` 仅保留为兼容性导入。正常启动直接导入`uep_third_person.bootstrap`。

<a id="play-contract"></a>

## 玩合约

玩家可以使用官方模板输入动作来移动、查看和跳跃。六个漂浮的Python生成的球体形成一轮。收集全部六个进入可见的回合完成状态，然后在短暂的倒计时后开始新的回合。 PythonHUD显示目标、回合得分、总得分、计时器、移动速度和当前Python动画状态。一个小同伴演员展示了连续的Python拥有的世界行为。

HUD 是游戏视口中真实的 Slate 小部件，而不是屏幕上的调试消息。当世界会话结束时它会被删除，并在切图后重新创建一次。

<a id="lightweight-checks"></a>

## 轻量级检查

暂存或刷新一次性项目而不编译：

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Mode Prepare `
    -Incremental
```

无需构建 Unreal 即可测试圆形状态：

```powershell
$env:PYTHONDONTWRITEBYTECODE = "1"
& F:\UnrealEngine\Engine\Binaries\ThirdParty\Python3\Win64\python.exe `
    -m unittest discover `
    -s Demos\UEPPythonThirdPerson\Tests `
    -p "test_*.py" `
    -v
```

<a id="unreal-validation"></a>

## 虚幻验证

快速运行时验证执行增量编辑器目标构建，然后执行无头独立冒烟测试。它没有Cook/package:

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Mode Smoke `
    -Incremental
```

冒烟测试通过PlayerInput和官方输入映射上下文发送`W`、`MouseX`/`MouseY`和`SpaceBar`。它不调用直接InputAction注入。它观察生成的Python回调、移动、相机旋转和跳跃弧，检查locomotion/jump/fall/land状态，收集所有六个游戏球体，检查SlateHUD，执行相同地图切图，验证干净的新回合，然后显式释放HUD，输入绑定和运行时会话。每个演示进程都会禁用 Android 文件服务器、UDP 消息传递和 TCP 消息传递，并且不使用游戏网络。演示游戏目标设置`bEnableTrace = false`，因此Development包不会打开UE的TCP1985跟踪控制侦听器，并且不会在每个带时间戳的包路径上获取新的防火墙身份。这是项目 Target 规则，不会修改 Engine 源。

共享的 `UnrealEditor.exe` 目标使引擎跟踪保持启用状态。因此，`Mode Play`使用稳定的编辑器可执行路径。在该路径尚未分类并且不需要远程 Unreal Insights 控制的计算机上，管理员可以创建显式入站阻止规则：

```powershell
New-NetFirewallRule `
    -DisplayName "UEP Validation - Block Unreal Trace Control 1985" `
    -Group "UnrealEnginePython5 Validation" `
    -Direction Inbound `
    -Action Block `
    -Protocol TCP `
    -LocalPort 1985 `
    -Profile Any
```

演示驱动程序本身不会更改防火墙策略，也不会扩大网络访问范围。

互动单机游戏是：

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Mode Play `
    -Incremental
```

正式发布转正还需要`-Mode Audit`和`-Mode Package`、可见的独立捕获、CPython3.11、清理严格日志和未更改的engine/template源树。

针对源构建引擎运行的第一个干净的`Package`可能会将大型游戏目标依赖关系图编译到一次性项目中。它不编辑引擎源。随后的`-Incremental`运行重用这些项目本地对象。 `Prepare`永远不会编译，而`Smoke`构建编辑器目标，但不构建Cook或打包。

<a id="current-status"></a>

## 目前状态

版本0.6.0已完成。 Headless UE 5.8 独立结果 `20260824-211718` 通过引擎捆绑下的 schema-5 运行时合约 CPython 3.11.8，包括加载的 UEP 0.6.0描述符，映射`W`，`MouseX`/`MouseY`和`SpaceBar`交付，所有六个接送，HUD切图后的娱乐并验证HUD/input/runtime拆解。 Blueprint审核结果`20260824-211829`通过，保留四Blueprint、27图、173节点参考基线。 Win64打包结果`20260824-203312`记录UAT`Build=False`，存档1754Pak条目并从内部打包目标传递相同的模式-5契约，零释放阻塞UAT/runtime 诊断。可见的 1280x720 播放结果 `20260824-044028` 确认渲染的 Python HUD、物理鼠标外观和 SpaceBar jump/fall/land 序列。最终禁用跟踪的打包可执行文件也会以零个TCP侦听器和没有Windows安全选择器重新启动。
