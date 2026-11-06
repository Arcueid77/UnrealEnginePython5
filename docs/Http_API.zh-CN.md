[English](Http_API.md) | [简体中文](Http_API.zh-CN.md)

<a id="the-http-api"></a>

HTTP API
=

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

IHttpRequest 和 IHttpResponse 接口公开为 Python 类（均继承自 IHttpBase）

此处提供单元测试：https://github.com/20tab/UnrealEnginePython/blob/master/tests/test_http.py

其用法非常“Pythonic”，并且支持轮询和事件方法：

```python
from unreal_engine import IHttpRequest
import json

request = IHttpRequest('GET', 'http://httpbin.org/user-agent')

def response_received(request, response, success):
    data = json.loads(response.get_content_as_string())
    ue.log(data['user-agent'])

# bind OnProcessRequestComplete event to the response_received callable
request.bind_on_process_request_complete(response_received)

# run the request
request.process_request()
```

如果您更喜欢轮询方法，则需要检查 get_status() 返回值（一个 int）。在C++中它被定义为：

```c++
namespace EHttpRequestStatus
{
    enum Type
    {
        NotStarted,
        Processing,
        Failed,
        Failed_ConnectionError,
        Succeeded,
    }
}
```

因此任何值 >= 2 都将是请求完成的标志：

```python
from unreal_engine import IHttpRequest
import json

request = IHttpRequest('GET', 'http://httpbin.org/user-agent')

# run the request
request.process_request()

# check its status

if request.get_status() >= 2:
    response = request.get_response()
    data = json.loads(response.get_content_as_string())
    ue.log(data['user-agent'])
```

如果你想在循环中调用request.get_status()，请确保“勾选”它（否则你将永远阻塞，因为 python 永远不会将控制权交还给 unreal）：

```python
from unreal_engine import IHttpRequest
import json

request = IHttpRequest('GET', 'http://httpbin.org/user-agent')

# run the request
request.process_request()

# check its status
# tick it at each iteration to avoid blocking ue forever !
# the argument of tick is the DeltaSeconds added to the value returned by get_elapsed_time()
while request.get_status() < 2:
    request.tick(0.01)
    
response = request.get_response()
data = json.loads(response.get_content_as_string())
ue.log(data['user-agent'])
```

如果请求长时间运行，可以绑定另一个事件：

```python
from unreal_engine import IHttpRequest
import json

request = IHttpRequest('GET', 'http://httpbin.org/user-agent')

def response_received(request, response, success):
    data = json.loads(response.get_content_as_string())
    ue.log(data['user-agent'])
    
def request_progress(request, sent, received):
    ue.log(sent)
    ue.log(received)

# bind OnProcessRequestComplete event to the response_received callable
request.bind_on_process_request_complete(response_received)

request.bind_on_request_progress(request_progress)

# run the request
request.process_request()
```

<a id="exposed-methods-for-ihttpbase-inherited-by-ihttprequest-and-ihttpresponse"></a>

IHttpBase的公开方法（由IHttpRequest和IHttpResponse继承）
-


<a id="get_content"></a>

### get_content()

返回request/response的有效负载

<a id="get_all_headers"></a>

### get_all_headers()

以字符串列表的形式返回标头列表，其中每个项目为 'HeaderKey: HeaderValue'

<a id="get_content_length"></a>

### get_content_length()

返回request/response主体长度

<a id="get_content_type"></a>

### get_content_type()

返回 request/response 正文内容类型

<a id="get_headername"></a>

### get_header(姓名)

返回指定的request/response标头的值

<a id="get_url"></a>

### get_url()

返回网址

<a id="get_url_parametername"></a>

### get_url_parameter(姓名)

获取 url 查询字符串项的值


<a id="exposed-methods-for-ihttprequest"></a>

IHttpRequest 的公开方法
-

<a id="bind_on_process_request_completecallable"></a>

### bind_on_process_request_complete（可调用）

为 OnProcessRequestComplete 事件分配一个 python 可调用对象

<a id="bind_on_request_progresscallable"></a>

### bind_on_request_progress（可调用）

为 OnRequestProcess 事件分配一个 python 可调用对象

<a id="append_to_headerkey-value"></a>

### append_to_header（键，值）

将新值附加到已存在的请求标头

<a id="cancel_request"></a>

### cancel_request()

取消正在运行的请求

<a id="get_elapsed_time"></a>

### get_elapsed_time()

获取完成请求所需的秒数（由刻度控制）

<a id="get_response"></a>

### get_response()

获取请求的IHttpResponse（如果可用）

<a id="get_status"></a>

### get_status()

获取请求的状态（请参阅上面的可能值）

<a id="get_verb"></a>

### get_verb()

获取请求的http METHOD（如果设置）

<a id="process_request"></a>

### process_request()

运行请求

<a id="set_contentbody"></a>

### set_content(正文)

设置请求正文（作为字符串或字节）

<a id="set_headerkey-value"></a>

### set_header（键，值）

设置请求头

<a id="set_urlurl"></a>

### set_url(网址)

将 url 分配给请求

<a id="set_verbhttp_method"></a>

### set_verb(http_method)

将 http METHOD 分配给请求

<a id="tickdelta_seconds"></a>

### 勾选(delta_seconds)

“勾选”http 引擎

<a id="exposed-methods-for-ihttpresponse"></a>

IHttpResponse 的公开方法
-

<a id="get_response_code"></a>

### get_response_code()

返回响应状态码

<a id="get_content_as_string"></a>

### get_content_as_string()

以字符串形式返回响应正文
