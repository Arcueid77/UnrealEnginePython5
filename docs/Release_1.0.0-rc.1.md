[English](Release_1.0.0-rc.1.md) | [简体中文](Release_1.0.0-rc.1.zh-CN.md)

# UnrealEnginePython 1.0.0-rc.1

The release candidate targets Unreal Engine 5.8.1, its bundled CPython 3.11 and
Win64. The candidate retains the Beta descriptor flag. Development and Shipping
validation are recorded separately.

The accepted migration baseline covers the original twenty-two Blueprint
criteria, thirty selected game-C++ candidates (twenty-nine production groups and
one capability group), H01-H05, and actual Escape/Menu input. The candidate adds
a frozen supported API, current core/interpreter tests, a Shipping source build
and cooked runtime acceptance, source/archive installation, and checksummed
release artifacts.

Candidate validation passed on 2026-11-06. The complete evidence manifest is
[validation.json](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/Releases/1.0.0-rc.1/validation.json).

| Gate | Accepted result |
| --- | --- |
| Indexed source | 5,866 host checks and 2,027 Python files |
| Supported API | 213 module and 462 UObject registrations retained |
| Generic | Six native suites, seventy checks across shared/owned interpreters, exceptions, Editor and the actual game package |
| Mixin | Eleven call-matrix lanes and three consecutive PIE sessions with final cleanup |
| Third Person | PythonFirst and Mixin rendered Editor runs and rendered game packages, including six packaged images |
| Lyra Development | Fresh candidate cook and two remote clients for each Damage/Pawn lane, eight authority trials and sixteen independent client views |
| Lyra Shipping | Fresh source-archive installation, 1,151 build actions, actual cook/archive, thirteen exception/recovery cases and normal frontend flow |
| Runtime locality | Actual packaged Python DLL/home and 4,578 receipt files checked |

The Shipping source build took 11,524.80 seconds. Every reviewed action output
stays in the isolated project. Protected Engine binaries/manifests and the
official reference inputs retain their fingerprints.

The Editor tools and Development Lyra game products reuse verified
native-source-identical artifacts. Development candidate content is freshly
cooked and its actual network lanes are rerun. Shipping compiles the complete
configuration from the installed source archive.

Git source archives use LF while Windows checkout text can use CRLF. Installation
records 139 exact newline-only materializations, with strict binary/content
hashes. The original failed materialization attempt remains in the evidence.

Shipping starts its configured frontend because the engine's default policy
disables command-line map override. The opt-in gameplay validation uses native
`GameplayStatics.OpenLevel` from that frontend. Its original waiting attempt is
retained. The final package passes all thirteen recovery cases and normal exit.

The first rendered Mixin package exposed a startup-render-hitch timing defect in
the smoke fixture. The observation window now starts after native key delivery
and crosses native frames, while retaining the original movement threshold.
Editor and packaged rendering pass after the correction. Full source validation
also repaired missing snapshot documents, localized PowerShell error decoding
and historical completion/bootstrap assertions. Failed captures remain retained.

Source archives, the Examples archive, the validation manifest and SHA256SUMS
form the release artifacts. Both repository tags identify the final source pair.

The bounded twenty-minute H02 run recorded about 207 MiB of private-memory
growth within its declared 256 MiB budget. The H05 synthetic workload adds
200 rule queries per frame and measures additional Python GameThread/CPU cost.
Their durations, workloads and results remain available in the linked migration
ledgers. The platform matrix records the configurations accepted by this release.

The supported API is described in [Supported API inventory](Supported_API_Inventory.md),
[Mixin API](Mixin_API.md), [lifecycle and threading](Lifecycle_Threading_API.md)
and [runtime subscriptions](Runtime_Subscriptions_API.md). These documents define
the callable signatures, ownership, reload and game-thread contracts.
