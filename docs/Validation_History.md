# Validation history

Historical milestones and retained result identifiers, separated from the
[current roadmap](../ROADMAP.md). Reviewed on 2026-09-10.

## How to read this archive

These records preserve what earlier runs checked. Their dates, result IDs,
check counts and status fields must not be read as current-HEAD acceptance.
Where an exact source revision was not recorded below, do not assign today's
commit retroactively. Machine-local result paths are not portable release
artifacts; a future candidate must retain its own manifest and accessible logs.

Review qualifications that take precedence over historical completion wording:

- 0.1 retained an exact-source package gap.
- 0.3/0.4 Win64 results do not validate Linux. The 70/70 generic result
  `20260812-043408` is from 2026-08-12, not a fresh 0.8 core run.
- 0.5's final selector change had Network/Standalone tests but no exact-source
  package rerun, even though the historical version is tagged.
- 0.7 is tagged, but visible-client acceptance for its final tree is unrecorded.
- 0.8 has no release tag. `20260903-033426` contains
  `full_acceptance: true`, `hud_audit: null` and
  `hud_asset_generation: null`; the separate audit/generation runs must not be
  presented as steps executed by that invocation. NullRHI validates state, not
  the rendered health-bar animations.
- That 0.8 run used the then-current six host tests and predates the later
  source-only bootstrap fix/seventh test. A current full real-runtime rerun is
  still required. Matching some staged Python file hashes does not make the
  entire run current-source evidence.
- The pre-closeout validator accepted two active presenters if its count/balance
  checks otherwise agreed, and recorded success before quit. Thus the existing
  `3 Constructs / 2 Destructs` snapshots do not enforce exactly one presenter
  or post-shutdown zero owned callbacks. Old logs do contain cleanup events;
  this is a missing validation guarantee, not a finding of an actual leak.
- Retained package evidence described here is Win64 Development.
  DebugGame and Shipping have no retained validation in this review.

The 0.8 archived/tested executable SHA-256 recorded by the historical run is
`07618B6071C837E1334E4F9FEE2212ACC6A604FD881EEB94419C19AD9DA8F3E9`.
HUD audit `20260903-032632` and clean-base generation
`20260903-033001` / `20260903-033049` are separate supporting records. The
reference Healthbar SHA-256 was
`7AD30080E82AF2BB2FB40DD132F632A35E3429076ABAD49A37FDFD657895CF66`.

The retained `20260903-032632` audit has no healthbar `mixin` declaration field.
It is an asset/graph inventory, not a pass of the later strict Interface/profile
audit contract. The updated semantic validator correctly rejects that old data.

## 0.1.0 — UE 5.8 foundation

Historical status: tagged; implementation complete, exact-source package confirmation deferred.

- Build all runtime and editor plugin modules against UE 5.8.
- Use the engine-bundled CPython 3.11 runtime.
- Support both shared and UEP-owned interpreter lifecycles.
- Validate reflection, common property types, functions, delegates, garbage
  collection, editor objects and packaged runtime behavior.
- Provide a Third Person integration demo with additional Python gameplay.

Acceptance gate: the four-suite validation run passes all 40 required checks,
the Third Person smoke test passes, and neither workflow changes engine source.

## 0.2.0 — Python-first Third Person

Historical status: tagged; milestone was marked complete at the time. See the qualification above.

- Rebuild dynamic Python `UClass`/`UFunction` generation on UE5's `FField`
  reflection model where it is required for Python subclasses and event
  overrides.
- Produce a Python-first variant of the official UE 5.8 Third Person template:
  character/Pawn lifecycle, camera boom and control rotation, Enhanced Input
  mapping setup, move/look/jump actions, PlayerController/GameMode bootstrap and
  locomotion state calculation move out of Blueprint event logic.
- Drive the animation instance from Python while retaining skeletal meshes,
  animation clips and pose-blending assets as Unreal assets. Blueprint graphs
  should be removed or reduced to asset-only glue with documented reasons.
- Keep the reference Blueprint template unchanged and stage the Python variant
  separately so behavior can be compared automatically.
- Add deterministic tests for input binding, movement, jump, camera response,
  animation state changes, map travel, standalone play and packaged execution.

Acceptance gate: the Python-first variant reaches feature parity with the basic
Third Person template for keyboard/mouse play, its remaining Blueprint logic is
inventoried, and all gameplay checks pass in visible and headless modes.

Completed gate: UE 5.8.0 and Python 3.11.8 passed 46 shared, standalone,
editor and packaged core checks. The Python-first demo passed Blueprint audit,
headless smoke, packaged smoke and a rendered Standalone capture while the
unchanged template overlay continued to pass its regression smoke test.

## 0.3.0 — API and platform hardening

Historical status: tagged; milestone was marked complete at the time. See the qualification above.

- Add generic `TSet` property marshalling and promote it into the required core
  suite.
- Expand lifecycle, reload, exception, threading and long-running stress tests.
- Audit the remaining editor, animation, Slate, Sequencer, networking and asset
  wrappers for UE5 behavior rather than compile-only compatibility.
- Add at least one non-Windows build/runtime validation lane before claiming
  broader platform support.
- Define reproducible source and optional binary release packaging.

Acceptance gate: the six-suite Win64 matrix passes all 67 required checks,
including cooked packaged execution and orderly interpreter/process shutdown;
the wrapper audit has behavioral coverage, platform claims match retained
artifacts, and release archives are generated from a clean named commit.

Completed gate: UE 5.8.0 and CPython 3.11.8 passed 20 shared core, 20
standalone core, two isolated exception-boundary, five editor and 20 packaged
core checks in full result `20260811-153622`. The run exposed and fixed a
`BlendSpace` parameter shallow-copy shutdown corruption, then completed with
zero fatal, compiler or unexpected error diagnostics and process exit code 0.
Linux remains explicitly unclaimed: readiness result `20260811-154243` reports
the required `v26_clang-20.1.8-rockylinux8` SDK is not installed locally.

## 0.4.0 — Lyra integration

Historical status: tagged; milestone was marked complete at the time. See the qualification above.

- Start with a capability audit of Lyra's Game Feature plugins, modular gameplay,
  Enhanced Input, Gameplay Ability System, asset management and multiplayer
  lifecycle boundaries.
- Introduce narrow Python extension points with explicit thread, authority,
  replication and hot-reload rules instead of attempting an immediate Lyra
  rewrite.
- Validate editor startup, Game Feature activation, client/server play, cook and
  package behavior against an unchanged Lyra reference project.
- Expand Python ownership only where performance and lifecycle measurements show
  it is safe and maintainable.

Lyra is intentionally not a 0.2.0 acceptance dependency.

Source gate result `20260811-165230` built a clean disposable `LyraEditor`
stage, linked `UEPLyraBridge`, started a game world with UEP-owned CPython
3.11.8, captured a game-thread/Standalone snapshot and shut down with zero
compiler, fatal or `Log*: Error` diagnostics. Historical readiness result
`20260811-184203` correctly reports the local Git sample as source-ready but
content-blocked. Complete-project readiness result `20260812-005352`, followed
by full-driver Readiness result `20260812-013646`, passes UE 5.8.0, CPython
3.11.8, all five Game Features and every critical Unreal package against
`F:\LyraStarterGame\LyraStarterGame.uproject`.
Final source regression `20260811-183357` also passed both Standalone and a
real UDP-listening dedicated-server graceful-exit gate. Final generic regression
`20260812-043408` passed 70/70 checks including Editor/Slate, a full Development
BuildCookRun and packaged CPython 3.11.8. `Run-UEP58LyraValidation.ps1` now encodes
the complete Standalone, explicitly synchronized dedicated-server/client and
packaged-runtime contract. Negative result `20260811-184148` rejected the
content-free sample before staging. Pre-release `All` result
`20260812-025232` then passed readiness, Editor build, Standalone gameplay,
dedicated-server/client authority and replication, and a cold-DDC full Win64
BuildCookRun. Its executable-layout guard exposed and stopped on one incorrect
internal-path assumption after UAT had archived successfully. The corrected,
bit-identical package passed the full gameplay and lifecycle contract in strict
result `20260812-042711-packaged-resume` with CPython 3.11.8 and zero fatal or
`Log*: Error` diagnostics.

Named release-code commit `c797d56` subsequently passed formal `All` result
`20260812-051532` from readiness through packaged runtime in one invocation and
set `full_acceptance: true`. It cooked 4,046 packages, returned exit code 0 for
Editor, Standalone, both network roles, UAT and packaged gameplay, and retained
zero strict runtime/UAT error diagnostics with matching executable hashes.

The completed boundary keeps Game Feature activation, ability grants, input
mappings and replicated authority-sensitive state native to Lyra. Python
observes those states through the disposable bridge. The reference project and
Unreal Engine source remain unchanged throughout validation.

## 0.5.0 — Python-driven Lyra gameplay slice

Historical status: tagged; milestone was marked complete at the time. See the qualification above.

- Add one bounded authority write instead of broad arbitrary GAS access. Python
  chooses a command ID, health delta, target role and timing; the adapter checks
  game thread, authority, target readiness, magnitude, non-lethal/non-overheal
  policy, damage immunity and idempotency.
- Execute Lyra's existing SetByCaller Damage/Heal Gameplay Effects through the
  target ASC. Do not write Health directly or replace Lyra replication.
- Prove client writes are rejected locally with no implicit RPC.
- Prove a dedicated-server Python process changes a real remote player's Health,
  client Python observes the replicated damaged value, server Python restores
  only after that acknowledgement, and client Python observes restoration.
- Retain the 0.4 observation contract and unchanged external Engine/Lyra trees.

Acceptance gate: strict Standalone, synchronized dedicated-server/client,
Win64 BuildCookRun and packaged gameplay all pass on UE 5.8 with engine-bundled
CPython 3.11. Result JSON must record authority rejection, exact `100 -> 90 ->
100` Health, duplicate-command rejection and orderly shutdown with no compiler,
fatal/assert or `Log*: Error` diagnostics.

Incremental implementation results `20260812-233341` (Standalone) and
`20260812-233801` (Network) pass the new command, authority, idempotency and
replication contract. Formal `All` result `20260812-234501` then passed the
complete gameplay-slice candidate with `full_acceptance: true`: readiness,
Editor, Standalone,
loopback dedicated server/client, Win64 BuildCookRun and packaged execution all
passed on UE 5.8.0 and CPython 3.11.8. Every process exited 0, the package hashes
matched, and strict runtime logs contained no fatal/assert/`Log*: Error`
diagnostics. After the controller selector was hardened to reject ambiguous
human targets, exact-source results `20260813-005436` (Network) and
`20260813-005835` (Standalone) passed without another Cook/package. A final
package confirmation for that exact source was left open. The version was
subsequently tagged; the tag does not close this evidence gap.

## 0.6.0 — Playable Python-first Third Person

Historical status: completed and released on 2026-08-24. Lightweight checks, the headless
UE 5.8 Standalone contract, Blueprint audit, packaged runtime contract and
visible-client gate pass. The completed demo history was then moved to
`AvaloNero/UnrealEnginePython5Examples` and pinned here as the `Demos` submodule.

- Replace the former 543-line combined runtime/smoke module with a package that
  separates generated gameplay classes, animation, game state, visible actors,
  viewport HUD, world lifecycle and automation.
- Turn the template-parity proof into a complete small round: six collectible
  orbs, cumulative score, timer, completion state, automatic next round and a
  Python-driven companion.
- Replace per-frame debug HUD text with one real hit-test-invisible Slate tree
  owned by the current game-world session.
- Make PythonFirst the default demo while retaining the original Blueprint
  overlay only as an explicit compatibility regression.
- Keep the official UE 5.8 map, mesh, animation and input assets unchanged and
  keep the empty project C++ module free of gameplay.

