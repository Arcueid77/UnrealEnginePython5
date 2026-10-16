# Roadmap

Capability milestones, not delivery dates. Review baseline: 2026-10-16.
Implementation, retained test evidence and a published release are separate
states; a version number in the plugin descriptor is not release approval.

The target is Unreal Engine 5.8 (current validation: upstream 5.8.1) with
engine-bundled CPython 3.11, without
modifying Engine source or the official Third Person/Lyra reference projects.
Engine and general-purpose plugin C++ remain native; Python calls those
capabilities. Game-project runtime Blueprint business, including the
ShooterCore, ShooterExplorer and TopDownArena gameplay plugins, moves to Python
in small accepted batches. ABPs, the animation system, editor/test tools,
interface declarations, component/default-data shells and UMG layouts remain.
Game-project C++ business migration is a separate later scope.

## Current status

The latest locally recorded release tag is `v0.7.0` in both repositories;
neither checkout has a `v0.8.0` tag. The 0.8 closeout remains separate from
the new `dev/lyra-blueprint-python` work, which starts from the 0.8 development
baseline. The plugin descriptor still says 0.8.0; it is not a release gate.

Implementation cadence: modify one coherent batch, verify that exact batch,
then make a local commit. Backfill earlier accepted work the same way. Each
Examples batch has an isolated Git-index test record and a compact evidence
snapshot under `Migration/Acceptance/`; pair its core submodule pointer and
validation entrypoints after their dependencies exist. Shared BP assets/Profile
sets stay with all their related implementations. Failed or unfinished batches
remain uncommitted. Preserve old binary/report provenance and record skipped
checks; do not promote a historical pass or later source freeze into a fresh
current-DLL acceptance. Publishing/pushing/tagging requires separate authority.

| Version | Delivered scope | Status and retained qualification |
| --- | --- | --- |
| 0.1.0 | UE5.8 binding foundation and compatibility demo | Tagged; exact-source package confirmation was deferred |
| 0.2.0 | Python-first Third Person template parity | Tagged; retained 46-check core, demo and visible evidence |
| 0.3.0 | API/lifecycle hardening | Tagged; retained 67-check Win64 evidence, Linux unvalidated |
| 0.4.0 | Lyra integration and authority/replication observation | Tagged; retained generic 70/70 and Lyra package evidence |
| 0.5.0 | Bounded Python-driven Lyra GAS gameplay slice | Tagged; final selector hardening had runtime tests but no new exact-source package |
| 0.6.0 | Playable Python-first Third Person and Examples split | Tagged; retained headless, package and visible evidence |
| 0.7.0 | Retained-class Mixin Third Person | Tagged; retained headless/package evidence, visible-client gate still unrecorded |
| 0.8.0 | Lyra Python health-bar foundation | Implemented in development; review closeout and release gates remain open |

Historical tags and delivered scope are not being rewritten. The 0.1/0.5
exact-source package gaps and 0.7 visible-client gap remain recorded debt, not
retroactively passed checks. A fresh candidate matrix must cover the current
behavior before 1.0; it cannot change what was tested in an older release.
Original result IDs and milestone details are preserved in
[Validation history](docs/Validation_History.md).

## Runtime Blueprint migration sequence

The complete static audit contains 491 Blueprint-family assets: 471 non-ABPs
and 20 retained ABPs. Scope review leaves 246 runtime-logic candidates, 182
configuration-only assets and 63 retained assets. These are graph candidates,
not proof that every asset is reachable in the selected Experience or has
been migrated. Eleven diagnostic, prototype or welcome-map candidates require
reference/scope review before their batch is accepted.

| Version | Runtime BP scope | Initial candidate count |
| --- | --- | --- |
| 0.8.0 | Existing health-bar closeout only | Existing slice |
| 0.9.0 | Batch 1A: health-bar finish, weapon/ammo panel, three ammo counters | 5 |
| 0.10.0 | Remaining combat HUD/nameplates, pickups and world interactions | 32 |
| 0.11.0 | Characters, input, hero abilities and weapons | 37 |
| 0.12.0 | Effects/audio orchestration, phases/scoring/notifications and AI | 75 |
| 0.13.0 | Common UI, frontend, settings, sessions and replays | 57 |
| 0.14.0 | ShooterExplorer, TopDownArena and inventory reconciliation | 40 |
| 1.0.0-rc.N / 1.0.0 | Freeze the supported API and validate the identified source pair | Accepted scope |

Each version contains normally five-to-ten-Blueprint batches, adjusted for
parent classes and shared functions/macros. A completed batch lists the exact
replaced methods and Python owners, remaining BP/native dependencies and
evidence. Do not silently change counts when unreachable or retained assets
are found; record the reason. The initial inventory and batch assignments
belong to Examples at `UEPLyraIntegration/Migration/batches.json`.

After every behavior batch, run the original BP baseline and Python candidate
with the same inputs. Compare state, return/out values, event order, side
effects and presentation using declared tolerances. Prove Python ownership
without an implicit second execution of the original BP. Add the affected
real-UE and one-server/two-client scenarios, including respawn/rebind and
cleanup, before accepting the batch. Host fakes and isolated UMG fixtures are
supporting evidence, not substitutes for real gameplay or replication.
Passed, failed and skipped checks remain separate; a failed check is repaired
and rerun, never converted into a pass by weakening the assertion.

## 0.8.0 — Finish the Lyra Python health bar

Status: unreleased; implementation present, acceptance incomplete.

Goal: one event-driven health-bar presenter on Lyra's existing
`W_Healthbar_C`, with correct visuals and provable lifecycle ownership.
CommonUI, Game Feature actions, GAS authority and replication stay native.

The 2026-09-03 `All` result `20260903-033426` passed the checks implemented
then, but it used NullRHI, has `hud_audit: null`, and does not establish visual
parity, exactly one active presenter or post-shutdown zero owned callbacks.
It also predates the final source-only bootstrap fix. Passing host tests does
not replace fresh real-runtime evidence.

Closeout implementation now routes HUD-enabled `All` through the audit, requires
one active presenter, and delays HUD success until Python-exit cleanup evidence
is available. 29 Python tests and 40 PowerShell contract tests pass, including
real CPython exit/skip-finalizer cases. A fresh strict HUD audit and current-script
NullRHI Standalone passed on 2026-09-07: one active presenter, then zero final
references and balanced 3/3 controller and 6/6 health subscriptions. UBT repaired
the earlier BuildId mismatch with two metadata-only actions. On 2026-09-10,
the animation/interpolation fixes passed real UMG rendering in an isolated
fixture, and the precompiled cross-Actor caller passed all five routing phases.
Additional live profile-switch coverage found a zero-sized native fallback
frame defect; the UEP-only fix requires four incremental plugin build actions,
not an Engine rebuild or package. Mid-animation cleanup now avoids completion
reentry while the router is unavailable.
Integrated full `All` and current-source package gates remain open. See
[Validation history](docs/Validation_History.md).

