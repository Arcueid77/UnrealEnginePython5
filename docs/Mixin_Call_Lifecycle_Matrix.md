# Mixin call and lifecycle matrix

UE 5.8 / CPython 3.11, Win64 Development. This matrix covers the production
retained-class Mixin router. A tested path does not certify other UE VM opcodes,
signatures, build configurations or direct C++ invocation.

## Calls

| ID | Entry or contract | Classification | Reproducible evidence |
| --- | --- | --- | --- |
| C01 | Caller BP compiled before injection -> Actor reference -> virtual target function | Tested supported | `Validation/UEP58Host/Tests/mixin_callsite_validation.py`; two same-class targets use Python or missing-method fallback independently; proof group `callsite` |
| C02 | Repeated Python success without executing the original BP | Tested supported | Same caller fixture checks separate BP/Python counters before/after profile swap and unregister; proof group `callsite` |
| C03 | Reflected name lookup / `call_function` / native ProcessEvent entry | Tested supported for identified signatures | `mixin_signature_validation.py`: integer return, const struct input, struct return, native event; proof group `signature` |
| C04 | Return plus const array input, including inherited Blueprint owner | Tested supported | Mixin Third Person `interface_probe`: AddInstances and BatchUpdateInstancesTransforms, Python and native fallback; proof group `third-person` |
| C05 | Explicit `call_mixin_original` | Tested supported | Signature fixture and Mixin Third Person: preserved native return values and BP input movement; proof group `signature` |
| C06 | Explicit parent/child routers with same-name preserved originals | Tested supported within the bounded 0.11 fixture | Dash `generate_mixin_inheritance_probe.py`: literal Object BPs, both registration/unregister orders, owned37/inherited23 originals, class-qualified nested parent return, initializer/teardown and fallback. Does not imply interception of all explicit-parent VM opcodes; proof group `inheritance` |
| C07 | Profile omits one method from the router union | Tested supported | Caller/signature/Third Person fixtures; the original executes once; proof group `callsite` |
| C08 | Python callback raises | Tested supported exception boundary | `mixin_exception_validation.py`: no implicit native broadcast, later profile recovery, original restored on unregister; expected error log is required; proof group `exception` |
| C09 | Python `object.broadcast` -> reflected native multicast -> Python subscriber | Tested supported as ordinary reflected multicast, outside Mixin interception | `delegate_broadcast_validation.py`: empty inline delegate, native/Python delivery, bad-parameter rejection/recovery and unsubscribe; the 5.8.1 property-value address fix is required. No sparse-delegate coverage claim; proof group `delegate` |
| C10 | Blueprint Enhanced Input -> Character Move/Aim -> Python | Tested supported | Rendered Mixin Third Person native-input smoke, movement/rotation state and screenshots; proof group `third-person` |
| C11 | Static functions | Intentionally rejected; runtime tested | Signature fixture rejects KismetSystemLibrary.IsValid and preserves the active router; proof group `signature` |
| C12 | Non-const reference parameters, or outputs without explicit named-output opt-in | Intentionally rejected; runtime tested | Signature fixture rejects unmarked ComputeOutputs. Non-const references remain rejected; the explicit non-reference output extension is C19, with C20 rejection/recovery checks; proof group `signature` |
| C13 | Wrong Python argument signature | Intentionally rejected; runtime tested | Signature fixture and Third Person invalid-profile fixture; active registration remains usable; proof group `signature` |
| C14 | RPC and delegate-signature functions | Intentionally rejected; native Editor registration tested | `Validation/UEP58Host/Tests/mixin_rejection_validation.py`: real inherited ServerRestartPlayer RPC and compiled BP dispatcher signature are rejected before callback entry; valid routers remain usable and originals restore. No RPC invocation/network test is implied; proof group `rejection` |
| C15 | Native server RPC -> explicitly authored non-RPC body gateway | Tested supported through the authored Lyra gateway; RPC interception remains rejected | Examples ledger63: unchanged SendInfo Net/reliable/server flags, eight real two-owner native RPC ingresses and two original/Python input stores. Python bypasses only those stores, then rejoins retained Commit/tasks; no receiver replay, raw data/velocity fixture writes or full Dash migration claim; proof group `rpc-gateway` |
| C16 | Latent functions | Intentionally rejected by native Editor metadata validation | The same rejection fixture tests actual Latent metadata on a test-owned BP function. No general packaged latent interception, cooked-metadata rejection or coroutine semantics are promised; proof group `rejection` |
| C17 | Cached original UFunction pointer, explicit-parent/final VM calls, direct native C++ calls | Bypass/unsupported interception | They can avoid the replaced class-map entry. Source boundary, not a universal runtime interception claim; proof group `source-boundary` |
| C18 | Experimental in-place BP body gateway | Bypass/unsupported by production Mixin; separately tested experimental API | `blueprint_script_body_validation.py` checks one precompiled caller plus integer/bool out-address writeback. Lyra production profiles do not use it; proof group `experimental` |
| C19 | Explicit non-reference named-output opt-in on a retained-class Mixin function | Tested supported for the named fixture signatures | `mixin_named_output_validation.py` uses a Boolean `uep_named_outputs=True` marker, precompiled BP calls, native entry, explicit original, missing-method fallback, native return plus named outputs and unregister restoration. This does not relax RPC/latent/reference rejection or prove packed Boolean layouts; proof group `named-outputs` |
| C20 | Invalid named-output marker, dictionary, missing output or extra key | Intentionally rejected; runtime tested | The same fixture's negative mode requires actual conversion/rejection diagnostics, valid-profile recovery and original restoration; no implicit original BP fallback after a bad Python result; proof group `named-outputs` |
| C21 | Authored child Parent Construction -> virtual body helper -> parent Mixin router | Tested supported for the explicit forwarding fixture | `mixin_construction_forwarder_validation.py` preserves the original body and class, routes through the authored virtual helper, rejects invalid helper names and restores the Profile/router. It does not intercept arbitrary explicit-parent VM calls; proof group `construction-forwarder` |

