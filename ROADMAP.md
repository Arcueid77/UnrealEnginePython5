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

The held-input Widget root now uses Python activation/create/remove/native-End
orchestration, retaining both scoreboard child types/configuration and native
GAS/async streaming/CommonUI layers. `20261016-widget-held/Assets02` preserves
full CDO, public signatures and original business graphs; typed soft-class
transport and explicit teardown-only state guards avoid eager loads and router
reentry. Elimination03 and ControlPoint01 each pass seven original/Python
pairs in their actual native Experience plus three canceled/replaced/pending
Profile-handoff GC regressions, with 21/21 scopes and original state restored.
Pause correctly invalidates the original non-pause scoreboard input: native
WaitInputRelease removes UI while game time is frozen, not an invented
keep-active-on-pause rule. Network02 passes 24 Elimination LocalOnly owner
trials, twelve independent foreign-UI observations per client, inactive native
authority, 0/0 + 12/12 + 12/12 scopes, strict logs, independent gate, 1,453
frozen inputs and three real server-last zero exits. Five failed fixture/
teardown attempts remain recorded. Python intentionally clears canceled proxy
references and cancels a previous owned pending request; those are safety
improvements, not exact parity with the original stale-reference behavior.
CP networking, travel/rejoin, physical input, scoreboard pixel/text parity and
packages remain untested here. The scoreboard Widget's own BP business is
still a later UI/scoring batch. Whole 0.11 remains open, and no Engine
build/cook/package was needed.

The pressed-input Widget root now routes activation/deactivation/native-End to
Python without changing either Inventory/Map child. Native authoring preserves
the full original CDO, type, three signatures and retained business graphs;
typed soft-class transport and exact original-delegate cleanup avoid eager
loading and foreign-listener removal. The actual Inventory Experience grants
two instances per toggle class; fixtures preserve both and issue a single real
EnhancedInput press. Differential01 passes fourteen original/Python pairs,
six native pending-GC regressions and four same-BP mixed-Profile cases, with
74/74 policy and 28/28 fixture scopes and 1,465 frozen inputs. Ordinary End
keeps the UI-owned panel, active Profile teardown closes it, and inactive
teardown cannot close pooled UI. Pressed UI survives pause, unlike held input.

Network01's UI reports passed but its strict-log gate correctly FAILED on
SpawnEffect's nullable cached Controller at owner startup. The repair is a
separate accepted batch (Examples fb1b13d): no missing-controller lock is owned,
and a later Controller cannot cause an unowned unlock. Real native cache-null/
foreign-lock probes and ten SpawnEffect pairs plus 28 two-owner authority
trials pass final Differential02/Network02 gates, 1,468 frozen inputs and normal
exits. Its earlier Network01 probe failure is retained; comparison now forbids
new native tasks/effects without assuming old native tasks are absent. No exact
BP null-receiver-warning parity is claimed.

Pressed Network02 then passes 48 owner trials, 24 foreign-owner observations
per client, unchanged native grants and inactive LocalOnly authority. All
strict logs, independent report gates, 1,469 frozen inputs and three actual
server-last zero exits pass; policy scopes close 0/0 + 48/48 + 48/48. Pending
completion/stale callback disarming is an intentional safety improvement, not
exact original stale-reference parity. Inventory/Map Widget BP business is
still untouched for later UI batches; no UI replication, physical-input,
pixel/text, filter-token, packet-loss, travel/rejoin or packaged-runtime claim.
These remain two bounded local batches, not whole-version acceptance or a
release. No Engine build/cook/package or official-source modification.

AutoRespawn now has a separately accepted three-helper pilot: Python implements
GetOwningPlayerState, Is Avatar Dead or Dying and EndDeathAbilities. Its retained
BP identity/full CDO, twelve signatures and complete original business graphs
are preserved, with no business transport added. The existing named-output
binding handles the original non-reference IsDeadOrDying out pin. Final
`20261016-auto-respawn-helpers/Differential06` passes four BP/Python pairs,
eight actual lethal GAS deaths/restarts, native five-second delay, pause and
mid-death Profile switch. Network05 passes twelve authority/owning trials and
six independent foreign-owner observations per client, exact persistent
AutoRespawn/Death handles and native equipment class multiplicities. Both runs
pass strict logs, independent semantic gates, normal exits and 1,479 frozen
inputs; the network server exits after actual client exits.

The original K2_HasAuthority checks activation mode, not Pawn role. The native
inactive client ability retains default Authority mode 0, so original BP and
Python both call EndDeathAbilities once there. Three measured snapshots per
trial verify that behavior alongside actual roles 3/2/2 and GameMode presence
true/false/false. Clients apply no damage or ability activation; native restart
remains on the server. Network04's incorrect client-helper-zero gate and all
earlier failed attempts remain retained, without being relabeled as passes.
Original avatar/death/EndPlay listeners, activation, reset messages, UI,
latent delays and restart business are still BP. Next migrate listener bind/
clear orchestration, then the remaining event/delay/restart business in
separate verified batches. Whole AutoRespawn, 0.10 and 0.11 remain open.

The next accepted listener batch moves BindDeathListener/ClearDeathListener
orchestration to Python and explicitly reuses the three helper function objects
in each Profile's local dictionary. Differential01 correctly fails when plain
inheritance left those helpers unregistered by the current collector; its
normal exit is not counted as acceptance. No C++ change or rebuild is needed.
Four exact named native delegate transports (16 nodes) preserve foreign
subscribers and the original cached-Avatar rule, full CDO/twelve signatures/
business graphs. Final `20261017-auto-respawn-listeners/Differential02` passes
four pairs/eight actual deaths and restarts, repeated/cross-Profile clear and
binding, pause and mid-death handoff. Independent native Death/EndPlay callbacks
each fire once, fixture scopes close 8/8 and original native events traverse
Python after explicit-probe counters are snapshotted. Network01 passes twelve
authority and owner rows, six foreign-owner observations per client, fixture
scopes 12/12 + 6/6 + 6/6, strict logs/independent gates/restore and actual
server-last zero exits. Both final runs freeze 1,489 inputs. Production policy
owns no Python delegate callback, scope, timer or ability lifetime. Activation,
reset/UI, death/avatar event decisions and delay/restart/completion business
remain the next implementation work; these five methods do not complete the
whole asset or release.

AutoRespawn death/Avatar/restart decisions now have bounded native acceptance
in `20261017-auto-respawn-events`: seven original methods plus two new
continuation gates route to Python. Assets01 keeps class/full CDO/twelve
signatures and original business digests around four declared continuation
endpoints. It reuses the original five-second and 0.1-second Delay nodes,
adding two entries/four dispatch/four gate-body nodes and retaining the sixteen
exact-listener transport nodes. Final Differential02 passes four real death
pairs plus an original/Python live-Pawn K2_DestroyActor pair. Real duration and
completion payloads, native restart/RPC calls, pause, mid-delay Profile switch
and independent Death/EndPlay delivery pass; both fixture scope ledgers close
10/10. Differential01 is retained as failed: bare destruction loses the same
three pistol grants in both original BP and Python. The probe now separately
records/compares that raw native behavior, then restores equipment using native
QuickBar empty/original slot RPCs and requires original QuickBar slot item identities,
logical classes and persistent handles. Production behavior is unchanged.

Network01 passes twelve authority/owner trials and six independent foreign
reliable-completion payload observations per client. Dedicated server has no
local cosmetic completion; clients have no GameMode restart path. Native
listener scopes close 12/12 + 6/6 + 6/6; message scopes close 12/12 on all three
peers. Both final runs pass strict logs, independent gates, restoration,
1,499 frozen inputs and normal exits, server last in networking. Forced
Avatar destruction is standalone-only here; pending Reset/removal cancellation,
travel/rejoin, physical input, loss and packages are not certified. The remaining
AutoRespawn activation, Reset subscription/filter, UI registration and end/
removal business is next; whole asset and versions remain open.

