[English](Viewport_API.md) | [简体中文](Viewport_API.zh-CN.md)

<a id="working-with-viewports"></a>

使用视口
----------------------

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

unreal_engine模块公开了以下功能

检查 https://github.com/20tab/UnrealEnginePython/blob/master/examples/pie_screenshotter.py 以获得 PIE 视口屏幕截图的示例

```py
# returns a tuple of FColor objects, None if no game viewport is active
pixels = ue.get_viewport_screenshot()

# returns None if no game viewport is active
width, height = ue.get_viewport_size()

# returns a tuple of FColor objects, None if no viewport is active in the editor
pixels = ue.editor_get_active_viewport_screenshot()

# returns None if no viewport is active in the editor
width, height = ue.editor_get_active_viewport_size()

# returns a tuple of FColor objects, None if no PIE is active in the editor
pixels = ue.editor_get_pie_viewport_screenshot()

# returns None if no PIE is active in the editor
width, height = ue.editor_get_pie_viewport_size()

# trigger highres screenshot in the editor
ue.editor_take_high_res_screen_shots()
```