Acceptance gate: UE-bundled CPython 3.11 passes the pure state tests; the
Blueprint audit remains stable; headless Standalone proves generated classes,
five input bindings, movement/look/jump, the four animation states, all six
pickups, score/victory, companion motion, HUD attach/update, same-map travel and
explicit teardown; a visible 1280x720 run is playable; and the same contract
passes in a Win64 package with strict clean logs.

Historical evidence: headless Standalone result `20260824-211718` passes the full
schema-5 runtime/teardown contract with UE 5.8.0, CPython 3.11.8 and the loaded
UEP 0.6.0 descriptor. It delivers `W`, `MouseX`/`MouseY` and `SpaceBar` through
the official mapping contexts and records movement, look, jump and all released
keys. Blueprint audit result `20260824-211829` retains the expected four
Blueprints, 27 graphs and 173 nodes. Win64 package result `20260824-203312`
records UAT `Build=False`, archives 1754 Pak entries and passes the same schema-5
contract from the inner packaged target with zero release-blocking UAT/runtime
diagnostics. Visible Play result `20260824-044028` confirms the rendered Python
HUD, physical mouse look and the SpaceBar jump/fall/land sequence; the final
trace-disabled package relaunches with zero TCP listeners and no Windows
Security picker.

## 0.7.0 — Blueprint mixins and retained-class Third Person

Historical status: tagged; source implementation, asset generation, headless Standalone and Win64
Cook/package acceptance complete; visible-client acceptance pending.

- Add `register_mixin`, `mixin`, `unregister_mixin` and registry inspection for
  Blueprint-generated classes.
- Add one class router with CDO-declared Mixin Sets, mutually exclusive named
  profiles and cached per-instance profile selection through a Blueprint
  Interface or explicit Python API.
- Replace selected Blueprint `UFunction` map entries while keeping every object
  and asset on its original Unreal class.
- Automatically call the preserved Blueprint implementation when an active
  profile omits one function from the router union.
- Preserve an explicit `call_mixin_original` path, per-UObject Python state and
  helper methods without retaining bound-method reference cycles.
- Restore every original function on explicit unregister, reload and process
  shutdown.
- Discover directly declared Interface owners from package completion in Editor,
  Game and packaged builds; inherited Blueprint children share the parent router.
- Reject registry mutation during selector/initializer/teardown/dispatch
  callbacks while allowing nested initialization of a different object.
- Preserve native return values and const-reference inputs by copying between
  the injected and preserved UFunction's native parameter layouts before direct
  original dispatch.
- Add a Third Person Mixin variant in which two instances of the official
  Character BP select different profiles, including one whose missing `Move`
  falls back to Blueprint, while native jump and AnimBP remain unchanged.

Acceptance gate: two live `BP_ThirdPersonCharacter_C` objects must retain the
same class while selecting different profiles; the player must move/look
through Python, move through automatic Blueprint fallback after a profile
switch, call its original BeginPlay, retain Blueprint jump/animation, survive
unregister/re-register on the same pawn and restore the original Blueprint Move
implementation. The installed Engine/template remains unchanged; the examples
repository intentionally owns a same-path Character BP copy containing only the
Mixin Interface configuration in addition to Epic's gameplay graphs.

Historical evidence: repeat-generation result `20260831-012003` and schema-4
headless Standalone result `20260831-012054` compile/link on UE 5.8.0 with
CPython 3.11.8. The playable Character declares
`DA_ThirdPersonCharacterMixin`, reads its instance-editable
`PythonMixinProfile` variable, and passes same-BP selection, Blueprint fallback,
direct and declared re-registration, full restoration, package-load fixture,
native const-array/return and callback-reentry gates. Win64 Package result
`20260831-014230` builds the Game target, cooks/stages/archives and passes the
same contract in the packaged runtime. Its Cook log proves commandlet bootstrap
is skipped and no routed function map is serialized into assets.
Template audit `20260829-225525` and Python-first regression `20260829-225336`
also pass. Strict package/build/runtime logs are clean. Visible-client evidence
is not yet recorded for this tree.

## 0.8.0 — Lyra Python HUD foundation

Historical status: unreleased development candidate. The 2026-09-03 run passed
its then-implemented checks, not the corrected 0.8 release contract. It was
NullRHI/headless, omitted HUDAudit and did not enforce final cleanup or exactly
one active presenter; visual parity and a current-source rerun remain open.

- Reuse the proven HUD/session lifecycle while preserving Lyra's `ALyraHUD`,
  Game Feature activation and CommonUI ownership.
- Replace the visible health-bar behavior with a Python presenter bound to
  Lyra's Health Component events.
- Prove replicated `100 -> 90 -> 100`, respawn, Experience-owned `Add Widgets`
  teardown/recreation, repeated travel and zero dedicated-server widget
  creation.

Historical result `20260903-033426` passed the then-implemented `All` lane on UE 5.8.0
and CPython 3.11.8 with `full_acceptance: true`. Standalone, network client and
packaged game each recorded 3 Constructs / 2 Destructs and balanced final
delegates; the dedicated server recorded zero HUD state. BuildCookRun and the
packaged runtime exited 0 with matching executable hashes and clean strict logs.

## 2026-09-07 closeout progress — host checks, audit and focused Standalone

Documentation baseline was pushed as core `55d8670` / Examples `6a749ee`.
The following closeout changes were tested from a subsequent dirty working
tree, not a new tagged or fully runtime-accepted release:

- HUD-enabled `All` invokes the strict audit and cannot set its full flag
  without a passed in-run audit; diagnostic skips still prevent full acceptance.
- Probe/driver checks reject duplicate active presenters. Schema 5 preserves
  the active snapshot, writes `awaiting_shutdown`, and records final HUD state
  from Python `atexit` after UEP's Mixin pre-exit teardown. The external driver
  checks final zero-owned-callback/reference counts and ordered exit markers
  after process completion. Missing/unclean finalization fails closed.
- 17 Python tests and 28 PowerShell positive/negative checks pass. The Python
  tests include real CPython subprocess exits with cleanup, a residual binding,
  and `os._exit(0)` bypassing finalizers. These are not Unreal runtime tests.
  Logs are retained under
  `.build/LyraValidation/Full/Results/20260907-hud-closeout/` as
  `python-host-tests.log` and `powershell-contract-tests.log`; both processes
  exited 0. `hud-audit.log` in that directory records the failed Editor launch.
- Old `20260903-033426` runtime JSON is rejected by the new schema/final-evidence
  contract; it remains historical evidence, unchanged on disk.
- Read-only Editor attempt `20260907-hud-closeout` exited 1 before running the
  audit. The engine BuildId was `91898095-bb6d-4da0-9340-28669c3653b3`, versus
  `160ea5ae-f247-4a72-996b-dea22b186e2f` for the staged plugin and multiple
  Engine plugins; `DerivedDataBuildController` failed to load. This is an
  environment/binary-provenance blocker at that point, not a failed Python presenter test.
  The Engine's `UnrealEditor.target` receipt had a third BuildId,
  `81feb3cc-2985-40bd-9e05-ca9d4172c49f`; the launch failure alone does not
  establish which build step introduced that inconsistency.
  No BuildIds were manually overridden. Startup did invoke Unreal's SDK
  validation, not a C++ compile.
- Follow-up diagnosis found that `NetCore.dll` was newer than some engine
  plugin manifests: the old All run used `160ea5ae...`, while the DLL/root
  metadata had subsequently changed at 2026-09-02 19:53:45/46 UTC. The specific
  originating command was not established. The old base `UnrealEditor.target`
  receipt is not proof of an ABI mismatch by itself.
- Guarded UBT preflight (`build-preflight-detailed.log`) found only two outdated
  metadata actions, with no compiler/linker actions. Existing generated records
  were copied to `metadata-backup/` (344 files). Official UBT then executed only
  `WriteMetadata UnrealEditor.version (LyraEditor)` and
  `WriteMetadata LyraEditor.target`, succeeded in 3.72 seconds, and recycled
  the current engine BuildId `91898095-bb6d-4da0-9340-28669c3653b3`.
  `build-metadata-repair.log` retains the action list. No Engine source was
  edited. NetCore, UEP and LyraGame DLL SHA-256 values were unchanged.
- `hud-audit-after-repair.json` and its log record a fresh strict audit pass;
  the Editor exited 0. The real Healthbar retains its class, declares
  `UEPPythonMixinInterface`, selects `Python` and retains `BlueprintFallback`.
  Authored graph pin defaults were read without compiling/saving assets.
- Current overlay Python scripts were synchronized into the existing stage;
  native staged sources matched the checkout and no C++ build was invoked.
  `standalone-shutdown-summary.json` retains dirty-tree core/Examples revisions,
  script and binary hashes and the explicit `full_acceptance: false` scope.
  `standalone-shutdown.json` passes schema 5 on UE 5.8.0 / Python 3.11.8:
  health `100 -> 90 -> 100`, Pawn replacement, widget action recreation and
  travel pass, with exactly one active presenter/reference. After actual UE
  shutdown, the snapshot records 0 presenters/references, 3 Constructs /
  3 Destructs, 1 router teardown, controller binds/unbinds 3/3 and health
  binds/unbinds 6/6, with no presenter errors. The process exited 0 after
  102.024 seconds; the current driver's strict report/log assertions pass.
  The log orders `UEP_LYRA_AWAITING_SHUTDOWN`, `Goodbye Python`,
  `UEP_LYRA_HUD_SHUTDOWN_PASSED`, then `Log file closed`.
- Reference Healthbar hash remains the value above; staged Healthbar remains
  `3247123608F568DCA5A5D48A9ECEE6B02F02DE36EC59716BA27E57515795D1AC`.

At that point, visual fixes and caller-BP fixtures remained open (see the next
follow-up). The 2026-09-07 run did not run full `All`, synchronized network,
cook/package or rendered acceptance. Combined gates still require fresh evidence;
neither this focused pass nor the old green run is release approval.

### 2026-09-10 animation and cross-Actor follow-up

The Python presenter now uses retained `OnDamaged`/`OnHealed` animations and
CommonUI interpolation rather than resetting on each health notification.
Initial/new-Pawn state uses `InitializeBarVisuals`; max-health normalization
is no longer hardcoded to 100. The reflected `OnAnimationFinished` event chains
damage completion to `OnEliminated`. Cancellation disarms pending death before
stopping animations in normal destruction; router teardown pauses silently.
Host checks pass 29 Python tests and 40 PowerShell cases.

Retained records under `.build/LyraValidation/Full/Results`:

- `20260907-hud-closeout/standalone-visuals-20260910-summary.json`: real current-
  animation-script NullRHI Standalone passes health events, Pawn replacement,
  Game Feature action replacement and travel, then final zero presenters/
  references and controller 3/3, health 6/6 bindings. It predates the later
  additive animation-event ledger and isolated visual-test module, and is not
  assigned to the entire final tree retroactively.
- `20260910-hud-visuals/callsite-04.json`: a caller BP compiled before Mixin
  registration invokes two pre-existing same-class Actor targets. Original,
  mixed, repeated, swapped and restored phases all pass. Python does not
  implicitly invoke the preserved BP; missing methods do, and unregister
  restores the already-compiled callsite. No Blueprint asset was saved.
  Earlier fixture attempts failed on Editor `PostEditChange` reconstruction;
  runtime-style `set_property` writes isolate the dispatch behavior.
- `20260910-hud-visuals/visual-02.json` and eight PNGs: actual D3D12 UMG
  rendering shows damage `100 -> 93 -> 60`, healing `60 -> 67 -> 100`,
  elimination at 0 and restored full health. Screenshot inspection confirms
  red damage, green healing and the `ELIMINATED` state. Initial failed attempt
  called an unreflected current-value getter; the fixture now reads real
  `GetText()` output and the reflected target. Values are sampled frames, not
  a promise of exact frame timing.