The next bounded AutoRespawn batch now moves that remaining entry/reset/UI/
lifetime business to `auto_respawn_activation_mixin.py`: twelve original methods
have script business through eleven original entries and a retained-parent End
gate (sixteen routed functions total). It keeps the original typed native Reset
listener, both latent nodes, delegates, GameMode restart and reliable GameState
RPC. Explicit Python/BP startup variants pass natural grants/Added/AvatarSet/
OnSpawn, four death pairs, a real Avatar-destroy pair and the twelve-trial
two-owner natural regression. Native End/observe-original-deadline/Clear/Give
passes three pairs with exact resource cleanup and explicitly new grant handles.
Native End removes latent actions; the fixture does not replay cancelled
callbacks or root garbage-marked GAS instances.

`20261017-auto-respawn-activation/ResetDifferential02` passes four real native
Reset pairs, including repeat, pending death and mid-pending Profile switch.
`ResetNetwork02` passes sixteen authority/owner trials and sixteen passive
foreign-client observations, 16/16 scope closure per peer, typed exact owners,
foreign authority filtering and server-last three normal exits. A stage-only
four-node VM reader independently observes Reset; the production message
adapter is unchanged. The foreign client receives completion through native
reliable RPC, not a replicated Reset router payload. UI validity preserves the
measured role baseline: false/false on dedicated server, true/true on owning
clients. Final Reset runs freeze 1,525 inputs. Lifecycle03 freezes 1,513.
Earlier failed fixture/driver runs remain failed and preserved. End/removal's
explicit listener/UI cancellation is an intentional lifetime improvement in
both Profiles, not a claim about unmodified BP stale-callback behavior.

This batch receives ledger 38 and isolated-index verification; full host models
pass 1,096. Original runtime business is now script-owned, but whole-asset/
version acceptance stays open: active Clear without a preceding explicit End,
travel/rejoin, loss, physical input and packages are not certified. Native
warnings remain. No Engine/official project changes, C++ build or cook/package.

The next Character batch migrates only `B_Hero_ShooterMannequin.ClearInventory`
to `uep_lyra_characters/inventory_clear_mixin.py`. Native C++ death/Reset enters
the unchanged original BP events, then invokes the same retained helper type.
Python preserves authority, the QuickBar-valid guard, every slot before copied
item-list removal, and native QuickBar/inventory operations and replication.
Only two Mixin Interface declarations are added; complete original graphs,
full CDO and six public signatures stay unchanged. Controller/missing-inventory
handling is intentionally safe, not original null-warning parity.

`20261017-character-inventory/Differential02` passes four death pairs and a bare
Avatar pair, independently observing an empty inventory before replacement
Pawn and native item re-creation. `Network02` passes twelve authority/owner
trials and twelve passive foreign observations: no client removals, legal
client callback roles 1/2 rather than an assumed fixed role 2, unchanged foreign
inventory and native replicated item-definition restore. Inventory observers
close 10/10 standalone and 12/12 + 6/6 + 6/6 networking. `Reset01` passes eight
existing native Reset requests through the original Character BP with 8/8
inventory observer closure. All strict logs, independent gates and normal exits
pass; network server exits last. Frozen inputs are 1,540 / 1,544 / 1,551.

This reveals a qualification in the older bare-Avatar proof: original slot
identities/specs were checked, not every InventoryManager entry. Both BP and
Python bypass ClearInventory on direct destruction, and native initial grants
add one new un-slotted pistol. The new probe records that raw delta and removes
only the new orphan using the native API before requiring exact original
item/slot identities. It does not change production behavior or relabel the
earlier failed runs as passes. Ledger 39 records this bounded helper batch;
all 1,134 host models pass. Other Character business, native multi-item/
nullable-controller/Character-Profile-switch probes, Reset networking for this
Character change, travel/rejoin, physical input, packages and whole-version
acceptance remain open. ABPs/animation and Engine/official projects stay intact.

The next bounded Character helper batch adds Get/SetEmoteAudioComponent in
`uep_lyra_characters/emote_audio_mixin.py`, explicitly retaining the accepted
ClearInventory alias. Original Character type, complete graphs/full CDO/eight
signatures and ANS_EmoteSound animation-notify bytes stay unchanged. A stage-only
second BP sends actual typed Interface messages; Python getter returns the
named AudioComponent object out pin, setter only updates the original field.
Software02 passes twelve original/Python/cross-Profile nullable/object/repeat/
replace round trips, two same-class mixed-instance cases, native GC with held
references, non-interface defaults and actual component destruction/restoration.
Network01 passes the same local software matrix in server/two-client native
worlds (36 round trips), owner/foreign roles and server-last three zero exits.
Strict logs/independent gates pass with 1,562 frozen inputs in each final lane;
all 1,162 host models pass. Ledger 40 records this helper-only scope, not actual
animation-notify production, audio playback/hardware or replicated references.
Remaining Character business, travel/rejoin/packages and full-version gates
remain open. No Engine/official project changes or C++ build/cook/package.

The next retained Character method, ChangeQuickbarSlot, is now script-owned in
`uep_lyra_characters/quickbar_input_mixin.py`; accepted three helpers are explicit
local aliases. Original occupied-slot condition, supplied GameplayTag and
double slot-index magnitude remain; no payload object fields are invented.
Assets01 preserves original type/full CDO/nine signatures/all complete graphs;
a stage-only second BP invokes the original method on a typed Actor reference.
Differential01 passes six original/Python pairs plus two Python-only invalid-
index safety cases. Native GAS observers verify exact payloads; native equipment
matches independently expected item definitions. Network01 passes 28 owning-
client calls/28 authority equipment results through the original QuickBar Server
RPC, exact foreign-owner isolation and server-last three normal exits. Local
GameplayEvents are not claimed as replicated. Each owner closes fourteen native
observer tasks/scopes while the original three Quickslot tasks remain active;
original inventory identities/field/Profile/CDO restore. Strict logs and gates
pass with 1,568 standalone/1,572 network frozen inputs; 1,192 host models pass.
Ledger 41 is this bounded helper revision. Safe missing Controller/QuickBar and
invalid-index handling intentionally differs from BP receiver/array warnings;
only invalid-index safety has native probes. Physical keyboard, nullable native
probes, travel/loss/packages and remaining Character business stay open.

AddInitialInventory is the fifth retained Character helper, implemented in
`uep_lyra_characters/initial_inventory_mixin.py` with four accepted local aliases.
Authority/Controller/InventoryManager guards, original ordered native grant
(stack one)/slot attempts and final nonempty slot-zero activation remain. It
preserves the original native unslotted extras for occupied/overflow slots.
Missing QuickBar is intentionally safe; native null-receiver parity is unclaimed.
Assets01 keeps original type/full CDO/nine signatures/all graphs and adds only a
stage-only typed BP caller. Differential01 passes six original/Python config
pairs and a natural first-Pawn Python grant. Natural02 passes four death pairs/
two Avatar cases, ten actual new-Pawn Python grants and the original clear/
empty-before-respawn regression, 10/10 observers. Network02 passes 24 authority
grants/owner replica observations plus 24 real client BP no-op calls, native
FastArray/QuickBar replication and foreign-owner isolation. Both clients have
zero natural startup helper entries; no natural client execution is invented.
Original item/slot identities and config/Profile/CDO restore, not old equipment
instance identities. Client observer scopes close 1/1 each; restored native state
is frozen before one-way release and only POD exits are read after disconnect.
All strict closed logs/independent gates and server-last three zero exits pass.
Frozen inputs are 1,584 manual/1,588 natural/network; 1,236 host models pass.
Ledger 42 excludes failed Natural01 (premature wrapper error marker) and
Network01 (post-release native-owner reread); fixes have executable regressions
and complete fresh reruns. Remaining Character business, nullable native probes,
hardware/travel/loss/packages and whole-version acceptance remain open.