## Lifecycle

| ID | Scenario | Classification | Reproducible evidence |
| --- | --- | --- | --- |
| L01 | Already placed BP Actor and newly spawned Actor retain their class | Tested supported | Repeated PIE fixture creates an Editor-placed Actor, then a second Actor in each PIE world; proof group `pie` |
| L02 | Construction on newly spawned Actor | Tested supported with prior registration | PIE fixture sees Python UserConstructionScript. A Construction event that already ran is not replayed; proof group `pie` |
| L03 | BeginPlay and EndPlay | Tested supported | Three real PIE sessions in one Editor; two BeginPlay/two EndPlay events per session; proof group `pie` |
| L04 | Per-instance profile, inherited Interface/CDO, fallback, initializer/teardown reentry guards | Tested supported | Mixin Third Person runtime and its parent/child Interface probe; proof group `third-person` |
| L05 | Child owns an Interface provider override after compiler removes duplicate Interface descriptors | Tested supported within the bounded 0.11 fixture | Dash authoring control accepts owned GetPythonMixinSet plus native Interface implementation, rejects ordinary inherited sibling; original class/signatures restored; proof group `inheritance` |
| L06 | Live weapon profile Python -> BP -> Python | Tested supported in the weapon fixture | No Construct replay; teardown removes observation and first Python Tick resumes it once; proof group `weapon` |
| L07 | Controlled unregister -> module reload -> register -> NEW widget | Tested supported | Weapon fixture, three cycles; explicit native CollectGarbage and stale-wrapper checks; proof group `weapon` |
| L08 | Native UObject GC between PIE sessions | Tested supported | PIE Actors become invalid, subscription scopes close and original function identity is restored; proof group `pie` |
| L09 | Blueprint `CollectGarbage` called from Python | Tested supported as a deferred request; wait across an engine frame | Explorer follow mode records distinct request/check frames before asserting old task/Actor release. The call itself is not a synchronous-GC guarantee; proof group `follow` |
| L10 | Observing a Boolean gateway before original graph continuation | Tested supported with the returned Boolean preserved and output sampled next frame | The follow-map observer forwards the existing handler once; its next control frame reads the location updated by the original fallback graph; proof group `follow` |
| L11 | Pawn replacement, two world travels, client exit/rejoin | Tested supported in real Lyra weapon lane | Dedicated server + two independent clients, 19 protocol phases, native inventory/GAS and per-player HUD comparisons; proof group `travel` |
| L12 | Arbitrary live BP recompile, changed reflected signatures, generated-class replacement, automatic state migration | Bypass/unsupported | Unregister before controlled BP authoring. Restart for generated type/signature changes; proof group `source-boundary` |

## Running the fixtures

The focused drivers reuse marked, already built stages and check source/module
parity. Run them with PowerShell 7 and fresh output directories:

The call matrix accepts `-TestName` for an affected subset. Omitting it keeps
the original eleven cases. Unknown or duplicate names fail before staging or
launching a native process. For example:

```powershell
& .\Validation\Run-UEP58FocusedCallMatrixValidation.ps1 `
  -StageProject F:\UnrealEnginePython5\.build\Validation\UEP58Host\UEP58Host.uproject `
  -OutputDirectory F:\UnrealEnginePython5\.build\Validation\Results\Calls-NewRun `
  -TestName @('signature-standalone', 'delegate-broadcast')
```

```powershell
.\Validation\Run-UEP58FocusedLifecycleValidation.ps1 `
  -StageProject F:\UnrealEnginePython5\.build\Validation\UEP58Host\UEP58Host.uproject `
  -OutputDirectory F:\UnrealEnginePython5\.build\Validation\Results\PIE-NewRun

.\Validation\Run-UEP58FocusedThirdPersonValidation.ps1 `
  -NativeProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
  -OutputDirectory F:\UnrealEnginePython5\.build\Validation\Results\ThirdPerson-NewRun
```

Signature/body/caller fixtures run through the Py commandlet with their required
result arguments. Exception fixtures use a separate process: UE may exit 1
because it counts the deliberately logged traceback. Accept only the declared
exception marker, complete report, recovery evidence and normal shutdown.

## Proof groups and scope

The stable C01-C21/L01-L12 rows use exactly three contract categories. A bounded
supported row promises only its named signature and fixture. An intentionally
rejected row proves rejection and recovery. A bypass/unsupported row records an
excluded contract; it does not promise a universal interception fixture.

`audit_call_lifecycle_matrix_acceptance.py` maps every proof group to exact,
checked-in fixture paths and hashes. The generic groups use
`Validation/UEP58Host/Tests/`: `callsite` -> `mixin_callsite_validation.py`,
`signature` -> `mixin_signature_validation.py`, `exception` ->
`mixin_exception_validation.py`, `delegate` -> `delegate_broadcast_validation.py`,
`rejection` -> `mixin_rejection_validation.py`, `experimental` ->
`blueprint_script_body_validation.py`, and `pie` -> `mixin_pie_validation.py`.
`named-outputs` uses `mixin_named_output_validation.py` in positive and negative
modes; `construction-forwarder` uses `mixin_construction_forwarder_validation.py`.

The supplemental groups retain their original execution scope:

- `third-person`: Mixin `interface_probe.py`, `smoke.py` and `character_mixin.py`;
  ledger217 NativeFixed05. This is historical Third Person SDK evidence.
- `inheritance`: `generate_mixin_inheritance_probe.py` and
  `dash_selector_probe_policy.py`; ledger62 Assets06. Both router orders and
  original restoration are bounded to those owned/inherited functions.
- `rpc-gateway`: `generate_dash_rpc_input_assets.py` and
  `dash_rpc_input_contract.py`; ledger63 Network02. The RPC itself stays native.
- `weapon`: `weapon_validation.py`, `Run-UEP58PackagedWeaponHUDValidation.ps1`
  and `LyraHUDContracts.ps1`; ledger211
  PackagedWeaponHUD01. Controlled reload constructs NEW widgets; its packaged
  executable is historical and is not the current Editor candidate.
- `follow`: `explorer_follow_validation.py` and `explorer_follow_contract.py`;
  ledger231 Python03DeferredGC. Deferred GC and next-frame readback remain
  explicit engine-frame boundaries.
- `travel`: `uep_lyra_weapon_protocol.py` and the weapon network driver; the
  nineteen-phase CombinedNetwork01 record covers two travels and owner rejoin.
- `source-boundary`: `UEPyMixin.cpp` and `PythonFunction.cpp` implement the
  reflected class-map router. The callsite fixture supplies the preserved-original
  control. Cached original pointers/direct C++/other VM dispatch remain excluded;
  arbitrary recompile/signature changes require controlled unregister or restart.

Batch266 combines the two current-SDK call cases from ledger258 with only the
nine missing current-SDK cases in `20261027-call-lifecycle-matrix/MissingCalls01`.
The same batch's PIE01 records three sessions in one current-SDK Editor. No new
compile or cook is required. The supplemental historical records are pinned
references; they are not recertified as current SDK/configuration executions.
This matrix criterion does not by itself accept the other 0.9 release criteria.
