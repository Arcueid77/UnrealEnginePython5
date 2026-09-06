# Validation history

Historical milestones and retained result identifiers, separated from the
[current roadmap](../ROADMAP.md). Reviewed on 2026-09-07.

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
- The current validator accepts two active presenters if its count/balance
  checks otherwise agree, and records success before quit. Thus the existing
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