CreateOrUpdateOutlineIfNeeded is the sixth retained Character helper in
`uep_lyra_characters/outline_mixin.py`, with five accepted explicit aliases.
Original local-control/create-if-missing/attach-once/scalar-then-vector decisions
remain; existing detached MIDs stay detached and repeats reuse the same object.
Native material, camera TScriptInterface, rendering and GC remain unchanged.
Assets01 preserves type/full CDO/ten signatures/all graphs. Software03 passes
eight real BP/Python pairs, full camera-setting/field/Profile/CDO/inventory undo,
signed/HDR parameters, true unpossessed Actor and held-reference native GC.
Natural startup enters Python three times, creates/adds one MID/blendable and
updates three scalar/vector pairs. Network01 passes 48 case trials/54 BP calls
in actual server/two-client worlds: own-player server nonlocal no-op, both client
owners local create/update, all unpossessed fixtures nonlocal. Natural Python
startup is observed twice per world, with zero/one/one material creations.
All fixture material and caller-class roots balance; production roots nothing.
Cleanup freezes before release and three zero exits finish server last. Strict
closed logs/independent gates pass with 1,600 final standalone/1,602 network
inputs; original/staged parent material hashes match. All 1,270 models pass.
Ledger 43 excludes failed Software01 (unowned test-caller class collected by GC)
and records complete fresh reruns after explicit test-class lifetime ownership.
No rendered-pixel/material-replication/all-transient-MID-reclamation or full
Character/version claim. Remaining team/cosmetic orchestration and other business,
hardware/travel/loss/packages remain open; animations/ABPs remain untouched.

OnTeamOrCosmeticsChanged is the seventh retained Character helper in
`uep_lyra_characters/team_cosmetics_mixin.py`, with six accepted explicit aliases.
Its two function arguments and original color/outline/stencil -> optional native
display application -> platform/device Sequence remain. Inherited parent stencil
business is still BP. Assets01 preserves class/full CDO/eleven signatures/every
graph. Final Differential03 passes eight BP/Python pairs/twenty real BP calls,
actual material/stencil state, three natural Python startup callbacks and sixteen
naturally evaluated/removed device properties. Network02 passes 48 trials/60 BP
calls in actual server/two-client worlds, with two natural callbacks per world.
The Engine deliberately has no device subsystem on the dedicated server; zero
activation there, sixteen actual scheduled properties per client. Native disabled
color marker handles bracket synchronous calls for bounded read-only public
handle queries; only handle POD copies change, never native allocation/sets or
production handles. Markers finish naturally, roots balance 0/0 + 48/48 + 48/48,
and full visual/camera/Profile/CDO/inventory state restores before release.
Strict closed logs, independent gates, 1,618 inputs per final run and server-last
three zero exits pass. Ledger 44 preserves failed Differential01 (unhashable
native-set observation) and Network01 (fixture assumed a server device subsystem)
as failures; both fixture fixes have executable regressions and fresh runs.
All 1,307 isolated-index models and 558-file all-index syntax/import checks pass. No
hardware/pixels, replicated team changes/material state, travel/loss/packages,
whole Character or release claim. Remaining runtime BP business continues in
independently implemented, verified and locally committed batches.

UpdateCustomStencilFromTeamID adds the eighth retained Character helper in
`uep_lyra_characters/stencil_mixin.py`, explicitly aliasing seven prior helpers.
It shadows this inherited method only on the retained Shooter Character; the
original parent asset/function and other subclass families remain unchanged.
Local AND player control selects zero; otherwise TeamId reaches the native
setter unchanged. Native recursive primitive discovery and 0..255 clamping/
render-state behavior remain. Assets01 preserves class/full CDO/twelve signatures/
all graphs. Final Differential02 has eight team plus twelve direct BP/Python
pairs (40 trials/52 BP calls), true ChildActor/extra primitive, native negative/
overflow clamps, unchanged render-depth enable flags, repeats and 24 actual GC
calls. Both original and Python nested team-to-stencil dispatch counts are exact.
Natural Python startup has three calls/queries and sixteen component writes.
Network01 has 120 trials/156 BP calls/72 actual GC calls in three actual worlds;
natural stencil enters twice/world. Native role/control/device-subsystem
differences, nonreplicated parent/child fixture destruction, two caller-class
root scopes/world and full visual/camera/Profile/CDO/inventory restore pass.
Strict independent gates/closed logs, 1,636 inputs/final run and server-last
three zero exits pass. All 1,336 isolated-index models and 567-file all-index
syntax/local-import checks pass. Ledger 45 excludes the earlier-gate Differential01 pass from final
standalone proof. No pixels/stencil/team/material replication, hardware/travel/
loss/package, whole Character/parent-family/version or publication claim.

K2_OnDeathFinished and K2_OnReset add two retained Character event bodies in
`uep_lyra_characters/lifecycle_mixin.py`, explicitly aliasing eight prior methods
(ten routed methods total). Original native CPP events still trigger them;
Python forwards once to selected ClearInventory, fallback invokes only its saved
BP event. Native authority/GAS/destruction/respawn/replication remain. Assets01
preserves type/full CDO/twelve signatures/every original graph. Natural01 passes
four real death pairs plus two bare Avatar trials, exact event/helper counts,
independent empty inventory windows and restored definitions with new native
item identities. Bare Avatar still has the original unslotted-pistol delta;
only that newly observed orphan receives fixture-only native cleanup. Reset01
passes eight actual existing Reset requests and exact Reset-not-death entry.
Network01 passes twelve authority/twelve owner event trials and twelve passive
foreign observations: real owner replication, zero client removals, actual
callback role 1 (legal non-authority roles 1/2), unchanged foreign inventory AND
event POD. Inventory scopes close 10/10,
8/8, 12/12 + 6/6 + 6/6; old Actor evidence needs only its retained dict, never
Actor/GAS roots or dead-wrapper reads. Private selectors prevent imported legacy
fixtures from starting a second lane. Strict closed logs/independent gates,
1,648 / 1,652 / 1,648 frozen inputs and server-last three zero exits pass.
All 1,363 isolated-index models and 575-file all-index syntax/import checks pass. Ledger
46 has four passed runs/thirteen matched scoped inputs. Remaining component
callbacks/team listener/init/input/health business and parent/sibling families,
physical input/hardware/travel/loss/packages and whole-version gates remain open.

The original PawnCosmeticsComponent OnCharacterPartsChanged bound receiver adds
the eleventh retained Character method in
`uep_lyra_characters/parts_changed_mixin.py`, with ten explicit aliases. Native
FindTeamFromObject(Self,false) controls the virtual team-helper call; component
payload remains unused, matching BP. Assets01 preserves type/full CDO/thirteen
signatures/every graph and actually registers eleven functions on both Profiles,
then unregisters/restores signatures. Final Differential03 has six native part
cycles/eighteen Add/Remove/repeated-remove operations/twelve independent delegates,
unassigned-team noop and add/remove Profile switch, genuine temporary part Actor
lifetimes, original entry/Actor/visual/camera/Profile/CDO/inventory restore,
one closed scope/two bindings and 44/44 device roots. Natural startup enters
Python once. Network02 has eighteen actual authority operations/thirty-six
client Actor observations/twenty-four independent delegates via native FastArray
replication. Two same-type Pawns use opposing then swapped Profiles. Headless
authority correctly spawns no render parts/broadcasts zero such callbacks;
clients observe local role2 and foreign role1 and actual one-shot device objects
inside the native multicast before later tick expiry. Each client has twelve
delegates, six production properties and 36/36 roots. Native original parts,
Actor identities/visual/Profile/CDO/inventory, observer scopes and server-last
three zero exits restore. Strict independent gates/closed logs pass with 1,665
inputs/final run. Ledger 47 keeps Network01 failed (fixture validity import),
adds executable cleanup/cached-POD regression and fresh full rerun; earlier
Differential01/02 are not final standalone proof. All 1,399 isolated-index models
and 584-file all-index syntax/local-import closure pass. No callback replay/property-array rewrite,
file-delivered gameplay state, pixels/hardware/travel/loss/package/whole-version
claim. Team listener/health/init/input and parent/sibling business remain open.