The 2026-09-12 scope clarification makes two independent clients mandatory for
the 0.8 network gate. `Network/All` now route to the two-client acceptance
driver; the old single-client lane is named `NetworkPrecheck` and cannot
satisfy the gate. Explicit World/Player tokens, per-player health/restart,
20-phase ACK barriers and all four process exits are part of the new contract.
The focused `20260912-network-run-05` passes on UE 5.8.0 / Python 3.11.8:
A/B isolation, two travels and B0 leave/B1 rejoin, with all four exits clean.
It is a loopback NullRHI pass, not rendered or packaged network acceptance.
See the [network acceptance plan](docs/Lyra_Network_Acceptance_Plan.md).

Required exit gates (host checks alone do not close a runtime gate):

- [x] Restore damage/heal/death presentation and numeric interpolation. Initial
  setup and subsequent health changes must use the appropriate retained visual
  primitives rather than resetting the bar on every update.
- [ ] Integrate `HUDAudit` into `All` and its success condition. Missing or
  invalid Interface/selector/profile/action configuration must fail the gate.
- [ ] Require exactly one presenter for the tested local player while active,
  zero dedicated-server presenters, and zero presenter-owned delegates/state
  after Destruct, router teardown and interpreter shutdown. Final acceptance
  must be decided after cleanup evidence, not from a pre-quit snapshot.
- [x] Add negative tests for duplicate presenters, missing cleanup evidence and
  invalid audit data; each must make validation fail. Existing cleanup log
  messages are retained evidence, not proof of an observed leak.
- [x] Add a focused caller-BP regression: another Blueprint calls an Actor
  reference targeting two instances of the same BP class. One profile implements
  the function in Python; the other omits it and reaches the preserved BP.
  Both pass through the shared router and select by target UObject. Assert
  class identity, per-instance counters/side effects, no implicit original call
  after Python success, and restoration after unregister.
- [x] Record a rendered damage/heal/death/respawn acceptance run. Use native
  Lyra gameplay or an isolated fixture for death; do not broaden the existing
  non-lethal health-delta bridge just to drive this test.
- [x] Pass the dedicated-server/two-independent-client network gate: explicit
  per-player command/snapshot/respawn targets, isolated local HUD ownership,
  interleaved command idempotency, second-player join and one-player leave/rejoin
  without disrupting the other. Preserve ambiguous-target rejection and collect
  final evidence for every started process/connection generation. The adapter,
  driver and release-gate contract are implemented; focused run
  `20260912-network-run-05` has 20 server phases, 20 A, 13 B0 and 4 B1 ACKs.
- [ ] After the fixes, rerun current-source host tests, HUD audit, Standalone,
  synchronized server/client, Win64 Development cook/package and packaged
  runtime, plus the rendered check. Retain both repository revisions, binary
  and reference hashes, strict logs and final cleanup evidence.

Non-goals: other combat HUD panels, a general GAS/RPC surface, broad hot reload,
new platform support, or a new native networking authority model. Current-source
combined runtime/network/package acceptance remains unfinished. The no-build
focused lane is supporting evidence, not a substitute for that combined run.

## 0.9.0 — Mixin engineering and one reusable HUD chain

Status: in development; 0.8 release closeout remains independently open.

Goal: make the retained-class model predictable in normal project development,
then exercise the reusable pieces with one weapon/ammo HUD chain.

Batch 1A consists of `W_Healthbar`, `W_WeaponAmmoAndName`,
`W_AmmoCounter_Pistol`, `W_AmmoCounter_Rifle` and `W_AmmoCounter_Shotgun`.
The first implementation gate is correct BP/reflected/native call entry and
return/out-parameter writeback. The experimental in-place function-body gateway
now passes one precompiled caller/ProcessEvent integer-and-bool output fixture;
it remains separate from the production Mixin router and is not enabled in
Lyra business. This is not blanket return, delegate, RPC or latent support.
Separate normal playable startup from opt-in validation probes, and verify
the staged script/asset hashes before interpreting a runtime result.

Progress recorded on 2026-10-13: four weapon widgets retain persisted
Interface/CDO assets and pass 42 original-BP/Python real-UMG comparisons. A
shared read-only frame sampler replaces per-widget native polling and emits
presentation changes only when values/ownership change. Native QuickBar/Pawn
signals trigger immediate refresh. Lyra StatTags has no public ammo-change
delegate; a replication-event subscription is not claimed.

`WeaponNetwork08` passes 19 real-input phases with a dedicated Editor server and
two rendered clients: native firing/GAS reload, empty ammo, native pickup entry,
slot switch, Pawn restart, two travels and B exit/rejoin. Native per-player ammo,
Python HUD and an original-BP baseline agree; all four process instances exit 0
with closed scopes. The pickup fixture invokes the existing native/BP spawner
entry; physical walking into a pickup is not claimed.

`WeaponScopeRegression05` passes native message cancellation, four live Profile
round trips without Construct replay, and three controlled reload/native-GC
cycles. `PIERegression05` passes three real PIE sessions in one Editor with
placed/spawned Actors, Construction/BeginPlay/EndPlay, closed scopes, collected
old Actors and restored UFunctions. `CallMatrixRegression`, both rendered Third
Person variants and standalone/shared core regressions pass. Host tests total
82 Examples cases, 9 core subscription cases, 45 existing HUD/network contracts
and 16 weapon contracts.

The current Win64 game archive passes rendered weapon presentation and the
same native message/profile/reload/GC fixture. Packaging exposed and repaired
the missing runtime plugin-script search path and suppressed dependent-import
error. Cooked-network attempts remain failed: LyraGame is not a dedicated
Server target, and mixed uncooked Editor/cooked World Partition peers reject
missing generated level packages. A real LyraServer dry plan has 1,235 cold
actions; dedicated packaged networking remains an explicit RC-matrix debt,
not a passed 0.9 check. CC review timed out twice with no review decision.
The batch's bounded gameplay/presentation evidence permits 0.10 development;
release publication/0.8 closeout and the wider target matrix remain open.

- Define and test a call-entry matrix: cross-Actor BP calls, reflected
  name-lookup/ProcessEvent paths, ordinary events, explicit original calls,
  supported return/const-reference signatures and rejected signatures.
  Separately record retained-original pointers, Final/explicit-parent paths
  and direct native C++ calls as interception boundaries, not blanket promises.
- Cover placed, spawned and late-loaded objects; first-call registration timing;
  BeginPlay/Construction/EndPlay; per-instance selection, fallback, reentry,
  profile switching, GC, repeated PIE and world travel. An event that already
  ran is never replayed by registration.
- Provide a controlled unregister/reload/re-register workflow, with explicit
  restart requirements for generated type or function-signature changes. Do
  not promise arbitrary live Blueprint recompile or state migration.
