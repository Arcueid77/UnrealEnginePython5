# UEP 5.8 automated validation

Current validation uses the approved upstream UE 5.8.1 update and bundled
CPython 3.11. For each migration batch, `Test-UEPStagedBatch.ps1` tests isolated
Git-index-only core and Examples archives, then
`Save-UEPBatchAcceptance.ps1` records bounded native evidence. Host/model checks
are not runtime acceptance. Native runs retain their actual DLL provenance;
later source-hash freezes do not re-execute old scenarios. Failed or unfinished
batches must not be committed as accepted. See
[batch ledgers](../Demos/UEPLyraIntegration/Migration/Acceptance/) and
[current progress](../Demos/UEPLyraIntegration/Migration/PROGRESS.md).

As requested on 2026-10-20, regression is incremental by default. The staged
driver checks changed Python syntax/imports and selects host tests affected by
local imports, inheritance and literal module/file references. Each report lists
changed paths, selected tests, dependency reasons and unmapped paths. Add
`-TestPattern 'test_footstep_*.py'` for dependencies that static analysis cannot
resolve. A code change with no identified tests fails with a request for an
explicit test scope; it never silently expands to the full suite. Native asset,
runtime, caller and lifecycle scenarios still run for the affected feature.

Use `-FullRegression` only for an intentionally broad check, such as shared SDK
changes or version acceptance; it also checks every indexed Python file. The
direct host runner has matching `--test-pattern`, `--changes-file` and explicit
`--all` options. Historical full-suite counts remain historical; an incremental
report only certifies its listed tests. Full mode includes both Examples and
Validation Python tests.

`UEP58Host` is a disposable, minimal C++ project used to validate the current
plugin against Unreal Engine 5.8 and the engine-bundled CPython 3.11.

The validation driver copies the project and the current plugin sources into
`.build/Validation/UEP58Host`. It never installs the plugin into the engine and
does not modify Unreal Engine source code.

## Validation scope and cost

The [roadmap](../ROADMAP.md) separates implementation, historical evidence and
release approval. 0.8 is unreleased: the old Lyra `All` run does not include
`HUDAudit`, enforce exactly one active presenter, verify post-shutdown zero
owned callbacks, or prove rendered animation parity. The updated driver now
audits HUD-enabled `All` and enforces one active presenter plus final Python-exit
evidence. Host checks, a fresh strict HUD audit and current-script NullRHI
Standalone now pass. Integrated `All`, synchronized network, package and visual
acceptance remain open; see the scoped 2026-09-07 record in
[Validation history](../docs/Validation_History.md).

Run the lightweight checks without launching or compiling Unreal:

```powershell
& F:\UnrealEngine\Engine\Binaries\ThirdParty\Python3\Win64\python.exe -B Validation/Run-UEPLyraHostTests.py --result .build/host-incremental.json
.\Validation\Tests\Test-LyraHUDContracts.ps1
```

These currently pass 17 Python tests and 28 PowerShell checks. Runtime report
schema 5 preserves `hud` as the active snapshot and adds `shutdown.hud` from
Python `atexit`, after the UEP Mixin pre-exit cleanup. `awaiting_shutdown` is
not success. The driver waits for process completion and verifies ordered
exit markers; missing finalization or residual counters/references fail.

Use diff/format/link checks for documentation; host tests and affected runtime
scenarios for Python changes; affected incremental builds for C++/reflection;
and staged generation/audits when Blueprint declarations change. Reusing a
native binary for script-only work requires matching native-source provenance
and recording the actual new script hashes. Announce full cook/package work
before starting it and reserve the full matrix for candidates or relevant risk.