- `20260910-hud-closeout-integrated/summary.json`: the checked-in focused
  validator passes both checks together, records native/script/PNG hashes and
  final cleanup (one Construct/Destruct, no retained widgets/callbacks).
  It is explicitly **not** the full Lyra `All`: `full_acceptance: false`,
  no UBT, C++ compile, cook/package or asset save. The final runner revision is
  also rechecked under `20260910-hud-closeout-final`.

The visual run uses an isolated real widget with a test-only health reader;
it is not a GAS/delegate/network or packaged-runtime test. The normal overlay
imports that fixture only with an explicit visual-validation flag.

Shared Engine activity changed NetCore and module records during iteration.
Official UBT preflight listed only two metadata actions, then regenerated
records; the repair itself did not compile/link or change checked DLL hashes.
Focused combined evidence uses BuildId `347adf8a-0e10-4046-9bb4-c7a62877a03a`.
No Engine source/reference project was edited; the reference Healthbar SHA-256
remains `7AD30080E82AF2BB2FB40DD132F632A35E3429076ABAD49A37FDFD657895CF66`.
The full driver's audit + new checks + Standalone/network/package combination
has not been rerun, and no 0.8 release tag is implied by these focused passes.

Additional same-turn edge-case records:

- `20260910-hud-switch-probe` reproduced a completion dispatch into a mutating
  router, then a fatal zero-sized original `Destruct` frame. The subsequent
  `20260910-hud-switch-fixed` run confirmed that silent pause eliminated the
  completion reentry but not the independent native fallback assertion.
- `20260910-hud-visuals/build-native-fallback.log`: official UBT with
  `-NoEngineChanges` performed exactly four actions in 24.15 seconds: compile
  `PythonFunction.cpp`, link UEP lib/DLL, and write project metadata. The sole
  native source change makes the original fallback allocation non-null for
  zero-sized functions. No Engine source, Game target or package was rebuilt.
- Earlier focused passes predate this final native change. The post-fix
  `20260910-hud-native-closeout` record reruns caller routing including the
  parameterless native fallback, normal rendered cleanup, and a separate
  immediate animation/profile-switch process. Do not relabel the earlier
  recorded DLL hashes as the new DLL.
- `20260907-hud-closeout/standalone-native-final-20260910-summary.json`: the
  post-native-fix regular Lyra Standalone also passes in 98.906 seconds, with
  health events, Pawn replacement, widget action replacement, travel, one
  active presenter, and final 3/3 Constructs/Destructs, 3/3 controller binds,
  6/6 health binds and zero owned widget references. Both post-fix runs record
  UEP DLL SHA-256 `39E68245A1919FA901CE5D79AAA9482972B13DA331CBAA97C5672D0588F079C7`.
  Final overlay script hashes still match the passed focused run. Only the
  focused runner's rejection of invalid `Mode`/switch combinations and docs
  were tightened afterward; no runtime scripts/native source changed.

## 2026-09-12 — Two-client network closeout implementation

The expanded contract is one real dedicated server and two independent clients,
with B0 exiting and B1 rejoining (four process instances). The Examples Bridge
now exposes explicit World/Player tokens, per-player snapshots, bounded Health
commands and Pawn restart. The core no-build runner performs fresh HUD audit,
source/module/hash checks, phase barriers, strict logs and all-process atexit
cleanup; `Network/All` require this gate, while `NetworkPrecheck` retains the old
single-client diagnostic. NullRHI networking does not prove rendered or packaged
network behavior, and never sets the full release flag.

Native build provenance, under `.build/LyraValidation/Full/Results`:

- `20260912-network-build-01`: official UBT with `-NoEngineChanges` stopped
  before C++ compilation because existing Engine module/version metadata needed
  regeneration. UHT generated three stage files; this was not a runtime pass.
- `20260912-network-build-02`: backed up the 326 affected Engine metadata files,
  inspected the official action export, then ran exactly five actions: Bridge
  compile, DLL/lib links, Engine metadata and project metadata. Build succeeded
  in 51.06 seconds. No Engine C++ compilation or cook/package was performed.
  NetCore DLL SHA-256 before/after remained
  `E71D3F07887D6376297A23A3B3A65122DCB75CF2ABC9885C7858F8FF1E5DE1A1`.
  Source/reference assets were not edited; module GUIDs were generated by UBT,
  not manually spoofed.

Retained failed harness iterations (not acceptance evidence):

- `20260912-network-run-01`: real A joined, but online identity replaced the URL
  nickname. The probe rejected its own incorrect nickname assumption. Fixed by
  correlating actual local/server PlayerState ID/name and server token, not join
  order or a user-provided nickname.
- `20260912-network-run-02`: damage/heal isolation, reversed ACK order and both
  restarts progressed, then a transient Windows sharing violation interrupted
  atomic status-file reading. Added bounded retry, preserving permanent error
  and malformed-JSON failures.
- `20260912-network-run-03`: native bot gunfire introduced repeated 12-point
  Health changes after a tested player restart. The unchanged 100/90/80 checks
  rejected this interference. The opt-in test now stops only the three bots'
  brain logic; it retains native Warmup and does not change player immunity,
  Health storage, replication or bounded GAS command rules.
- `20260912-network-run-04`: the bot helper initially failed to unpack UEP's
  single-out-parameter tuple. Its three-isolated-brains barrier stayed closed.
  Source inspection identified the mistake; this run was deliberately stopped
  and recorded failed. Added host tests for the real return shape and AI-only
  write boundary before retrying.

The current host suite has 50 Python tests and 45 PowerShell contracts. This
includes adversarial ACK identity, wrong-owner HUD/events, missing participants,
non-finite Health, absent finalization, sharing violations, reflected out-array
handling and the new mandatory two-client release gate. Host passes alone are
not the network runtime result.

### Passed focused runtime: `20260912-network-run-05`

- `summary.json`: status passed, `multi_client_acceptance: true`,
  `full_acceptance: false`; run ID `2fd770b9338043d39a6b1c0436b4d0f3`.
  UE 5.8.0 / CPython 3.11.8, BuildId
  `038ca067-a15c-47cf-a35d-073bd334643e` for Engine and staged modules.
  Core `980587e4bf2d449a4154a7ba2b25ef500829cdc3`, Examples
  `0395f360136070d96dd3ad17e1fb1023c4cc2595`, both dirty; 408 native source
  mappings and 99 executable/script/test/config/asset input hashes checked
  before and after. Later documentation-only changes do not change these inputs.
- Fresh HUD audit, 50/50 Python and 45/45 PowerShell host contracts pass.
  Existing asset registry reused; the focused run performs no C++ build,
  cook/package, asset generation or firewall changes. The necessary earlier
  Bridge build is recorded separately above.
- All 20 server phases and N01–N16 pass. A observes 100 → 90 → 100;
  B0 and B1 observe 100 → 80 → 100. Interleaved 90/80 and reversed ACK order,
  command dedupe including retarget attempts, client authority denial, separate
  restarts, two non-seamless same-map travels and obsolete-token rejection are
  corroborated by each participating client's native snapshots and fresh owned
  delegate events.
- B0 exits before the remaining A damage/heal test, then B1 joins with a new
  native token/Pawn. Server/A/B0/B1 preserve 20/20/13/4 phase records respectively.
  Final Python-exit report, strict error/log ordering and real OS exit code are
  checked for all four process instances, not just the final pair.

| Process | Runtime seconds | Exit | Active Constructs / Destructs | Final controller binds/unbinds | Final Health binds/unbinds | Final widget references |
| --- | ---: | ---: | --- | --- | --- | ---: |
| server | 187.337 | 0 | 0 / 0 | 0 / 0 | 0 / 0 | 0 |
| A | 168.506 | 0 | 3 / 2 | 3 / 3 | 7 / 7 | 0 |
| B0 | 110.955 | 0 | 3 / 2 | 3 / 3 | 6 / 6 | 0 |
| B1 | 21.051 | 0 | 1 / 0 | 1 / 1 | 1 / 1 | 0 |

The offline Python cross-report validator and the core multi-client release
contract were independently rerun against these final files. No test UE process
remained. Retained NullRHI logs contain warning-level native Niagara/footstep
`Accessed None` messages; this is not a visual/FX certification. No connected
rendered clients, weak-network/LAN/WAN, stress/repeat-stability, packaged network,
or new combined `All` release run was executed. No 0.8 release tag is implied.

## 0.9 Batch 1A progress — 2026-10-13

Evidence root: `.build/LyraValidation/BlueprintPython/20261013-batch1a`.
This is local development evidence, not a release or accepted migration batch.
Core `980587e4bf2d449a4154a7ba2b25ef500829cdc3` and Examples
`0395f360136070d96dd3ad17e1fb1023c4cc2595`, both dirty on
`dev/lyra-blueprint-python`; no commit, push, tag or packaging was performed.
UE 5.8.0 / engine CPython 3.11.8; Engine and staged module BuildId
`59220820-55ad-4797-9c21-bdc1adf3f709`.

- The static scope manifest was reconciled to 246 runtime BP business
  candidates, 182 configuration/layout shells and 63 retained animation,
  editor/test/interface assets. Examples `Migration/batches.json` assigns
  5/32/37/75/57/40 candidates to 0.9/0.10/0.11/0.12/0.13/0.14 respectively;
  11 boundary candidates still require scope review. Counts are not migration
  acceptance or runtime reachability.
- The experimental function-body thunk's native-entry output bug was fixed:
  `ProcessEvent` out values must be copied into `FFrame.OutParms` caller
  addresses, not just frame locals. Packed bool destinations use their own
  property masks. `script-body-after-metadata.json` passes a caller compiled
  before registration, repeated reflected/native entry, integer/bool output
  writeback, no implicit original BP call, unchanged class identity and
  unregister restoration. Outputs are 33/false, -6/false, then restored
  13/true. This narrow thunk remains experimental and is not used by the Lyra
  profiles; it does not certify all signatures, RPCs or latent functions.
- `plugin-build.log` records one incremental UEP module compile/library/link
  (three actions), UBT success, 9.45 seconds total. There was no Engine/Lyra C++
  rebuild or cook/package. An existing generated module BuildId mismatch blocked
  the first Editor start. After backing up 916 generated metadata records under
  `metadata-backup`, official UBT `WriteMetadata` ran two metadata-only actions,
  5.81 seconds total (`metadata-repair.log`). Engine **source** was not edited;
  generated Engine/stage module metadata was repaired, so the entire Engine
  directory is not claimed untouched. The original cause of the earlier
  Engine/stage ID difference was not established.
- Four example-owned weapon BPs and four Mixin Sets were generated/compiled in
  the marked disposable stage and copied into the Examples overlay. The normal
  class names and layout/material assets remain unchanged. Native inventory,
  equipment, GAS, input and replication are called, not rewritten. Authoring
  now checks that Unreal's current project matches the marked stage before
  any registry or asset mutation. The official Lyra assets were not saved.
  `weapon-hud-declared-audit-02.json` independently passes the real-UE stage
  guard and all four persisted selectors. Its first read-only attempt exposed
  UEP commandlets' absent `__file__`; tool imports were fixed to locate the
  supplied script argument and the fresh commandlet exits 0 without asset saves.
- `WeaponDeclaredRegression02/summary.json` passes the persisted Interface/CDO
  defaults and all 42 isolated real-UMG original-BP/Python comparisons. Exact
  text/visibility, Pistol/Rifle/Shotgun low-ammo thresholds, both material images,
  weapon/slot changes, empty slot, brush helper, native reload-input dispatch,
  unchanged classes, four router restorations and strict normal process/Python
  exit are checked. Both source/stage inputs and the four original BP reference
  hashes stay stable during the run. The BP-left/Python-right PNG was inspected;
  quantitative pixel diff was not executed.
