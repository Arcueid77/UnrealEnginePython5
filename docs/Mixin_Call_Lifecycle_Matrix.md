# Mixin call and lifecycle matrix

UE 5.8 / CPython 3.11, Win64 Development. This matrix covers the production
retained-class Mixin router. A tested path does not certify other UE VM opcodes,
signatures, build configurations or direct C++ invocation.

## Calls

| Entry or contract | Classification | Reproducible evidence |
| --- | --- | --- |
| Caller BP compiled before injection -> Actor reference -> virtual target function | Tested supported | `Validation/UEP58Host/Tests/mixin_callsite_validation.py`; two same-class targets use Python or missing-method fallback independently |
| Repeated Python success without executing the original BP | Tested supported | Same caller fixture checks separate BP/Python counters before/after profile swap and unregister |
| Reflected name lookup / `call_function` / native ProcessEvent entry | Tested supported for identified signatures | `mixin_signature_validation.py`: integer return, const struct input, struct return, native event |
| Return plus const array input, including inherited Blueprint owner | Tested supported | Mixin Third Person `interface_probe`: AddInstances and BatchUpdateInstancesTransforms, Python and native fallback |
| Explicit `call_mixin_original` | Tested supported | Signature fixture and Mixin Third Person: preserved native return values and BP input movement |
| Explicit parent/child routers with same-name preserved originals | Bounded 0.11 development support | Dash `generate_mixin_inheritance_probe.py`: literal Object BPs, both registration/unregister orders, owned37/inherited23 originals, class-qualified nested parent return, initializer/teardown and fallback. Does not imply interception of all explicit-parent VM opcodes |
| Profile omits one method from the router union | Tested supported | Caller/signature/Third Person fixtures; the original executes once |
| Python callback raises | Tested supported exception boundary | `mixin_exception_validation.py`: no implicit native broadcast, later profile recovery, original restored on unregister; expected error log is required |
| Python `object.broadcast` -> reflected native multicast -> Python subscriber | Tested separately from Mixin interception | `delegate_broadcast_validation.py`: empty inline delegate, native/Python delivery, bad-parameter rejection/recovery and unsubscribe; the 5.8.1 property-value address fix is required. No sparse-delegate coverage claim |
| Blueprint Enhanced Input -> Character Move/Aim -> Python | Tested supported | Rendered Mixin Third Person native-input smoke, movement/rotation state and screenshots |
| Static functions | Intentionally rejected; runtime tested | Signature fixture rejects KismetSystemLibrary.IsValid and preserves the active router |
| Non-const output/reference parameters | Intentionally rejected; runtime tested | Signature fixture rejects ComputeOutputs; these remain outside production Mixin support |
| Wrong Python argument signature | Intentionally rejected; runtime tested | Signature fixture and Third Person invalid-profile fixture; active registration remains usable |
| RPC and delegate-signature functions | Intentionally rejected; native Editor registration tested | `Validation/UEP58Host/Tests/mixin_rejection_validation.py`: real inherited ServerRestartPlayer RPC and compiled BP dispatcher signature are rejected before callback entry; valid routers remain usable and originals restore. No RPC invocation/network test is implied |
| Native server RPC -> explicitly authored non-RPC body gateway | Bounded Lyra support, not RPC interception | Examples ledger63: unchanged SendInfo Net/reliable/server flags, eight real two-owner native RPC ingresses and two original/Python input stores. Python bypasses only those stores, then rejoins retained Commit/tasks; no receiver replay, raw data/velocity fixture writes or full Dash migration claim |
| Latent functions | Unsupported; native Editor metadata rejection tested | The same rejection fixture tests actual Latent metadata on a test-owned BP function. No general packaged latent interception, cooked-metadata rejection or coroutine semantics are promised |
| Cached original UFunction pointer, explicit-parent/final VM calls, direct native C++ calls | Bypass/unsupported interception | They can avoid the replaced class-map entry. Source boundary, not a universal runtime interception claim |
| Experimental in-place BP body gateway | Experimental, separate API | `blueprint_script_body_validation.py` checks one precompiled caller plus integer/bool out-address writeback. Lyra production profiles do not use it |

## Lifecycle

| Scenario | Classification | Reproducible evidence |
| --- | --- | --- |
| Already placed BP Actor and newly spawned Actor retain their class | Tested supported | Repeated PIE fixture creates an Editor-placed Actor, then a second Actor in each PIE world |
| Construction on newly spawned Actor | Tested supported with prior registration | PIE fixture sees Python UserConstructionScript. A Construction event that already ran is not replayed |
| BeginPlay and EndPlay | Tested supported | Three real PIE sessions in one Editor; two BeginPlay/two EndPlay events per session |
| Per-instance profile, inherited Interface/CDO, fallback, initializer/teardown reentry guards | Tested supported | Mixin Third Person runtime and its parent/child Interface probe |
| Child owns an Interface provider override after compiler removes duplicate Interface descriptors | Bounded 0.11 development support | Dash authoring control accepts owned GetPythonMixinSet plus native Interface implementation, rejects ordinary inherited sibling; original class/signatures restored |
| Live weapon profile Python -> BP -> Python | Tested supported in the weapon fixture | No Construct replay; teardown removes observation and first Python Tick resumes it once |
| Controlled unregister -> module reload -> register -> NEW widget | Tested supported | Weapon fixture, three cycles; explicit native CollectGarbage and stale-wrapper checks |
| Native UObject GC between PIE sessions | Tested supported | PIE Actors become invalid, subscription scopes close and original function identity is restored |
| Blueprint `CollectGarbage` called from Python | Deferred request; wait across an engine frame | Explorer follow mode records distinct request/check frames before asserting old task/Actor release. The call itself is not a synchronous-GC guarantee |
| Observing a Boolean gateway before original graph continuation | Preserve the returned Boolean and defer output sampling | The follow-map observer forwards the existing handler once; its next control frame reads the location updated by the original fallback graph |
| Pawn replacement, two world travels, client exit/rejoin | Tested supported in real Lyra weapon lane | Dedicated server + two independent clients, 19 protocol phases, native inventory/GAS and per-player HUD comparisons |
| Arbitrary live BP recompile, changed reflected signatures, generated-class replacement, automatic state migration | Unsupported | Unregister before controlled BP authoring. Restart for generated type/signature changes |

## Running the fixtures

The focused drivers reuse marked, already built stages and check source/module
parity. Run them with PowerShell 7 and fresh output directories:

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