The original HealthComponent OnHealthChanged receiver adds the twelfth retained
Character method in `uep_lyra_characters/health_changed_mixin.py`; eleven prior
methods are explicit aliases. Native authority/PlayerState/self/AI Controller
guards and raw Old-New, zero HitLocation/default Tag remain. Assets01 preserves
type/full CDO/fourteen signatures/every graph and actually registers twelve
methods on both Profiles. Differential04 has ten actual GAS primary trials,
twenty-two native primary/prime/restore health delegates and four true AI Damage
stimuli with matching native perception memory, including original negative
healing strength. Network01 has fourteen authority primary trials/twenty-eight
client primary observations, thirty native Health delegates/world and 4/0/0
authority/client Damage stimuli. Local role2/foreign role1, native null replica
instigators, opposing/swapped Profiles, original health/inventory/Profile/CDO,
one scope per world and 3 / 4,3,3 closed bindings PASS. A separate unregistered
test-owned bot producer calls native SpawnOneBot, so normal native team assignment
and real opposing sources obey damage rules; the original bot list is unchanged,
and owned Pawn/Controller/PlayerState/producer are destroyed. Three server-last
zero exits, strict closed logs, independent gates and 1,684 frozen inputs/final
run PASS. Differential01/02/03 remain failed fixture history (unreflected name
setter, unassigned-team spawn/negative Damage restore/Controller BP destroy noop,
then team-rejected source). Fixes have executable regression models; all 1,451
isolated-index models and 593-file all-index syntax/import closure PASS. Ledger
48 has exactly three accepted native runs and thirteen matched scoped inputs. Valid
non-PlayerState/missing-Pawn edges are host-only; no health property/delegate
replay or fixture-injected AI report, physical input/pixels/travel/loss/package/
whole-Character/version claim. Team listener/init/input and parent/sibling
business remain open.

Five original QuickSlot EnhancedInput receivers add seventeen retained Character
routes in `uep_lyra_characters/enhanced_input_mixin.py`, with twelve explicit
accepted aliases. Assets04 preserves type/full CDO/nineteen logical signatures/
every graph and five action/Triggered binding semantics. UE recompilation really
renumbers generated receiver symbols; callable descriptors resolve current
native names at every registration rather than hardcoding a compiler suffix.
Python implements seventeen functions, BlueprintFallback twelve: existing native
Original dispatch preserves the full input frame. Manual Python bool/vector ->
FInputActionValue roundtrip is still unsupported, not claimed fixed by a C++ build.
Differential02 PASSes sixteen actual input injections/eight BP-Python pairs,
twelve native GAS events and exact equipment. Five actions, repeated selection,
empty selection/default-zero-cycle noop and original zero event magnitude match;
sixteen scopes/tasks and original item/slot/Profile/CDO restore. Network01 has
two native input owners/sixteen trials each/thirty-two authority RPC-equipment
comparisons/twenty-four owner GAS events. Actual Client role2, unchanged foreign
Actor input/helper/Profile, unchanged other authority inventory and zero server
Character input/helper calls PASS. Cleanup freezes before release, server exits
last with three zero exits; strict closed logs/independent gates and 1,710 frozen
inputs/final run PASS. Ledger 49 has exactly three accepted native runs/thirteen
matched scoped inputs; all 1,495 isolated-index models and 602-file all-index
syntax/import closure PASS. Keep Assets01/02 and Differential01 failed, Assets03 as
earlier prototype proof only. No direct input-receiver calls, mapping changes,
physical keyboard/hardware/pixels/travel/loss/package/whole-version claim.
Team listener/init/possession readiness and parent/sibling business remain open.

The generated ObserveTeamColors result receiver adds the eighteenth Character
route in `uep_lyra_characters/team_observer_mixin.py`; the seventeen accepted
aliases preserve callable input descriptors. Assets01 preserves original type/
full CDO/every graph/twenty-one logical signatures, Python18/BlueprintFallback13.
Final Differential03 PASSes six BP/Python comparisons/eight actual native observer
activations, assigned/unassigned initial results and repeated factory calls,
six actual device properties, exact restoration and zero owned observers after
deferred engine GC. Differential01's same-tick collection gate remains failed;
Differential02 investigated deferred GC, not final stricter acceptance. Native
BP-frame retention was not observed. Network01 PASSes twelve native callbacks
per world/thirty-six total, actual DedicatedServer/Client/Client, role3/local2/
foreign1, opposite/swapped Profiles and six actual device properties per client,
zero on server/foreign Actors. Original proxies remain, owned proxies all collect,
roots balance 22/22 standalone and 0/0+30/30+30/30 network, cleanup freezes before
release and server-last three zero exits PASS. Strict closed logs, independent
gates and 1,728 frozen inputs/final run PASS. Ledger50 has three accepted runs
and fourteen matched scoped inputs; all 1,546 isolated-index models and 612-file
all-index syntax/import closure PASS. This
is initial observer activation, not real replicated team changes, listener
factory migration, all future display callbacks after Cancel, hardware/pixels/
travel/loss/package/full Character/version acceptance. Next migrate only the
ListenForTeam factory/bind/activation decisions with exact native delegate
transport, no retained Python callback or invented repeated-call cancellation.

ListenForTeam now adds the nineteenth retained route in
`uep_lyra_characters/team_listener_mixin.py`, aliasing eighteen accepted methods.
One four-node exact native named multicast transport owns only binding; factory/
bind/activate decisions are Python, no closure/proxy root/deduplication/added
cancellation. Assets01/02 remain failed authoring evidence: assigning a borrowed
MemberReference view onto itself loses the member owner. A separate struct value
fixes the typed connection without bypassing schema or modifying C++.
Assets03 preserves original type/full CDO/all graphs/twenty-one logical signatures
and actually registers Python19/BlueprintFallback14. Differential01 PASSes six
comparisons/eight real native creations and callbacks, assigned/unassigned and
repeated calls, six native device properties and zero owned observers after GC.
Natural BeginPlay enters Python creation on both fixture Actors. Network01 PASSes
both Pawn identities' natural Python creation in all three actual worlds,
thirty-six test callbacks, six local properties/client with zero foreign/server
output and zero owned observers after GC. Exact original state/live proxy sets,
roots22/22 standalone and 0/0+30/30+30/30 network, frozen cleanup/server-last three
zero exits, strict closed logs, independent gates and 1,742 frozen inputs/final
run PASS. All 1,577 host models PASS. Real team-change replication, post-Cancel
display updates and remaining initialization/possession/legacy OnRep/parent/
sibling/version acceptance are still open; no Engine/official Lyra/animation
changes, C++ build/cook/package or publication claim. Ledger51 lists three
accepted native runs and nineteen matched scoped sources/assets; all 1,577
isolated-index models and 622-file all-index syntax/import closure PASS.

Legacy OnRep_PlayerInfo adds the twentieth Character route in
`uep_lyra_characters/legacy_player_info_mixin.py`. Preserve its exact literal
OnTeamOrCosmeticsChanged(0, null), not an invented current-team query. Nineteen
raw Python aliases/fourteen fallback aliases preserve descriptors. Assets01
PASSes Python20/BlueprintFallback15, twenty-two original logical signatures,
type/full CDO/every graph and literal defaults, with no new business nodes.
The current class has no property named PlayerInfo; this is a legacy helper
contract, not real replicated notification delivery. Differential01 PASSes
six comparisons/eight manual typed second-BP calls, actual zero/null native
outline/software results, six device properties, unchanged native teams/live
observers and original restoration/owned bare Actor-startup observer GC.
Network01 PASSes thirty-six typed calls across three actual worlds, opposing/
swapped Profiles, role3/local2/foreign1 and six local properties/client, zero
foreign/server output. Roots22/22 standalone and 0/0+30/30+30/30 network, zero
owned proxy retention, frozen cleanup/server-last three zero exits, strict
closed logs/independent gates and 1,757 frozen inputs/final run PASS. All 1,606
host models PASS; Host01's incorrect unassigned noop fixture remains failed.
Reports explicitly disclose manual helper replay and no actual RepNotify or
team-change replication certification. Next migrate only ExperienceReady's
generated inventory-readiness continuation; keep BeginPlay/possession/visibility
init-state, parent/sibling/full-version gates open. No C++ build/cook/package,
Engine/official Lyra/animation changes or publication claim. Ledger52 has three
accepted native runs and fifteen matched scoped sources/assets; all 1,606
isolated-index models and 632-file all-index syntax/import closure PASS.