- The failed `WeaponDeclaredRegression` evidence is retained: the new reload
  path exposed an invalid `ue.Vector` name. The runner correctly rejected the
  error log despite the fixture's pass marker. It was repaired to `ue.FVector`,
  successful-call counters were moved after callback work, and the fresh `02`
  run passed without weakening the assertions. An earlier `weapon-differential-01`
  also retained a failed brush expectation; audit of the original graph showed
  that its resource is the supplied UImage object itself. The implementation
  and expectation were corrected to the authored behavior, not to a new feature.
- The same focused `02` run starts ordinary `L_Expanse` without UEP validation
  flags. All four declarations register, the native Experience loads, and the
  process remains alive for 20 seconds afterward without probe/quit markers.
  The driver then intentionally stops only that owned process (exit -1);
  this NullRHI observation is not rendered/input or graceful-exit acceptance.
- `HealthRegression/summary.json` passes precompiled cross-Actor calls and
  rendered damage/heal/death/respawn, with a separate live animation/profile
  switch process. `NetworkRegression/summary.json` passes the existing
  dedicated-server/two-client **Health/HUD** contract (N01–N16, 20 protocol
  phases, B leave/rejoin). Server/A/B0/B1 all exit 0 in
  189.755/171.747/113.067/20.911 seconds. Both focused lanes remain
  `full_acceptance: false`; their passing Health result is not new ammo proof.
- Current host reruns pass 67 Python tests, the existing 45 PowerShell HUD/network
  contracts and 10 additional narrow weapon-evidence contracts. The network
  invocation preceded the last weapon-test additions; its own recorded host
  results must not be relabeled as a 67-test invocation.

Still open for Batch 1A: real fire and GAS reload, replicated per-player ammo/UI,
weapon/Pawn replacement, event-driven ammo subscriptions and cleanup. The weapon
profiles currently preserve the original BP Tick polling; the isolated fixture
uses deterministic native inventory inputs, not real equipment/replication.
The wider 0.9 call/lifecycle matrix, controlled reload, repeated PIE/GC/travel,
candidate package and API freeze gates also remain open. No 0.9 completion or
full gameplay/network acceptance is implied.

## 0.9 Batch 1A runtime follow-up — 2026-10-13

Same dirty Core/Examples source pair as the preceding entry, with additional
scoped fixes; no commit/push/tag. Current Editor BuildId is
`2cd71c4e-d118-4430-ab9a-53606fc64e3a`. Scope and actual process configurations
are recorded per run. Official Engine/Lyra source and original assets were not
edited. Generated build metadata and disposable stages changed.

- `WeaponNetwork08` passes all 19 real-input weapon phases with a dedicated
  Editor server and two rendered clients. Server/A/B0/B1 exit 0 after
  252.162/234.725/161.275/36.268 seconds. Native fire/GAS reload, depletion,
  existing pickup entry and slot switch, Pawn restart, two travels and B rejoin
  preserve per-player native ammo/Python HUD/original-BP comparisons. The probe
  does not write ammo or inventory. Physical pickup overlap is not tested.
- `WeaponScopeRegression05` passes 42 real-UMG comparisons, native QuickBar
  message cancellation, four Python -> BP -> Python Profile round trips without
  Construct replay and three controlled reload/native-GC cycles. One shared
  read-only sampler replaces per-widget polling. Ammo producer is explicitly
  `read-only-frame-sampler`, not an invented native replication delegate.
- `RuntimeImportCoreRegression` passes standalone/shared 21/21 each. Its
  separate missing-dependency case requires expected exit 1 and the actual
  dependency name/traceback; an existing ue_site failure must not be suppressed
  as an absent optional hook. Core subscription tests pass 9; Examples pass 82;
  HUD/network contracts pass 45, weapon contracts 16.
- `CallMatrixRegression` passes standalone/shared signature boundaries,
  precompiled cross-Actor caller, narrow experimental body out-writeback and
  expected Mixin exception/no-native-fallthrough/recovery. Expected exception
  exit 1 is isolated, checked and not counted as an ordinary clean process.
- `PIERegression05` passes three real sessions in one Editor, placed/spawned
  unchanged Actor classes, spawn Construction, two BeginPlay/EndPlay pairs per
  session, closed scopes, native GC and original function restoration.
- `ThirdPersonRendered05` passes both Mixin/Python-first variants with native
  input, movement/look/jump, six rendered PNGs and strict cleanup/log checks.
  The 0.7 Mixin visible candidate gate is now recorded; historical missing
  evidence remains historical. Incremental variant preparation was repaired
  after it retained the Mixin Character CDO while removing its Python module.
- `HealthCoreRegression` separately passes health/cross-Actor/eight-frame and
  live-animation profile-switch regression before the later import-path fix;
  unchanged health implementation is not relabelled as a newer invocation.
- `WeaponPackage05` records the current Game build and successful Cook/archive.
  `WeaponPackagePresentation07` reuses its unchanged inputs/archive and passes
  the rendered 42-case/native-signal/profile/reload/GC fixture, with explicit
  packaged-network skip and `full_acceptance: false`. Internal/stable native
  executable SHA-256 is
  `F65A8D7342093B064BE7F528AF0473AFEB1F4CA1CB6C329D63B20890FA29C28C`.
  The core helper sources are loose NonUFS files and actually import in Game.

Retained failures and repairs:

- Early weapon-network fixture failures exposed a non-reflected GetItemDef,
  stale unrooted InputAction, absent second weapon, an unpacked GetAllActors
  output tuple and GC of an invisible baseline widget. Native/property lookup,
  input lifetime and test-owned rooting were corrected; later runs passed.
- Native GC testing exposed a real UEP crash on `new_object(Object)` where the
  UClass is abstract. UEP now raises TypeError before UE's native assertion;
  real UE fixtures verify it.
- Separate generated Editor module metadata drift blocked validation startup.
  Official UBT WriteMetadata refreshed existing records after backup under
  observer/generic metadata backups. No hand-written BuildId replacement or
  Engine source edit was used.
- Package01 archived successfully but strict logs rejected two UnrealPak
  PlatformCrypto module-load errors. `pak-metadata-backup` preserves prior
  generated records; official WriteMetadata retains UnrealPak BuildId
  `5fcd6720-663f-4993-8774-c33f25582f7f`. Package02 has clean UAT logs, then
  failed startup because the stable executable alias lacked its basedir.
- Package03 used correct basedir, but a real missing runtime plugin-script
  search path prevented uep_runtime import. The optional-hook handler hid that
  dependent ModuleNotFoundError, the probe never started, and uncapped offscreen
  rendering eventually exhausted video memory. Runtime plugin search and
  accurate dependent-import reporting were fixed; test rendering is capped.
- The first Game compile of that fix failed because IPluginManager's include
  was still Editor-only (Package04). The include was corrected; current Editor
  and Game builds pass. Only the required module/current game target was built.
- Package05's UMG test passes, but using Game target `-server` cannot produce a
  dedicated Server role. Package06's Editor-server/cooked-clients attempt then
  fails on MissingLevelPackage for generated World Partition cells. Neither
  failed topology is promoted to packaged-network acceptance. LyraServer dry
  planning exports 1,235 cold actions and 14,064 generated UHT files; no Server
  C++ compile or Server package was executed. This remains a separate RC debt.
- Core expected-exception and new driver log-order/schema mistakes were
  corrected in their dedicated fixtures/drivers, with fresh result directories.
  Two existing-configuration CC invocations timed out (20 and 10 minutes); no
  external reviewer decision was received or claimed.

Previous managed packages are recoverable under
`.build/LyraValidation/Full/PreviousPackage-*`; their paths are recorded in each
package summary. Package presentation and Editor multiplayer are passed scopes;
full release, dedicated packaged networking, DebugGame/Shipping, weak-network,
cross-machine and unrestricted hot reload remain unvalidated. See the new
call/lifecycle matrix, runtime subscription contract and API inventory.

## 0.10 Batch 2A pilot — 2026-10-13

`20261013-batch2a/assets.json` authors only the marked stage's ammo-reticle BP
and Mixin Set; original Lyra asset SHA-256 is unchanged. Two example-owned
persisted assets are copied into the overlay. `reticle_ammo_mixin.py` owns
material ActiveRange/Segments presentation via the existing shared observer;
native inventory and UMG layout remain.

`ReticleRegression03` passes ten real-UMG BP/Python material comparisons (two
magazine sizes, five counts each), class identity, Python -> BP -> Python
without reconstruction, rendered screenshot and zero final observer/scopes/
ticker. The process exits 0 with strict logs. No C++ compile/cook/package was
performed for this pilot. Its first loose invocation lacked the established
`culture=en` flag and logged UE UnifiedError format-test failures in Chinese;
the new focused driver uses the same declared culture as other lanes and the
fresh invocation passes without ignoring error logs. A visual check of `02`
found zero desired size produced a black image; `03` gives both comparison
widgets an explicit equal viewport size and the actual two arcs were inspected.
Native material assertions were never relaxed. Host Examples tests now
pass 83. Actual reticle use during gameplay, multiplayer/package proof and
the rest of 0.10 remain open; this pilot is not a completed release/batch.

### Combat HUD native-input/context follow-up

`fire-button-assets.json` passes marked-stage Interface/Set/CDO authoring and
retains `W_FireButton_C`. Python owns the original bound-click entry and
injects the same Fire/Fire_Auto actions and FVector(1,1,1); BlueprintFallback
calls the saved BP entry. No ammo/inventory/GAS/authority/replication writes.

Retained failures and repairs:

- `CombatHUDNetwork01` times out because the fixture incorrectly expects a
  production ammo-bar reticle. Original Pistol/Rifle/Shotgun defaults use
  their specific reticles/counters. The corrected test explicitly owns its
  overlay and initializes candidate/BP baseline from the production counter's
  native WeaponInstance. No item definition is changed; global reachability
  remains unreviewed, not declared absent.
- `CombatHUDNetwork02` fails on uppercase R/G/B/A access: UEP's specialized
  FLinearColor wrapper uses lowercase channels. A wrapper-shape host test
  guards the corrected read.
- `CombatHUDNetwork03` passes its then-current numeric protocol, but rendered
  review rejects final visual approval: a rolled camera and healthy eliminated
  UI are visible. UEP's FRotator order is Roll/Pitch/Yaw, so old `(80,0,0)` did
  not aim up. This qualifies the sky-aim claim of older WeaponNetwork runs,
  not their measured ammo/replication evidence. Axes are now explicit and
  schema 4 requires native Pitch=80/Roll=0 at firing ACKs.
- The presenter could read pre-ASC 0/0, then receive old=100,new=100 and leave
  OnEliminated visible. It now recognizes the previously presented zero and
  restores OnSpawned/numeric/material state. Health or max-health can be the
  first ready notification; ordinary damage/denominator-only updates are not
  reinitialized.

`HealthBootstrapRegression01` passes current-source caller-BP routing, eight
rendered health checkpoints and a separate mid-animation Profile-switch
process. Both visual processes require delayed-ASC recovery. Initial healthy
and later death/respawn images are inspected.

`CombatHUDNetwork04` passes schema 4: 19 server/A phases, 14 B0, 3 B1; two
rendered clients; Python/BP fire intent, native reload/depletion, existing
pickup-entry/slot switch, Pawn restart, two travels and B0 exit/B1 rejoin.
Eight screenshots are hashed. Each owner's health number/current target/
material ratio also matches native Health. All exits are 0: server 234.871s,
A 219.634s, B0 142.821s, B1 38.390s. A/B0/B1 subscriptions balance 17/17,
13/13 and 3/3, scopes 3/3, 3/3 and 1/1; every peer has zero active observer,
scope, ticker and errors. Examples host tests pass 111.

