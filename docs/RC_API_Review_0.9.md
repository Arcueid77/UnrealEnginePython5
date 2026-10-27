# 0.9 API freeze review

Status: ready for the original 0.9 API freeze within the supported inventory.
Batch273 accepts the independent candidate matrix. This review does not create
a tag or publication. The supported candidate is UE 5.8 / CPython 3.11,
Win64 Development.

The [supported inventory](Supported_API_Inventory.md) describes capabilities
within their tested boundaries. Legacy wrappers outside that inventory do not
gain a compatibility or correctness certification from this review.

| Surface | Evidence and boundary |
| --- | --- |
| Interpreter | Batch268: a clean Generic shared/standalone, expected exception, Editor and real packaged run passes70 checks. Finalize only the owned interpreter. |
| UObject reflection | Batch268 core21 in each supported interpreter/runtime mode covers the documented property and reflected-call cases. This is a fixture/type inventory, not every possible UFunction signature. |
| Lazy soft-class input | Batch266 current call fixtures distinguish null, loaded class and validated path inputs, reject malformed paths and avoid implicit loading. No new soft-reference getter promise. |
| Dynamic types | Generic core and batch266 repeated PIE cover the documented transient types and lifecycle. Names remain unique for the process; restart for generated signature/type replacement. |
| Production Mixin | Batch266 classifies33 call/lifecycle paths. Batches269/271 verify controlled restoration, native GC and two-owner travel. Cached/direct native calls and arbitrary recompile remain explicit bypasses. |
| Delegates and Enhanced Input | Current generic boundary runs258, three PIE sessions266 and visible Third Person267 cover the bounded callables, handles, input and cleanup paths. UObject operations stay on the game thread. |
| Runtime subscriptions | Batches269/270/271 cover native slot/possession signals, read-only sampled changes and cancellation. Typed message delivery requires its supplied verified VM reader; no generic wildcard ProcessEvent access. |
| Actor, World and exit | Generic core, scoped ability/world comparisons and batch271 actual native travel/rejoin retain native authority and request orderly shutdown. No universal network stability claim. |
| World lookup convenience | The inventory explicitly limits get_world to World, Actor and ActorComponent. Explorer's reflected context operations do not expand this convenience API to arbitrary UObject types. |
| Editor, assets and Slate | Batch268's fresh Editor5 retains its actual Editor-only boundary. Unique test assets are retained with their evidence rather than deleting or reusing prior files. |
| Construction extraction | Batch266's Editor-authored zero-parameter Actor clone/virtual helper is explicit authoring support. It does not intercept every Parent or native path. |
| Experimental BP body scripting | Batch266 tests a separate bounded int/bool fixture. It is excluded from production Mixin support and the RC stability promise. |

The numbered ledgers are in
[Migration/Acceptance](../Demos/UEPLyraIntegration/Migration/Acceptance).
Each retains its own execution configuration, source/binary fingerprints and
limits. A reference here does not turn an older capture into a new runtime run.

## Source table compatibility check

Compare the continuation checkpoint `e1199d2b02937bbddb947d660916a2c5c6b55464`
with the current source tables in
[UEPyModule.cpp](../Source/UnrealEnginePython/Private/UEPyModule.cpp).
The module table retains213 entries and the UObject method table retains462.
Names, function expressions and method flags are unchanged in both tables.

This checks the source registration tables, including their conditional entries.
It does not certify every legacy wrapper, C++ ABI, argument conversion, behavior
or platform. The native regression evidence supplies the supported behavior
checks; the source comparison alone cannot replace them.

## Migration and deprecation decisions

Keep register_mixin and the mixin decorator as compatible single-profile forms.
Named profiles and Mixin Sets add selection without replacing the generated BP
class. A successful or exceptional Python callback must not silently fall
through to the original BP body. The call matrix records explicit composition,
fallback, intentionally rejected signatures and native bypasses separately.

Close subscriptions and unregister before controlled reload or asset authoring.
Recreate widgets when new lifecycle events are needed; registration never
replays events. Native GC requests cross an engine frame before lifetime is
measured. Generated types or signatures require a process restart.

No public method-table entry is removed by this candidate. A future deprecation
must name the old API, replacement, affected examples and removal version, with
a compatibility path until that version. Experimental surfaces cannot silently
become a supported gameplay dependency.

## Known correctness findings and disposition

The bootstrap temporary UTF-8 conversion lifetime defect is fixed in SDK236.
Current candidate cells use its exact Editor SDK, or Games built from the same
current native source. Both actual Third Person Game variants are verified in
batch272; the old5.8.0 product is retained only as historical evidence.

The Lyra simulated-proxy initialization race is an external game-C++ finding.
The accepted candidate requires the user-approved isolated eight-line Hero
initialization guard from batch246. That batch records twelve guarded waits,
forty authority interactions, eighty viewer checks and no canonical ready Pawn
with empty bindings. Current native weapon/network acceptance retains the guard.
The official Lyra source remains unpatched and its original finding remains
open; this review does not claim that an unpatched checkout satisfies the gate.

The original NetShooter multicast/replicated-component discrepancy is retained
in batch97 and the candidate dispositions. It is an original0.11 native-game
baseline difference, with an explicit retained native boundary. It does not
change the production Mixin/API freeze contract or gain a blanket fix claim.

The reviewed supported API has no currently identified release-blocking
correctness defect after these explicit dispositions. This is a scoped review,
not a proof that unknown defects or unsupported legacy wrappers cannot exist.
Full Explorer/TopDownArena acceptance, other platforms/configurations and
release publication keep their own gates. No RC tag or release is created here.
