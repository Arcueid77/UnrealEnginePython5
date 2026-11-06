[English](Native_Gameplay_Migration.md) | [简体中文](Native_Gameplay_Migration.zh-CN.md)

# Lyra native gameplay migration

The user approved CPP-001 through CPP-015 on 2026-11-01. Progress and per-batch
acceptance live in [the Examples ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/cpp_batches.json).
This extends the earlier accepted Blueprint scope; it does not reopen or replace it.

The [consolidated completion index](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/completion_status.json)
covers all three subsequently approved C++ stages and H01-H05. All thirty C++
candidates are implemented and accepted within the confirmed scope: twenty-nine
production replacements and one capability case. CPP09 passed fourteen actual
Escape presses, native Menu input transitions and visible original UI/restoration
on 2026-11-05 after the user unlocked the desktop. The completion index verifies
the source-bound reports and captures. Two earlier live compiler intermediates
retain separate historical/current fingerprints. The batch notes below preserve
their original capture boundaries.

CPP01 moves elimination streak, rapid elimination chain, and assist rules into
Python. Four native callback seams are `BlueprintNativeEvent` functions. The
original C++ bodies remain selectable through `NativeFallback`; native Gameplay
Message registration, authority roles, and listener shutdown retain their existing
ownership. The UEP binding source and engine binaries were not changed.

The [source patch and implementation notes](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/README.md)
and [CPP01 acceptance](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP01-acceptance.json)
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

CPP02 also passed and is recorded in
[its team acceptance ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP02-acceptance.json).
It moves player team selection and least-populated team calculation to Python,
using the original two/four-team configuration classes. A thin reflected setter
keeps native team notifications intact. Six branch comparisons passed for each
configuration, with temporary fixture state fully restored. The four-team case
uses three temporary native PlayerState actors alongside one natural owner; it
does not claim four actual network owners.

The dedicated server and two actual clients passed in both profiles: eleven
natural player/bot assignments produced populations 6/5, and the CPP01 native
damage, scoring, and owner notification checks still passed. Native compilation
was limited to the two affected LyraGame unity units. No engine compilation or
Cook was needed for this batch.

CPP03 passed for bot count, names, and removal selection; see
[the bot acceptance ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP03-acceptance.json).
Both production spawner configurations passed native/Python creation, count
precedence, naming, nine native self-destruct/removal operations, and cleanup.
Native spawn/initialization/destruction and the native RNG remain in use. The
performance test Blueprint keeps its custom creation graph. This does not claim
an exact RNG sequence or separate PIE editor-override acceptance.

The dedicated server and two actual clients passed naturally creating/naming
nine bots, with the CPP01 damage/score/notification and CPP02 team gates enabled.
Only LyraGame units 1/2 were recompiled; the accepted team object was reused.

CPP05 passed quickbar cycling/free-slot selection and pickup grant ordering; see
[the inventory acceptance ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP05-acceptance.json).
Fourteen native/Python boundary cases and a dedicated server with two actual
owners passed native event/RPC/equipment, inventory stack replication, OnRep
notifications, owner isolation, and restoration. Only the three LyraGame unity
units included by the shared headers were rebuilt. The original native
existing-instance inventory AddEntry remains unimplemented; this migration
preserves that limitation and does not claim runtime support for it.

CPP06 passed native spawner pickup/reset/completion orchestration; see
[its acceptance ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP06-acceptance.json).
The original C++ reference and Python implementation keep the previously accepted
Blueprint Python layer fixed. Five guards, real timer completion, stationary
overlap retry, and pending-timer destruction passed. The original level actors
then passed 36 scenarios with two actual clients, including unchanged ten-second
cooldown, inventory/equipment/health replication, and owner isolation. Native
timer/replication ownership is retained. Only LyraGame units 1/3 were rebuilt.

CPP04 passed TDM and general player-start policy migration; see
[the spawning acceptance ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP04-acceptance.json).
Eleven native/Python cases use real collision geometry for empty, partial, and
full fits, check distance and claim preferences, preserve spectator behavior,
and enter actual native RestartPlayer. Start discovery, weak caches, PIE start
preference, physics, and claim timers retain native ownership. The peer run
enters selection 22 times per profile, with CPP01–CPP03 regression gates enabled.
The affected base/derived module compilation reuses the unchanged LyraGame unit.

CPP07 passed accolade notification, registry-order, cancellation, timer, and
teardown policy migration; see
[its acceptance ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP07-acceptance.json).
Eleven paired native/Python cases include pending native asset and registry
callbacks across destruction/rebuild. The two-owner native damage lane passes
both profiles with equal four-award queue/presentation results and no awards for
the other owner. NullRHI clients each construct one original owner-bound host
fixture; natural HUD creation and visible rendering are outside this evidence.
Only ShooterCore is rebuilt. The official Lyra reference and SDK remain unchanged.