The gameplay PNGs retain native `WeaponAudioFunctions.EarlyReflections`
TapIDs warnings also present in `WeaponNetwork08` under `-NoSound`. Strict
error checks pass, not a zero-warning or audio acceptance claim. Unmigrated
audio orchestration is 0.12 scope; its warnings are not hidden or repaired in
the official BP.

No C++ compile, cook/package, firewall change or reference-project edit was
performed for this follow-up. Physical touchscreen/gesture dispatch is not
tested (the bound-click entry is invoked programmatically). Ammo-bar default/
production reachability, actual production reticles, new-asset package proof
and the other 30 initial 0.10 candidates remain open. Old 0.9 packages are not
current script/asset proof. Three parent-only touch shells need parent-call
review; initial counts remain unchanged. No release/publication or external
CC approval is claimed.

### World pad parent pilot and inherited selector follow-up

`20261013-batch2b/assets.json` fails because the Editor authoring helper tries
to redeclare an inherited PythonMixinProfile. The helper now reuses a scalar
Name and writes only the child CDO default, without changing parent metadata.
The first unrestricted target build is rejected by `-NoEngineChanges` before
compiling; module-only UBT then compiles UEPyEditor.cpp plus lib/DLL links (three
actions, 88.99s). No Engine C++/source modification or cook/package is used.

`inherited-selector04` passes parent Python default, child BlueprintFallback
default after compile, no redeclaration and two same-child-class instances
using independent reflected selectors; only the native fallback broadcasts.
The attempted expansion of child declaration discovery hits the existing
related-class router guard in `inherited-selector03`. It is reverted, not
silently allowed: the final UEPyMixin.cpp source retains the original runtime
contract. Two further module builds verify the attempt/restore (7.42/7.27s).
`CallMatrixRegression01` passes five fresh signature/shared/caller/body/exception
fixtures with the final DLL. The general parent/child simultaneous-router and
explicit-Parent bypass limits remain; this is not hierarchy interception support.

`parent-differential01` passes four real Actor construction comparisons
(damage/heal/special/invalid), selecting profiles before deferred FinishSpawn.
Material parent, text/world size, class identity, Python construction count and
no-ASC overlap no-op agree with BP; all eight test Actors are destroyed.
Original disconnected PrintString/attribute-read nodes are not migrated as
runtime business. Level=0 and class/all-stack removal intent preserve authored
inputs; true GAS execution, physical overlap, child and network remain unverified.
Only the parent BP/Set copies are added to the example overlay; the child's
staged experimental configuration is restored from the official reference.
The generator now targets the parent only. Examples host tests pass 118.

No 0.10 release/complete batch or current-source package is claimed. Earlier
CombatHUDNetwork04 evidence precedes this Editor authoring fix and is not
relabeled as a fresh invocation of the final DLL.

### Effect Pad physical GAS and explicit-Parent construction adapter

`20261013-batch2b/PhysicalGAS01` fails on the fixture's unreflected
GetComponentLocation name; K2_GetComponentLocation fixes the test entry.
`PhysicalGAS02` then passes the parent-only native GAS comparison on the prior
DLL. The authored damage/heal effects use Period=1, Level=0 and an empty
EffectContext. Two physical enter/leave rounds per profile give damage
75->65->55 and heal 75->85->95; native source-effect count becomes zero and
Health remains stable outside. Handlers are never invoked manually.

The new Editor-only `blueprint_extract_construction_helper` retains the BP
body in a virtual helper and leaves a two-node construction forwarder. A module-
only UEP build compiles UEPyEditor.cpp/UEPyModule.cpp plus lib/DLL links (four
actions, 23.44s). Engine source/builds and cook/package are untouched. The generic
`construction-forwarder01` fixture fails on a missing break_all_pin_links
argument; `construction-forwarder02` passes explicit child Parent -> virtual
helper -> single parent router, no BP fallthrough, Profile switching, original
restoration and five invalid/duplicate/non-Actor authoring rejections.
Related-class router rejection and other cached/final/direct-native bypasses
remain unchanged.

`assets-forwarder01` returns passed JSON but exits 1 with an old-declaration
auto-discovery error (the new helper did not exist yet); it is **not accepted**.
Fresh official parent input in the marked disposable stage gives
`assets-forwarder02` with a clean exit/log. The cloned original BP helper body
is retained as BlueprintFallback. Only parent BP/Set overlay copies change;
the original child asset/default is retained (its name does not imply a heal
default). The native authoring API does not save automatically.

`parent-child-differential02` passes eight construction/no-ASC cases and sixteen
Actor destructions. `PhysicalGAS03` on the final DLL/serialized parent asset
passes eight parent/child cases and sixteen physical native GAS rounds; all
eight pad Actors/delegates close, parent routing restores, and post-exit HUD/
weapon scopes are zero. `CallMatrixRegression02` passes seven final-DLL fixtures
(the former five plus inherited selector and construction forwarder).
Examples host tests pass 126; core SubscriptionScope tests pass nine.

`PadNetwork01` exposes a fixture setup error after the first case: the existing
native bridge rejects a zero/no-op Health delta for the unaffected player.
Setup now skips that no-op; the bridge/game authority contract is unchanged.
The network state machine also stops active effects on its server deadline,
without waiting for client Health-number animation convergence. The replacement
two-client lane `PadNetwork02` passes sixteen parent/child/effect/owner/profile
cases. Server/A/B0 exit 0 after 135.857/136.065/137.270s; native Health and
actual number/target/material ratio on each client's production HUD agree,
and non-target Health stays 75. No original BP fallthrough/replayed Python
intents occur; all owned pad delegates and post-exit HUD/weapon scopes close.
Native server teleports are not physical client/manual
input, client prediction, production-pad reachability, rendered pad comparison
or packaged-server acceptance. No 0.10 release/complete batch is claimed.

### Debug spread native-context follow-up

`20261013-batch2c/assets01` authors the example-owned debug widget/Set without
changing its native LyraReticleWidgetBase parent or official reference asset.
The Python Tick calls native ComputeSpreadAngle and KismetTextLibrary with the
original HalfToEven/sign/grouping/integral/fractional defaults. No weapon
spread, inventory/ammo or native calculation is overwritten.

`DebugSpreadNetwork01` passes nineteen native fire/reload/switch/Pawn/travel/
disconnect/rejoin phases with `-WeaponGameplay -CombatHUD -DebugSpread` on the
current Editor DLL. Server/A/B0/B1 exit 0 in 251.456/229.197/145.608/45.652s.
The test-owned overlay receives the production ammo counter's native weapon
instance, runs native automatic Widget Tick (Python Tick is not manually
called), and compares original BP and native-formatted text. Native spread
peaks above ten degrees are observed; accepting only a null-weapon zero is
explicitly rejected. Owner/item identity and post-exit scopes agree.

Eight screenshots are hashed. Visual inspection includes switched weapon and
rejoined B1; spread text 2.25, upward aim and healthy 100 HUD are visible.
Native NoSound EarlyReflections and EditorDataStorageUI purpose-registration
warnings remain visible/logged; there is no warning-free/audio acceptance
claim. The debug overlay is not a production reachability proof, and neither
C++ build nor cook/package runs in this follow-up. Host tests pass 135.

### Typed message transport and production reticle differential

`20261013-batch2d/assets01` fails linking the GetPayload reference-input pin
directly to a result input. `assets02` generates a typed local temporary plus
schema connections: ReadUI/ReadVerb have four nodes each, BroadcastUI/Verb two
each. This twelve-node example-only BP adapter supplies typed VM wildcard
transport, not business logic; generic ProcessEvent never calls native wildcard
placeholders. No C++/Engine build, source change or cook/package is required.

`transport01` passes real optional-plugin delivery of unchanged Struct_UIMessaging
and native LyraVerbMessage, Controller identity, nested copy preservation,
wrong-reader and outside-delivery rejection, legacy channel-only listener parity
and idempotent close with zero later callbacks. Core's typed subscription API
requires a supplied verified payload reader. Thirteen host scope tests pass.

`reticle-assets01` generates the three retained reticle declarations, serialized
kind/decoder class configuration and Mixin Sets without reference asset edits.
`reticle-differential01/02` catch the initial Python cast/fixture assumption of
Character instigator; the original casts LyraPlayerState. The owner/suicide
filter and fixture are corrected, not the baseline. The first cleanup assumes
identical async variable names across weapons; enumeration fixes that fixture.
`reticle-differential03` verifies animations after the cast correction but fails
on a nonexistent screenshot method; the verified native console screenshot path
is used instead. None of those failed reports is accepted merely for exit 0.

`ReticleDifferential04` passes three retained layout comparisons on a real
equipped pistol native instance (source production counter), automatic Python
Tick, matching radius/width/height, local versus foreign ADS, unchanged
disconnected ADS animation behavior, native-router elimination/restart and
suicide filtering. Animation times match at 0.04993333. Five created scopes close,
zero active/errors remain at Python exit, process/log exit cleanly and the
paired PNG is hashed/visually inspected. Native r.MotionVectorSimulation warning
is retained. This is not real ADS/kill input, equipped-shotgun validation or
multi-client/package approval. Host tests pass 141. Later docstring/API notes
retain their separate relation to recorded script hashes.

### Production reticle multiplayer and real ADS/shotgun input

`ProductionReticleNetwork01` passes nineteen fire/reload/empty/switch/respawn/
travel/exit/rejoin phases with actual production Pistol/Rifle reticles. The
separate hidden BP baseline reads the same native weapon/camera; automatic
Python Tick, class/profile/owner/item and radius/size agree. Server/A/B0/B1
exit 0 in 269.24/247.96/157.88/52.45s. Native dedicated server creates no reticle
scopes; A/B0/B1 close 11/11, 7/7 and 1/1 respectively. Dropping the production
checkpoint cannot be accepted through an overlay-only/old validation lane.
No real ADS/kill message is generated by those weapon phases; they do not
silently certify such input or a network shotgun.

`ReticleNativeADS05` passes thirty native IA_ADS pressed and thirty released
frames, through the existing Enhanced Input/native ability message producer.
The four owning production/test reticles receive the press and release state;
synthetic test messages do not substitute for this phase. `ReticleNativeShotgun06`
then calls the original/native shotgun pickup entry, selects its native QuickBar
slot, obtains its equipped WeaponInstance from the actual ammo counter, fires
8->5 ammo and reruns the three layout comparisons on that weapon. No inventory,
weapon spread/ammo or ability property is written by the probe. It is not a
physical-overlap pickup test, real kill gameplay or network shotgun acceptance.
Native warnings remain retained, no package was produced, and these runs precede
the subsequent soft-class conversion DLL build. Later host tests pass 148.

### Lazy CommonUI menu and current soft-class DLL

The Unicode `FSoftClassProperty` input stores a soft object path without native
FindObject/LoadObject/TryLoad. Empty/null and existing UClass inputs retain their
meaning; malformed paths, missing object-name separators and embedded NUL fail.
`soft-class01/02` exposed fixture lookup handling and UE's permissive package-
only validator respectively; neither was promoted to a pass. `soft-class03`
passes on the final DLL and `CallMatrixRegression04` passes eight fixtures.
The final incremental UEP module build has three actions (13.68s); no Engine or
Game compile, cook or package was run. Previous reticle/pad runs keep their own
DLL provenance and are not current-DLL reruns.

The example-owned `W_OpenMenuTouchButton` Interface/CDO routes its original
bound-click method through `open_menu_mixin`. Python retains lazy menu loading,
UI.Layer.Menu and native CommonUI async input-suspend/layer behavior. It does
not preload the menu class or rewrite streaming/input execution. `menu-
differential01` caught incorrect generic out-array parameter positions; `02`
had a correct data report but no visible menu and is not visually accepted.
Waiting for the native transition fixes the capture. `MenuDifferential04`
passes the reusable focused driver: initially unloaded class, retained button
type, Python/BP/Python three native push/deactivation cycles, ordered clean log,
exit 0 (66.461s), stable source/asset/DLL/reference hashes and an inspected PNG
showing Options/Quit Game/Back over the blurred game. No compilation or cook
occurs in this driver. Real touch, input-token resume/cancel behavior, default
production reachability, two-client menus and packages remain unverified.

