# Lyra Python HUD foundation for 0.8.0

The unreleased UEP 0.8.0 candidate moves the event/subscription behavior of
Lyra's existing health bar into Python without
replacing `ALyraHUD`, bypassing CommonUI, changing the widget class, or editing
the Lyra/Engine source trees. The disposable validation stage overlays a
configured copy of `/Game/UI/Hud/W_Healthbar`; the live object is still
`W_Healthbar_C` and is still created and removed by Lyra's Game Feature
`Add Widgets` action.

Data updates and lifecycle hooks are implemented; damage/heal/death visual
parity and release acceptance remain incomplete. The [roadmap](../ROADMAP.md)
defines the remaining work, not an already-passed contract.

## Ownership boundary

| Concern | Owner in 0.8.0 |
| --- | --- |
| HUD layout, CommonUI layers and widget creation/removal | Lyra Game Feature actions |
| Health authority, Gameplay Effects and replication | Lyra GAS and `ULyraHealthComponent` |
| Widget `Construct`/`Destruct`, controller and health subscriptions | Python mixin presenter |
| Current-pawn selection and rebinding after possession changes | Python mixin presenter |
| Health normalization and refresh timing | Python mixin presenter |
| Dynamic materials, bar animation and numeric widget primitives | Retained `W_Healthbar` Blueprint functions; Python animation/interpolation orchestration still needs parity fixes |
| Dedicated-server UI | None; the acceptance contract requires zero widget/presenter instances |

The presenter is intentionally narrow. It reads replicated health and invokes
Lyra's existing visual helper functions; it does not set attributes, activate
an Experience, grant abilities, replace input mappings, or move gameplay
authority to Python. The bounded 0.5 health-delta bridge remains responsible
for producing the validation sequence through Lyra's native Gameplay Effects.

## Mixin declaration and selection

The Examples repository owns two overlay assets:

- `/Game/UI/Hud/W_Healthbar`, a same-path copy of the official widget with
  `UEPPythonMixinInterface` and the `PythonMixinProfile` selector added;
- `/Game/UEPMixins/DA_LyraHealthbarMixin`, whose `Python` and
  `BlueprintFallback` profiles point to the two presenter classes.

The default `Python` profile replaces the widget's reflected `Construct` and
`Destruct` functions at runtime. `BlueprintFallback` calls the preserved
Blueprint `Construct`, providing a per-instance escape hatch without changing
the object's Unreal type. The original Blueprint graphs remain in the copied
asset and are restored when the router unregisters.

The assets are generated only in a marker-protected disposable copy of Lyra:

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -OutputRoot F:\UnrealEnginePython5\.build\LyraValidation\HUD08 `
    -Mode GenerateHUDAssets `
    -Incremental
