# Roadmap

Capability milestones, not delivery dates. Review baseline: 2026-09-07.
Implementation, retained test evidence and a published release are separate
states; a version number in the plugin descriptor is not release approval.

The target is Unreal Engine 5.8 with engine-bundled CPython 3.11, without
modifying Engine source or the official Third Person/Lyra reference projects.
Blueprint assets remain useful for authored content and visual primitives;
Python owns the selected behavior, not every native engine subsystem.

## Current status

The latest published tag is `v0.7.0` in both repositories. Development is on
`dev/release-0.8.0`; neither repository has a `v0.8.0` tag. The core default
branch is `master`, the Examples default branch is `main`, and both still
point to 0.7.0. These are review-date facts, not automatic release metadata.

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
is available. 17 Python tests and 28 PowerShell contract tests pass, including
real CPython exit/skip-finalizer cases. A fresh strict HUD audit and current-script
NullRHI Standalone passed on 2026-09-07: one active presenter, then zero final
references and balanced 3/3 controller and 6/6 health subscriptions. UBT repaired
the earlier BuildId mismatch with two metadata-only actions. Integrated `All`,
network, package and visual gates remain open. See
[Validation history](docs/Validation_History.md).

Required exit gates (host checks alone do not close a runtime gate):

- [ ] Restore damage/heal/death presentation and numeric interpolation. Initial
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
- [ ] Add a focused caller-BP regression: another Blueprint calls an Actor
  reference targeting two instances of the same BP class. One profile implements
  the function in Python; the other omits it and reaches the preserved BP.
  Both pass through the shared router and select by target UObject. Assert
  class identity, per-instance counters/side effects, no implicit original call
  after Python success, and restoration after unregister.
- [ ] Record a rendered damage/heal/death/respawn acceptance run. Use native
  Lyra gameplay or an isolated fixture for death; do not broaden the existing
  non-lethal health-delta bridge just to drive this test.
- [ ] After the fixes, rerun current-source host tests, HUD audit, Standalone,
  synchronized server/client, Win64 Development cook/package and packaged
  runtime, plus the rendered check. Retain both repository revisions, binary
  and reference hashes, strict logs and final cleanup evidence.

Non-goals: other combat HUD panels, a general GAS/RPC surface, broad hot reload,
new platform support, or a new native networking authority model. Visual fixes,
caller-BP coverage and current-source Unreal acceptance remain unfinished.

## 0.9.0 — Mixin engineering and one reusable HUD chain

Status: planned; starts after 0.8 closeout.

Goal: make the retained-class model predictable in normal project development,
then exercise the reusable pieces with one weapon/ammo HUD chain.

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

- [ ] A checked-in call/lifecycle matrix labels every path as tested supported,
  intentionally rejected, or bypass/unsupported, with reproducible fixtures.
- [ ] The controlled reload and cleanup tests pass across repeated PIE, GC and
  travel; state, callbacks and router restoration are checked after teardown.
- [ ] A visible and packaged weapon/ammo example proves event-driven updates,
  safe subscription removal and native authority ownership.
- [ ] Generic, both Third Person variants and Lyra pass the candidate regression
  matrix; the missing Mixin Third Person visible gate is closed.
- [ ] The supported API inventory and migration/deprecation rules are ready for
  RC freeze, with no known release-blocking correctness defects.

Non-goals: full QuickBar, reticle, team score, elimination feed and accolades;
RPC/latent support; arbitrary C++ interception; unrestricted hot reload.
The remaining combat HUD is 1.1+ backlog. If it later becomes a pre-1.0
requirement, explicitly plan 0.10 rather than silently enlarging 0.9.

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
API and configurations, not a promise that all Lyra C++/Blueprint logic is Python.

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
A skip flag, an old `full_acceptance: true`, or merely launching a client is
not release approval. Do not regenerate unchanged assets or start a package
for a documentation review.

The plugin repository owns generic binding/runtime APIs; Examples owns demos,
assets and Lyra adapters. Future releases record the Examples commit first,
then the core `Demos` gitlink, and verify both tags against the tested manifest.
Repository separation must not introduce a core dependency on Lyra.

## 1.1+ backlog

Full combat HUD, broader platform/configuration coverage and additional
reflection/networking/hot-reload capabilities are independent proposals. Each
needs a concrete user scenario, bounded ownership and an acceptance contract;
none is implied by 1.0.