### Production reticle host and two-client lifetime

`assets01` fails because CreateDelegate resets an event selection while its
signature is unconnected. Selecting OnDeathStarted after object/signature
connections fixes generation; `assets02` compiles and persists the retained
host's Interface/CDO plus four VM-only cleanup nodes (24.46s, no C++ compile).
The helper removes only this widget's old BP delegate. It does not execute
UpdateVisibility through a busy Mixin router or replace native equipment.

`HostDifferential01` passes the early routing/lifetime cases but fails a fixture
assumption: LyraInventoryItemInstance object names do not identify the weapon.
Reading the native ReticleConfig fragment fixes pickup selection. `Host-
Differential02` passes eight original-BP/Python cases on the actual production
host, native automatic Tick/equipment callbacks, retained class and exact
child classes/item/weapon/fill alignment. Live Profile switching preserves
already-created children rather than relying on a nonexistent repeat native
weapon event. Null/missing-instigator cases, restoration and native Pistol/
Rifle/Shotgun equip agree. An injected GameplayEvent.Death executes the native
death ability/component: both wrappers collapse, Python receives exactly one
death callback and does not reopen that listener on subsequent Tick. This is
not lethal damage, a kill/score message or physical pickup. Exit 0 (70.062s),
strict log, inspected/hashed production screenshot and final host/reticle
scope balances 3/3 and 9/9 pass. Host tests later pass 170.

`ReticleHostNetwork01` passes nineteen native weapon/CombatHUD/debug/production-
reticle phases with the new mandatory host checkpoint and shutdown gate.
Actual host children are checked against unchanged native ReticleConfig and
owner/item/weapon/fill/visibility; Pistol/Rifle geometry has its separate hidden
original-BP baseline. Missing/old host checkpoints and manufactured Tick or
weapon-event evidence fail. Server/A/B0/B1 exit 0 in 249.481/228.23/147.788/
42.291s. Host scopes balance 0/0, 7/7, 5/5, 1/1; child reticle scopes balance
0/0, 11/11, 7/7, 1/1. Eight PNGs are hashed, selected A/B1 images inspected,
and known native audio/Editor warnings retained. No C++ compilation or cook/
package occurred. This is not network shotgun, lethal death, physical input,
warning-free, current packaged-runtime or complete 0.10 release acceptance.

### Interaction ability progress: implementation only, runtime pending

`assets01` in `20261013-batch2g` passes Editor asset compilation/Interface/CDO
authoring (27.02s). The retained W_AbilityProgress now points to its Python
profile. BP transport has six typed functions/eighteen nodes after adding
ReadDuration/BroadcastDuration; semantic pin/reference digests for the prior
four UI/Verb graphs remain unchanged. The original async proxy is exposed by
one ownership-only store node for cancellation, and the explicit hidden-
profile resume entry is a declaration-only shell. Python uses native game time,
division, culture-aware formatting and material/visibility calls. Host tests
pass 179. No C++ compilation, cook or package occurred.

This is not runtime, production reachability, actual interaction, pause,
multiplayer or package acceptance. A focused original-BP/Python fixture and
current-adapter reticle regressions remain required at this initial checkpoint. Earlier reticle/host
network evidence keeps its prior adapter asset hashes; unchanged graph digests
alone do not replace a current runtime rerun.

### Interaction progress production differential and current adapter regressions

`ProgressDifferential01` fails because its fixture counted all Python listeners:
an existing production progress widget also received the local synthetic message.
The corrected fixture uses that actual HUD widget and per-instance counters.
`ProgressDifferential02` passes eleven BP/Python comparisons in 71.211s, 0 exit,
strict ordered logs, frozen input/reference hashes and an inspected/hashed PNG.
It covers owner/foreign/repeated messages, native automatic UMG Tick, matching
duration/text/material/visibility, native game-time pause over 1.109s wall time,
last-second precision/completion, hidden Profile resume without lifecycle replay,
native Destruct and no later callback. Initial StartTime is not equal because
widgets initialize at different times; broadcast synchronizes it before all
countdown comparisons. Final scopes balance 3/3 with zero active/errors.
This is actual production reachability with synthetic typed duration production,
not a native interaction ability or replicated message test.

`ReticleAdapterRegression01` passes six geometry/three typed message comparisons,
actual ADS input and native equipped-shotgun fire 8->5 on the eighteen-node
adapter. Final reticle scopes balance 6/6; its image was inspected (native warning
banner remains). `TransportAdapterRegression01` times out in NullRHI startup,
before executing the fixture, and its owned process is stopped. The offscreen
`TransportAdapterRegression02` passes typed UI/Verb values, legacy signals,
nested-copy isolation, wrong reader/outside-delivery rejection and closed-listener
silence, with closed strict logs and stable hashes. These drivers do not build,
cook or package. Host tests now pass 194.

The optional `AbilityProgressNetwork01` runtime run fails, not accepted:
each phase uses actual production UI plus a hidden BP baseline, synthetic local
Pawn/Controller messages, visible countdown comparisons and native completion.
The Controller is a non-Pawn foreign Instigator fixture, not a remote player.
Native interaction ability and message replication remain explicitly untested.
Eleven phases are recorded, but first-travel readiness times out. Server and
clients load the new map and recover native Health; failed-condition diagnosis
requires finer readiness evidence, not a larger timeout. All owned processes
are stopped. `AbilityProgressNetwork02` adds durable per-client readiness
reason/actual-state history and reproduces the first-travel failure: native
map/player/Health recovers, but both clients have no active production progress
scope. A collapsed reused widget cannot Tick to rearm; OnInitialized is one-shot
and Destruct had cancelled the listener. Python Construct now idempotently
rearms, while the fallback Construct explicitly resumes its cancelled BP proxy
without model or lifecycle replay. Two host tests bring the suite to 196.
`ProgressReconstructRegression01` passes twelve BP/Python cases including
native same-widget remount into a test-owned viewport. Final scopes balance
4/4, zero active/errors, ordered strict closed logs and an inspected/hashed
screenshot. The same Construct rearm fix is now under the complete nineteen-
phase `AbilityProgressNetwork03` retry. Timeout is unchanged; no completed
network, native interaction producer or package claim is made yet.

`AbilityProgressNetwork03` then passes the unchanged nineteen-phase gate with
two clients, restart, two travels and B0 leave/B1 rejoin. Server/A/B0/B1 exit 0
in 288.844/266.404/155.281/71.214s, ordered strict closed logs and frozen hashes.
Final progress scopes balance 0/0, 6/6, 6/6, 2/2 with zero active/errors; local
owner/foreign counters are 0/0, 19/19, 14/14, 3/3. Visible BP/Python countdown
comparisons and native completion are required for every ACK. Twelve PNGs are
hashed; A/B0 join and B1 rejoin progress images were inspected. Known native
Editor/resource-preparation warnings remain. Reticle/host/debug/weapon lanes
also pass on the current eighteen-node adapter, with zero final subscriptions.
No C++ build, cook, package or source publication occurs. Full 0.10, real
interaction ability, remote-player duration producer and packaged acceptance
remain separate; these messages are local synthetic input in multiple processes.

### 0.10-2H failure UI prototype, startup not accepted (2026-10-14 local)

`ability_failure_mixin.py`, its generator and seventeen host tests are present.
`20261014-batch2h/host-tests01.json` passes 213 with a workspace-owned temporary
root. An initial 211-test run has one existing atomic-rename case fail in the
restricted default temporary directory; this failed run is not relabeled as
pass. Policy tests do not prove native FText localization identity, actual
animation callbacks, delay frame timing or the audited deferred BP output model.

`Assets01` exits 0 in 5.976s with empty stdout/stderr and no Unreal log/fixture
JSON. `StartupDiagnostic01` removes the custom UserDir flag, but also exits 0
in 0.814s without those files. No asset authoring occurred and no canonical
failure/transport asset update was copied. The cause is not diagnosed: event
logs and submodule Git metadata cannot be read in the current restricted
environment. No further duplicate launch or permission change is attempted.
Per-process cache/temp paths remain inside the workspace; environment values
are not logged by the shared process helper. Native source/BuildId checks pass,
but do not substitute for initialization, compilation or runtime acceptance.
No C++ build/cook/package, Engine/reference edit or source publication occurred.

The next bounded step prepares (does not execute) a seventeen-case actual
production UI/original-BP fixture and a focused driver. It covers same-reason
no-retrigger, pause/one-second native Outro onset (two-observed-game-frame bound,
maximum 0.15s), natural animation completion, hidden Profile resume, Destruct/
remount, deferred latest foreign payload, persistent callback visible result
and teardown while work is pending. Original OnInitialized is not replayed;
the test-owned baseline resumes only its listener. Its FText is synthetic
display text, not native localized identity or GAS producer acceptance. Dead/
invalid health and multi-client/package lanes still need additional evidence.

`20261014-batch2h/host-tests02.json` passes 223, no failures/errors/skips. Ten new
gate/static checks reject incomplete/reordered or mismatching reports,
unsupported claims, widened/NaN timer bounds and unbalanced final lifetimes.
The new focused PowerShell driver parses without errors.
`fixture-preflight01.json` passes an actual negative preflight against Assets01:
failed authoring is rejected before a runtime output directory is created;
no UE process was launched and none remains. This check is not a runtime pass.
The seventeen-case fixture, asset generation and network acceptance remain
unrun/unaccepted. Git diff checking is unavailable in this execution context
(`this operation must be run in a work tree`), so no Git cleanliness/whitespace
gate is claimed. Mixed changes remain untouched; no publication or heavy build.

### 0.10-2H accepted bounded runtime and native-text checks (2026-10-14)

Restrictions were lifted before these runs. The former pre-log startup results
remain historical failures, not the current blocker. `Assets06` is the clean
authoring gate: ten transport functions / 32 nodes, old six semantic digests
unchanged, original script-Tick flag retained and an empty int32 Linkage native
delay-completion declaration. No Engine/C++ build or official asset edit.

`FailureDifferential01` hit a cold isolated-cache startup timeout; all owned
processes were stopped. Runs 02 and 03 exposed non-equivalent paused timing in
the world-clock and manual UI-delta prototypes. Both were removed in favor of
the actual native UMG latent scheduler via RetriggerableDelay. Run 04 then
exposed the named-output shape `(False,)` mistaken for a bare bool; both policy
and host fake now extract/check the exact shape. None of these runs is a pass.
Run 05 passes 17 comparisons (69.280s), first Outro at 1.000s on both sides,
observed frame 0.016s/tolerance 0.032s and scopes 4/4, zero active/errors. Its
early screenshot contains no visible label and is not visual acceptance.
Run 06 repeats all 17 with visible `UEP resumed` on both sides, opacity 1.0;
the actual PNG was inspected. The cases include native pause/animations,
hidden Profile resume, Destruct/remount, deferred latest foreign payload and
persistent native callback order. The baseline resumes only its old listener,
never replays original OnInitialized.

`TextFixtureAssets01` creates a stage-only four-node native live-table seed
(InputKeys/LeftMouseButton). `NativeCulture01` passes its data gate but deferred
screenshots show swapped language labels. `NativeCulture02` adds separate shot
waits and passes the one-broadcast en/zh-Hans/en comparison in 47.859s; corrected
PNGs were inspected (Left Mouse Button / 鼠标左键 on both widgets). The test
explicitly cancels timers to hold received text. Scopes 2/2, zero active/errors.
This proves native FText localization identity, not native GAS production.
Known native render-thread and translation warnings remain visible.