CPP08 passed native interaction indicator/option/first-choice orchestration; see
[its acceptance ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP08-acceptance.json).
The typed native adapters retain interface calls, soft class paths, payload
customization, ActorInfo assembly, and GAS execution. Native/Python boundary
matrices and the existing Explorer regression pass. In both profiles, two actual
owners each issue three native inputs and produce two matching local-predicted
and authority interactions; empty inputs and foreign targets remain inactive.
The native witness uses the ASC owner/avatar that UE5.8.1 actually applies;
the engine's ignored ActorInfo argument is preserved as existing behavior.
Only affected LyraGame units are compiled; SDK, bridge, ShooterCore, and engine
binaries are reused. No physical-keyboard or visible-rendering claim is made.

CPP09 implements the Escape menu request seam and its Python policy, preserving
native CommonUI action binding, streamed loading, and input/lifetime ownership.
Its four original HUD shells and shared Set passed asset checks. LyraGame units
1/3 were compiled; unit 2 and the other module/engine binaries were reused.
The review patch reproduces those compiled sources without another build.

The added `-Headless` mode of `Run-UEP58NativeEscapeValidation.ps1` compares policy
and widget deactivation directly in isolated CommonUI worlds. It uses temporary
zero-duration runtime stack transitions and checks restoration. This lane is
separate from actual keyboard and visible-window acceptance. The later
[CPP09 actual-window ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP09-acceptance.json)
closes fourteen real Escape inputs, seven cycles and two native HUD travels;
all nine batches and fifteen first-stage candidates are now accepted.

[The CPP09 progress ledger](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP09-progress.json)
records seven passing native/Python open/close cycles and two native travels,
including menu class/layer/owner, desired Menu configuration, input-state
equivalence/restoration, native HUD destruction/rebuild, and fixture cleanup.
The offscreen input router stayed in `All`; its actual `Menu` takeover remains
part of the pending window acceptance. Headless reports are rejected by that gate.

The original uncooked shooter level has a separate Niagara graph failure in an
unchanged rifle asset. The isolated UI worlds do not claim full shooter rendering
acceptance or a fix for that resource. The optional CPP-019 through CPP-030 groups
remain outside the approved implementation scope.

A read-only preflight for CPP-016 through CPP-018 is now available in
[the next-batch review](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/CPP16_18_PREFLIGHT_REVIEW.md).
The native commandlet examined 44 original Lyra item/ability definitions and two
existing stage fixtures, finding five initial-stat fragments, five item costs,
and no player-cost consumer in that census. GameplayTag struct keys cannot be
read through the current Python dictionary conversion. The proposal uses typed
stat snapshots and existing Blueprint owners while preserving native instanced
objects, authority, prediction, and the original caller's hit-only filtering.
The preflight itself does not establish runtime acceptance. Player-cost fixture validation must be
distinguished from production migration. Existing CPP09 sources, assets, and
binary remain available for its pending actual-window acceptance.

The user then selected CPP-016 through CPP-018; their independent progress lives
in [the extended tracker](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/cpp_extended_batches.json).
CPP10/CPP-016 passed [native initial-stat acceptance](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP10-acceptance.json).
Two Const owner events and typed stat snapshots preserve the native instanced
fragments and map iteration order. Definition/boundary creation, missing-owner
fallback, no native replay, and actual two-owner tag-stack replication passed.
Prior inventory/quickbar Python behavior stays fixed in the native/Python
comparison. Only affected LyraGame units are compiled; SDK, bridge, ShooterCore,
and engine are reused. The unused/prototype definitions and exception-injection
limits remain explicit in the ledger.

CPP11/CPP-017 routes item-cost decisions through three typed ability-owner events.
Original instanced costs, native curve/level evaluation and truncation, failure-tag
writeback, AdditionalCosts ordering, hit-only filtering, authority and replicated
stack writes remain native. Three mixin sets retain the earlier weapon/heal/net
Python methods and add `NativeCostFallback` for the new rules. The original
`BlueprintFallback` profile and ability Blueprint bytes are preserved.

CPP12/CPP-018 uses the same binary and remains capability-only: the preflight found
no original configured player-cost consumer. Disposable cost-only abilities and
temporary additional player costs on real owned weapons exercise this capability.
The lifecycle lane applies actual lethal GAS damage and native Avatar destruction,
observes replacement Pawns with the same PlayerState/stacks and native ASC binding,
then fires from the new Avatar. Forced Avatar destruction retains its previously
documented native quickbar recovery; this does not claim an original inventory fix.
Restoration compares the native post-lifecycle inventory baseline and its replicas.