- Make diagnostics identify the UObject, class, profile, function and lifecycle
  stage; document recovery from import, selector and Python callback errors.
- Add one bounded reusable Gameplay Message subscription/lifetime surface and
  use it for weapon/ammo presentation, without moving inventory, equipment,
  GAS, replication or scoring authority out of Lyra.
- Keep generic binding/message/lifetime APIs in the plugin; keep Lyra-specific
  adapters, presentation policy and assets in Examples.

Exit gates:

- [x] A checked-in call/lifecycle matrix labels every path as tested supported,
  intentionally rejected, or bypass/unsupported, with reproducible fixtures.
- [x] The controlled reload and cleanup tests pass across repeated PIE, GC and
  travel; state, callbacks and router restoration are checked after teardown.
- [x] A visible and packaged weapon/ammo example proves native signal plus
  read-only sampled change updates,
  safe subscription removal and native authority ownership.
- [x] Batch 1A has original-BP/Python state and visual comparisons for weapon
  switching, firing, reload, empty ammo and Pawn replacement. One server and
  two clients prove that ammo/UI state never crosses local-player ownership.
- [x] Normal playable startup does not auto-run validation or request exit;
  explicitly enabled test modes retain bounded timeouts and cleanup evidence.
  Focused rendered weapon mode exits cleanly; the no-test-flag Lyra observation
  is bounded and stopped only by its owning test driver, not by a probe.
- [x] Generic, both Third Person variants and Lyra pass the candidate regression
  matrix; the missing Mixin Third Person visible gate is closed.
- [x] The supported API inventory and migration/deprecation rules are ready for
  RC freeze, with no known release-blocking correctness defects.

The [call/lifecycle matrix](docs/Mixin_Call_Lifecycle_Matrix.md),
[subscription contract](docs/Runtime_Subscriptions_API.md) and
[API inventory](docs/Supported_API_Inventory.md) define these bounded claims.
Production Mixin out/RPC/delegate/latent restrictions and native-call bypasses
remain explicit. No release tag or independent CC approval is implied.

Non-goals: full QuickBar, reticle, team score, elimination feed and accolades;
RPC/latent support; arbitrary C++ interception; unrestricted hot reload.
Those runtime BP groups are assigned below rather than enlarging 0.9.

## 0.10.0 Combat HUD and world interactions

Status: HUD and world pilots have bounded native-input/context evidence; the
complete batch/version remains open.
Begin with ammo-reticle presentation and touch/input HUD, then grouped world
interactions; typed message payload and asynchronous support is added only
when the selected asset requires it.

The first `W_Reticle_AmmoBar` pilot has persisted Interface/CDO assets and a
Python-owned shared-observer presenter. `ReticleRegression03` passes ten real
BP/Python material comparisons, retained class, live Profile round trip,
rendered PNG and zero final scope/ticker state. `W_FireButton` now routes its
authored bound-click entry through Python to the same two Enhanced Input
actions; native GAS, ammo and replication remain unchanged.

`CombatHUDNetwork04` passes 19 phases with a dedicated Editor server, two
rendered clients, B0 exit/B1 rejoin, eight screenshots and four clean exits.
Python/BP FireButton intent, actual ammo consumption/reload, weapon/Pawn
replacement, two travels and zero final owned observer/scopes are checked.
Native aim is now asserted as Pitch=80/Roll=0, and healthy UI numeric/material
values must match native Health. `HealthBootstrapRegression01` also verifies
the repaired pre-ASC 0/0 -> first 100/100 notification, eight rendered health
checkpoints and mid-animation Profile teardown. No build/cook was needed.

Reachability audit found the original Pistol/Rifle/Shotgun definitions use
their own reticles/ammo counters, not `W_Reticle_AmmoBar`. Its multiplayer
evidence is explicitly a test-owned overlay initialized from the production
counter's native WeaponInstance, not a shipped HUD substitution or a global
unreachability verdict. Physical touch, the new assets' packaged runtime and
the other 30 initial candidates remain open; the 0.9 package is not current
proof after these Python/asset changes.

Next group: touch HUD parent logic and menu intent, then world interactions.
Three apparent candidates contain only Parent calls; retain their BP shells
but verify parent/child routing after the parent migration before excluding
anything. Typed message payload, lazy soft-class asynchronous input and world
RPC dispatch need explicit bounded support/tests when consumed. Cached/final
parent calls and net functions must not be silently assumed interceptable.

The `BP_GameplayEffectPad` parent and unchanged child now pass eight deferred-
spawn construction comparisons (damage/heal/special/invalid per class), retained
Actor type, no-ASC overlap no-op and sixteen Actor destructions. `PhysicalGAS03`
also passes eight real Lyra Pawn cases / sixteen native enter/leave rounds:
damage 75->65->55, heal 75->85->95, active effect removal and stable Health after
leaving agree with BP. Native Pawn teleports trigger physical collision; these
are not manual-player-input or network acceptance.
The Editor authoring helper now reuses inherited scalar Name selectors without
redeclaring them or changing the parent CDO/metadata; `inherited-selector04`
and seven current-DLL call-matrix fixtures pass. Only UEP Editor module builds were
performed for this fix. Related-class simultaneous routers remain rejected;
an attempted child declaration expansion was reverted after the guard caught
it. An Editor-only construction extraction helper retains the BP body under
`UEPConstructEffectPad` and leaves a two-node virtual construction forwarder.
Thus this child's explicit Parent call reaches the single parent router;
there is no generic cached-pointer/Parent interception or second child router.
`PadNetwork02` passes sixteen parent/child x damage/heal x A/B x BP/Python
cases on an Editor dedicated server and two rendered-offscreen clients. Native
Health replication, unchanged non-target Health and actual numeric/material
HUD agree; all three processes exit 0 with zero final scopes. Test-owned server
pads/teleports are not forced pad replication, client effect prediction,
production reachability, rendered/manual pad input or package acceptance.

Migrate the remaining combat HUD, QuickBar slots, reticles and nameplates,
then pickups, grant pads, launchers and teleporters. Preserve UMG layout,
inventory/equipment facilities, collision, native replication and authority
checks. Scope is BP business, not a rewrite of Lyra's C++ inventory system.

`DebugSpreadNetwork01` adds a retained-class Python debug spread Tick to the
native weapon regression. Nineteen phases, two clients plus rejoin, automatic
Tick, nonzero native spread and exact BP/Python/native formatted text pass;
four processes exit 0. Its debug overlay is test-owned. Native audio/Editor
warnings are retained, and production reachability/package remain unaccepted.