`host-tests08.json` passes 237 with no failures/errors/skips, including six
new synthetic network contract negatives. These are supporting checks only.
`AbilityFailureNetwork01` has no complete report/driver summary and is recorded
incomplete; no owned processes remained before retry. Network02 passes server/A
19 phases, B0 14 and B1 3, with two travels, rejoin and four normal exits.
Final failure scopes server/A/B0/B1: 0/0, 6/6, 6/6, 2/2; zero active/errors.
Selected A/B0/B1 PNGs were inspected. Messages are locally synthetic and the
foreign case uses a null controller, not remote-player replication. Native
weapons/GAS remain real in the existing network lane. Current ten-function
`TransportAdapterRegression01` passes original UI/Verb copy/rejection/cancel
checks (32.720s); Duration and Failure are exercised by the other lanes.
Native failure producer, dead/invalid health, packaging and whole-version
acceptance remain open.

The active 0.10-2I Dash record is in Examples Migration/PROGRESS.md and
NEXT_DashCooldown.md. Assets01 passes; DashDifferential05 passes 11 comparisons
in 50.422s, scopes 11/11, inspected PNG and 0.00001 material tolerance. Earlier
runs retain a real live-animation teardown bug and fixture failures. The
production UI is a native UIExtension pool entry; viewport lifecycle fixtures
are explicitly separate. DashNetwork01 fails on its second travel with two
active production pool entries. A read-only shared native-membership cleanup
fix has 269 supporting host checks and is currently being retested. No network
pass, native producer, death, package or full batch was implied by that code.

The later `DashDifferential06` repeats all eleven on the membership fix
(50.297s, scopes 11/11, pool watches 2/2, zero active/errors). DashNetwork02
reaches two travels/B0 exit but fails at B1 rejoin on Windows status-file
replacement. Network03 is stopped by host preflight before UE launch; the held-
reader test exposes that os.replace is insufficient on this filesystem.
Delete-sharing readers/ReplaceFileW solve that test, retaining permanent
access errors as failures. Network04 exposes a second-read TOCTOU; per-peer
once-per-frame snapshots now avoid it without using previous-frame data.

`DashNetwork05` passes all nineteen phases, both travels/rejoin and four
normal exits. Final scopes server/A/B0/B1 0/0,14/14,12/12,3/3; Health bindings
0/0,7/7,5/5,1/1; pool watches 0/0,4/4,4/4,1/1. A/B0 each show one native pool
deactivation. No final active/ticker/errors. Selected PNGs inspected; existing
weapon/progress/failure/reticle/host lanes pass together. Durations in this
network lane are local synthetic messages, not native Dash or message RPC.

`NativeDash01` passes native Dash/death steps but fails a fixture's null-owner
assumption; UserWidget falls back to player zero. `NativeDash02` uses native
UnPossess and passes five cases (45.141s), original granted GA_Hero_Dash native
ASC -> 1.5s duration -> production Python/original-BP UI, rejected repeat,
completion, exact-once native death/hidden wrapper and absent-Pawn failure
rejection. Dash/failure scopes 4/4 and4/4, pool watches1/1, no residue/errors.
PNG inspected. No ability/Health/CDO/velocity writes, manual widget events,
lethal damage or physical key claim. Native repeat emits zero user-facing
failure messages, so that producer stays untested. Host-tests12 passes282.

Respawn Assets01 compiles preserved class/CDO and a five-node exact original
animation delegate cleanup; no Engine/reference changes or build/package.
Host tests pass290. RespawnDifferential01 fails before comparisons because
TimeUntilRespawn is a BP function-local, not a UObject field. Policy now uses
a Python local; reports label remaining time as a derived native deadline,
not a read of Blueprint stack storage. Runtime retest is in progress; no full
2J or version acceptance is implied.

## 2026-10-15: approved UE 5.8.1 update and bounded Editor acceptance

Evidence root: `.build/LyraValidation/BlueprintPython/20261015-ue581-acceptance`.
The user approved the official 5.8.1 source/dependency update and matching
Editor build, then explicitly allowed all cores and requested progress updates.
The upstream delta and independent backups precede EditorBuild01: 4,610 actions,
Result Succeeded in 5,714.65s, BuildId `2f7b5df8-1c9a-4414-a598-6d3b022aa38d`.
This is not authorization for custom Engine implementation edits or packaging.

Two full-build deprecation warnings identify UEP's old unsafe package callback.
The Editor path now consumes completed OnEndLoadPackage batches; ordinary
non-Editor discovery still needs a safe replacement and packaged acceptance.
HostBuild02/03 and UEPRefresh01/02 are guarded incremental project/plugin builds,
not another Engine build. The latest protected Engine hashes remain unchanged.

Nameplate testing additionally exposes an old UEP multicast bug: passing the
UObject address to GetMulticastDelegate, which expects the property's value
address. NameplateDifferential05 crashes with bogus access-detector state;
failure evidence is retained. UEP now resolves the value pointer and handles
an empty sparse delegate pointer (sparse runtime coverage is not claimed).
HostBuild03/UEPRefresh02 pass in 25.27/20.62s with zero compiler warnings.
Latest Lyra UEP DLL SHA-256:
`A37911F9105E33A130BE049C93F86911CAD5C2B305CEB04C702CCE8AF5B65555`.

Final-DLL bounded results, all with source/module/input guards and closed logs:

- CallMatrix02: eleven lanes, including native/Python multicast, bad-parameter
  recovery/unsubscribe, shared/standalone signatures, caller, named outputs,
  inheritance, construction forwarding, soft paths and declared exceptions.
- Lifecycle02: three real PIE sessions in one Editor; placed/spawned Actors,
  two Begin/End events per session, closed scopes, native GC and restored routers.
- PackageLoad02: saved Main/Companion BP packages load/discover in a fresh
  process without registration calls; imported-package and fallback/restore proof.
- Transport02: compiled-VM nested copy/owner checks, wrong-reader and
  outside-delivery rejection, idempotent close and no later callback.
- QuickBarDifferential02: twelve production/original-BP cases, nine named
  Python queries, scopes 12/12 and an inspected 1280x720 PNG.
- NameplateDifferential06: fourteen Widget/original-BP cases, scopes 23/23,
  team proxies 13/13, init delegates explicitly removed 10/10, zero residual/
  errors/ensures; inspected PNG. Earlier failures include CompareTeams output
  shape, a released fixture ticker, missing fixture APIs, mismatched resume
  epochs, shutdown-manager availability and the multicast crash. None is erased.
- Network03: nineteen phases, two rendered clients plus dedicated Editor server,
  two travels, B0 leave/B1 rejoin and four normal exits. Existing optional HUD
  gates pass, with final A/B0/B1 quickbar scopes 12/12,12/12,6/6 and queries
  15/8/2; progress scopes 6/6,6/6,2/2. Twenty-four PNGs hashed; selected switched-
  fire/rejoin-respawn frames inspected. The controlled steep aiming frame is not
  free-camera/physical-input proof. Native Editor warning banners remain.

Network01 fails on harness ReplaceFileW WinError 1175, before completing the
scenario. Bounded retry now includes that error without deleting destinations;
partial-replace/unrelated errors remain fatal. Network02 then passes on the
preceding DLL; Network03 is the required final-DLL repeat. The final network
run also passes all 397 host checks; host checks alone are not runtime proof.

Version stays 0.10.0 development. Nameplate Source/Manager component authoring,
native differential and nameplate-specific multiplayer remain open; the next
plan is `Demos/UEPLyraIntegration/Migration/NEXT_NameplateComponents.md`.
No new cooked package, standalone Server target, physical touch, native
interaction producer, replicated duration-message or full-version acceptance
is claimed. No commit, push, tag or release is performed.

## 2026-10-16: per-batch local commit backfill

The user requested coherent modify/verify/commit batches and the same backfill
for earlier completed work. Examples checks now run from the Git index in a
fresh archive plus committed core, so missing unstaged dependencies cannot be
masked by the mixed worktree. Compact per-batch ledgers live at
`Demos/UEPLyraIntegration/Migration/Acceptance/`; they reference raw local
reports and preserve native DLL/report hashes. Models, source provenance and
native gameplay evidence are separate. No push, tag or publication is implied.

Core `6fd3d79` records the verified runtime foundations. Subsequent Examples
commits separate shared HUD/network infrastructure, individual HUD business,
world actors, the shared Widget/Jump/ADS/Emote family and other hero/weapon
abilities. Current-DLL Emote/ADS/shared-Widget report gates pass, while older
Jump and other feature runs stay explicitly historical. The current combined
native HUD report rechecks nineteen phases, two clients, two travels and
leave/rejoin across ten HUD groups using isolated staged modules. Four old
reload-family network gates recheck 36 authority rows each; these checks do not
launch fresh clients or become a current-DLL family rerun.

An old weapon-instance report cannot pass the evolved gate because it lacks
the later `profile` field. Its report is not patched and the gate is not
weakened: a serial current-DLL rifle/shotgun two-owner network rerun is used
instead, at `20261016-batch-backfill`. Keep the pending/failed closeout attempt
and final results distinct. See PROGRESS for observed exits and acceptance;
gameplay markers alone do not pass a batch. No new compile/cook/package or
official Lyra/Engine implementation edit is part of this backfill.

Final backfill outcome: 32 bounded Examples ledgers and separate local commits;
893 isolated Examples checks and full-index closure for 438 Python files pass.
Current-DLL rifle-Network01 and shotgun-Network02 each pass 36 authority trials,
two-owner equipment observations, independent report/log gates and three real
zero exits. Shotgun-Network01 remains a failed 520-second shutdown-timeout run.
Engine source explicitly supports NoDDCCleanup; adding only that process switch
produces a passing fresh retry with D3D12/cases/gates unchanged. This does not
prove all shutdown delays have that cause. Native warnings remain qualified.
Third Person historical fixture hashes and both old normal exits recheck, not
a new 5.8.1 native run. Incomplete held-widget drafts remain uncommitted; full
0.10/0.11/version/package-network gates are still open. Unrelated repository
URL-owner edits are preserved outside this task's staged commits.

## Candidate record template

This is a required future record format, not an implemented manifest generator
or a claim that any candidate has already passed. Copy it per candidate and
replace every placeholder with measured evidence.

| Field | Required record |
| --- | --- |
| Candidate | Version/RC ID, UTC test time and disposition |
| Core source | Full commit, branch/tag, clean-tree status and any documented diff |
| Examples source | Full commit, branch/tag, clean-tree status; core gitlink must match |
| Engine | UE version, source revision/BuildId and target platform |
| Python | Exact version, shared/UEP-owned interpreter mode |
| Build | Editor/Game/server target, Development/DebugGame/Shipping, toolchain and binary hashes |
| Content | Staged script/asset hashes and untouched Engine/reference asset hashes |
| Checks | Every required suite/mode, run ID, pass/fail/skipped result and retained log location |
| Lifecycle | Active-instance counts and final post-exit callback/router/state evidence |
| Visible check | Scenario, screenshot/video location and input/visual acceptance result |
| Artifacts | Package/source archive location and SHA-256; relationship to tested source |
| Limitations | Unsupported paths, untested configurations and outstanding blockers |
| Review | Reviewer, decision and any follow-up candidate required |

A script-only retest must record the actual new scripts and the compatible
native binary provenance. A source change after the candidate invalidates the
affected results. Do not fill a missing field with an unrelated old green run.

## Original call/lifecycle matrix criterion batch266 (2026-10-27)

The checked-in contract now classifies21 call and12 lifecycle paths,with named
reproducers:24 bounded supported,six intentionally rejected,three bypass or
unsupported. Correct the blanket output-parameter rejection to distinguish
explicit non-reference named-output opt-in,and include the already tested
authored Parent Construction virtual-helper route. No runtime behavior changes.