Retained packages are Win64 Development. The generic driver accepts DebugGame,
but this review establishes no DebugGame or Shipping validation. A future RC
must record exact core/Examples/engine/Python/configuration provenance using the
[candidate record](../docs/Validation_History.md#candidate-record-template);
old green results and skip modes are not current-source release approval.

The desktop-only host disables the unrelated `AndroidFileServer` plugin for
editor, cook and packaged execution so Android deployment tooling is outside
this acceptance contract. Its package step waits for Unreal's global UAT mutex
instead of failing or interfering when another project is cooking. It also uses
UE's loose cooked-package writer so staging does not depend on a transient local
Zen server remaining alive after Cook exits. The driver's `MaxParallelActions`
limit and `-NoUBA` policy apply to both direct Editor compilation and UAT's
nested Game build; the package wait allows two hours so a memory-safe low
parallelism build is not mistaken for a compiler failure.

## Core release gate

The core gate is complete only when a clean full run returns exit code 0 and its
`summary.json` reports `status: passed`, UE 5.8, Python 3.11 and all six required
suites. The unchanged 0.5.0 core contract contains 70 required checks: 21 shared core checks,
21 standalone core checks, two isolated exception-recovery checks, five editor
checks and 21 packaged core checks. The core cases exercise UE5 `FField`-based
dynamic class/function generation, `TSet`, non-trivial string returns, thread
diagnostics, animation, UDP receiver lifecycle, parent event overrides and
Enhanced Input callback release. Known exclusions must remain explicitly listed
rather than being silently counted as passes.

The release gate also preserves the independent Python-first Third Person
audit, headless gameplay smoke and packaged gameplay smoke documented in
[`../Demos/README.md`](../Demos/README.md). A green core report alone does not
claim gameplay parity.

The validation output is local evidence and is intentionally ignored by Git.
Source changes must be followed by a new run; an older green result is not a
substitute for testing the changed source.

Release-candidate result `20260812-043408` passed all six suites and 70/70
checks against UE 5.8.0 and CPython 3.11.8. Its full Development BuildCookRun
reported `BUILD SUCCESSFUL` and ExitCode 0, and its hash-recorded stable package
completed the packaged core suite without fatal or error diagnostics.

## Full acceptance run

From the repository root:

```powershell
.\Validation\Run-UEP58Validation.ps1 -EngineRoot F:\UnrealEngine
```

The full run performs:

1. `UEP58HostEditor` compilation and plugin module linking;
2. `UEP58Host` Game compilation/linking as part of packaging;
3. core reflection tests while sharing Epic's Python interpreter;
4. the same core tests with `-DisablePython`, so UEP owns CPython 3.11;
5. shared and standalone exception-boundary processes whose expected traceback
   is strictly filtered from any unexpected engine/Python errors;
6. full-editor Actor, asset, Sequencer and Slate lifetime tests;
7. Win64 Development cook/package and a packaged-runtime core test;
8. JSON result and log validation, including fatal/assert detection.

Results are written under `.build/Validation/Results/<timestamp>/summary.json`.
Any failed build, missing result, failed test, fatal log marker or non-zero child
process exit causes the driver to return exit code 1. The two exception lanes
may return 0 or 1 because UE commandlets count a handled logged Python exception
as an error; their JSON recovery result and every `Log*: Error:` line are still
validated explicitly.

Timestamped results keep per-run logs, JSON reports and the SHA-256 of the
tested game executable. The package itself is archived directly to the guarded
fixed path `.build/Validation/Package`; Windows Firewall keys unpackaged
listeners by their complete executable path, so later runs do not appear as new
`UEP58Host` applications. Preconfigure TCP/UDP inbound **Block** rules for
`.build/Validation/Package/Windows/UEP58Host/Binaries/Win64/UEP58Host.exe`, or
choose **Cancel** if Windows asks once. The loopback-only UDP lifecycle test does
not need public/private inbound access. Do not disable Firewall notifications
globally.

Packaged success is not inferred from the JSON marker alone. The executable
must return exit code 0 after Unreal tears down its object system and UEP-owned
CPython. This caught a `BlendSpace` reflected-struct shallow copy that passed all
assertions but corrupted memory during process shutdown.

Each result directory keeps the UBT log, the complete AutomationTool log, the
per-suite Unreal logs and machine-readable JSON reports. A successful full run
contains six suites:

| Suite | Interpreter ownership | Required checks |
| --- | --- | --- |
| core/shared | Epic `PythonScriptPlugin` | reflection, values, `TSet`, animation, UDP lifecycle, dynamic classes/functions, Enhanced Input callback lifetime, delegates and GC |
| core/standalone | UEP | the same core contract with `-DisablePython` |
| exception/shared | Epic `PythonScriptPlugin` | reflected callback exception logging and subsequent-call recovery |
| exception/standalone | UEP | the same exception boundary with UEP-owned Python |
| editor/shared | Epic `PythonScriptPlugin` | Actor lifecycle, asset/Level Sequence save/load, Sequencer operations and Slate item ownership |
| core/packaged | UEP | cooked executable startup and the full core contract |

All modes require the engine-bundled CPython 3.11. The packaged suite also
requires the `UEP_PACKAGED_VALIDATION_PASSED` runtime marker.

## Faster development run

Skip packaging and reuse the existing staging directory:

```powershell
.\Validation\Run-UEP58Validation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -SkipPackage `
    -Incremental
```

Omit `-Incremental` for a clean staging copy. Clean-up is restricted to the
script-marked `.build/Validation/UEP58Host` and
`.build/Validation/Package` directories.

The quick run still compiles the Runtime plugin through UBT's foreign-plugin
mode. While iterating only on Python tests, that compile can also be skipped:

```powershell
.\Validation\Run-UEP58Validation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -SkipPackage `
    -SkipRuntimeCompile `
    -Incremental
```

## Linux lane and platform readiness

The Win64 host can record whether another UBT platform has the required UE5.8
SDK without installing or changing that SDK:

```powershell
.\Validation\Test-UEP58PlatformReadiness.ps1 `
    -EngineRoot F:\UnrealEngine `
    -Platform Linux
```

Add `-Strict` when an invalid platform should fail CI. A UE5.8 Linux machine can
run `Validation/Run-UEP58LinuxValidation.sh`; the matching GitHub workflow
targets a self-hosted runner labelled `linux` and `unreal-engine-5.8`. It builds
the Editor and foreign runtime plugin targets, then executes both interpreter
ownership modes. Merely defining this lane is not a Linux support claim: a
green `summary.json` artifact is required.

## Current intentional exclusions

The suite records, but does not fail for, these known limitations:

- Unreal's unattended asset deletion reference scan is not used; the driver
  removes only the two exact disposable Material/Level Sequence asset files
  after the editor process exits;
- the current local UE5.8 install lacks the required Linux
  `v26_clang-20.1.8-rockylinux8` SDK, so only Win64 is release-validated.

Runtime exclusions stay visible in suite JSON; platform availability is kept in
the separate readiness JSON until a real Linux lane result exists.

## Lyra 0.5.0 source, content and gameplay gates

The Git Lyra sample under a source-engine checkout intentionally omits content.
Check a candidate project without changing it:

```powershell
.\Validation\Test-UEP58LyraReadiness.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject
```

The report separates `source_ready` from `content_ready`. Add `-Strict` only
when missing Marketplace content should fail the calling job. A content-ready
project must contain the base GameData, front-end/editor maps, a gameplay map
and root GameFeatureData assets for every Lyra Game Feature plugin. Critical
files must also carry a valid Unreal package header; zero-byte/place-holder
files cannot satisfy the gate.

The source-only compatibility lane is independently runnable:

```powershell
.\Validation\Run-UEP58LyraSourceValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\UnrealEngine\Samples\Games\Lyra\Lyra.uproject
```

It copies Lyra source/config/plugin code to the script-marked
`.build/LyraValidation/Stage/Lyra`, injects the current UEP source and
`UEPLyraBridge`, and disables content-backed Lyra startup only in that disposable
stage. It then builds `LyraEditor`, runs `/Engine/Maps/Entry` in Standalone, and
runs a second content-free dedicated server that must listen on its requested
UDP port and exit through `unreal_engine.request_exit()`. Passing proves
compiler/UHT compatibility, module loading, game-thread bridge access and clean
headless shutdown; it explicitly records
`source_content_gate: not_claimed` and is not a substitute for real Lyra
gameplay, networking or packaging.

Current evidence is clean source result `20260811-165230`, final source
regression `20260811-183357` (Standalone plus dedicated-server graceful exit),
full generic regression `20260811-184425` (70/70 including packaged runtime),
and full-content readiness result `20260812-005352` (`status: ready`, UE 5.8.0,
CPython 3.11.8, all five Game Features and all critical packages valid). The
reference project is `F:\LyraStarterGame\LyraStarterGame.uproject`; it remains
external and is never modified by validation.

### Full-content acceptance lane

Point the full driver at a complete project outside both this repository and
the Unreal Engine source tree:

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -Mode All
```

The driver first invokes strict readiness and refuses to create its disposable
stage unless all required assets/maps and root GameFeatureData assets exist. It
then copies the project to marker-protected
`.build/LyraValidation/Full/Stage/Lyra`, injects UEP and `UEPLyraBridge`, and
overlays the example-owned `W_Healthbar` Mixin declaration. It never writes the
overlay to the reference project. The `GenerateHUDAssets` lane resets its
stage to the official health bar, hashes that reference before/after staged
authoring and copies back only the two declared overlay assets; `HUDAudit`
inventories the relevant Healthbar/layout/action-set assets without changing
them. Generated Unreal package metadata is not byte-stable, so the gate checks
the declared Interface/Profile semantics and runtime behavior. The driver
disables the unrelated desktop `AndroidFileServer` only in that disposable
stage. After compiling the complete Editor target, it disables the test-only
`ShooterTests` and `RuntimeTests` roots for gameplay/package execution so the
runtime evidence covers production Lyra features. ShooterTests content is still
staged and validated by readiness. Runtime launches pin `-culture=en` because
UE5.8's startup Core smoke tests compare source-language UnifiedError strings;
on a localized Windows culture those engine tests otherwise emit false
`LogAutomationTest: Error` diagnostics. The strict runtime error gate is not
relaxed. The driver runs these gates without changing the reference project:

1. 17 fast presenter/bootstrap/shutdown tests under the engine-bundled
   CPython 3.11, including the source-only missing-asset path, followed by a
   warning/error-free `LyraEditor` build;
2. real `L_Expanse` Standalone Experience with active `ShooterCore`, registered
   content-only `ShooterMaps`, local pawn, PlayerState, Enhanced Input, ASC and
   Health, followed by Python-driven GAS damage, duplicate rejection and
   restoration. Lyra's existing `W_Healthbar_C` remains CommonUI-owned while a
   Python mixin presenter observes the real `100 -> 90 -> 100` delegate events;
3. a dedicated server/client pair proving remote connection, server authority,
   client `AutonomousProxy`, replicated PlayerState and ASC on both roles. Client
   Python first proves `RejectedNotAuthority`; server Python then applies 10
   damage, client Python observes replicated Health 90, server Python restores
   only after that acknowledgement, and client Python observes Health 100. Both
   processes wait behind a shared release signal until both completed markers
   have been observed. The client must also pass Pawn replacement, an
   Experience-owned `Add Widgets` action teardown/recreation, and a second
   travel cleanup/reconstruction, while the dedicated server records zero HUD
   creation or subscriptions; and
4. Win64 BuildCookRun followed by the same `100 -> 90 -> 100` gameplay contract
   and Python HUD lifecycle in `LyraGame.exe` with UEP-owned CPython 3.11.

A new full-content stage has no cached asset registry. Before launching a game
or two Editor-based network peers, the driver runs one headless Editor
commandlet to complete the initial scan and persist its discovery/sharded
caches. Runtime processes consume that cache read-only. This avoids an uncached
multi-process startup stall before the client services the handshake, and the
summary records every cache path and byte count.

Per-run logs and JSON remain under `Results/<timestamp>`, while the package is
archived directly to the marker-protected fixed path
`.build/LyraValidation/Full/Package`. UAT's internal executable remains at
`Windows/LyraStarterGame/Binaries/Win64/LyraGame.exe`; the driver synchronizes
its complete `Binaries/Win64` tree to the validation-only stable listener path
`Windows/LyraGame/Binaries/Win64/LyraGame.exe`. It verifies that both executable
SHA-256 values match before launch and passes the original directory through
UE's `-basedir=` override, so project, engine and ICU content still resolve from
the unmodified UAT layout. This avoids a package-sized mirror and a new Windows
Firewall application identity for every timestamp. Each result records the
wrapper, original internal executable, tested listener and both hashes.
Preconfigure TCP/UDP inbound **Block** rules for the stable listener path if the
host has no existing policy; packaged Standalone validation does not require
public/private inbound access. Do not disable Firewall notifications globally.
The Editor-based network lane binds its server only to `127.0.0.1`. To avoid a
first-listen prompt on a new machine, also preconfigure exact TCP/UDP inbound
Block rules for `Engine/Binaries/Win64/UnrealEditor-Cmd.exe`; an existing exact
rule for the active profile is also sufficient.

`-Incremental` retains injected-plugin `Binaries`/`Intermediate`, skips files
whose size and UTC timestamp are unchanged, and prunes stale owned source files.
Both direct UBT and BuildCookRun's UBT child default to two non-UBA actions via
`-MaxParallelActions`; override the script parameter only on a host with enough
memory.

`Readiness`, `HUDAudit`, `GenerateHUDAssets`, `Standalone`, `Network` and
`Package` modes run narrower diagnostic lanes. The gameplay and HUD slices are
enabled by default in runtime modes; `-SkipGameplaySlice` and `-SkipHUDSlice`
exist for focused/back-compat diagnostics, but only `All` with both enabled can
set `full_acceptance: true`, and the updated flag additionally requires its
in-run HUD audit to pass. `HUDAudit` remains available independently; HUD-enabled
`All` now invokes it too. Rendered visual acceptance is still a separate open
gate. `-GameplaySliceDamage` accepts 0.01 through 25 and
defaults to the release value 10. Negative result
`20260811-184148` correctly reports `blocked` with 11 missing-content reasons
and no staging project for the local Git sample.

Pre-release `All` result `20260812-025232` passed readiness, Editor build,
Standalone and synchronized network roles, then completed its cold-DDC Win64
BuildCookRun with UAT ExitCode 0. Its post-archive executable guard exposed one
incorrect assumed internal directory before packaged launch. The corrected,
hash-verified package passed the exact packaged gameplay and strict lifecycle/
log contract in result `20260812-042711-packaged-resume`.

Formal named-commit result `20260812-051532` validates release-code commit
`c797d56` in one `All` invocation. Its summary reports `status: passed` and
`full_acceptance: true`; readiness, Editor, Standalone, synchronized server and
client, the 4,046-package Win64 BuildCookRun, and packaged gameplay all passed.
Every process exited 0, strict UAT/runtime error counts were zero, and the
archived internal and stable tested executable hashes matched.

For 0.5 development, incremental Standalone result `20260812-233341` passed the
new authority GAS command and exact `100 -> 90 -> 100` Health lifecycle.
Incremental Network result `20260812-233801` passed client authority rejection,
server command idempotency and both client replication observations. Formal
`All` result `20260812-234501` then passed the complete gameplay-slice candidate
and reported
`full_acceptance: true`. Readiness, Editor, Standalone, both network roles, UAT
and packaged gameplay exited 0; UAT reported `BUILD SUCCESSFUL`, executable
hashes matched, and strict runtime fatal/error counts were zero.

After the target selector was hardened to reject more than one matching human
controller, exact-source Network result `20260813-005436` rebuilt only
`UEPLyraBridge` and passed both roles; Standalone result `20260813-005835` was
up to date and passed the local sequence. No Cook/package was repeated after
that hardening; these remain historical 0.5 evidence.

For the historical 0.8 candidate, clean-base generation results `20260903-033001` and
`20260903-033049` passed the same two-profile semantic postconditions while the
reference Healthbar hash stayed unchanged. Read-only HUD audit result
`20260903-032632` confirms that `LAS_ShooterGame_StandardHUD` contains one
`GameFeatureAction_AddWidgets` with 1 layout and 11 widget entries. Formal
`All` result `20260903-033426` reports `full_acceptance: true`: host tests,
readiness, Editor build, asset-registry prime, Standalone, synchronized network,
Win64 BuildCookRun and packaged runtime all exited 0. Every UI role recorded the
real Health `100 -> 90 -> 100`, Pawn replacement, 3 Constructs / 2 Destructs
and balanced delegates after two Experience lifecycles; the dedicated server
recorded zero HUD state. The archived and stable tested executable hashes match,
and all strict logs passed.

That `All` invocation used NullRHI and has `hud_audit: null`; the audit and
generation above were independent runs. Its snapshots do not enforce exactly
one active presenter or post-exit zero owned callbacks, and its pre-bootstrap-
fix source/six host tests are not a fresh run of the current closeout tree.
Existing cleanup log events do not close those validation gaps or imply an
observed leak. A corrected current-source full and rendered run is required.
Preserved IDs and limitations are in
[Validation history](../docs/Validation_History.md).

The full ownership and rejection contract is documented in
[`../docs/Lyra_Gameplay_Slice_0.5.0.md`](../docs/Lyra_Gameplay_Slice_0.5.0.md).
The 0.8 widget ownership, Mixin routing and lifecycle contract is documented in
[`../docs/Lyra_Python_HUD_0.8.0.md`](../docs/Lyra_Python_HUD_0.8.0.md).

The [Lyra network acceptance plan](../docs/Lyra_Network_Acceptance_Plan.md)
requires one server and two independent clients, with explicit player targeting,
HUD isolation, interleaved commands and leave/rejoin cleanup. `Network` and
HUD-enabled `All` now require the two-client runner; the old single-client
diagnostic is named `NetworkPrecheck` and cannot satisfy full acceptance.

With an already built, matching marked stage, run without UBT/cook/package:

```powershell
.\Validation\Run-UEP58FocusedNetworkValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\Full\Results\Network-NewRun `
    -ClientCount 2 -ServerPort 7788
```

This checks source/module parity and input hashes, syncs Python scripts, runs
host contracts and a read-only HUD audit, then starts hidden NullRHI processes
on loopback. B0 exits and B1 rejoins: three concurrent processes, four total
process instances. A fresh output directory is required; failure only stops
this invocation's processes. Existing module mismatch fails without repair.
Three bots retain native Warmup participation, but their brain logic is stopped
by the opt-in test probe to isolate Health changes from random AI gunfire.
Health/GAS/replication and human player input are not replaced by this harness.
`multi_client_acceptance` is separate from `full_acceptance` (always false here).
Visible network play, weak-network and packaged-network tests remain separate.

### First weapon HUD batch (0.9 development)

`Run-UEP58FocusedWeaponHUDValidation.ps1` reuses a marked full-content stage
with matching native sources, module BuildIds and eight weapon overlay assets.
Run this entry in PowerShell 7.
It syncs current Python scripts, checks unchanged source/binary/script/asset
hashes and the official four BP reference hashes, and runs the persisted-CDO
original-BP/Python differential fixture. It never invokes UBT/UAT, saves assets,
repairs metadata or changes firewall settings. Use a fresh output directory.

```powershell
.\Validation\Run-UEP58FocusedWeaponHUDValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\WeaponHUD-NewRun `
    -CheckPlayableStartup
```

The isolated rendered Entry fixture checks 42 UI scenarios and one PNG, strict
error logs, normal Python/process exit and restoration of four routers. It also
checks native Gameplay Message cancel, four live Profile round trips without
Construct replay, and three controlled reload/native-GC cycles. Native reload
input injection is covered here; real firing/GAS/replication use the separate
weapon network lane. `LyraWeaponHUDContracts.ps1` and its sixteen host tests reject
missing/duplicate scenarios, BP-only execution, wrong native values, missing
CDO declarations and overstated network acceptance.

The optional startup check uses no UEP test flags. It observes ordinary Lyra
under NullRHI for 20 seconds after native Experience load and explicitly stops
only its owned process. Its forced cleanup is recorded separately and is not
claimed as a graceful-exit test. Full and weapon-network acceptance remain false.

`Run-UEP58FocusedNetworkValidation.ps1 -WeaponGameplay` runs 19 real-input phases
with a dedicated Editor server and two rendered clients. The native producer,
replicated owner state, Python weapon panel and original-BP comparison widget
must agree, including two travels and B0 exit/B1 rejoin. The shared sampler is
labelled `read-only-frame-sampler`; QuickBar/Pawn signals are native, not an
invented ammo replication delegate. `WeaponNetwork08` passes all four normal
exits against the current import/profile fix.

`Run-UEP58FocusedLifecycleValidation.ps1` reuses the generic host for three actual
PIE sessions in one Editor. `Run-UEP58FocusedCallMatrixValidation.ps1` runs
production signature/fallback/rejection, precompiled caller, experimental body
and an isolated expected-exception/no-fallthrough/recovery fixture.
It now also runs `delegate_broadcast_validation.py`: the same reflected
multicast property receives native and Python broadcasts, invalid parameters
are rejected without delivery, a later valid call recovers, and unsubscribe
prevents later delivery. Empty inline delegates are exercised; sparse-delegate
coverage is not implied. This is delegate invocation, not interception of
delegate-signature UFunctions by the Mixin router.
`Run-UEP58FocusedThirdPersonValidation.ps1` prepares both variants, reuses
source-matching Editor modules and records native-input rendered gameplay frames.
It performs only project-owned metadata refresh, without C++ compilation.

`Run-UEP58FocusedWeaponPackageValidation.ps1` builds the game target with
`-NoEngineChanges`, cooks/archives, preserves the previous managed package,
and tests the stable firewall-covered executable using its required `basedir`.
The runtime helper sources are NonUFS files and must import in the packaged VM.
Use `-ReusePackageEvidence <summary.json>` only when the earlier build/archive
logs and all recorded runtime inputs are unchanged. `-SkipPackagedNetwork`
explicitly limits acceptance to package presentation/lifetime and records the
network skip; it never closes a full release gate.

Dedicated packaged networking is still open. LyraGame is a Game target;
`-server` cannot substitute for LyraServer. An Editor/cooked mixed topology was
also attempted and failed on generated World Partition level-package mismatch.
A dry LyraServer plan exports 1,235 cold actions; no server compile was run.
Those failed lanes are retained, rather than represented as packaged network
support. Two CC invocations timed out and produced no review decision.

### 0.10 ammo-reticle pilot

`Run-UEP58FocusedReticleValidation.ps1` checks the first persisted ammo-reticle
copy, original reference hash, current scripts/native source, ten real
original-BP/Python material cases, a live Profile round trip, rendered PNG,
closed observer scopes and ordered normal exit. It is an Entry-map presentation
lane with `culture=en`, without build/cook/package or network approval.
Real reticle gameplay use and later batch assets need separate acceptance.

The opt-in `-WeaponGameplay -CombatHUD` network extension compares Python/BP
FireButton bound-click intent through actual Enhanced Input/GAS and initializes
an explicitly test-owned ammo-bar overlay from the production counter's native
weapon. Original weapon definitions do not list this ammo-bar widget; the
fixture must not claim production reachability. Schema 4 asserts native upward
aim and per-owner numeric/material Health, in addition to native ammo/HUD,
respawn/travel/rejoin and post-exit observer cleanup. Screenshots are hashed.
This is not a physical-touch test or new packaged-runtime evidence.

```powershell
.\Validation\Run-UEP58FocusedNetworkValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\CombatHUD-NewRun `
    -WeaponGameplay -CombatHUD
```

`CombatHUDNetwork04` passes the 19-phase lane with four clean exits and eight
PNGs. `HealthBootstrapRegression01` passes delayed-ASC recovery plus ordinary
health animations and mid-animation Profile cleanup. Use focused HUD `-Mode
All -RenderOffscreen` to render without showing an interactive window. Both
lanes reuse matching native binaries; neither builds/cooks/packages. Audio is
disabled in these scenarios: existing native EarlyReflections/TapIDs warnings
are retained, not treated as audio acceptance or hidden from screenshots.

### Effect Pad world-interaction pilots

`Run-UEP58FocusedEffectPadValidation.ps1` verifies eight parent/child cases and
sixteen physical enter/leave rounds on a real standalone Lyra Pawn. Test-owned
pads select BP/Python before native construction; native teleports drive real
collision, GAS applies/removes effects, and Health is read rather than written.
The existing nonlethal native bridge only supplies explicit starting Health.
Shutdown requires zero HUD/weapon observers and a restored parent router.

`Run-UEP58FocusedEffectPadNetworkValidation.ps1` adds an Editor dedicated server
and two rendered-offscreen clients, sixteen parent/child x effect x owner x
profile comparisons, native Health replication and numeric/material HUD checks.
It does not claim physical client input, client effect prediction, pad
replication or packaged networking. Both drivers require a marked stage and
fresh evidence directory; neither builds/cooks/packages or changes firewall.

`CallMatrixRegression02` includes the construction-forwarder and inherited-
selector fixtures alongside the earlier five call/exception/body checks.
The child explicit-Parent route uses a virtual BP helper, not a new runtime
interception contract. `PhysicalGAS03` and sixteen-case `PadNetwork02` pass with
three clean network exits. Those results retain the input/DLL hashes from their
own runs; subsequent unrelated HUD changes are not retroactive reruns.

The focused weapon network driver accepts `-WeaponGameplay -CombatHUD -DebugSpread`
for the debug spread pilot. It requires real native automatic Tick
(the probe does not invoke Python Tick), BP/Python/native formatted text and a
nonzero observed angle over the nineteen native input/lifecycle phases. Old
reports cannot satisfy the new opt-in lane; dropping a debug checkpoint fails.
`DebugSpreadNetwork01` passes four clean exits and eight screenshots, with
known native audio/Editor warnings retained. It is not production debug-widget
reachability or package approval.

`Run-UEP58FocusedOpenMenuValidation.ps1` checks the retained CommonUI button's
Python/BP/Python profile roundtrip and three native asynchronous layer pushes/
deactivations. It requires an initially unloaded menu class, retained widget
type, actual visible menu PNG, ordered clean shutdown and stable source/asset/
DLL/reference hashes. `MenuDifferential04` passes with an inspected screenshot.
Use a marked full Lyra stage and a fresh evidence directory. The driver does
not build/cook/package; it does not certify physical touch, input-token resume/
cancel behavior, production reachability or multiplayer menu isolation.

`Run-UEP58FocusedReticleHostValidation.ps1` checks eight native production-host
versus original-BP cases, including default automatic weapon routing, three
native equipped weapon contexts, Profile preservation and injected native
death-event hiding/one-shot listener cleanup. `HostDifferential02` passes with
an inspected screenshot and final host/child scopes 3/3 and 9/9. It is not
physical pickup or lethal-damage gameplay.

Add `-ReticleHosts` to the focused network driver's `-WeaponGameplay -CombatHUD
-DebugSpread -ProductionReticles` lane to require actual production host
configuration/owner/child/visibility checkpoints and final host scope closure.
`ReticleHostNetwork01` passes nineteen phases, two clients plus B rejoin and
four clean exits; the server creates no UI. This lane does not call Python Tick
or OnWeaponChanged to manufacture production routing. Old reports cannot
certify it. Both drivers reuse matching binaries and never build/cook/package.

### Ability duration progress and typed-transport regressions

`Run-UEP58FocusedAbilityProgressValidation.ps1` uses the actual production
W_AbilityProgress and a test-owned original-BP baseline. `ProgressDifferential02`
passes eleven owner/foreign/repeat/countdown/paused-native-clock/hidden-Profile/
Destruct cases, with real automatic UMG Tick and final scopes 3/3. Its screenshot
was inspected. The input is a compiled typed synthetic duration broadcast,
not an actual interaction ability. Initial StartTime differs because the two
widgets initialize at different times; after broadcast, native fields match.

`Run-UEP58FocusedTypedMessageValidation.ps1` reruns legacy signals, typed UI/Verb,
nested payload copy, wrong reader/outside-delivery rejection and cancellation
against the extended six-function adapter. A startup timeout is not a pass.

Add `-AbilityProgress` to `-WeaponGameplay -CombatHUD` for an optional network
lane. Each phase must show one owner delivery, one non-Pawn Instigator rejection,
visible original-BP/Python countdown comparisons and native completion. It
inspects the actual production UI without invoking Python Tick, and requires
zero dedicated-server UI plus balanced client scopes after travel/rejoin/exit.
The foreign payload uses the owning Controller instead of Pawn. This is local
synthetic UI delivery in multiple processes, not remote-player interaction,
native ability production or GameplayMessage replication. This lane is
validated in `AbilityProgressNetwork03` after the lifecycle fix below.

The first two network runs expose a hidden-widget reuse defect on travel:
Destruct closes the listener, while one-shot OnInitialized and Collapsed Tick
cannot rearm it. Construct now idempotently rearms; the original-BP fallback
uses the explicit preserve-model resume. `ProgressReconstructRegression01`
passes twelve comparisons, including native same-widget remount, with final
scopes 4/4 and an inspected image. `AbilityProgressNetwork03` passes nineteen
phases, two travels/respawn/rejoin, four clean exits and final server/A/B0/B1
progress scopes 0/0, 6/6, 6/6, 2/2. Twelve PNGs are hashed; selected progress
images were inspected. Known native warnings remain. These are bounded pilot
gates, not full 0.10, native interaction production or package acceptance.

### Ability failure feedback: bounded differential and native FText accepted

`Run-UEP58AbilityFailureAssetAuthoring.ps1` must first produce an accepted asset
report in a marked workspace stage. The focused
`Run-UEP58FocusedAbilityFailureValidation.ps1` requires that directory via
`-AssetAuthoringDirectory`; failed authoring is rejected before UE launch.
`fixture-preflight01.json` verifies this guard against the actual failed run.

The opt-in `-UEPAbilityFailureResult=` fixture passes in `FailureDifferential06`.
Seventeen cases compare the actual production W_AbilityFailureFeedback against
the same class's listener-resumed original-BP baseline: ownership/de-duplication,
pause/one-second native Outro timing, natural animations, hidden Profile resume,
native Destruct/remount, deferred payload/persistent callback result and pending
work cancellation. No direct widget lifecycle/completion event invocation.
Post-exit scope/ticker balance, exact case/state inventory, strict closed logs,
stable input hashes and a PNG are required. Timer deviation cannot exceed two
observed UI frames or 0.15 seconds. The corrected visible PNG was inspected.

`Run-UEPLyraHostTests.py --result <workspace .build path>` passes 237 in
`20261014-batch2h/host-tests08.json`. The gate tests use artificial reports; they
do not certify the seventeen runtime cases. Synthetic display-text input cannot
prove native localized FText identity, dead-health behavior, native GAS failure
production, multiple clients or package acceptance. `Assets06` cleanly compiles
the ten-function/32-node transport plus declaration-only int32 latent completion.
The final timer calls native RetriggerableDelay; no external ticker or new Tick.
`-CultureIdentity -TextFixtureAssetResult <accepted seed report>` selects the
separate culture lane. `NativeCulture02` passes native live-table FText through
en/zh-Hans/en without rebroadcast; its corrected screenshots were inspected.
Timer cancellation to hold the text is explicitly test-owned. The seed is
stage-only. `-AbilityFailure` adds local synthetic ownership/visual/cleanup
checks to the existing two-client weapon driver; native GAS failure production
and failure-message replication remain unclaimed. No build/cook/package.

### Dash cooldown: bounded standalone, production-pool network retest

`Run-UEP58WidgetAssetAuthoring.ps1 -Widget DashCooldown` authors only the marked
workspace stage and copies accepted BP/Mixin assets into Examples. It reuses
the existing duration adapter, retains the class/Tick/animations and adds
only proxy ownership plus four-node delegate cleanup.
`Run-UEP58FocusedDashCooldownValidation.ps1 -AssetAuthoringDirectory <accepted
directory>` runs eleven comparisons. Nine use production UI; Destruct/remount
is a declared same-class viewport fixture, not a production pool-remount claim.
Material tolerance is 0.00001. DashDifferential05 passes with an inspected PNG;
the pool fix repeats the eleven in DashDifferential06 (50.297s, scopes 11/11,
pool watches 2/2, zero active/errors). A tightened pure final gate independently
rechecks the saved report. `-DashCooldown` adds production UI/native-pool
lifetime and local synthetic duration comparisons to the two-client weapon
lane. First run fails on second-travel duplicated production scopes. A shared
read-only GetAllEntries sampler disarms inactive entries, prevents inactive
Tick health rebinding and permits natural reinsertion without event replay.
DashNetwork02 is running on the fix. Host-tests08 passes 270, not runtime proof.
Native Dash production, native death/invalid-health and packaging remain open.

Later DashNetwork05 passes all nineteen phases/two travels/rejoin/four exits
with native pool deactivation observed in A/B0. NativeDash02 passes original
GAS Dash duration (1.5s), native death and absent-Pawn feedback cases; no native
failure message is emitted by the rejected repeat. Those earlier open labels
are historical; full package/batch and failure-producer scope stay open.

### Nameplate Widget: bounded 5.8.1 acceptance

`Run-UEP58WidgetAssetAuthoring.ps1 -Widget Nameplate` first compiles the copied
Interface/CDO, original class/Tick, typed init-state helpers and exact delegate
cleanup. `Run-UEP58FocusedNameplateValidation.ps1 -AssetAuthoringDirectory
<accepted directory>` then compares actual production binding and same-class
original BP across fourteen declared cases. It holds its native ticker handle;
Profile comparisons use matching native resume epochs, not state copying.

`20261015-ue581-acceptance/NameplateDifferential06` passes with an inspected PNG,
scopes 23/23, team proxies 13/13, init delegates 10/10 and no residual/errors/
ensures. `init_owner_released` is separately counted when the native init-state
owner/manager has already gone; it is zero in this accepted run. The gate still
requires explicit unregisters to have been exercised. Native damage, team
reassignment, projection parity, Source/Manager components and nameplate-specific
multiplayer are not certified by these fourteen Widget cases.

### Fresh-process package discovery

`Run-UEP58FocusedPackageLoadValidation.ps1 -StageProject <marked generic host>
-OutputDirectory <fresh workspace .build path>` saves two uniquely named BP
packages and a Mixin Set in the disposable host, then starts a separate Editor
process. Loading Main also imports Companion through a hard CDO class reference.
The load phase must discover both automatically, without explicit registration,
and prove Python replacement, explicit original calls, absent-callable fallback,
same-class per-instance profiles and unregister restoration. Source/module/input
hashes, serialized asset hashes, distinct process IDs and closed logs are gated.
No build, cook, canonical fixture asset or official project write is involved.
`20261015-ue581-acceptance/PackageLoad01` passes on the rebuilt 5.8.1 Editor;
this covers Editor OnEndLoadPackage, not ordinary non-Editor/cooked discovery.

### Respawn timer

`Run-UEP58WidgetAssetAuthoring.ps1 -Widget RespawnTimer` accepts the copied
Interface/CDO and five-node cleanup while retaining official asset hashes.
`Run-UEP58FocusedRespawnTimerValidation.ps1 -AssetAuthoringDirectory <accepted
directory>` enables native audio components and compares ten production-widget/
original-BP cases. RespawnDifferential04 passes (51.578s), material tolerance
0.00001, exact two Python scope epochs, zero final pool/scope state and inspected
PNG. Remaining time is a derived native deadline, never a BP-stack read.
Both materials update in the actual compiled baseline, despite the compact
multi-link graph's misleading first-link inference. With `-NativeRespawn`,
NativeRespawn02 passes original GA_AutoRespawn/native GAS -> 5s duration/UI ->
new Pawn/completion (49.735s), no synthetic duration/completion, manual widget
events or Health/CDO writes. This is death-state/event evidence, not lethal
damage/acoustic parity. `-RespawnTimer` adds local duration/completion filtering
and native pool lifetime to the two-client weapon lane; clients enable native
audio. RespawnNetwork01 is running. Host checks pass299, not network proof.
