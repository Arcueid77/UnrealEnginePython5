[English](Thumbnail_API.md) | [简体中文](Thumbnail_API.zh-CN.md)

<a id="the-thumbnail-api"></a>

# 缩略图API

> API 示例和上游参考。 [1.0.0支持的API库存](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.zh-CN.md)定义了发布合约。个别例子记录了它们原来的环境。

UE4 python api 公开了两个主要函数来访问缩略图：

```python
thumbnail = uobject.get_thumbnail([force_create])
```

此函数尝试从缓存中获取对象的缩略图，或者（如果在缓存中找不到）从包文件中获取对象的缩略图。

布尔参数如果为 True，则强制函数生成新的缩略图（具有默认大小）（如果asset/package 中不可用）

返回的对象的类型为FObjectThumbail（见下文）

```python
thumbnail = uobject.render_thumbnail([width, height, no_flush])
```

该函数从一个对象生成一个新的FObjectThumbail。默认情况下，纹理流在创建缩略图后刷新。通过指定“no_flush”，流将​​不会被刷新。

<a id="the-fobjectthumbnail-object"></a>

## FObjectThumbnail对象

这个类代表一个缩略图


可以使用以下方法：

```python
width = thumbnail.get_image_width()
```

```python
height = thumbnail.get_image_height()
```

```python
# caould return zero if the thumbnail is not compressed
size = thumbnail.get_compressed_data_size()
```

```python
# returns BGRA bytearray of pixels
data = thumbnail.get_uncompressed_image_data()
```

```python
# if this is a newly created thumbnail, force compression
thumbnail.compress_image_data()
```

有关缩略图 api 检查的方便示例https://github.com/20tab/UnrealEnginePython/blob/master/examples/thumbnail_viewer.py