ExperienceReady's generated OnReady continuation adds the twenty-first Character
route in `uep_lyra_characters/inventory_ready_mixin.py`. Only the immediately-ready
Controller -> InventoryManager -> Quickbar path becomes Python; missing components
still enter the original three-delay BP macro. Native grants/authority remain.
Assets03 preserves original type/full CDO/every graph/twenty-three signatures,
Python21/BlueprintFallback16. A four-node exact named delegate transport and
five-node stage-only actual Experience factory producer never directly replay
the callback. Preload dependent probes against the original and perform temporary
router verification after compiler work; Assets01/02 remain failed. Differential01
fails a runtime fixture syntax error before validation; Host now parses actual
working-tree runtime/tools/tests. Final Differential02 PASSes six inventory pairs/
twelve real delayed native signals, two missing-controller original-wait controls,
distinct items/overflow/occupied slots and exact native identity/configuration/
Profile/CDO restoration. No early/late grant around owned Actor destruction and
fourteen collected Experience proxies/caller root1/1 PASS. Network01's async
recapture overwrites measured grants after undo and remains failed; freeze that
capture in restore phase and add an AST regression. Network02 PASSes 24 authority/
24 owner replica-noop trials with actual FastArray/Quickbar replication, natural
authority Experience delivery/zero invented client startup and foreign inventory
isolation. All owned proxies24/12/12 collect, caller roots1/1 per world, inventory
observer scopes close, original state restores and cleanup freezes before
server-last three zero exits. Strict closed logs/independent gates and 1,776
frozen inputs/final run PASS. Network-only fixture repair is executed in Network02;
unchanged standalone production/fixture proof stays Differential02. All 1,640 host
models PASS. Full deferred waits/factory/initialization/Character/version,
hardware/pixels/travel/loss/package gates remain open; no Engine/official Lyra/
animation changes, C++ build or publication claim. Ledger53 contains three
accepted native runs/seventeen matched scoped sources/assets; all 1,640
isolated-index models and 643-file all-index syntax/import closure PASS.

Batch54 replaces the three Controller/InventoryManager/Quickbar pending
decisions in `uep_lyra_characters/inventory_wait_mixin.py`. Scheduling stays
native DelayUntilNextTick, with three stable per-Actor UUIDs and an empty
two-node int32 resume declaration; no Python wait ticker/callback root or global
latent cancellation. Do not promise a whole engine-frame delay: preserve the
actual native next-tick backend. Assets01 preserves original type/full CDO/all
graphs/twenty-three logical signatures, Python22/fallback17. Differential04
PASSes six immediate inventory pairs, two destroyed-wait controls and six late
readiness/single/repeated-request BP/Python pairs. Actual possession adds a
second independent ready signal; native coalescing and the two grants match BP.
All32 owned Experience proxies and Character-owned observers collect, root1/1.
Failed Differential01-03 remain failed: broad observer ownership included an
original pooled GCNL_Spawning handle; the diagnostic reference search itself
also emitted an Engine ensure. Final tests identify the exact native Cue handle
and owned target separately, recording one inactive/unrooted pooled observer
per row with unchanged fields and hidden/ownerless Cue, not pretending it was
collected or mutating the pool. Network01 PASSes24 authority/24 replica-noop
trials, actual inventory replication, owner isolation and restored native state;
proxies24/12/12 collect, roots1/1 each world. Strict closed logs, independent
gates, server-last three zero exits and1,796 frozen inputs/final run PASS.
All1,702 host/isolated-index models and653-file all-index checks pass. Ledger54
is bounded: factory creation/ReceivePossessed is next, initialization and
parent/sibling/full-version gates remain open. No native pending-Profile-switch
or deferred-component replication, hardware/pixels/travel/loss/package claim;
no Engine/official Lyra/animation changes or C++ build/cook/package/publication.

Batch55 routes ReceivePossessed through
`uep_lyra_characters/possessed_mixin.py`: Actor authority -> native Experience
factory(Self) -> existing exact named delegate transport -> activation.
NewController remains an unused business input (its actual identity is recorded),
with no added parent event, duplicate original execution or Python callback root.
Assets03 PASSes Python23/fallback18 and original type/full CDO/all graphs/
twenty-three signatures; actual ActorMacros:Switch Has Authority semantics and
source asset are frozen. Assets01/02 fail guessed macro-name/library guards and
remain failed. Differential01 fails overcounting the original AI Controller BP's
independent Experience bootstrap; classify exact native identities separately,
capture paths while live, close constructor failures and require all tasks to
collect. Differential02 PASSes24 actual owned Pawn possessions/Character tasks,
12 separate original Controller-BP bootstrap tasks, all32 typed Experience
requests and the complete prior wait/inventory regression. The natural main
player executes exactly one Python factory chain. Network01 PASSes24 authority/
24 owner replica-noop trials, each server player's one natural Python factory
and zero invented client possession callbacks, inventory identity/replication/
undo, proxy cleanup24/12/12 and roots1/1 per world. Strict closed logs, independent
gates, server-last three zero exits and1,817 frozen inputs/final run PASS.
All1,741 host/isolated-index models and662-file all-index checks pass. Ledger55
is bounded; InitState's delayed visibility is next, then BeginPlay orchestration
and parent/sibling coverage. No full Character/version, deferred-component
replication, pending Profile-switch, hardware/pixels/travel/loss/package claim;
no Engine/official Lyra/animation changes or C++ build/cook/package/publication.

Batch56 moves ShowPawnAgainNextFrame's native InitState callback/delayed-show
business to `uep_lyra_characters/visibility_mixin.py`. GameplayReady registration
still starts in original BeginPlay; scheduling remains native DelayUntilNextTick
with named int32 resumption, no Python wait ticker/root. An Actor-local latent
site allocator guarantees disjoint stable Python inventory/visibility keys.
Assets01 PASSes Python25/fallback20, original type/full CDO/all graphs/twenty-four
signatures, an empty two-node continuation declaration and four-node exact
native InitState registration transport. Differential01 PASSes actual native
callback payload identity, six late-readiness visibility pairs and four pairs
of single/repeated/immediate-destroy/both-direction pending Profile-switch
trials, without manually replaying the callback. Original and Python hidden
flags agree before/after native ticks; pending destruction remains quiet and
prior possession/inventory/resource/pool gates stay strict. Natural startup
records received/delay while hidden at6438, native resume/show at6439; preserve
the actual backend, not a universal whole-frame-delay promise. Network01 PASSes
one natural callback/delay/resume/show on both authority and both owning-client
Pawns,24 authority/24 replica-noop inventory trials, exact original state and
proxies24/12/12 collected, roots1/1 each world. Strict closed logs, independent
gates, server-last three zero exits and1,838 frozen inputs/final run PASS.
All1,788 host/isolated-index models and673-file all-index checks pass; ledger56
is bounded. ReceiveBeginPlay orchestration is next, then ancestor/sibling and
whole-version gates. No network repeat/destroy/Profile-switch visibility,
physical pixels, hardware/travel/loss/package/full-version claim; no Engine /
official Lyra/animation changes or C++ build/cook/package/publication.

