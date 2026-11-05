# UnrealEnginePython 1.0.0

The stable release targets Unreal Engine 5.8.1, engine-bundled CPython 3.11.8
and Win64 Development/Shipping. It promotes the accepted
[1.0.0-rc.1 candidate](Release_1.0.0-rc.1.md).

The SDK implementation and matching Examples source retain the accepted
candidate's content. Promotion changes the plugin version to `1.0.0`, advances
its numeric version to 1001 and clears the Beta flag. Formal artifacts and
packaged-runtime version checks identify the final tagged source pair.

The supported API, ownership, threading and reload contracts remain defined by
[the inventory](Supported_API_Inventory.md), [Mixin API](Mixin_API.md),
[lifecycle contract](Lifecycle_Threading_API.md) and
[runtime subscriptions](Runtime_Subscriptions_API.md).

The source distribution includes plugin and matching Examples archives,
validation evidence and SHA256SUMS. Configuration-specific results and the
candidate's workload limits are retained in the linked candidate record.

Formal promotion validation passed on 2026-11-06. The Shipping package passes
thirteen exception/recovery cases, normal frontend flow, actual packaged Python
locality and 4,578 dependency checks. Both rendered Third Person packages report
`1.0.0`, produce all six expected images and exit with restored lifecycle state.
The complete formal record is [validation.json](../Releases/1.0.0/validation.json).

The candidate's 5,866 source checks, seventy Generic native checks, eleven Mixin
call lanes, three PIE sessions and sixteen independent Lyra client views carry
forward through the verified implementation-identical metadata promotion.
Protected Engine/reference artifacts keep their tested fingerprints.
