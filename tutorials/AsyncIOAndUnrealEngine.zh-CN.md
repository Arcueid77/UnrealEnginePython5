[English](AsyncIOAndUnrealEngine.md) | [简体中文](AsyncIOAndUnrealEngine.zh-CN.md)

<a id="using-asyncio-with-unreal-engine"></a>

# 将 asyncio 与 Unreal Engine 一起使用

> 历史指南。此页面记录其原始里程碑或上游环境。有关当前支持，请参阅[1.0.0发布记录](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.zh-CN.md)和[支持的API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)。

<a id="asyncio--what-is-it-"></a>

# 异步？它是什么？

从 python 3.4 开始可用，asyncio (https://docs.python.org/3/library/asyncio.html) 是在现代 Python 应用程序中处理高并发时的“必经之路”。

它将基本的非阻塞编程模式与“协程”概念混合在一起。您可以将协程视为即使在执行流程中间也可以“暂停”和“恢复”的函数

考虑以下示例（使用 python >= 3.6 从标准 shell 运行它）：

```python

import asyncio

async def simple_timer(frequency):
    while True:
        await asyncio.sleep(frequency)
        print('{0} seconds elapsed'.format(frequency))

loop = asyncio.get_event_loop()

asyncio.ensure_future(simple_timer(1))
asyncio.ensure_future(simple_timer(3))

loop.run_forever()
```

运行该示例将导致无限输出：

```
1 seconds elapsed
1 seconds elapsed
3 seconds elapsed
1 seconds elapsed
1 seconds elapsed
1 seconds elapsed
3 seconds elapsed
1 seconds elapsed
1 seconds elapsed
...
```

发生什么事了？

`simple_timer` 函数实际上是一个“协程”（使用 `async def` 定义它会通知 python 虚拟机该函数可以挂起）。

尽管该函数包含 `while True:` 循环，但 `await` 调用允许挂起协程并将控制权传回某种“集线器”（循环引擎），该集线器将在指定的秒数后将控制权返回给 simple_timer 函数。

除了等待时间之外，循环引擎还能够等待文件描述符准备就绪以及所谓的“未来”（将它们视为持有可监视更改的值的对象）

这是等待来自流行的 telnet 站点 `towel.blinkenlights.nl` 的数据的另一个示例，该网站返回 Star Wars Episode IV 的 ascii 艺术版本：

```python
import asyncio

async def simple_timer(frequency):
    while True:
        await asyncio.sleep(frequency)
        print('{0} seconds elapsed'.format(frequency))

async def star_wars():
    reader, writer = await asyncio.open_connection('towel.blinkenlights.nl', 23)
    while True:
        data = await reader.read(1024)
        if not data:
            break
        print(data.decode())

loop = asyncio.get_event_loop()
asyncio.ensure_future(simple_timer(1))
asyncio.ensure_future(simple_timer(3))

asyncio.ensure_future(star_wars())

loop.run_forever()
```

一个新的协程已经产生，它在等待连接到主机时挂起自己，一旦建立连接，循环引擎就会将控制权交还给它。在 while 循环中，只要需要等待来自套接字的数据，协程就会自行挂起。

当没有更多数据时，协程结束。

运行脚本将沿着我们之前见过的2计时器打印ascii艺术。全部同时进行。

<a id="why-using-asyncio-in-unreal-engine-4-"></a>

## 为什么在 Unreal Engine 4 中使用 asyncio ？

有很多 asyncio 第三方库和框架可用。

有用于数据库交互、http 和 websockets 服务、dns 以及任何您能想到的 asyncio 模块（客户端和服务器）。

这些包装器非常易于使用，并且可以让您完全摆脱并发问题。所有这些都将与 UE4 主循环配合使用（在编辑器和游戏中），因此您基本上可以在 Unreal Engine 4 中执行 asyncio 允许的任何操作。

想要将 HTTP 服务器集成到UE 中吗？可行的。想要等待 redis pubsub 队列吗？可行的。想通过 ssh 向编辑器发出命令吗？可行的。嗯，确实有无限的可能性:)

<a id="adding-an-asyncio-loop-engine-in-the-ue4-core"></a>

## 在UE4核心中添加异步循环引擎

我们将首先向我们的项目添加一个新的（非常简单）模块（称之为ue_asyncio.py）：

```python
import asyncio
import unreal_engine as ue

loop = asyncio.new_event_loop()

asyncio.set_event_loop(loop)

def ticker_loop(delta_time):
    try:
        loop.stop()
        loop.run_forever()
    except Exception as e:
        ue.log_error(e)
    return True


ticker = ue.add_ticker(ticker_loop)
```

不要运行此模块，它将只是我们项目的其他部分将连接到的“集线器”。