The three production reticle copies now use Python Tick and owned typed
ADS/elimination subscriptions. `ReticleDifferential04` compares their geometry
using the same real equipped pistol instance, typed owner/PlayerState/suicide
filters, restarted elimination animation/time and five closed final scopes.
The original disconnected ADS animation branch remains a no-op. A twelve-node
example-only BP adapter supplies typed native-VM wildcard conversion; it contains
no subscriber/gameplay business and adds no native plugin dependency or Engine
edit. Transport proof includes nested-copy isolation, wrong-reader/outside-
delivery rejection and idempotent cancellation. `ProductionReticleNetwork01`
passes nineteen real weapon phases with actual production Pistol/Rifle reticles,
four exits and A/B0/B1 final scope balance 11/11, 7/7, 1/1. `ReticleNativeADS05`
then verifies real IA_ADS press/release through the native ability/message
producer. `ReticleNativeShotgun06` equips a native shotgun through the original
pickup entry, fires 8->5 ammo and reruns all layout comparisons against that
native weapon. Physical pickup, real kill gameplay, network shotgun and packages
remain separate; geometry on one weapon alone is not three-weapon gameplay proof.

`MenuDifferential04` verifies the retained menu-button bound-click entry across
Python/BP/Python profiles, native asynchronous push and deactivation, initially
unloaded menu class and a rendered/inspected/hashed menu screenshot. Python passes
a validated soft-class string without preloading; streaming, input suspension
and layer insertion stay in CommonUI. Eight current-DLL call fixtures include
the new lazy soft-class conversion. Only the UEP Editor module was incrementally
built; this menu driver performs no compilation/cook/package. Physical touch,
input suspension/resumption tokens, cancellation, production reachability and
multiplayer/package acceptance are not inferred from this bounded test.

`HostDifferential02` migrates the actual production `W_WeaponReticleHost`:
native LyraWeaponUserInterface Tick still detects equipment changes; Python
clears old children, reads the original item fragment, initializes/adds the
same reticle/counter classes with fill alignment, and manages death visibility.
Eight BP/Python cases include automatic default HUD reachability, live Profile
roundtrip without recreating children and Pistol/Rifle/Shotgun native equip.
An injected GameplayEvent.Death reaches the native ability/component delegate:
both wrappers collapse, Python handles it once and does not resubscribe the
same dead component. This is not a lethal-damage/kill or physical-pickup test.
Four VM cleanup nodes remove only the old BP delegate, avoiding routed business
reentry during teardown. `ReticleHostNetwork01` then passes nineteen weapon/
lifetime phases on the current DLL, two clients plus rejoin and four exits;
host scopes server/A/B0/B1 balance 0/0, 7/7, 5/5, 1/1. Native child configuration,
player/item ownership, automatic routing, overlay cleanup and production
Pistol/Rifle BP geometry agree. Network shotgun, lethal death, packaging and
the complete 0.10 batch remain open. No C++ build or cook/package was needed.

`ProgressDifferential02` moves the existing production `W_AbilityProgress`
message subscription, owner filter, game-time countdown/text/material and
completion visibility to Python. Eleven BP/Python cases pass, including real
automatic UMG Tick, paused native game time, repeated messages, explicit hidden
Profile resume and Destruct/no-late-delivery; final scopes balance 3/3.
The original async proxy has one ownership-only storage node for cancellation;
the hidden resume entry is a declaration-only BP shell, not lifecycle replay.
ReadDuration/BroadcastDuration extend the VM-only transport to six functions /
eighteen nodes. `TransportAdapterRegression02` passes typed UI/Verb/nested-copy/
wrong-reader/outside-delivery/cancel regression on that adapter; the first
NullRHI startup attempt timed out without executing its fixture. The affected
`ReticleAdapterRegression01` passes actual ADS and native equipped-shotgun fire
8->5 alongside all geometry/message comparisons. Screenshots were inspected.
The first two ability-progress network runs expose a hidden-widget reuse defect
after Destruct/travel: one-shot OnInitialized cannot restore a cancelled scope,
and Collapsed widgets cannot Tick. Construct now idempotently rearms; the BP
fallback resumes without resetting model/lifecycle. `ProgressReconstructRegression01`
passes twelve cases/final scopes 4/4. `AbilityProgressNetwork03` passes all nineteen
phases, two clients/rejoin/two travels/four exits and final progress scopes
server/A/B0/B1 0/0, 6/6, 6/6, 2/2. Twelve screenshots are hashed and selected
progress images inspected. Synthetic local duration messages are not native
interaction-ability production, remote-player interaction or GameplayMessage
replication.

Ability-failure feedback now has a clean ten-function transport asset and
seventeen production-widget/original-BP comparisons, including native latent
delay during pause, persistent animation callbacks, hidden Profile resume and
native remount/cleanup. The world-clock prototype failed and was replaced by
native RetriggerableDelay with an explicit int32 Linkage callback. Named BP
bool-output tuple handling was repaired after a real differential failure.
One native live-table FText survives en/zh-Hans/en culture changes without
rebroadcast; corrected screenshots were inspected. Two-client failure feedback
passes all 19 phases/two travels/rejoin/four exits, with scopes 0/0, 6/6, 6/6,
2/2 and no final active/errors. It uses local synthetic owner/null-controller
messages, not native GAS failure or message RPC. Current adapter UI/Verb
regression also passes. FailureNative03 additionally passes five real original
Pistol full-magazine ASC-rejection checkpoints: native MagazineFull/FText
delivery, duplicate reason, automatic latent/Outro completion, a REAL second
LocalPlayer/Controller's own production UI and first-owner filtering, then
native secondary-player removal and pending Profile cleanup. Inventory/ammo/
Health stay unchanged, final scopes balance 3/3, strict logs/normal exit and
1,102 frozen hashes pass; the split-screen native image was inspected. Its
Slate user bootstrap is explicit synthetic input-environment setup, NOT
hardware input. One backwards-compatible optional FCharacterEvent user-index
argument needed a bounded THREE-action UEP-only compile, no Engine rebuild.
Dead/invalid-health, cross-process native GAS failure production, packaging
and remaining candidates stay open. Dash cooldown (2I) has eleven
bounded comparisons plus a five-case original native GAS Dash/death check;
its 1.5s duration is not injected by the fixture. Two-client travel/rejoin
passes after repairing inactive UIExtension-pool subscriptions and Windows
report races. Final scopes/pool watches are closed; selected images inspected.
Native repeated Dash emits no user-facing failure in this scenario; that
producer and lethal damage stay unclaimed. Respawn timer (2J) now has copied
assets and a Python policy using native timers/audio. Twelve bounded comparisons
pass (production comparisons plus isolated viewport lifetime), as does the original 5s native GA_AutoRespawn -> UI -> genuinely new Pawn/
completion sequence. Blueprint local-variable and two-material inference
errors were repaired against actual runtime results. Shared pool watches can
explicitly resume collapsed entries without lifecycle replay. Two-client
travel/rejoin passes, with inspected '1 RESPAWNING' A/B0/B1 images after the
overlapping short fixture UI closes. Actual inactive-pool reinsertion and
acoustic/package proof remain open.

