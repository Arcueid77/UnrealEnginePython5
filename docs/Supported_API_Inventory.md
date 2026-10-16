# Supported API inventory before RC freeze

This is a capability inventory for the UE 5.8 / CPython 3.11 Win64 Development
candidate. It is not a compatibility claim for every legacy wrapper, UE version,
platform or build configuration. Validation history identifies actual runs.

| Surface | Support and boundaries | Primary contract |
| --- | --- | --- |
| Interpreter | Engine CPython 3.11; standalone or shared Editor VM; finalize only the owned interpreter | Lifecycle_Threading_API.md |
| UObject reflection | Tested scalar/math/struct/enum/object, array/map/set properties; function inputs, returns and native out parameters | uobject_API.md, core_validation.py |
| Lazy soft-class input | Empty/null, loaded UClass or validated object-path Unicode input; rejects invalid paths/NUL, does not load the class; no new soft-reference getter contract | soft_class_path_validation.py, open_menu_mixin.py |
| Dynamic types | Transient generated UClass/FProperty/UFunction; unique names for process lifetime; restart for type/signature replacement | Subclassing_API.md, Lifecycle_Threading_API.md |
| Production Mixin | Retained BP class, named per-instance profiles, Interface/CDO declarations, original fallback/composition, teardown/restoration | Mixin_API.md, Mixin_Call_Lifecycle_Matrix.md |
| Delegate / Enhanced Input lifetime | Exact callable/handle removal; game thread; explicit teardown | EnhancedInput_API.md, Lifecycle_Threading_API.md |
| Runtime subscription scope | Native delegate and optional Gameplay Message signal or typed delivery with a supplied verified VM payload reader; explicit close, no generic wildcard ProcessEvent API | Runtime_Subscriptions_API.md |
| Actor / World / exit | Native spawn/destruction, observed authority/replication, graceful request_exit; game thread | Level_API.md, Lifecycle_Threading_API.md |
| Editor / asset / Slate helpers | Editor-only APIs retain their build boundary; focused asset and Slate ownership tests | ManagingAssets.md, Slate_API.md, editor_validation.py |
| Construction extraction authoring | Editor-only zero-parameter Actor construction clone plus virtual helper forwarder; explicit compile/save; not generic Parent interception | Mixin_API.md, mixin_construction_forwarder_validation.py |
| Experimental Blueprint body scripting | Separate API; one int/bool out-address fixture; not part of production Mixin support or RC stability promise | blueprint_script_body_validation.py |

## Migration rules

UEP's specialized `FRotator` positional constructor uses Roll/Pitch/Yaw,
not UE C++'s Pitch/Yaw/Roll. Prefer explicit `.pitch`, `.yaw`, `.roll` fields
for test/game intent and verify the native returned axes; a rotated screenshot
is not evidence that a Pawn aimed at the intended target.

Existing `register_mixin` and `@mixin` remain compatible single-profile forms.
Use named profiles/Mixin Sets for multiple behaviors on one class. An object
keeps its BP-generated Unreal type; unrelated code resolves reflected methods
normally within the tested call-entry boundary. Never silently execute the BP
after a Python success or exception.

Close subscriptions and unregister before controlled module reload or BP asset
authoring. Preserve original UFunction identity on restore. Recreate widgets
explicitly when the workflow needs fresh native lifecycle events. Change
generated types/reflected signatures by restarting the process.

Unsupported RPC/delegate/latent Mixin signatures, direct C++ interception and
unrestricted hot reload remain outside the contract. Ordinary reflected calls
to native capabilities remain available without claiming that those native
implementations can be intercepted. Native wildcard CustomThunks need dedicated
binding support; do not invoke their placeholder C++ signatures through generic
ProcessEvent.

No public API is removed in this candidate. Deprecation must identify the old
API, replacement, affected examples and removal version, and keep a compatibility
path until the documented removal. Experimental APIs may change before RC and
must not silently become a supported gameplay dependency.

The engine/general-purpose plugin C++ systems remain native. Examples owns
Lyra-specific presentation/business and assets. ABPs/animation, editor/test
tools, interface declarations, component/default-data shells and UMG layouts
are retained. Game-project C++ business migration remains a separate phase.