基本上，当您第一次导入此模块时，一个新的“股票代码”将被注册到Unreal Engine中。股票代码是一种周期性“滴答”的功能。在这种情况下，Unreal Engine将使用这个ticker函数来唤醒异步循环引擎来管理所有注册到它的协程。

让我们从前面的计时器示例开始：

```python
import asyncio
import unreal_engine as ue

import ue_asyncio

async def simple_timer(frequency):
    while True:
        await asyncio.sleep(frequency)
        ue.log('{0} seconds elapsed'.format(frequency))

asyncio.ensure_future(simple_timer(2))
```

如果您在 UE Python 控制台中运行此脚本，您将开始每隔 2 秒收到消息。

如果重新运行脚本，将会生成一个新的协程，但旧的协程仍然存在......

通常这不是您想要的，幸运的是每个 asyncio 循环都允许您访问当前可用协程的列表，并最终取消它们：

```python
for task in asyncio.Task.all_tasks():
    task.cancel()
```

<a id="a-simple-tcp-server-spawning-characters-in-the-editor"></a>

## 一个简单的 TCP 服务器在编辑器中生成角色

这是一个更复杂（但更有用）的示例，展示了如何在 UE 实例中打开 TCP 服务器，以允许外部通信。

在这里，协议非常愚蠢：客户端发送的每个留置权都会生成一个新的角色，其名称设置为客户端传递的字符串。

```python
import asyncio
import ue_asyncio
from unreal_engine.classes import Character

# cleanup previous tasks
for task in asyncio.Task.all_tasks():
    task.cancel()

# this is called whenever a new client connects
async def new_client_connected(reader, writer):
    name = writer.get_extra_info('peername')
    ue.log('new client connection from {0}'.format(name))
    while True:
        # wait for a line
        data = await reader.readline()
        if not data:
            break
        ue.log('client {0} issued: {1}'.format(name, data.decode()))
        # spawn a new Character and set its label
        new_actor = ue.get_editor_world().actor_spawn(Character)
        new_actor.set_actor_label(data.decode())
    ue.log('client {0} disconnected'.format(name))

# this spawns the server
# the try/finally trick allows for gentle shutdown of the server
# see below for more infos about exception management
async def spawn_server(host, port):
    try:
        coro = await asyncio.start_server(new_client_connected, host, port, reuse_address=True)
        ue.log('tcp server spawned on {0}:{1}'.format(host, port))
        await coro.wait_closed()
    finally:
        coro.close()
        ue.log('tcp server ended')
    
asyncio.ensure_future(spawn_server('192.168.173.45', 8885))
```

<a id="redis-pubsub"></a>

## Redis 发布订阅

另一个有用的例子，这里我们订阅远程redis队列，并等待消息

```python
import asyncio
import ue_asyncio
import unreal_engine as ue
import aioredis

# cleanup previous tasks
for task in asyncio.Task.all_tasks():
    task.cancel()

async def wait_for_redis():
    redis = await aioredis.create_redis(('192.168.173.27', 6379))
    channel, = await redis.subscribe('foobar')
    ue.log('subscribed to redis queue, waiting for messages ...')
    while await channel.wait_message():
        msg = await channel.get()
        ue.log_warning(msg)
    redis.close()
    ue.log_warning('done with redis')

asyncio.ensure_future(wait_for_redis())
```

<a id="managinx-exceptions-in-non-awaited-coroutines"></a>

## 非等待协程中的 Managinx 异常

默认情况下，在非等待协程中抛出的异常（例如使用 asyncio.ensure_future 生成的异常）不会被传播。

您可以使用多种技巧来管理它们。最简单的一种是在协程本身中捕获异常并将其报告为 UE 错误：

```python
async def connecto_to_a_broken_redis():
    try:
        redis = await aioredis.create_redis(('192.168.173.27', 6379))
        ...
    except Exception as e:
        ue.log_error(e)
    finally:
        # here you can run important cleanup tasks
        redis.close()
```

一种更优雅的方法是在协程结束时添加回调，我们将检查它是否因异常而死亡或已被取消（或者显然它只是完成了工作）：

```python

async def broken_coroutine():
    raise Exception('OOOOOOPS')
    
def check_exception(coro):
    # if the coroutine has been cancelled, just ignore it
    if coro.cancelled():
            return
    # check if the coroutine ended with an exception
    exc = coro.exception()
    # in such a case raise/propagate it
    if exc:
        raise exc

coroutine = asyncio.ensure_future(broken_coroutine())
coroutine.add_done_callback(check_exception)
```

请记住，您只需要注意未等待的协程，其他协程将正确地将异常传播到等待它的任务（显然该任务可能是未等待的任务，因此作为一般规则，每次使用asyncio.ensure_future()时添加回调）

