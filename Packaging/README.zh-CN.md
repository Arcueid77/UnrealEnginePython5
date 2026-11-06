[English](README.md) | [简体中文](README.zh-CN.md)

<a id="release-packaging"></a>

# 发布打包

`Build-UEPRelease.ps1` 创建以提交为标识的发布产物，无需将插件安装到 Unreal Engine 或修改引擎源代码。

<a id="source-release"></a>

## 源码发布

从干净的提交工作树运行：

```powershell
.\Packaging\Build-UEPRelease.ps1
```

源 zip 来自 `git archive`，使用明确的公共白名单，并排除构建输出、二进制文件、中间体、字节码缓存和内部参考材料。 `manifest.json` 记录准确的提交、版本、条目数、字节大小和SHA-256。 `SHA256SUMS.txt`适合发布上传验证。重新运行相同的提交会产生相同的源存档内容，同时写入新的非破坏性结果目录。

<a id="optional-win64-binary-package"></a>

## 可选Win64二进制包

```powershell
.\Packaging\Build-UEPRelease.ps1 `
    -EngineRoot F:\UnrealEngine `
    -IncludeBinary `
    -TargetPlatforms Win64
```

这会调用 UE5.8 AutomationTool `BuildPlugin`，验证其成功标记，并将其哈希和 engine/platform 身份添加到同一清单中。 BuildPlugin 永远不会收到存储库路径：脚本将经过审核的源 zip 提取到隔离的暂存树并编译该确切的提交。在接受产物之前，会扫描生成的包树和最终 zip 中的存储库元数据、内部参考材料、临时主机项目和Python字节码。二进制产物在其文件名中与确切的 UE 版本和目标平台相关联。它不是一个可移植的跨版本插件二进制文件。

产物被写入`.build/Releases/<version>/`并且保持未跟踪状态。 `-AllowDirty`仅用于开发打包脚本而存在。发布证据必须来自默认的 clean-worktree 路径。