The focused lanes cover 18 boundary scenarios per cost kind in both profiles,
all five configured item costs, three weapon types with two actual clients, and
the additional respawn/Avatar lane. The previous weapon Python policy stays fixed
while cost profiles change. Diagnostic history is bounded to 128 entries; 320
native callbacks exercise that bound. The earlier matrices are reused only after
verifying the exact one-line diagnostic-only change. No SDK/bridge rebuild, full
engine build, cook/package, new platform, or physical-input acceptance is added.

[CPP11 production acceptance](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP11-acceptance.json)
and [CPP12 capability acceptance](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP12-acceptance.json)
close the selected extended scope: two production groups and one capability-only
group. The first-stage CPP09 actual-window gate remains pending.

The user has now selected all remaining CPP-019 through CPP-030 and requested
continuous execution. [Remaining progress](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/cpp_remaining_batches.json)
tracks that scope. [CPP13 input/physics progress](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP13-progress.json)
passes 28 real native network Jump trials and 12 admission-boundary calls.
Death/respawn crosschecks remain explicit for CPP14. The user deferred desktop
operation, so CPP09 actual-window input remains pending while other work continues.

[CPP13](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP13-acceptance.json),
[CPP14](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP14-acceptance.json),
and [CPP15](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP15-acceptance.json)
now close native Jump, Death and Reset replacement. Incremental evidence includes
four death/new-Avatar Jump checks, 24 native lethal/self-destruct network cases,
two original Arena death tasks and 12 original native Reset requests. Existing
Blueprint Python rules stay fixed while the new native policy changes. Reset
uses a world-owned Blueprint carrier because the SDK rejects native UClass mixins;
native GAS handles, waits, cancellation, typed payloads and transport remain.
The carrier build compiles LyraGame units 1/2 plus UHT and reuses unit 3, SDK,
bridge and engine. Startup selection passes 46 focused tests. CPP16-24 continue;
CPP09 actual desktop input remains user-deferred.

[CPP16](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP16-acceptance.json),
[CPP17](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP17-acceptance.json),
and [CPP18](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP18-acceptance.json)
accept frontend, controller cosmetic selection and camera priority. Evidence
contains 106 typed boundaries, native/Python actual runtime paths, default boot
smokes and four network Reset trials with eight independent cosmetic actor/mesh
views. Native GAS camera ownership/end cleanup, cosmetic fast arrays, flow handles
and async widget lifetimes remain. Frontend online-provider outcomes are not
claimed; supplied callback results and typed cancellation choices stay explicit.
Only LyraGame units 1/3 plus UHT were compiled; unit 2, SDK, bridge and engine were
reused. Startup selection passes 48 tests. CPP19-24 continue; CPP09 physical
desktop input remains user-deferred.

[CPP19](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP19-acceptance.json)
through [CPP24](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/CPP24-acceptance.json)
close the remaining device-notification, replay-retention, audio-selection,
team-damage, Arena-attribute and GameMode-selection policies. Their default profile
retains all earlier Python replacements. Evidence includes 600 typed boundaries,
actual native/Python callbacks and effects, two network lanes with eight authority
trials and sixteen independent client views, two-local-player native GAS clamps
and original bomb input/refund. Final combined frontend, Pawn and Arena smokes pass;
four original pistol shots prove native prediction-key/target-data agreement and
eight replicated damage observations. Startup selection passes 51 focused tests.

Device callback inputs are supplied by fixtures; physical disconnects are untested.
Replay uses temporary memory streams, with keep/live flags checked in typed contexts
and invalid negative retention rejected by Python. Existing recordings and gameplay
playback are untouched. Audio verifies native resource/state parameters, not audible
output. Attribute writes belong to an explicit restored fixture phase; subsequent
input remains the original Enhanced Input path, without OS desktop control.

Incremental compilation covers LyraGame units 1/2/3, one TopDownArena unit and
LyraGame UHT. The body repair reuses UHT and successful units 1/2. The engine's stale
unregistered 5.8.0 memory-streamer DLL is not used: one current-source test module is
built and registered solely in the advancing stage. Engine manifest/binaries, SDK,
bridge and the preserved CPP09 stage remain unchanged; 972 protected hashes match.
No full-engine build, cook/package, new platform or hardware/audio acceptance is
added. All 30 selected candidates are implemented, with 29 accepted in their stated
scope (CPP-018 capability-only); CPP09 actual desktop input remains user-deferred.

