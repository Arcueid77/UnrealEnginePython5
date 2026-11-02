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

CPP02 also passed and is recorded in
[its team acceptance ledger](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP02-acceptance.json).
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
[the bot acceptance ledger](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP03-acceptance.json).
Both production spawner configurations passed native/Python creation, count
precedence, naming, nine native self-destruct/removal operations, and cleanup.
Native spawn/initialization/destruction and the native RNG remain in use. The
performance test Blueprint keeps its custom creation graph. This does not claim
an exact RNG sequence or separate PIE editor-override acceptance.

The dedicated server and two actual clients passed naturally creating/naming
nine bots, with the CPP01 damage/score/notification and CPP02 team gates enabled.
Only LyraGame units 1/2 were recompiled; the accepted team object was reused.

CPP05 passed quickbar cycling/free-slot selection and pickup grant ordering; see
[the inventory acceptance ledger](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP05-acceptance.json).
Fourteen native/Python boundary cases and a dedicated server with two actual
owners passed native event/RPC/equipment, inventory stack replication, OnRep
notifications, owner isolation, and restoration. Only the three LyraGame unity
units included by the shared headers were rebuilt. The original native
existing-instance inventory AddEntry remains unimplemented; this migration
preserves that limitation and does not claim runtime support for it.

CPP06 passed native spawner pickup/reset/completion orchestration; see
[its acceptance ledger](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP06-acceptance.json).
The original C++ reference and Python implementation keep the previously accepted
Blueprint Python layer fixed. Five guards, real timer completion, stationary
overlap retry, and pending-timer destruction passed. The original level actors
then passed 36 scenarios with two actual clients, including unchanged ten-second
cooldown, inventory/equipment/health replication, and owner isolation. Native
timer/replication ownership is retained. Only LyraGame units 1/3 were rebuilt.

CPP04 passed TDM and general player-start policy migration; see
[the spawning acceptance ledger](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP04-acceptance.json).
Eleven native/Python cases use real collision geometry for empty, partial, and
full fits, check distance and claim preferences, preserve spectator behavior,
and enter actual native RestartPlayer. Start discovery, weak caches, PIE start
preference, physics, and claim timers retain native ownership. The peer run
enters selection 22 times per profile, with CPP01–CPP03 regression gates enabled.
The affected base/derived module compilation reuses the unchanged LyraGame unit.

CPP07 passed accolade notification, registry-order, cancellation, timer, and
teardown policy migration; see
[its acceptance ledger](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP07-acceptance.json).
Eleven paired native/Python cases include pending native asset and registry
callbacks across destruction/rebuild. The two-owner native damage lane passes
both profiles with equal four-award queue/presentation results and no awards for
the other owner. NullRHI clients each construct one original owner-bound host
fixture; natural HUD creation and visible rendering are outside this evidence.
Only ShooterCore is rebuilt. The official Lyra reference and SDK remain unchanged.

CPP08 passed native interaction indicator/option/first-choice orchestration; see
[its acceptance ledger](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP08-acceptance.json).
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
separate from actual keyboard and visible-window acceptance. CPP09 remains
pending those checks; eight batches and fourteen candidates are accepted.

[The CPP09 progress ledger](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP09-progress.json)
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
[the next-batch review](../Demos/UEPLyraIntegration/Migration/CPP16_18_PREFLIGHT_REVIEW.md).
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
in [the extended tracker](../Demos/UEPLyraIntegration/Migration/cpp_extended_batches.json).
CPP10/CPP-016 passed [native initial-stat acceptance](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP10-acceptance.json).
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

[CPP11 production acceptance](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP11-acceptance.json)
and [CPP12 capability acceptance](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP12-acceptance.json)
close the selected extended scope: two production groups and one capability-only
group. The first-stage CPP09 actual-window gate remains pending.

The user has now selected all remaining CPP-019 through CPP-030 and requested
continuous execution. [Remaining progress](../Demos/UEPLyraIntegration/Migration/cpp_remaining_batches.json)
tracks that scope. [CPP13 input/physics progress](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP13-progress.json)
passes 28 real native network Jump trials and 12 admission-boundary calls.
Death/respawn crosschecks remain explicit for CPP14. The user deferred desktop
operation, so CPP09 actual-window input remains pending while other work continues.

[CPP13](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP13-acceptance.json),
[CPP14](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP14-acceptance.json),
and [CPP15](../Demos/UEPLyraIntegration/Migration/NativeGameplay/CPP15-acceptance.json)
now close native Jump, Death and Reset replacement. Incremental evidence includes
four death/new-Avatar Jump checks, 24 native lethal/self-destruct network cases,
two original Arena death tasks and 12 original native Reset requests. Existing
Blueprint Python rules stay fixed while the new native policy changes. Reset
uses a world-owned Blueprint carrier because the SDK rejects native UClass mixins;
native GAS handles, waits, cancellation, typed payloads and transport remain.
The carrier build compiles LyraGame units 1/2 plus UHT and reuses unit 3, SDK,
bridge and engine. Startup selection passes 46 focused tests. CPP16-24 continue;
CPP09 actual desktop input remains user-deferred.