```

The generator resets the disposable stage to the official health-bar package,
creates a fresh Mixin DataAsset, compiles and saves both staged assets, then
copies only those two verified files into the Examples overlay. It compares
the SHA-256 of the reference `W_Healthbar.uasset` before and after and never
writes to `F:\LyraStarterGame` or `F:\UnrealEngine`. Unreal package-save
metadata is generation-specific, so acceptance checks semantic configuration
and runtime behavior rather than requiring byte-identical generated uassets.

## Runtime sequence

1. `ue_site.py` skips all runtime registration in Cook and other commandlets.
2. A launched game loads the staged `W_Healthbar_C` and registers the Mixin Set
   declared by its Interface.
3. Lyra activates its normal Experience and Game Feature action, which creates
   `W_Healthbar_C` through CommonUI.
4. The routed `Construct` keeps the exact callback objects required for later
   unbinding, creates Lyra's dynamic materials through the existing Blueprint
   helper, subscribes to `APlayerController.OnPossessedPawnChanged`, then binds
   the current Pawn's `OnHealthChanged` and `OnMaxHealthChanged` delegates.
5. Python reads health/max health, clamps the normalized value, updates the
   widget state and calls the existing Blueprint visual primitives.
6. A possession change unbinds the old Health Component before binding the new
   one. `Destruct`, router teardown and interpreter shutdown all clear health
   and controller delegates before releasing presenter state.

No Tick poll drives the health bar. The initial render is explicit; later
updates are caused by Health Component or possession delegates.

## Required acceptance contract (Unreal closeout still pending)

The 0.8 full-content lane must prove all of the following on UE 5.8 and the
engine-bundled CPython 3.11. This is the target contract, not a statement that
every item has passed on the current source:

- 17 host-side presenter/bootstrap/shutdown tests cover source-only asset absence,
  exact callback identity, event-driven rendering, Pawn replacement, Blueprint
  fallback, Destruct, registry teardown and final Python exit, plus 28 PowerShell
  positive/negative acceptance checks before an Unreal process is launched;
- generation preserves the untouched reference widget, while the read-only
  audit proves that the staged copy declares the expected Interface, Mixin Set,
  selector, profiles, reflected state and ShooterCore `Add Widgets` shape;
- Standalone and a network client observe the real replicated
  `100 -> 90 -> 100` sequence from delegate callbacks, and a separate rendered
  run verifies damage/heal/death/respawn visuals and numeric interpolation;
- an authority-driven Pawn restart replaces the Pawn and produces exactly one
  active binding to the new Health Component;
- a first same-map Experience replacement drives the real
  `LAS_ShooterGame_StandardHUD` `Add Widgets` deactivation/activation path,
  tears down the old widget and reconstructs one clean presenter;
- a second independent same-map travel repeats teardown/reconstruction, so a
  client must finish with at least three Constructs, two Destructs and one
  balanced active presenter;
- a dedicated server records zero health-bar constructs, subscriptions or
  health presentation events;
- explicit widget destruction, mixin teardown and Python shutdown leave no
  stale callback balance; and
- strict logs contain no compiler, fatal, assertion, unhandled-exception or
  unexpected `Log*: Error` diagnostics.

Current closeout gaps:

- HUD-enabled `All` now calls `HUDAudit` and requires its passed result. The
  former audit-mode-only behavior is historical; the integrated path still
  needs a current-source Unreal run.
- Probe/driver checks now require exactly one active presenter. Report schema 5
  writes `awaiting_shutdown` first and finalizes from Python `atexit`, after
  Mixin pre-exit cleanup, with a separate `shutdown.hud` snapshot. The driver
  checks zero final owned callbacks/references and ordered exit markers after
  process completion. Host negative tests and the actual UE Standalone exit
  path pass on the current scripts; synchronized network/package validation
  remains outstanding.
- The presenter currently calls `InitializeBarVisuals` and then numeric
  `SetCurrentValue` on updates. Correct damage/heal/death animation selection and
  interpolation remain to be implemented and visibly checked.
- After fixing these gaps, repeat current-source full and rendered acceptance.
  Use native Lyra gameplay or an isolated fixture for lethal/death coverage;
  do not expand the non-lethal bridge's authority for test convenience.

Existing cleanup paths and historical cleanup logs are real evidence; these
gaps do not establish a current leak. The 17 Python tests use fake reflected
objects and real CPython-only subprocess exits, not a running Unreal game.
The first 2026-09-07 Editor attempt failed on mismatched module BuildIds. After
UBT's metadata-only repair, a fresh strict audit and current-script NullRHI
Standalone passed. Active presenter/reference counts were 1/1; after Python
exit both were 0, controller bindings were 3/3 and health bindings 6/6. No C++
compile, cook/package or asset save was performed. The integrated `All` path
and rendered parity still need their own evidence.

A fresh staged Lyra tree has no asset-registry cache. Before multi-process
runtime tests, the driver completes one headless Editor scan and retains the
resulting read-only cache. This prevents two `Editor -game` processes from
competing over an uncached initial Lyra scan before the client can service its
network handshake. The cache path and byte counts are recorded in the run
summary.

Run the existing combined runtime/package lane with:

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -Mode All
```

`All` includes a full Win64 cook/package and can take substantially longer
than `Standalone` or `Network`. HUD-enabled `All` includes the audit, but rendered
visual acceptance still needs its own check. Do not equate a green summary with
release approval; the updated combined lane has not yet passed in Unreal.
Use the narrower modes during iteration.

## Retained historical evidence

- HUD audit `20260903-032632`: the official action set has one
  `GameFeatureAction_AddWidgets`, 1 layout entry and 11 widget entries.
- Clean-base asset generation `20260903-033001` and `20260903-033049`: both
  pass the same `W_Healthbar_C`, `Python` default, two-profile and selector
  postconditions; the reference package hash remains unchanged.
- Full run `20260903-033426`: `full_acceptance: true` on UE 5.8.0 and CPython
  3.11.8. Standalone, network client and packaged game each report the real
  `100 -> 90 -> 100` sequence, 3 Constructs and 2 Destructs; the dedicated
  server reports zero HUD state. BuildCookRun and packaged runtime exit 0,
  strict logs pass, and archived/tested executable hashes match.

The complete run was NullRHI/headless, has `hud_audit: null`, and did not open
a visible manual client. Its `full_acceptance` field records the checks of that
driver version, not the revised contract. It predates the final source-only
bootstrap fix/seventh test and is Development-only, not DebugGame or Shipping
evidence. See [Validation history](Validation_History.md).

## Deliberate boundary

0.8.0 targets only the health bar and lifecycle foundation. 0.9 prioritizes
Mixin engineering, one weapon/ammo HUD chain and a bounded reusable Gameplay
Message subscription surface. Full QuickBar, reticle, team score, elimination
feed and accolades are 1.1+ backlog. The runtime Mixin API retains the 0.7
restrictions documented in [Mixin_API.md](Mixin_API.md).