The user selected exception recovery, timing/long-run stability, fresh-stage
reproduction and actual packaged delivery in
[the hardening tracker](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/hardening_batches.json).
[H01](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H01-acceptance.json)
passes thirteen actual native failure/recovery cases, including original equipped
item costs, one reward callback after its real native broadcast and three GAS
Reset aborts/recoveries. Incomplete world policies reject their outputs without an
engine ensure; incomplete Reset plans take only their terminal EndAbility action.
Normal default frontend and 52 startup selection tests pass. Only changed bodies
in LyraGame units 3 and then 1 compile; UHT, other units/modules, SDK and Engine
are reused. H02-H04 acceptance follows; CPP09 desktop input is still user-deferred.

H02's first long run exposed expired Mixin selector targets after the original
twelve-minute match ended and seamless travel destroyed the cached world. The
[incremental selector repair](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H02-selector-guard-acceptance.json)
checks the tracked weak owner before using that pointer. One SDK source file and
two links rebuild; Engine, game/bridge DLLs and the CPP09 checkpoint remain intact.
Ninety seconds of active gameplay, actual early travel, three rejected expired
selectors, three native respawns and 4,250 queries pass. The harness now rebinds
to the ready world, with travel waits excluded from activity duration.

[H02](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H02-acceptance.json)
then passes 1,200 active seconds, 58 native respawns, 57,250 native queries and a
natural seamless travel. Post-warmup median private bytes grow 207.16 MiB and
handles grow four within the predeclared 256 MiB/32 budgets; native actor population
ranges by one, router count stays constant and quiescent native contexts peak at
two. This bounded observation includes memory growth and does not establish
unlimited stability or leak freedom. Current SDK timing covers 14,400 interleaved
calls: Damage medians 6.18/17.22 microseconds native/Python and Pawn 4.70/15.43.
The scope is the same reflected entrypoint with bridge admission, not frame rate.
[H03](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H03-acceptance.json)
reproduces all 63 current production outputs from fifteen versioned recipes in
an independent stage. All 11,341 final staged files match their original/versioned
composition; 23 project modules build with 289 actions scoped to that stage, and
thirteen actual exception/recovery cases pass on the fresh DLLs. No old project
compiler outputs are imported. The production descriptor now consistently disables
RuntimeTests/ShooterTests, and project-local manifests use the unchanged Engine
BuildId. See [the reproduction entry point](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/REPRODUCE_NATIVE.md).
[H04](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/NativeGameplay/H04-acceptance.json)
closes the current Game build, cook and actual packaged execution. Its cold Game
configuration compiles 1,190 actions, including Engine runtime dependencies inside
the owned project; 4,105 compiler-generated paths stay in that stage. The installed
Engine distribution and original projects remain unchanged. The cook processes
4,707 packages, with all 246 original candidates, 493 overlay assets, twelve maps
and three typed validation observers present in the archive.

The packaged executable passes thirteen native exception/recovery cases, normal
frontend startup and Damage/Pawn listen-authority/two-remote-client lanes: eight
authority trials and sixteen independent client views. All eight processes exit
normally, loading the packaged CPython DLL, home and 4,578 receipt files. Exactly
one test INI allows only UAT's BOM/newline transformation; all other hashes remain
strict. Separate pure reviews preserve the original dependency and dedicated/listen
gate failures without repeating successful native runs. The listen checker keeps
all raw gameplay assertions and explicitly checks stable UI/local cosmetic messages.

All four selected follow-up groups are accepted in this Win64 Development scope.
Actual desktop Escape/Menu subsequently passed on 2026-11-05. H04 adds no packaged Dedicated
Server, Shipping, other-platform, rendered graphics or hardware/audio claim.

The later [H05 frame/CPU follow-up](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/RENDERED_PERFORMANCE.md)
does enable actual D3D12 offscreen rendering on the current package, with 1080p
Medium settings and sixteen balanced twenty-second blocks. Only the shared
native world-policy carrier changes; the other migrated layers stay fixed.
Normal fixed-scene Native/Python results are 120.56/120.39 FPS and
36.92%/36.72% whole-machine CPU, with no distinguishable paired local effect.
At 200 extra reflected Damage/Pawn queries per frame, GameThread grows from
4.54 to 8.25 ms, CPU from 37.28% to 39.85%, and FPS falls from 120.23 to 118.26.
The complete ledger keeps profiler captures, CPU cross-checks, low-frame results
and scope limits. This adds no desktop, combat, hardware/audio or other-target
acceptance and reuses the Game build and cooked package unchanged.
