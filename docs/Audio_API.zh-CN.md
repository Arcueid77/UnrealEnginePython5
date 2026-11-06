[English](Audio_API.md) | [简体中文](Audio_API.zh-CN.md)

<a id="the-audio-api"></a>

# 音频API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

暴露了uobject.play_sound_at_location(sound,position[,volume_multiplier,pitch_multiplier,start_time])api方法：

```py
# get a reference to asound
sound = ue.find_object('my_sound')
# play the sound at position 0,0,0
self.uobject.play_sound_at_location(sound, FVector(0, 0, 0))
```

如果您更喜欢使用AudioComponent：

```py
from unreal_engine.classes import AudioComponent

class Sounder:
    def begin_play(self):
        # find the AudioComponent of this actor
        self.audio = self.uobject.get_component_by_type(AudioComponent)
        self.audio.call('Stop')
    def tick(self, delta_time):
        # start the sound when pressing 'A'
        if self.uobject.is_input_key_down('A'):
            self.audio.call('Play')
```