Quickbar slots (2K) preserve the native inventory/equipment and replace slot,
selected/empty/ammo and mouse-to-input orchestration. Twelve bounded comparisons
and nineteen-phase two-client travel/rejoin pass. An explicit named-output
Mixin opt-in now routes IsThisTheActiveQuickbarSlot to Python, including real
BP/native output propagation and original fallback. The ten-lane call matrix
passes; current-DLL query counts are 9 standalone and 15/8/2 network A/B0/B1.
Only the UEP plugin module was incrementally compiled, not Engine modules.
Packed-bool adversarial layout, original BP OnInitialized, physical mouse and
package gates remain open.

Nameplates (2L) now have Widget/Source/Manager Python implementation and typed
VM authoring. The approved upstream 5.8.1 update and matching Editor/modules
resolve the former shared-binary blocker without relabeling manifests or
custom Engine edits. NameplateAssets01 accepts/copies the Widget/Set only;
NameplateDifferential06 passes fourteen native Widget/original-BP cases with
an inspected PNG, final scopes 23/23, team proxies 13/13 and init delegates
10/10, zero residual/errors/ensures. Component Assets01 accepts Source/Manager
and the extended 19-function/59-node typed transport. Differential02/03 and
ComponentReleaseRegression01 pass eleven original-BP/native component cases;
WidgetReleaseRegression01 passes all fourteen Widget cases with an inspected
PNG. The explicit QuickBarAssets19 revision chain preserves all nineteen old
transport semantic digests. Network14 now passes all nineteen native-input
loopback phases, two travels and B rejoin, four normal exits, final owned
scope/root cleanup and 415 unchanged input hashes. Native asset inspection
confirms both components are client-only: zero dedicated-server scopes are
required. Host checks pass 451, not a substitute for native gates. Low-quality
rendering and fixture-owned old-Pawn/Source retirement are declared; projection,
native death-ability and package acceptance are NOT implied. Earlier failed
experiments remain in PROGRESS. The UEP broadcast property-address
fix requires only plugin incremental builds; the new eleven-lane call matrix
passes on 5.8.1. No new package or release acceptance is implied.
Original duplicate-Pawn descriptor retention is confirmed against native BP;
fixture-only orphan cleanup is declared, not a production-policy fix. Next is
the 0.10-2M inventory-pad original-BP/native physical-overlap differential;
0.10, all later migration batches and full release acceptance remain open.

Inventory pads (2M): Assets01 retains parent/mesh class identities and original
business blocks behind four virtual boolean gates owned by one parent Mixin
Set; all four old graph semantic digests survive compilation. Differential02
passes twelve native construction/Tick/Profile/physical-pickup/rejection/
destruction comparisons and cleans sixty fixture actors. Player01 adds four
real Lyra player comparison pairs: physical pickup -> native QuickBar equipment
instigator -> Enhanced Input/GAS pistol firing (12 -> 11), full-slot rejection,
and native inventory identity / position / movement / aim rollback. Native
Controller K2 destruction being a no-op is handled only in fixture cleanup.
Network03 passes all sixteen two-client native inventory/equipment/fire
replication cases with target isolation and per-case native rollback, three
normal exits, strict logs and 1,012 unchanged input/reference hashes. Host
checks pass 464. Pads retain their original replication flag; no forced
replication is claimed. Remote audio, native exception gating,
production-map placement, client pad Profile parity and package remain open.
Next 2N is B_GrantAbilityPad_ApplyGE, retaining native GAS and Timeline curves.

Grant-GE pad (2N): Assets01 retains the original Actor class, two business
graph digests and native Timeline/curve data. Six boolean gates route business
to Python; a four-node FText transport preserves native text history without
moving business decisions into VM glue. Differential02 passes six native
original-BP/Python comparisons including real instant healing, leave-triggered
charge, paused Actor Tick with continuing native Timeline and restored visuals.
Actual default cooldowns are 15.004688/15.005099s; no Duration override is used.
Both fixture actors/subscriptions and player health/position/movement restore.
Network04 passes four BP/Python x A/B owner-isolation/inactive-reentry/default-
cooldown cases and both clients' native replicated Health HUDs. All three
peers exit normally and 1,019 frozen input/reference hashes remain unchanged.
An early-damage queued spawn-animation reset is fixed by flushing stopped
UMG animations before writing current materials; HUDRegression01 (including
ordinary teardown and mid-animation Profile switching) and WeaponHUDRegression01
pass for that shared presenter change. Host checks pass 482. Culture,
client prediction/Profile parity, placement and package remain open.

Launchers (2O): Assets03 retains base/Push/Up classes with one inherited
Interface Set, seven dispatch gates, original multicast signature/flags and
the original bReplicates=false. Differential04 passes eight native BP/Python
pairs using owned zero-gravity Character fixtures: 16 actual overlaps, 36
actors and 16 closed scopes, unchanged 1,045 input/reference hashes. The
original Push Y clamp is intentionally preserved at zero. Host tests pass
509. Network05 passes 12 real-player two-client cases with original gravity,
native launch request parity, actual owner motion and other-owner isolation,
verified player/observer restoration, three clean exits and 1,037 frozen input
hashes. Native CharacterMovement/collision/RPC remain; client pad Profile/VFX parity,
production placement and package are not claimed.

Spawners (2P): Assets02 retains weapon/ability classes, six original graphs,
eight gates, one inherited Set, the original failure multicast/FText transport
and a four-node native reload-interface adapter. Differential03 passes nine
real-player BP/Python pairs including native Rifle fire (30 -> 29), duplicate
ammo/full/reload guards, healing, original respawn curve and four natural
10s cooldowns. Network02 passes 36 A/B x BP/Python cases using original
L_Expanse Rifle/small-heal actors and their serialized definitions; no new
network field or test-derived class. Native inventory identities, Health,
position/movement/aim and actor configuration/Profile restore, 36 scopes close,
three peers exit normally and 1,059 input/reference hashes remain unchanged.
Host tests pass 534; InventoryRegression01 also passes the older 16-case
two-client lane. PostGame/culture/all definitions, exact client constructor
Profile parity and package are still unverified. Native game-project C++
spawner machinery is not claimed as migrated in this BP phase.

Teleporter (2Q): Audit02/Assets01 retain the original actor class, five graph
digests (including its two macros), five dispatch gates, signatures and
non-replication. Differential04 passes seven physical Character BP/Python
pairs with native Niagara settings, teleport, direction/launch flags, original
world-space relative offset/clamps and no-controller behavior. All 54 actors
and 14 scopes close; strict logs, normal exit and 1,059 frozen inputs pass.
The strict log gate caught and fixed a missing hidden native Owner parameter
for receiver Box destruction; live component-list proof replaces stale SCS
references. Network02 passes 12 real-player A/B x BP/Python launch/no-launch/
relative-offset cases, native requests/transforms, actual owner flight and
other-owner isolation, 24 portal/12 scope cleanup, player state restore and
three normal exits. Natural Lyra braking remains enabled. Host checks pass 559. Audible
parity, client portal Profile/prediction, original level placement, grenade/
multi-destination runtime, invalid-config parity and package remain open.