<a id="aiohttp"></a>

## aiohttp

这可能是最著名的第三方异步模块。它基本上与每个 HTTP 方面交互（服务器、客户端、websockets...）

<a id="asyncio-in-your-actors"></a>

## 演员中的 asyncio

<a id="a-simple-icecastshoutcast-streaming-radio-component"></a>

### 一个简单的Icecast/Shoutcast流媒体广播组件

```python
import ue_asyncio
import asyncio
import aiohttp
import unreal_engine as ue
from unreal_engine.classes import SoundWaveProcedural, AudioComponent
import mpg123
import os

class RadioStreaming:

    def initialize_component(self):
        ue.print_string('Hello')
        self.actor = self.uobject.get_owner()
        self.audio = self.actor.get_actor_component_by_type(AudioComponent)
        self.audio.Sound = SoundWaveProcedural()
        self.audio.Sound.Duration = 10000
        # if you do not have libmpg123 in the system path, specify its absolute location here
        # self.mp3 = mpg123.Mpg123(library_path=os.path.join(ue.get_content_dir(), 'libmpg123-0.dll'))
        self.mp3 = mpg123.Mpg123()
        self.coroutine = asyncio.ensure_future(self.stream('http://178.32.136.160:8050'))
        self.coroutine.add_done_callback(self.check_exception)

    def check_exception(self, coro):
        if coro.cancelled():
            return
        exc = coro.exception()
        if exc:
            raise exc

    async def stream(self, url):
        async with aiohttp.ClientSession() as session:
            async with session.get(url) as response:
                ue.log_warning('start of stream')
                while True:
                    chunk = await response.content.read(4096)
                    if not chunk:
                        break

                    self.mp3.feed(chunk)

                    if not self.audio.IsPlaying():
                        rate, channels, encoding = self.mp3.get_format()
                        self.audio.Sound.SampleRate = rate
                        self.audio.Sound.NumChannels = channels
                        self.audio.Play()

                    for frame in self.mp3.iter_frames():
                        self.audio.Sound.queue_audio(frame)
                        

    def end_play(self, reason):
        ue.log_warning('end of stream')
        self.coroutine.cancel()
```

<a id="pyuserwidget-websocket-echo-test"></a>

### PyUserWidget WebSocket 回声测试

![PyUserWidget设计师](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/AsyncIO_Assets/py_user_widget_designer.PNG)


![PyUserWidget图](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/AsyncIO_Assets/py_user_widget_graph.PNG)

![PyUserWidget等级Blueprint](https://github.com/20tab/UnrealEnginePython/blob/master/tutorials/AsyncIO_Assets/py_user_widget_level_blueprint.PNG)

```python
import unreal_engine as ue
import ue_asyncio
import asyncio
import aiohttp

class Echo:

    def construct(self):
        self.coroutine = asyncio.ensure_future(self.ws_connect('ws://echo.websocket.org'))
        self.coroutine.add_done_callback(self.check_exception)
        self.ws = None


    def button_clicked(self):
        if self.ws:
            self.ws.send_str(self.uobject.Input.GetText())

    def check_exception(self, coro):
        if coro.cancelled():
            return
        exc = coro.exception()
        if exc:
            raise exc

    async def ws_connect(self, url):
        session = aiohttp.ClientSession()
        async with session.ws_connect(url) as ws:
            self.ws = ws
            async for msg in ws:
                orig_text = self.uobject.WSData.GetText()
                self.uobject.WSData.SetText(orig_text + '\n' + msg.data)
        await ws.close()              

```

<a id="additional-transient-loop-engines"></a>

## 额外的“瞬态”循环引擎

<a id="note-concurrency-vs-parallelism"></a>

## 注意：并发与并行

在整个教程中，我从未使用过术语“并行性”。

区分“并发”和“并行”很重要。 “并发”是指软件管理多个任务的可能性，“并行”是指并行执行这些任务的一种方式（每个 CPU 核心一个）。线程是一种获得并行性的方法（尽管在Python中并不总是如此）以及进程。

协程的工作原理与经典游戏引擎（包括 unreal）非常相似：我们将代码路径分割为多个微小的逻辑抽象（如 UE 中的 Actors），并且我们连续地对每个suspend/resume 进行操作，给用户一种多个组件同时协同工作的错觉。 （实际上，这也是内核调度程序的工作方式，如果您有一个 cpu 核心，您的计算机进程永远不会并行运行！）。

有关 python 线程和 asyncio 协程之间协作的更多信息，请查看此处：https://docs.python.org/3/library/asyncio-dev.html#concurrency-and-multithreading（TLDR，如果您不知道自己在做什么，请不要混合它们:P）
