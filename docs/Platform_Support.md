# Platform support and readiness

## Target and evidence status

UnrealEnginePython 0.8.0 is an unreleased candidate targeting Win64, Unreal
Engine 5.8 and engine-bundled CPython 3.11. Historical runs used UE 5.8.0 and
CPython 3.11.8; they do not validate every change in the current checkout.
The core gate compiles Editor and Game plugin targets, runs shared and
UEP-owned interpreters, runs full editor tests,
cooks a Development package and executes the packaged game. The Lyra gate adds
strict content readiness, Standalone gameplay, synchronized dedicated-
server/client authority and replication, full Win64 BuildCookRun and packaged
Experience/Pawn/Input/ASC/Health validation plus the bounded Python-driven GAS
damage, authority rejection, replication and restoration slice. The 0.8 gate
also exercises the retained-class Python Healthbar presenter across Pawn
replacement, Experience-owned widget action teardown/recreation, repeated
travel and dedicated-server zero-UI behavior.

Historical 0.8 result `20260903-033426` passed the then-implemented `All` lane with
`full_acceptance: true`. Standalone, the synchronized client and the packaged
game each observed Health `100 -> 90 -> 100`, 3 widget Constructs and 2
Destructs with balanced delegates; the dedicated server created no HUD state.
BuildCookRun and packaged runtime exited 0, strict logs passed, and archived and
stable tested executable hashes matched.

That Development run used NullRHI and contains `hud_audit: null`; it does not
prove rendered visual parity or the corrected release contract. The closeout
code adds exactly-one presenter and post-exit zero-owned-callback checks, but
they now have host tests and a current-script NullRHI Standalone pass. A fresh
full real-runtime run is still required. See
[the roadmap](../ROADMAP.md) and [Validation history](Validation_History.md).

The first 2026-09-07 read-only Editor audit attempt could not launch the project:
the engine manifest BuildId was `91898095-bb6d-4da0-9340-28669c3653b3`, while
the staged plugin and multiple Engine plugins used
`160ea5ae-f247-4a72-996b-dea22b186e2f`. Matching source files alone does not make
those binaries compatible. A guarded UBT preflight subsequently found only
metadata actions outdated; official UBT updated the manifests/receipt in two
actions and retained the engine's current BuildId. No manual GUID override or
C++ compile was used. The fresh strict audit and Standalone then passed, with
final zero HUD presenters/references and balanced owned subscriptions. These
focused runs do not establish package, network, rendered or release acceptance.

| Win64 configuration | Evidence at the 2026-09-07 review |
| --- | --- |
| Development | Historical Editor/Game/package results below; current 0.8 release gates open |
| DebugGame | Accepted by the generic driver, but no retained validation established |
| Shipping | No retained validation; current generic driver does not expose this configuration |

A production-game 1.0 support claim requires a dedicated Shipping gate during
RC. Until then, Development evidence must not be described as Shipping support.

The historical generic Win64 result `20260812-043408` (2026-08-12) passed 70/70 shared,
standalone, exception-boundary, Editor/Slate and packaged-runtime checks; its
Development BuildCookRun completed with UAT ExitCode 0.
This is not a newly run 0.8 generic matrix.

The historical Lyra result `20260812-051532` passed the complete `All` lane for named
release-code commit `c797d56` and reported `full_acceptance: true`, including
synchronized client/server evidence and a 4,046-package Win64 BuildCookRun.

The 0.5 Lyra result `20260812-234501` passed the expanded `All` lane with
`full_acceptance: true`: Standalone and packaged processes proved exact Health
`100 -> 90 -> 100`, the client proved `RejectedNotAuthority`, both network
roles observed server replication, UAT returned ExitCode 0, and the tested
executable hashes matched. All runtime processes exited 0 with zero strict
fatal/assert/`Log*: Error` diagnostics.

The 0.5 target-selector hardening then passed exact-source Network result
`20260813-005436` and Standalone result `20260813-005835`; both use UE 5.8.0,
CPython 3.11.8 and the same `100 -> 90 -> 100` contract with clean logs. No
package was rebuilt for that final 0.5 tree, so `20260812-234501` is historical
package-level evidence for the earlier slice, not an exact-tree package claim.

No Unreal Engine source change is required or permitted by these workflows.

## Linux lane

`Validation/Run-UEP58LinuxValidation.sh` is a real build/runtime lane for a
Linux UE5.8 installation. It compiles the Editor plugin and a foreign UnrealGame
plugin target, then executes the core suite with both interpreter owners. The
GitHub workflow requires a self-hosted runner labelled `linux` and
`unreal-engine-5.8`, with `UE_ENGINE_ROOT` configured as a repository variable.

A checked-in lane is not proof that Linux works. Linux becomes release-validated
only after its `summary.json` and logs are retained as a green artifact.

## Historical local readiness and recheck

Readiness result `20260811-154243` reported Linux as not ready for the Win64
UE5.8 installation at `F:\UnrealEngine` and identified
`v26_clang-20.1.8-rockylinux8` as the required SDK. UEP does not
install that SDK or alter the engine tree automatically.

Recheck without changing the SDK:

```powershell
.\Validation\Test-UEP58PlatformReadiness.ps1 -Platform Linux
```

Use `-Strict` in CI when missing readiness must return a failure code.

Mac, LinuxArm64, Android and console platforms have no 0.8.0 release-level
runtime result and are not included in the support claim.