Batch57 migrates ReceiveBeginPlay orchestration in
`uep_lyra_characters/begin_play_mixin.py`: exact original parent -> ListenForTeam
-> hide -> PawnExt GameplayReady registration (call-immediately true). An empty
two-node static parent-call transport preserves the original ancestor call;
no existing Actor's BeginPlay is replayed. Assets01 PASSes Python26/fallback21,
original type/full CDO/all graphs/twenty-four signatures. Differential01 PASSes
the entire preceding wait/possession/visibility regression plus two new fresh
Actor pending/ready BP/Python pairs. A synchronous disposable test-only ordinary
CDO Profile override selects each fresh baseline; finally restores immediately,
checks again after native GC and never saves that default. Pending Actors stay
hidden without premature InitState delivery; ready native Actors show with
equal native inventory and balanced owned resources. Network01 has no CDO
fixture: both authority and owning-client Pawns naturally enter exactly one
ordered Python BeginPlay, one InitState delayed show,24 authority/24 replica-noop
inventory trials and exact original restoration; proxies24/12/12 collect and
roots1/1 each world. Strict closed logs, independent gates, server-last three
zero exits and1,856 frozen inputs/final run PASS. All1,812 host/isolated-index
models and683-file index closure pass; ledger57 is bounded. Next audit inherited
Hero-default equipment/death business; Character_Default's parent-only
construction and empty BeginPlay are structural forwarding, not invented
business. Animation/ABPs and native physics stay. No whole ancestor/sibling /
version, broader network lifecycle, hardware/pixels/travel/loss/package claim;
no Engine/official Lyra/animation changes or C++ build/cook/package/publication.

Batch58 migrates the inherited HideEquippedWeapons decision loop in
`uep_lyra_characters/equipment_hide_mixin.py`, retaining native equipment
instances/spawned Actors and SetActorHiddenInGame. Original missing-manager
no-op, no additional authority check, original parent bytes/root type/full CDO/
graphs/twenty-five signatures and Python27/fallback22 PASS Assets01. A three-node
second-BP caller remains stage-only. Differential01-04 are preserved failures:
inactive observer collection/global proxy differences exposed constructor-only
AI isolation before the Controller BP's asynchronous ExperienceReady bootstrap.
Shared owned-bot readiness now observes exact native Cue identities while live
and reapplies native AI quarantine; the complete fixture also isolates bots
every tick without Health/immunity writes. Differential05 PASSes all prior
regressions and six new BP/Python pairs: equipped/already-hidden/repeat/empty/
missing-manager/real lethal GAS. Original random native death Delay is awaited
(BP0.567/Python0.542 game seconds), not replayed; real weapon Actors hide.
Three original bot identities/100 Health and every row's complete original
active proxy set remain exact; no Cue-lifecycle exemption is needed in the
accepted run. Native owned resources and caller roots1/1 balance. Network01
PASSes eight local actual weapon-Actor hide/undo calls (server4/A2/B02), exact
visibility/inventory/Profile undo, natural startup/visibility and24 authority/
24 replica-noop inventory regressions. Factory proxies24/12/12 collect and roots
1/1 per world release. Strict closed logs, independent semantic gates, normal
server-last exits and1,873 frozen inputs/final run PASS. All1,865 host/isolated
models and694-file index closure precede ledger58/local commit. Hidden-flag
replication, network death ingress, pixels, Ragdoll/death orchestration, siblings
and whole-version acceptance remain separate. Next migrate Ragdoll's project
call ordering/impulse choice, not native physics or animation. No Engine /
official Lyra/animation changes, C++ build/cook/package or publication.

Batch59 migrates inherited Ragdoll project orchestration in
`uep_lyra_characters/ragdoll_mixin.py`: native collision Profile -> native bone
simulation -> native bVelChange impulse. Original fourteen-node parent graph
dataflow/literals, root type/full CDO/all graphs/twenty-six signatures and
Python28/fallback23 PASS Assets03; the original physics asset remains byte-equal.
Differential01 is a preserved failed immediate-velocity assumption: BP and
Python both queue an impulse, not immediately update the readable velocity.
PhysicsCore source confirms the accumulation. Assets02 preserves an unreflected
getter failure. Assets03 adds a deep-copied stage-only single Pelvis body/no
constraints control. Quantitative moving/zero-strength/repeat cases use only
that owned test mesh, native gravity/damping/known-velocity setup, and observe
after at least two engine frames. Differential02 PASSes all eight direct cases,
both natural-death Profiles and the entire preceding regression. Largest actual
velocity-component error0.0000578486 stays under the unchanged0.02 gate.
Stationary and real death retain the full original rig; its coupled trajectory/
pose is not numerically certified by the single-body control. Owned resources,
original bot identities/Health, strict closed logs, independent gate, exit0 and
1,897 frozen inputs PASS. Network01 is a preserved A-early/B0-still-testing
global-proxy equality failure. Network02 waits for all24 inventory restores and
both hide/undo tokens before a shared start barrier. Six actual local typed BP/
Python Ragdoll calls across server/A/B0, full-rig body state, one owned observer
per Actor collected, quiet destroyed Actors and exact original proxy sets PASS.
Caller roots1/1 each world, eight prior hide/undo calls,24 authority/24 replica
inventory regressions, independent gate/strict closed logs/server-last zero
exits and1,897 frozen inputs PASS. The network-only barrier revision is not a
new standalone re-execution. All1,912 host/isolated-index checks and704-file
closure precede ledger59/local commit. No owner ragdoll/death replication,
physical pixels, full-rig trajectory, Engine/animation implementation, package
or version/release claim. Next migrate the real Health.OnDeathStarted bound
receiver's montage/sense/native random delay and post-delay Ragdoll/Hide/Death
calls. Keep the empty Death endpoint, animations/physics native and broader
ancestor/sibling/version gates separate; no C++ build/cook/package/publication.

Batch60 migrates that actual inherited Health.OnDeathStarted generated receiver
in `uep_lyra_characters/death_started_mixin.py`: native random configured montage,
PlayAnimMontage, native Sight unregister, native random Delay(0.1..0.6), then
virtual Ragdoll/HideEquippedWeapons/empty Death. Assets01 preserves the original
fourteen-node death span, delegate binding, parent bytes/root CDO/all graphs/
twenty-eight signatures and registers Python30/fallback25. Differential04 PASSes
all prior scenarios and ten new lethal-GAS default/single/empty-montage,
destroy-pending and both-direction Profile-switch cases. A read-only actual
Health delegate witness records montage/senses after the original receiver;
the later native HitReact overwriting current montage remains separate evidence.
Actual Sight removal preserves Hearing. Native game-clock/frame delay, no
prefix replay, weak-owner cancellation beyond0.6s and owned resource cleanup
are gated. Preserve failed Differential01(initialization),02(UUID reporting),
03(post-damage montage timing) and Network01(early pending startup snapshot).
Network02 waits only for the outstanding native startup-show action; unchanged
final visibility gates,24 authority/24 replica inventory rows,8 hide/undo and6
local nonreplicated Ragdoll calls PASS. Both final lanes pass strict closed
logs/independent gates/normal zero exits and1,915 frozen inputs. All1,963 host/
isolated-index models and714-file closure precede ledger60/local commit. This
network lane is regression, not real death ingress or physics replication.
Next batch61 verifies actual authority/owner/foreign death and native respawn;
no callback replay, animation/physics implementation change, C++ build, package,
whole-version acceptance or publication is implied.

Batch61 PASSes actual native death ingress rather than the preceding local-body
regression. `death_replication_network_validation.py` composes native lethal GAS /
death OnRep / original respawn with read-only Health signal and post-delay
body/weapon witnesses. Network04 records12 authority,12 owning and12 foreign
dying-replica observations, native roles3/2/1, both owner turns and BP/Python
Profiles, matched native PlayerState identities and unchanged foreign own-owner
inventory/lifecycle. Native montage, random Delay, Ragdoll/hide order/state,
empty/rebuilt inventory and quiet invalid old Actors PASS; the shortest actual
post-destroy quiet window is2.7321385 game seconds. Death scopes12/12/0 in each
process and prior inventory scopes balance. The test explicitly uses13 native
collision-checked relevance teleports before trial baselines/damage; no relevance
property/CDO writes. Read reflected World.AISystem.PerceptionSystem: server has1,
clients0; their original native unregister therefore retains configured Sight.
Independent gate/strict closed logs/server-last three zero exits and1,921 frozen
inputs PASS. All1,992 host/isolated-index models and719-file closure precede
ledger61/local commit. Retain Network01(worldless/unsupported get_world query),
02(A Renderer RDG async-task access violation/exit3),03(foreign replica missing
before damage). Network04 uses unchanged render settings, not an engine fix;
the earlier renderer crash remains an open stability observation for broader
acceptance. No new assets/compile, pose replication, standalone re-execution or
version promotion is claimed. Next start Dash's direction/montage decision helper,
then migrate/accept its actual activation, native task/cancel and RPC orchestration.

