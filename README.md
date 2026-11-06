[English](README.md) | [简体中文](README.zh-CN.md)

# UnrealEnginePython

Runtime Python scripting and Unreal Engine bindings for **UE 5.8.1**.
Use Python for gameplay, extend existing Blueprint classes, and run the same
runtime integration in the Editor and packaged Win64 games.

**Stable release — 1.0.0 · November 6, 2026**

[Download 1.0.0](https://github.com/Arcueid77/UnrealEnginePython5/releases/tag/v1.0.0)
· [Release notes](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0.md)
· [Supported API](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.md)
· [Examples](https://github.com/Arcueid77/UnrealEnginePython5Examples/tree/dev/release-1.0.0)

[Documentation index](docs/README.md)

## What you can build

- **Python gameplay** with reflected UObject properties, UFunction calls,
  Actors, components, collections, delegates, timers and Enhanced Input.
- **Blueprint Mixins** that preserve existing Blueprint class identities,
  select named Python profiles per object, fall back to original Blueprint
  functions, and explicitly compose Python and original behavior.
- **Python-defined Unreal types** using transient UClass, FProperty and
  UFunction generation, including reflected parent-event overrides.
- **Managed runtime callbacks** with explicit delegate/input unbinding,
  subscription scopes, cleanup and class-router restoration.
- **Editor tools** using asset, Sequencer and Slate helpers.

The plugin uses the engine-bundled Python runtime. It can share an
Editor interpreter initialized by Epic's PythonScriptPlugin or own the
interpreter when running independently. Public contracts cover interpreter
ownership, game-thread access and controlled reload.
[Lifecycle and threading](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Lifecycle_Threading_API.md)

## Release support

| Component | 1.0.0 release scope |
| --- | --- |
| Unreal Engine | 5.8.1 |
| Python | Engine-bundled CPython 3.11.8 |
| Platform | Windows / Win64 |
| Configurations | Development and Shipping, with configuration-specific validation |
| Distribution | Plugin source, matching Examples source, validation manifest and SHA256SUMS |

The release is distributed as source and requires the Windows C++ toolchain
for your UE 5.8.1 installation. The release record identifies the exact tested
engine build and artifact provenance.
[Platform support](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Platform_Support.md)

## Get 1.0.0

Download the versioned source archives and their checksums.

- [Plugin source](https://github.com/Arcueid77/UnrealEnginePython5/releases/download/v1.0.0/UnrealEnginePython-1.0.0-source.zip)
- [Matching Examples source](https://github.com/Arcueid77/UnrealEnginePython5/releases/download/v1.0.0/UnrealEnginePythonExamples-1.0.0-source.zip)
- [SHA256SUMS.txt](https://github.com/Arcueid77/UnrealEnginePython5/releases/download/v1.0.0/SHA256SUMS.txt)
- [Validation manifest](https://github.com/Arcueid77/UnrealEnginePython5/releases/download/v1.0.0/validation.json)

To get the release through Git, clone the **v1.0.0 tag** together with its
pinned `Demos` submodule.

```powershell
git clone --branch v1.0.0 --recurse-submodules https://github.com/Arcueid77/UnrealEnginePython5.git UnrealEnginePython5
cd UnrealEnginePython5
```

For an existing checkout at that tag, initialize the matching examples with
`git submodule update --init Demos`.

## Install in a project

1. Use a UE 5.8.1 C++ project with the engine's bundled Python runtime available.
2. Extract the plugin source archive into
   `YourProject/Plugins/UnrealEnginePython`. Keep `UnrealEnginePython.uplugin`
   directly inside that directory.
3. Generate project files and build your project's Editor target for
   **Win64 Development**.
4. Open the project, enable **UnrealEnginePython** in the Plugins window
   and restart the Editor when prompted.

Python selection and runtime dependencies are handled through UnrealBuildTool's
`Python3` module.

### Run your first script

Create `YourProject/Content/Scripts/ue_site.py`.

```python
import unreal_engine as ue

ue.log("UnrealEnginePython is ready")
```

The plugin imports `ue_site` during initialization. Restart the Editor and
check the Output Log for the message. The plugin's Python Console also supports
interactive `unreal_engine` calls.

For packaged games, stage project Python scripts as loose NonUFS files so
CPython can import them. The examples include working build, staging and
packaged-runtime workflows.

## Playable examples

The companion repository is pinned as `Demos` in the release checkout.
Its Third Person driver stages a disposable project from the engine's official
Blueprint template and copies the plugin into that project.

| Example | Demonstrates |
| --- | --- |
| Third Person `PythonFirst` | Python-defined Character, Controller and GameMode, movement, camera, collectibles and HUD |
| Third Person `Mixin` | Retained Blueprint classes, per-instance Python profiles, original fallback and live profile switching |
| Lyra integration | Python presentation and selected game-C++ business migration, native gameplay composition, lifecycle, authority and replication checks |

From the core repository root, launch the retained-class sample after
setting `-EngineRoot` to your UE 5.8.1 installation.

```powershell
.\Demos\Run-UEPThirdPersonDemo.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Variant Mixin `
    -Mode Play `
    -Incremental
```

Use `-Variant PythonFirst` for the Python-defined gameplay sample.
The driver also provides `Prepare`, `Audit`, `Smoke` and `Package` modes.
[Example workflows](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/v1.0.0/README.md)

The accepted Lyra migration covers **22 original Blueprint criteria** and
**30 approved game-C++ candidates**, comprising 29 production groups and
one capability-only group. The completion index records each batch and its
acceptance evidence.
[Migration completion](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/v1.0.0/UEPLyraIntegration/Migration/completion_status.json)

## Validation

The 1.0.0 release record includes the following accepted gates.

| Gate | Recorded result |
| --- | --- |
| Source checks | 5,866 host checks and 2,027 Python files checked |
| Generic runtime | Six native suites and 70 checks across shared/owned interpreters, exception recovery, Editor and packaged execution |
| Mixins and lifecycle | Eleven call-matrix lanes and three consecutive PIE sessions with final cleanup |
| Third Person | Both variants in rendered Editor and game-package runs |
| Lyra Development | Fresh cook, listen authority and two remote clients in each Damage/Pawn lane, with 16 independent client views |
| Lyra Shipping | Source/archive build, cook and package, 13 exception/recovery cases, frontend flow and packaged Python locality |

The stable release promotes the implementation accepted in `1.0.0-rc.1`.
Versioned package checks identify the final 1.0.0 source pair. The release
notes record the build provenance, reused source-identical products and
configuration-specific results.
[Stable validation](https://github.com/Arcueid77/UnrealEnginePython5/blob/v1.0.0/Releases/1.0.0/validation.json)
· [Candidate validation details](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Release_1.0.0-rc.1.md)

The migration also includes a bounded 20-minute memory/lifecycle run and
frame-rate, CPU and GameThread comparisons for declared native/Python
workloads. The performance record describes the hardware, workloads and
measurements.
[Memory and lifecycle results](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/v1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H02-acceptance.json)
·
[Performance results](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/v1.0.0/UEPLyraIntegration/Migration/RENDERED_PERFORMANCE.md)

## API and integration guides

- [Supported API inventory](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Supported_API_Inventory.md)
- [Blueprint Mixins and profiles](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Mixin_API.md)
- [Python-defined Unreal classes](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Subclassing_API.md)
- [UObject reflection and calls](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/uobject_API.md)
- [Enhanced Input](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/EnhancedInput_API.md)
- [Runtime subscriptions](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Runtime_Subscriptions_API.md)
- [Ownership, threading and reload](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Lifecycle_Threading_API.md)
- [Native gameplay migration](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/docs/Native_Gameplay_Migration.md)

Mixin routing supports the documented reflected call entries and signatures.
Static, RPC, delegate and latent function bodies retain their native or
Blueprint implementations. Generated Unreal type/signature changes require
a process restart. Controlled Python/profile reload uses explicit
subscription cleanup and router restoration.

## Project history and license

This UE5 continuation builds on Roberto De Ioris and 20tab's
UnrealEnginePython project. The original UE4 documentation and earlier UE5
milestone notes remain available in the versioned history.
[Original project](https://github.com/20tab/UnrealEnginePython)
· [Historical README](https://github.com/Arcueid77/UnrealEnginePython5/blob/v1.0.0/README.md#historical-ue5-migration-notes)

Released under the MIT license.
[LICENSE](LICENSE)