Action touch (2R): Assets02 keeps base/MobileOnly classes and five original
graphs, uses direct function Mixin and one inherited parent Set, and exposes
only typed message/proxy cleanup transport. Audit03 proves original native
script-Tick metadata is base=true/MobileOnly=false; it is not force-enabled.
Differential05 passes 30 mounted UMG checkpoints including native CommonUI
state changes, materials, owner/foreign/repeated duration, pause, base cooldown
completion, original child no-Tick behavior, teardown/reconstruct and Profile
roundtrip. Four roots and eight scopes close; two native PNGs were inspected,
strict logs/normal exit pass and 1,078 input/reference hashes stay unchanged.
Runtime reflected writes use set_property to avoid Editor notifications
rerunning PreConstruct. WeaponHUDRegression01 passes 42 prior UI cases.
Click01 passes four native CommonUI -> Enhanced Input -> existing GAS Jump
cases with actual owner rise/velocity and one native Jump event, restored
observer/player and released roots. These are synthetic activations, not touch
hardware. Network02 passes eight two-client owner/lifetime phases with
explicitly client-local typed producers, actual replicated foreign Pawns and
normal three-peer exit. Per-client final scopes balance 8/8 with zero active;
the two live production HUD listeners are preserved until native teardown.
GameplayMessageSubsystem replication is NOT claimed.
TouchRegionsAudit01 retains empty/base and three-parent-forwarder
left/right BP shells: no BP business exists there, native game C++ remains
a separate phase. Host checks pass 586. Production touch placement, physical
hardware, native duration ability producer and package remain unverified.

Heal pickup ability (2S): native dependency closure reaches FiringRange even
though its directory is named HealthPickup_Unused; it is NOT excluded. Assets03
preserves the original class, graph digest, native equipment AbilitySet source,
InstancedPerActor/LocalPredicted policies and original Montage/GE references.
Python owns cost/commit decisions, native Montage task delegates, immediate GE
and the same 1s native TimerManager with explicit timer/scope cleanup. Four
native end-notification guard nodes prevent teardown router reentry; compiled
K2_OnEndAbility ownership and runtime native-end counters prove the entry.
Differential05 passes seven BP/Python pairs: natural completion, native cancel,
interruption, original 1s timer, paused world-time, active Profile switch and
external native EndAbility. Native item identities/Health restore, strict logs,
normal exit and 1,083 frozen hashes pass. Host checks pass 607. Network03 passes
all 12 two-owner native ASC LocalPredicted trials, exact one-use native cost,
replicated Health/HUD/owner isolation and inventory/aim/movement rollback.
Three peers exit cleanly, final scopes/timers balance 6/6 + 3/3 + 3/3 with zero
active/errors, and 1,075 input hashes remain unchanged. This is bounded proof.
Native cost/commit refusal, original FiringRange placement and package remain
open; no Engine/plugin C++ changes/builds were needed for this batch.

- [ ] Each small batch passes original-BP/Python comparison without BP fallthrough.
- [ ] Pickup failure/success, cooldown/respawn and interaction effects match
  the baseline; two players cannot share another player's UI or claim state.
- [ ] Widget and Actor lifetime tests leave no owned subscriptions after
  teardown, travel or profile switching.

## 0.11.0 Characters abilities and weapons