Batch62 starts only the retained Dash SelectDirectionalMontage helper. Its42
native BP/Python pairs and three-world/two-owner helper lane PASS, with original
class/full CDO/graphs/signatures, null montages, strict angle boundaries, named
outputs, same-frame native-state invariance and restored Profile/configuration.
An actual inherited-Interface discovery failure exposed a UEP prerequisite:
accept an owned child provider after native compiler Interface conformance, and
support explicit parent/child routers with lexical weak-object invocation
contexts and unwrapped originals. Six private Object BP controls PASS same-name
nested parent/child originals, lifecycle hooks, fallback, both registration and
unregister orders, ordinary sibling exclusion and signature restoration.
This does not change RPC/final-call interception or automatically call originals.
The final reviewed plugin-only build compiles four UEP CPPs and links DLL/LIB in
22.299s, -NoEngineChanges, unchanged checked Engine/official references and BuildId;
earlier ledgers keep their actual older binary provenance. No full Engine build.
Current-DLL actual death/respawn regression PASSes36 native death witnesses;
ADS six and Emote nine standalone pairs, plus ADS and Emote each20-authority-trial/
two-owner network regressions PASS. All2,038 isolated-index models,729-file
syntax/import closure and ledger62's eight passed runs/sixteen matched scoped
files support a local bounded batch commit, not version promotion. Retain failed asset attempts,
the strict-log-failed first selector run and the post-release Controller-read
network failure. Dash activation, navigation/movement decisions, task/cancel and
server RPC body business remain subsequent batches; animation/GAS/movement/RPC
implementation stays native. No full-version, package or publication claim.

Batch63 moves only Direction/Montage stores after native reliable-server
SendInfo ingress. A four-node typed non-RPC gateway skips those two BP stores
after Python, then rejoins original Commit; RPC signature/flags, full CDO and
all other business semantics preserve. Assets01 and42-pair selector regression
PASS. Network02 PASSes eight actual RPC ingresses from two native ASC clients,
including four Python rows that must change BOTH old native fields. Forward/
left original/Python payloads match; owner roles/identity, foreign location/
velocity/Health/spec/config/data/Profile, native montage/RootMotion/end tasks,
cooldown rejection and20-frame quiet windows pass. Eight native collision-checked
pose resets and Pawn movement intent are explicit fixtures, not raw velocity or
input-data writes. Strict independent gates/closed logs/server-last three zero
exits and1,868 frozen inputs pass;2,081 models and735-file closure gate the local
commit. Initial Network01 remains initial evidence only: matching stale fields
could mask a no-op store; the stronger native rerun is final. No new C++ build,
whole Dash activation/task migration, quantitative movement parity, physical/
Enhanced Input, network pause/travel/loss/package or version promotion claim.
Next migrate local direction/navigation and activation decisions, then the
remaining native-task orchestration/Cue/UI business in bounded comparisons.

Batch64 moves the local direction preparation to Python, using native Actor
facing/raw input, camera forward*(1,1,1.2) or the original AI navigation
projection/flatten/Normal. Five transport nodes keep all original graphs,
class/full CDO/four signatures and unused Positive output; a live Direction
getter avoids a skipped impure setter's cached output. Assets01 and42-pair
selector regression PASS. Standalone01 PASSes10 native ASC requests across
original/Python no-input, forward, left, pitched camera and an actually granted
idle bot: zero directions cancel as before, nonzero directions retain native
montage/RootMotion/end/cooldown/20-tick cleanup. Native pitch20 yields scaled
Z0.4104241883. Both actors' Profile/spec/config/control rotation restore;
collision-checked pose resets are declared fixtures. Nonzero/failed AI
projection is model-covered, not claimed as a native off-nav AI run. Final
Network02 PASSes8 two-owner reliable RPCs/local preparations, no remote-authority
local preparation, foreign invariants, native tasks, strict gates/closed logs
and server-last3 zero exits; final runs freeze1,878 inputs.2,132 models and
743-file closure gate the bounded local commit. No C++ build/cook/package or
full Dash/version acceptance. Next move local activation, zero/cancel/Commit/
crouch decisions, then native-task/Cue/UI orchestration. Native GAS, RPC,
animation, navigation and movement implementation remain native.

Batch65 overrides the actual retained-class K2_ActivateAbility event, with no
automatic original fallthrough. Python owns IsLocallyControlled, local
preparation, native near-zero/cancel, Commit/cancel, crouch/UnCrouch and
K2_HasAuthority/unchanged reliable SendInfo order. Remote authority waits for
the original RPC. One non-Net event enters the untouched native task/Cue/UI/
Delay merge; class/full CDO/five signatures/all existing graphs and four-method
Profile registration/restoration preserve. Standalone02 PASSes12 native ASC
activations including actual crouch, control inputs/output parity, selected
event once, tasks/end/cooldown/quiet and exact both-actor restoration. Native
Controller suppresses tiny angle changes; the fixture restores exactly using
public yaw+1/original calls only when needed, without widening its gate.
Standalone01 remains failed restoration evidence, not relabeled acceptance.
Network01 PASSes8 owner/8 remote-authority actual event dispatches and8 original
reliable RPCs across2 owners, no remote local work, foreign invariants, native
task cleanup, independent gates/closed logs and three server-last zero exits;
final runs freeze1,888 inputs. A native GameplayTag property-map invalid-owner
warning repeats an earlier ADSRegression01 warning; cause/stability remains
open, with no warning-free/Engine-fix claim.2,168 models/751-file closure gate
the local commit. Native Commit-failure branch, remaining task/Cue/UI/Delay
business, physical input, quantitative movement and whole-version acceptance
remain open. No C++ build/cook/package/push/tag/release.

Batch66 moves native montage/RootMotion task creation, authority Cue parameters,
typed cooldown UI production, original root-finish/Kismet Delay/script-End
continuation and per-ability delegate cleanup to Python. The native reliable
RPC body also calls native Commit/task start from script without a second BP
body; the original ignored server Commit return is retained. Assets03 preserves
original class/CDO/accepted signatures/graphs except15 declared transport nodes,
12 old dispatch endpoints and zero/false duration/teardown fields. Seven methods
per Profile use a real Dash-owned BP End override and a native teardown guard.
Earlier direct-End routing errors and the unbound override attempt remain
failed evidence. Standalone04 PASSes12 native controls; Network04 PASSes8 real
RPC/owner trials with actual client Cue and local typed UI payloads.
Lifecycle03 PASSes10 native BP/Python root/Delay pause, montage interruption,
native cancellation and active Profile switch controls, measured game-time
boundaries and5/5 scope closure. NetworkLifecycle03 PASSes8 two-owner cancel/
active-Profile interventions after actual authority RPC/task confirmation;
scope balances are server/A/B0=4/4,2/2,2/2, all inactive/error-free. Selector
regression PASSes42 pairs. Independent gates/closed logs/real exits pass;
normal/lifecycle runs freeze1,908 inputs, two-owner lifecycle1,912. Atomic exit
publication repairs a partial-JSON coordination race without hiding malformed
messages. Original/Python native cancellation can interrupt montages on both
worlds; replicated End can cancel the other world's pending Delay, so gates
check actual per-world observations instead of replaying callbacks.2,247 host
models/765-file closure gate the local commit. A pre-existing native GameplayTag
weak-owner warning remains unresolved. No Engine/C++ build/cook/package,
native Commit-failure, quantitative movement/physical input, network pause/
travel/rejoin, full Dash/version or publication acceptance is implied.