MissingCalls01 refreshes only nine generic cases against SDK236;reuse two current
call cases from258 and native rejection from257. Seven new commandlets exit0;
named-output-negative PID39840 and mixin-exception PID2440 intentionally exit1,
with exclusive expected errors,recovery/original restoration and normal shutdown.
PIE01 PID39448 exits0 after three actual shared-interpreter sessions,with native
GC,closed scopes and original routers restored. Ten new processes;zero compile,
link,cook/package or full regression. Final immutable selected checks22/22 pass.

Historical Third Person,Dash,packaged reload,Explorer and travel/rejoin references
keep their own SDK/configuration scope. Only the exact matrix/reproducer original
criterion is newly accepted. Overall16/22;the other original0.9 conditions and
complete migration/version/package/release acceptance remain open. Official Lyra,
the isolated initialization guard/binaries and six unrelated files are preserved.

## Current Editor candidate components batch267 (2026-10-28)

ThirdPerson01 refreshes both rendered native-input variants against SDK236;
Mixin PID4068 and PythonFirst PID11468 exit0. Six1280x720 images are directly
inspected,with visible characters,map and HUD. Native movement/look/jump and
final teardown pass;PythonFirst also travels once. No pixel/animation/hardware
parity claim. Existing binaries and project-owned metadata are reused.

Five Generic Editor suites prove49 checks:shared/standalone core21 each,two
isolated expected dynamic-exception recovery checks,and Editor/Slate5. The
new selective driver performs no build. Preserve Core01's missing-result
standalone failure and Core02's existing-asset preflight stop;carry forward
only independently rechecked successful component reports. Core03 uses new
UUID-suffixed test assets;the original two files stay byte-identical in place.
Two new test packages and their copies are retained;deletion is still excluded.

Eight pure-gate checks,one driver parse and three invalid-selection checks pass
from an immutable index. Seven native components pass across eight attempts;
both failed capture summaries remain failed. The original Generic six-suite70
contract still lacks current-source packaged21. Complete candidate regression,
RC and full migration remain open;overall16/22. No C++/production policy/asset
changes,compile/link,cook/package or full regression. Official Lyra,the isolated
initialization guard/binaries and six unrelated files retain their fingerprints.

## Current Generic package and clean core70 batch268 (2026-10-28)

The current original Generic Game target required its first UE5.8.1 build:
948 compile actions,one link,one metadata action,parallel2,3872.613 seconds,
zero compiler diagnostics. All produced paths are inside the owned project;
NoEngineChanges guards existing Engine outputs. Native source remains unchanged.
Preserve the optional-library preflight failure that occurred before build start.

Package01 Cook/Pak/archive exits0,but its wrapper fails before runtime because
Pak belongs to STAGE rather than a separate completion marker. Keep the failed
capture/archive and exact old driver. Package02 corrects phase verification,
uses versioned incremental Entry cooking and skips native rebuild. Real Game
PID37948 exits0 and independently passes packaged21 without the earlier
unversioned serialization warning. Its binary matches the actual Game build.

CleanCandidate01 reuses these artifacts and runs all six original suites in one
failure-free candidate record:70/70. Only its two deliberately logged recovery
fixtures exit1;all ordinary processes exit0 and close normally. Six new gate
tests,one driver parse and three preflight rejection checks pass. Full regression
is limited to Generic Win64 Development core;the complete multi-domain candidate
and original migration conditions remain open,16/22. Preserve all unrelated
files,official Lyra and the already authorized isolated initialization guard.

## Controlled reload,PIE,GC and travel cleanup batch269 (2026-10-28)

Accept only the original0.9 controlled reload,PIE,GC and travel cleanup condition.
Weapon01 PID17880 exits0 after42 scenarios (38 BP/Python state comparisons),
four live Profile round trips and three unregister/reload/re-register cycles.
Each cycle constructs a NEW widget,collects the old native object and closes
all subscriptions/scopes/tickers. Four original class routers are restored;
the native message callback/cancellation probe also passes.

WeaponNetwork01's server38612,A22788,B037656 and rejoinedB112304 all exit0.
Nineteen phases cover native fire/reload/exhaustion,slot change,Pawn replacement,
two server travels,client exit/rejoin and continued fire. Both original clients
exercise three scope lifetimes. Final callbacks,HUD bindings,widget references
and weapon samplers are balanced and empty. Reuse current-SDK PIE01 PID39448
after exact frozen source/binary checks:three actual shared-Editor sessions,
native GC,closed scopes and restored routers. No PIE reexecution is claimed.

Twenty-two selected immutable-index checks pass;the network driver independently
passes91 selected host checks and its PowerShell contracts. No compile/link,
cook/package or full regression occurs. Only audit/index/tests and records are
changed. Overall17/22;all246 original candidate paths/order/versions and22 exact
checklist texts remain intact. Network screenshots show gameplay/ammo but retain
TapIDs/invalid-tap warnings in the NoSound fixture;complete visual/audio and
packaged criteria remain open. Preserve official Lyra,the authorized isolated
initialization guard/binaries and six unrelated modified files.

## Visible and current packaged weapon example batch270 (2026-10-28)

Accept only the original0.9 visible and packaged weapon/ammo example condition.
Visible01 PID17164 and the actual packaged LyraGame PID9996 exit0,each passing
42 scenarios (38 paired BP/Python states),native callback cancellation,four live
Profile switches,three new-widget reload/native-GC cycles and pre-exit cleanup.
Direct image review confirms paired ammo text and all three counter styles at
1280x720 and1440x900,without the earlier shader-preparation overlay. Do not
promote this initial presenter comparison to every gameplay visual transition.

The current native Game lacked the already authorized isolated Hero guard and
current SDK changes. UBT exports five owned-project actions before build:three
compiles,one link,one metadata write. Preserve the old Game/receipt first.
GameBuild01 PID39092 exits0 in85.931 seconds with zero compiler diagnostics;
NoEngineChanges is active and Engine/official Lyra remain unchanged. No new
C++ source change is made. The actual current Game SHA is
BEA390FA7C42EC59349F24B14E678AE96CDED0F608DFB303479903D93BF2AEFE.

Avoid recooking unchanged data:all246 original candidates,460 original Overlay
assets and12 runtime maps exactly match the successful prior cook plan. Clone
its immutable archive into fresh Packaged01/Payload,retain old copied Game and
Python directories,and place the current Game plus862 project/two core Python
files in that copy. All original cooked products and source bytes are guarded;
the real inner executable is run,not a bootstrap or Editor. No cook or full
regression occurs. The package preparation tool rejects changed data,stale
native input,escaped paths and existing output before copying.

Reuse and recheck batch269's current-SDK nineteen-phase native owner/replication
and slot/possession-signal protocol. Production sampler native calls are reads;
the presenter sends only local reload input intent and UI updates. Twenty-four
selected immutable-index tests,one driver parse and two preflight rejections
pass. Overall18/22;the Batch1A gameplay visual,candidate,RC and full two-Experience
criteria stay open. Original246/22 scope,existing assets and production policies,
the authorized isolated initialization guard and six unrelated files remain.

## Batch1A visual pairs and native owner comparison batch271 (2026-10-28)

Five actual native operation checkpoints now have directly reviewed paired
presenter views:fire,reload,weapon switch,empty ammo and Pawn replacement.
The explicit test-only adapter creates original BlueprintFallback left/Python
right panels and active-style counters,reading each local player's real native
item. It preserves the actual production HUD and unchanged nineteen-phase
native input/authority/replication producer. No lifecycle replay,ammo/inventory
write,asset authoring or normal-startup change occurs.

Native01's four peers pass the functional protocol,but its switch screenshot
has an obscured original panel. Preserve five raw images,all reports and exact
retired root/stage source copies;do not accept that partial visual result.
Change only three test UI coordinates. Native02 server36384,A12188,B014308 and
rejoinedB137984 all exit0 through19 phases,two travels and client exit/rejoin.
Widget roots close0/0,16/16,12/12 and4/4. Final original HUD/weapon callbacks,
scopes and samplers close normally. Directly inspect all five1280x720 recaptures;
paired ammo and counter values/styles agree. Keep NoSound TapIDs warnings in
logs;no suppression,whole-frame pixel parity,hardware input or audio claim.

Twenty-one selected immutable-index checks,one driver parse and two preflight
rejections pass. Eight new network processes total:four in the retained partial
visual run and four in the accepted recapture. Auxiliary asset audits are
separate. Zero compile/link,cook/package or full regression. Overall19/22;
candidate matrix,RC and full Explorer/TopDownArena acceptance remain open.
All246 original paths/order/versions and22 checklist texts,existing production
policies/assets,official Lyra,the authorized isolated guard/binaries and six
unrelated modified files remain intact.

## Current Third Person Game packages batch272 (2026-10-28)

Both actual packaged Game variants pass the original behavior/lifetime contract:
Mixin PID432 and PythonFirst PID34344 exit0,sharing executable SHA
4559C8EDC048B6F70EFCC3F52248247417637D40E355E6978E16C9B105E99E2D.
The current rendered Editor evidence stays separate. Original migration remains
19/22;candidate aggregation,RC and full Explorer/TopDownArena criteria stay open.

The old Game receipt is5.8.0. UBT invalidates its cache because Build.version and
UBT are newer. Preserve the old Game/receipt,review934 actions with all produced
paths inside the owned project,then build once at parallel2/NoUBA/NoEngineChanges.
Build01 PID4880 exits0 in3616.429 seconds:932 compiles,one link,one metadata write,
zero diagnostics. No C++ source change;both packages reuse this target.

MixinPackage01 fails Cook before runtime because the Editor lacks ResonanceAudio.
Keep the failed output and exact old control;apply the same scoped plugin disable
already used by focused Third Person Editor validation. MixinPackage02 completes
Cook/Stage/Archive and real runtime432,but its wrapper retains a failed status
because the original assertion pins UEP0.7.0. The unchanged compiled descriptor
is0.8.0. MixinReview01 binds only the version predicates to that exact descriptor;
all original behavior/lifetime assertions pass without another native process or
cook. PythonFirstPackage01 then passes directly. Packages compile no native code.

Fix the canonical demo controls to pass the staged descriptor version at all four
smoke/package call sites;retain0.7.0 only as the direct legacy-call default. Keep
all other assertions. Six immutable-index checks use both actual reports and prove
wrong versions and teardown failures still reject. Archive the original runner,
26 original build payload inputs and each variant's mutable stage files. Keep all
prior failed captures and the previous candidate matrix. Preserve gameplay code,
assets,official Lyra,the approved guard/binaries and six unrelated modified files.

## Original candidate matrix aggregate batch273 (2026-10-28)

**Original candidate matrix accepted batch273 (2026-10-28):**
The original0.9 Generic/both Third Person/Lyra candidate criterion is accepted;
overall20/22. Aggregate the existing clean Generic six-suite70/current11call/
three-PIE proof, both rendered current-SDK Third Person Editor captures and both
actual current Game packages. Lyra retains normal no-probe startup, the current
nineteen-phase two-client owner/travel/rejoin protocol, five directly reviewed
Batch1A paired views and the visible/actual packaged42-scenario weapon example.

Recheck actual source, binary, report, log and image fingerprints. Recover the
exact old bytes of three unselected ability/weapon test modules from the recorded
Examples Git parent; identify this as post-execution reconstruction. Both root
and stage input references remain explicit. Only these named test probes may use
the exact archive. Normal/focused weapon production inputs must still match.
Thirty-two immutable-index checks pass, including missing-family, stale-SDK,
missing-Game, ownership/visual/package cells and production-archive rejection.
No new native process, build, cook or broad regression. Full Explorer/TopDownArena
and RC API review remain separate original requirements. Preserve all246 paths,
22 original texts, prior19 accepted criteria, official Lyra and unrelated dirt.