Status: in development; the first GA_Hero_Jump/shared ability UI pilot is
authored on retained BP classes in the disposable Lyra copy. Native CommonUI
click smoke passes four cases against the new default Python Jump. Independent
hold/release, cancellation, state-end and active-Profile-switch BP/Python
comparison passes seven native pairs with balanced scopes, independent report
validation and 1,248 frozen hashes. Native UI grant/remove passes eight original/
Python cases on actual production extension-point entries, including two same-
tag registrations, empty/invalid configuration and cross-Profile cleanup.
The first bounded pilot also passes 28 native authority trials across two real
clients, fourteen BP/Python client pairs, independent report validation, strict
logs/normal server-last exit and 1,256 frozen hashes. Native scopes balance at
server 14/14 and each client 7/7. Warmup Pawn turnover and dedicated-server
readiness are explicitly gated. GA_QuickbarSlots also passes ten native BP/Python
pairs and forty two-owner trials: native GAS events reach the original/Python
three-task orchestration, native QuickBar RPC/equipment/replication remain, the
foreign owner's state stays unchanged, and original inventory identities restore.
Normal server-last exits, independent report validation and 1,265 frozen hashes
pass. These are native GameplayEvent API inputs, not hardware/EnhancedInput or
replicated GameplayEvents. GA_Hero_Death camera/cue/delay orchestration passes
five native lethal-damage BP/Python pairs, independent report gate, strict logs,
normal exit and 1,281 frozen inputs. The original five-second respawn preemption
and two actual eight-second wait completions are tested separately using an
explicit restored per-instance respawn-delay fixture (no Death Duration/CDO
change). Source observers balance 10/10, policy scopes 5/5. Its dedicated-server/
two-real-client lane also passes twenty authority trials and twenty independent
Cue observations per client, native owner activation/camera/payload/respawn,
foreign owner isolation, independent gate, normal server-last exit and 1,284
frozen inputs. Server scopes 10/10, clients 5/5 each; four actual authority waits
complete, while client waits end through retained native replicated end. The
process-local threaded-loading switch is recorded. Post-fixture-refactor single-
process regression also passes five pairs with 1,287 frozen inputs. Cosmetic
choice components pass four native standalone pairs and sixteen random trials,
real native child-actor spawn/attachment/no-collision and original-identity
rollback, independent gate, strict logs and 1,304 frozen inputs. Their native
FastArray/two-viewer lane also passes 48 authority trials and 48 real body/
delegate/cleanup observations on each client, zero client policy replay, exact
foreign-owner parts, independent gate/normal exit and 1,308 frozen inputs; viewer
scopes each close 48/48. Post-helper-refactor standalone regression also passes.
AutoReload's retained-class/public-signature/graph/default authoring and six
native ammo-predicate, real fire-to-empty/original reload and lifecycle pairs
pass the independent gate, strict logs, normal exit and 1,313 frozen inputs.
Its two-client lane also passes 24 authority trials, actual fire-to-empty and
reload, owner/authority ammo agreement, unchanged foreign owner and retained
inactive remote LocalOnly authority ability, independent gate, strict logs,
three server-last exits and 1,317 frozen inputs. Six post-helper standalone
pairs also pass. Its LocalOnly policy and native GAS/replication,
inventory, actual reload logic and animation remain original.
Native RandomBool is retained, with both branches observed rather than a
seeded-stream replay claim. Character_Default/B_SimpleHeroPawn are source-
reviewed empty/parent-forwarding shells; their inheritance runtime is pending.
The distinct GA_Hero_Heal original-class/default/graph authoring and eight
native input/state/montage/effect/movement-lifecycle pairs pass, with actual
original Health 75 -> 80, balanced scopes, independent gate/strict log/normal
exit and 1,327 frozen inputs. Its seven-pair-per-owner predicted authority lane
passes 28 authority trials, actual GE/Health/task observations, replication and
exact player/spec restore, independent gate/strict logs/three server-last exits
and 1,331 frozen inputs. Its declared native authority input fixture restores
the exact suspended counts; original BP's duplicate unlock can consume a foreign
lock, so natural original-BP lock preservation is not claimed. Early-end tests
wait for first actual authority heal, not a latency guarantee. Post-helper
standalone eight-pair regression and three Python foreign-lock preservation
cases also pass with balanced 11/11 scopes, strict logs/independent gate/normal
exit and 1,331 frozen inputs.
It is not the previously migrated legacy GA_HealPickup. ADS retained-class/
defaults/signatures/graphs authoring and six-pair real input, camera-mode/speed/
mapping/source-message/reticle differential pass with one shared-parent router,
6/6 task scopes, 13/13 rooted helpers, independent gate/strict logs/normal exit
and 1,342 frozen inputs. Shared-parent UI lifecycle also passes eight native
grant/remove cases with independent gate and 1,342 frozen inputs. Two-client ADS
also passes 20 authority trials, actual native speed/camera/task states, local
UI/reticle observations, foreign-owner isolation, 10/10 server and 5/5 owner
scopes, gate/strict logs/three server-last exits and 1,346 frozen inputs. Final
six-pair standalone regression also passes with 1,346 frozen inputs; network pause is not claimed. Native
camera/movement/input/audio and animation stay native.
DropWeapon retained-class/default/signature/graph authoring passes; four-pair
real input/native inventory deletion/cycle/restore differential passes with
independent gate/strict logs/normal exit and 1,353 frozen inputs. Two-owner
16-trial authority/replication validation and post-network-helper four-pair
standalone regression also pass, each with 1,357 frozen inputs. Preserve
delete-not-world-pickup and native index-reset rules.
The whole 37-candidate version remains open; continue equipment, fire and
other hero/weapon policy batches.
Magazine reload retained class/defaults/original graphs/public signatures and
guarded End adapter authoring passes; ten-pair native equipped-pistol input /
actual montage-notify / authority ammo / refusal-tag / lifetime differential
passes, with independent gate/strict logs/normal exit and 1,367 frozen inputs.
Two-owner 36-trial network validation also passes with 1,371 frozen inputs,
authority 14/14 and owner 7/7 scopes, native non-authority owner notify branches,
independent gate/strict logs/three server-last exits. Ten-pair post-hook pistol
regression also passes with 1,371 frozen inputs. Rifle and Shotgun each pass ten
standalone inherited-parent-policy pairs, original inventory/item/AutoReload
restore and 1,381 frozen inputs. Both then pass 36-trial two-owner network
lanes. NetShooter also passes ten standalone pairs and 36 native authority
network trials with 1,391 frozen inputs, preserving its original capacity-one
magazine and zero AutoReload grants. Final serial pistol/Rifle/Shotgun
standalone/network regressions pass on the same final implementation.
Read-only original family audit passes; prototype reference closure/defaults
do not establish that it is unused. Native AutoReload, when granted, is explicitly
paused/restored as fixture isolation. No task callback or ReloadDone event
replay is used. Network pause is not tested.
Equipment-instance retained Interface/CDO authoring and four-family alive
original/Python differential pass. Native GC removes each real callback proxy
without changing paused animation state; no script callback is subscribed or
strong UObject retained. These bounded standalone lanes pass independent gates,
strict logs, normal exits and 1,387 frozen inputs. Rifle, Shotgun and prototype
owner/authority integration pass 36 reload authority trials each, actual
equipment add/remove/source/role and restoration. Native local tags and linked
layers must match each peer's native selection: dedicated servers have no
cosmetic child actors, and female clients legitimately select female layers.
Common montage/dead-state results agree. Prototype original-BP control and
Python both pass with 1,419 frozen inputs; native tag-map weak-owner warnings
remain (server BP=3/Python=4, clients=0), so playback is not warning-free.
Five original/Python real lethal Death/respawn pairs with a declared native
empty-slot dead-pistol unequip also pass, no animation changes and exact
Profile/source/respawn inventory model restore, 1,403 frozen inputs.
Natural-destroy unequip, four-family death and remote equipment-viewer proof
remain separate.
SpawnEffect now passes retained original class/full CDO/signatures/graph proof,
ten native original/Python lifecycle pairs and immediate BP-to-Python
reactivation. Original level-zero own immunity effect, 2.75-second montage,
75% movement unlock and native EndAbility latent cleanup are preserved; no
speculative extra delay gates remain. Current standalone and 28-trial two-owner
ServerInitiated network lanes pass independent gates, strict error/ensure logs,
exact state/spec/fraction/input-stack restoration, normal exits and 1,412 frozen
inputs. Scopes balance 19/19 standalone, 24/24 authority and 9/9 each owner.
Clients never directly activate/replay the ability, each verifies 14 own and 14
unchanged foreign rows. Original spawning-Cue active-timeline recycling warnings
remain (network clients 13/12); this is not warning-free playback or network
pause/fraction-boundary/immediate-handoff proof. Whole version remains open;
continue character, emote, fire, melee, grenade and other hero policies.
Team-color device software now passes six native original/Python pairs,
default native factory discovery, repeat/loop/Profile/pause/invalid-public-user
boundaries, exact owned-handle cleanup and 15/15 temporary roots. Physical LED
output, network, secondary users and same-instance native reactivation are not
tested. Its return-before-out Blueprint transport exposed a UEP VM argument
decoder defect, fixed with a bounded three-action plugin-only refresh; no Engine
implementation edit or full build. On the new DLL, eleven generic call lanes,
three PIE cycles, six sparse-map cases and the real 28-trial two-owner SpawnEffect
network regression pass. Combined nineteen-phase, two-travel/rejoin/HUD
regression also passes with 757 frozen inputs and four actual normal exits;
earlier batches retain their recorded old-binary provenance.
Builds on bounded support already required by 0.10 and introduces only the
additional asynchronous/RPC surfaces its scenarios need.

Emote's existing shared ability-widget router now has typed activation,
movement-check and native-End gates. Current authoring preserves full CDO,
original public signatures/business graphs and existing ADS Profiles/defaults.
Nine original/Python standalone pairs pass actual EnhancedInput activation,
native montage completion/interruption, crouch/uncrouch, cancellation, Profile
teardown and pause, with 18/18 scope cleanup and 1,435 frozen inputs. Native
LaunchCharacter produces external motion; ordinary AddMovementInput interruption
is not certified (the failed fixture produces zero velocity on both sides).
Original BP's ClearAll removes a foreign movement listener; Python removes only
its own. That intentional isolation difference is independently asserted, not
reported as exact listener parity. Final-input Emote nine-pair, shared Widget
eight-case, ADS six-pair standalone/twenty-trial network regressions pass.
The first Emote five-pair-per-owner network lane also passes twenty authority
trials with 20/20 server and 10/10 scopes per owner and 1,439 frozen inputs. Network movement,
crouch interruption and pause are not yet exercised. Whole 0.11 remains open.