Batch67 begins Melee with the original public `Slelect Hit Montage` helper,
preserving its authored spelling, reflected spaced inputs/named montage output,
raw hit normal, native Actor basis/Dot/InRange and four original animation
assets. Inclusive right-dot[-0.5,0.5] and strict sign>0 are retained. Native
MakeVector avoids the legacy wrapper constructor's float narrowing at adjacent
double boundaries. Assets01 preserves class/full CDO/three signatures/all
graphs and24-node helper, registers/restores one method per Profile and adds
only a3-node stage-only typed external BP caller. Differential01 PASSes32 native
pairs using an owned identity Actor and actual player Pawn, no helper gameplay
state mutation, restored Profile/specs/root/control-Actor and quiet checks.
Network01 PASSes32 pairs in each of3 real native worlds/two owners, roles3/2/2,
foreign authority Health/spec invariance, cleanup-before-release and three
server-last zero exits. Both independent gates/strict closed logs pass; native
freezes are1,901/1,903 inputs.2,284 host models/772-file closure gate a bounded
local commit. Melee activation, trace/team/occlusion/damage/tasks/Cue and actual
null-Actor VM behavior are not accepted from this helper. No C++ build/cook/
package/full-version or publication claim; continue the remaining Melee body.

Batch68 moves Melee's actual activation, ignored native Commit return, first
equipment-index/cast/MeleeAttackMontage selection and original native montage
task/Completed/BlendOut/Interrupted/Cancelled lifecycle to Python. Three Profile
methods retain the67 helper; seven native transport nodes add an actual guarded
End override and a non-Net authority-trace entry without changing original
class/CDO/three accepted signatures/graphs. Original native/BP trace, target/
team/occlusion, root motion, damage and Cue business remain behind that entry,
explicitly NOT migrated. Assets01 and8 actual standalone ASC natural/interrupt/
cancel/active-Profile controls PASS using equipped AM_MM_Pistol_Melee,4/4 scopes,
all Pawn Health invariant and exact Profile/spec/config/pose/control restoration.
Network01 PASSes12 owner requests/12 remote authority activations across2 native
owners, actual montage-before-intervention confirmation, natural/cancel/active
Profile cleanup, foreign location/velocity/active/spec/config/Profile/equipment
and all-Pawn Health invariants. Scope balances server/A/B0=6/6,3/3,3/3, inactive/
error-free. Helper regressions PASS32 pairs standalone and32 in each of3 native
worlds. Strict independent gates/closed logs/real server-last exits pass;
standalone inputs1,911, network1,915.2,324 host models/781-file closure gate the
bounded local commit. No C++ build/cook/package, native Commit failure/no-weapon
warning parity, genuine hostile/friendly/occluded trace/damage/Cue, network
pause/travel/rejoin/loss, full Melee/version or publication claim. Continue the
original authority trace/damage body as the next business batch.

Batch69 moves authority capsule/target-ASC/team/occlusion business to Python,
retaining native queries, GAS, root motion and owner Cue. One new authority
dispatch node retains the original BP body only for explicit fallback; original
class/full CDO/six accepted signatures and4/4 methods remain. Differential04
PASSes10 actual standalone ASC requests across miss/no-ASC/friendly/occluded/
hostile BP/Python controls: rejected branches cause zero damage/root/Cue;
hostile causes100 actual Health damage and one native root task/observed owner
Cue each. Native force options/formula, original empty HitResult context and
default Cue fields are preserved. Existing const-array native-output ABI is
adapted using reflected flags, not an Engine/C++ change. Failed attempts01–03
and a read-only ABI diagnostic remain. Current-revision8 activation lifecycle
trials,32 helper pairs and12 two-owner no-damage requests/authority activations
PASS independent gates/closed logs/real exits;1,927 frozen inputs per runtime
lane.2,375 host models and full-index closure gate the bounded local commit.
No two-owner hostile damage, physical input, quantitative movement parity,
networkpause/travel/rejoin/loss, C++ build/cook/package/full-Melee/version or
publication claim. Next batch70 proves actual two-owner authority damage and
replicated observations before moving on to remaining hero/weapon BP business.

Batch70 adds two-owner native authority damage/two-viewer functional comparison,
not a general-stability or release gate. Current final Network08/09 each PASS20
real client requests/authority activations,40 viewer rows and4 actual100-damage
hostile hits across original/Python miss/no-ASC/friendly/occluded/hostile paths.
Native predicting mode2/authority-only trace, root configuration/query-derived
direction, empty hit context, unique replicated Bot names and zero native
immunity at activation are observed. Both clients receive Health; original GAS
local-prediction-key filtering produces exactly0 owner/1 foreign Hit Cue, not
an invented local replay. Stage-only replicated native floor, before/after
original-handler reads once, restored observers/Profile/spec/config/poses,
quiet20 ticks and scopes10/10,5/5,5/5 pass independent gates/strict closed logs/
real server-last exits;1,936 inputs per network run. StandaloneRegression02
PASSes10 controls.2,423 models and793-file closure gate the bounded local commit.
Failed Network05/07 expose an UNRESOLVED readiness discrepancy before friendly
activation: authority/one viewer Health100, another viewer Health0. New native
HealthSet/ASC/canonical-Pawn diagnostics and two repeated successes do not
prove a fix. Continue70b to isolate initialization/replication against original
character behavior; do not widen timeout/write Health or mark the full asset/
version stable. Physical input/PvP avatar turnover/quantitative movement/loss/
travel/rejoin/packages remain open; no Engine/C++ build or publication.

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
- [x] AI task/service outcomes and cancellation are reproducible; long-running
  tasks do not retain a destroyed Pawn or World.
- [ ] Multi-client score/phase state, local notifications and cleanup agree.

## 0.13.0 Frontend settings sessions and replays

Status: planned; UI parent classes and shared functions migrate before children.

Migrate game-owned CommonUI widget logic, frontend, settings, session browsing/
hosting and replay presentation. CommonUI, online/session and replay facilities
remain native. Welcome-map and runtime diagnostic candidates receive explicit
scope/reachability decisions; editor/test utilities remain excluded.

- [x] Navigation, focus/back behavior, settings persistence, session results
  and replay controls pass original-BP/Python comparisons.
- [x] Repeated screen open/close and travel restore subscriptions and state.
- [x] Failures/cancellations are tested, not accepted only on the success path.

## 0.14.0 Explorer TopDownArena and coverage closeout

Status: planned; each additional Experience gets its own acceptance scenarios.

Migrate Explorer interaction/inventory/StateTree BP business and TopDownArena
bombs, pickups, runtime level generation, match components and UI. Runtime map
generation belongs to this scope; editor geometry tools do not. Reconcile the
full initial inventory against actual references and accepted replacements.

- [ ] Both Experiences pass original-BP/Python gameplay, presentation and
  applicable multi-client/local-player comparisons.
- [x] Every audited candidate is migrated, explicitly retained, unreachable
  with checked references, or a named blocker; no silent coverage gaps remain.
- [x] Configuration-only BP shells and animation/editor/test exclusions have
  documented reasons. Game-project C++ migration stays a separate phase.

The [current candidate dispositions](Demos/UEPLyraIntegration/Migration/candidate_dispositions.json)
reconcile all246 candidates and963 original entries with the hash-bound native
class census,current declaration/dependency sources and explicit retained
transports/shells. Original candidate paths/order/versions stay fixed. The named
Pawn/ASC issue and original NetShooter component discrepancy remain visible.
This completes the inventory disposition criterion,including named open issues;
it does not accept all gameplay branches or any remaining version requirement.

The [per-asset scope reasons](Demos/UEPLyraIntegration/Migration/static_scope_dispositions.json)
record all182 configuration shells and63 retained assets. The source review
reconstructs the original491-asset classification and verifies all245 excluded
stage files against the official reference. This completes the documentation
criterion only;runtime candidates and both Experiences still need their
remaining semantic/gameplay/presentation and applicable multiplayer evidence.

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
