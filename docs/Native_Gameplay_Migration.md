# Lyra native gameplay migration

The user approved CPP-001 through CPP-015 on 2026-11-01. Progress and per-batch
acceptance live in [the Examples ledger](../Demos/UEPLyraIntegration/Migration/cpp_batches.json).
This extends the earlier accepted Blueprint scope; it does not reopen or replace it.

CPP01 moves elimination streak, rapid elimination chain, and assist rules into
Python. Four native callback seams are `BlueprintNativeEvent` functions. The
original C++ bodies remain selectable through `NativeFallback`; native Gameplay
Message registration, authority roles, and listener shutdown retain their existing
ownership. The UEP binding source and engine binaries were not changed.

The [source patch and implementation notes](../Demos/UEPLyraIntegration/Migration/NativeGameplay/README.md)
and [CPP01 acceptance](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP01-acceptance.json)
identify the precise scope. Validation passed native/Python payload and broadcast
ordering comparisons, exact 4.5-second clock boundaries, nested assist broadcasts,
and native EndPlay/listener cleanup. A dedicated server and two actual clients in
each profile then passed six native GAS damage applications, five native health
deaths, one assist, native score replication, and owner notification checks.
The clients used NullRHI: this batch does not establish visible rendering or a new
package. The approved stage target remains UE5.8.1 / CPython3.11 / Win64 Development.

Validation runs against an independent disposable project copied from the existing
accepted, compiled Lyra stage. The official `F:/LyraStarterGame` reference stays
unchanged. These local validation entry points reuse that stage's compiler response
files and native dependencies; they require the accepted baseline and are not a
general clean-machine SDK installer.

```powershell
$root = 'F:/UnrealEnginePython5/.build/LyraValidation/CppGameplay/20261101-CPP01'
# Initial stage preparation, before applying the native patch:
& 'F:/UnrealEngine/Engine/Binaries/ThirdParty/Python3/Win64/python.exe' -B -X utf8 `
  Demos/UEPLyraIntegration/Tools/prepare_native_gameplay_stage.py `
  --source .build/LyraValidation/Full/Stage/Lyra `
  --stage .build/LyraValidation/CppGameplay/Stage/Lyra --result "$root/stage-copy.json"

# Use a new output directory for every attempt; never overwrite earlier evidence.
& Validation/Run-UEP58NativeMessageBuild.ps1 -OutputDirectory "$root/Build02"
& Validation/Run-UEP58NativeMessageAuthoring.ps1 `
  -BuildEvidenceDirectory "$root/Build02" -OutputDirectory "$root/Assets03"
& Validation/Run-UEP58NativeMessageValidation.ps1 `
  -BuildEvidenceDirectory "$root/Build02" -AssetEvidenceDirectory "$root/Assets03" `
  -OutputDirectory "$root/Runtime01"
& Validation/Run-UEP58NativeMessageNetworkValidation.ps1 `
  -BuildEvidenceDirectory "$root/Build02" -AssetEvidenceDirectory "$root/Assets03" `
  -OutputDirectory "$root/Network03"
```

Only ShooterCoreRuntime header generation, one module compilation, and linking
were required. No full engine compilation or Cook ran. Future batches follow the
approved order and affected regression scope. After each accepted batch, push
Examples first, then the main repository's validation entry points and gitlink.