Migrate character/input BP decisions, hero abilities, fire/reload, weapon
instances and grenades. Animation assets/ABPs, movement prediction, physics,
GAS execution and the native RPC/replication machinery remain. Python game
decisions must preserve server/client roles and cancellation behavior.

- [ ] Fire, reload, ammo exhaustion, switching, death and respawn pass BP/Python
  comparison in Standalone and one-server/two-client play.
- [ ] Supported ability tasks, delegates, cancellation and latent boundaries
  have call/lifetime regressions; unsupported signatures fail explicitly.
- [ ] No replacement changes UObject class identity or bypasses the required
  authority, prediction or replication checks.

## 0.12.0 Effects audio match rules and AI

Status: planned; dependency order is reviewed within each group.

Migrate BP effects/audio orchestration and shared business macros/functions,
then match phases, scoring/notifications and Shooter AI BP tasks/services/EQS
logic. Keep rendering/audio engines, animation, navigation, Behavior Tree and
EQS execution facilities native. Match-rule and presentation ownership remain
separate, including dedicated-server zero-UI behavior.

- [ ] Effect/audio triggering, warmup/play/postgame, scoring and notifications
  match the original BP checkpoints under the same inputs.
- [ ] AI task/service outcomes and cancellation are reproducible; long-running
  tasks do not retain a destroyed Pawn or World.
- [ ] Multi-client score/phase state, local notifications and cleanup agree.

## 0.13.0 Frontend settings sessions and replays

Status: planned; UI parent classes and shared functions migrate before children.

Migrate game-owned CommonUI widget logic, frontend, settings, session browsing/
hosting and replay presentation. CommonUI, online/session and replay facilities
remain native. Welcome-map and runtime diagnostic candidates receive explicit
scope/reachability decisions; editor/test utilities remain excluded.

- [ ] Navigation, focus/back behavior, settings persistence, session results
  and replay controls pass original-BP/Python comparisons.
- [ ] Repeated screen open/close and travel restore subscriptions and state.
- [ ] Failures/cancellations are tested, not accepted only on the success path.

## 0.14.0 Explorer TopDownArena and coverage closeout

Status: planned; each additional Experience gets its own acceptance scenarios.

Migrate Explorer interaction/inventory/StateTree BP business and TopDownArena
bombs, pickups, runtime level generation, match components and UI. Runtime map
generation belongs to this scope; editor geometry tools do not. Reconcile the
full initial inventory against actual references and accepted replacements.

- [ ] Both Experiences pass original-BP/Python gameplay, presentation and
  applicable multi-client/local-player comparisons.
- [ ] Every audited candidate is migrated, explicitly retained, unreachable
  with checked references, or a named blocker; no silent coverage gaps remain.
- [ ] Configuration-only BP shells and animation/editor/test exclusions have
  documented reasons. Game-project C++ migration stays a separate phase.

## 1.0.0-rc.N — Freeze and prove a release candidate

Status: planned; release fixes only after scope/API freeze.

Goal: validate one identified plugin/Examples pair, not a mixture of old green
reports and new source.

- [ ] Freeze the API and declared support matrix, including exact UE revision/
  BuildId, CPython version, Win64 target and build configuration.
- [ ] Run the complete generic, PythonFirst, Mixin and Lyra matrix on the
  candidate; retain editor/standalone, synchronized network, package, visible
  and post-exit lifecycle evidence with strict diagnostics.
- [ ] Keep Development evidence separate from Shipping. A production-game 1.0
  claim requires a dedicated Shipping smoke/package gate; the current drivers
  and old Development runs do not provide it. DebugGame also needs its own
  evidence before being advertised as validated.
- [ ] Reproduce a clean checkout with its pinned Examples revision and test
  source/archive installation. Verify Engine/reference assets remain unchanged.
- [ ] Record the [candidate manifest](docs/Validation_History.md#candidate-record-template),
  artifact hashes, known limitations and migration notes. A code/asset change
  after validation invalidates affected evidence and requires a new candidate.

A failing release-blocking gate means another RC, not a changed definition of
success. Documentation-only corrections can be verified without recooking;
their source relationship to retained runtime artifacts must stay explicit.

## 1.0.0 — Stable UE5.8 runtime binding

Status: planned; promotion of a fully accepted RC.

Goal: a supported, documented Win64/UE5.8/CPython 3.11 binding for the declared
API and configurations, with the accepted runtime BP migration scope as a
validation example. It is not a promise that all Lyra game-project C++ is Python.

Exit gate: every RC requirement passes, support/limitations and migration
guidance match the retained artifacts, source archives and any optional
exact-engine binaries have checksums, and both repository tags identify the
tested pair. Keep 1.x API compatibility within that published surface and use
documented deprecation paths. Additional platforms/configurations need their
own green build/runtime evidence.

## Validation cost and release discipline

These are workflow requirements, not a claim that the driver already automates
every tier.

| Change/risk | Minimum development verification |
| --- | --- |
| Documentation only | Diff/format/link and cross-document consistency checks; no Unreal build |
| Python behavior only | Host tests plus affected real-runtime scenarios using a verified matching native binary; record the new script hashes |
| C++/reflection/engine change | Affected incremental Editor/Game build plus call, lifecycle and runtime regressions |
| Blueprint/Mixin declaration change | Disposable-stage generation/compile, semantic audit and affected runtime tests |
| Release candidate | Full relevant matrix, cook/package, rendered checks and post-exit evidence on the identified source pair |

Choose narrow lanes while iterating; announce heavy work before starting it.
Each behavior batch runs its own BP/Python differential scenarios and updates
only affected fixtures. Reuse verified matching binaries for Python-only
changes; native changes require the affected plugin/module incremental build.
Do not start full Engine builds or cook/package as routine iteration. Release
candidate package/configuration gates stay separate from batch acceptance.
A skip flag, an old `full_acceptance: true`, or merely launching a client is
not release approval. Do not regenerate unchanged assets or start a package
for a documentation review.

The plugin repository owns generic binding/runtime APIs; Examples owns demos,
assets and Lyra adapters. Future releases record the Examples commit first,
then the core `Demos` gitlink, and verify both tags against the tested manifest.
Repository separation must not introduce a core dependency on Lyra.

## 1.1+ backlog

Game-project C++ business migration, broader platform/configuration coverage
and additional reflection/networking/hot-reload capabilities are independent proposals. Each
needs a concrete user scenario, bounded ownership and an acceptance contract;
none is implied by 1.0.
