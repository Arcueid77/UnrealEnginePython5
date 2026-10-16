# Runtime subscriptions

`uep_runtime.SubscriptionScope` owns game-thread subscriptions. UEP stages its
Python source as loose NonUFS files and searches enabled plugins' Content/Scripts
directories in Editor and packaged games. Project Content/Scripts remains the
first project search path.

```python
from uep_runtime import SubscriptionScope

def on_quickbar_changed(channel):
    # Query this presenter's own controller. The message channel alone does
    # not identify a local player or transfer authority to Python.
    refresh_from_native_inventory()

scope = SubscriptionScope()
scope.bind_event(controller, "OnPossessedPawnChanged", on_pawn_changed)
scope.listen_gameplay_signal(controller, "Lyra.QuickBar.Message.ActiveIndexChanged", on_quickbar_changed)

# From Destruct/EndPlay and the Mixin teardown hook:
scope.close()
```

`bind_event` forwards the delegate's arguments. It preserves the exact bound
callable for removal. `listen_gameplay_signal` uses the optional native
GameplayMessageRouter async proxy, binds before activation, verifies activation
and cancels it on close. It exposes only the channel. It does not call the
wildcard CustomThunk GetPayload directly.

`listen_gameplay_message(context, channel, payload_type, payload_reader, callback)`
adds typed delivery when the caller supplies an explicitly verified adapter.
The type is a live UScriptStruct UObject; `payload_reader(proxy)` must copy the
payload **during** native delivery, and fail if extraction was unsuccessful.
The callback receives `(actual_channel, payload)`. Closing/disarming, exact
callable removal and native cancellation follow the same scope rules.

Do not implement the reader with generic ProcessEvent on GetPayload: its C++
signature is a wildcard placeholder. Examples' `BP_UEPGameplayMessages` supplies
compiled, typed VM ReadUI/ReadVerb functions with a local struct temporary,
returning an owning payload copy plus success. Only the wildcard conversion
is in that BP glue; subscriber business belongs in Python. Core neither links
GameplayMessageRouter nor assumes a Lyra/user-defined struct layout.
An incorrect reader/type must fail, not deliver a default/foreign payload.
Native proxy payload storage disappears after callback delivery. UObject
members in a copied struct still follow native World/GC lifetime; a value copy
does not root its referenced actors for later Worlds.

The focused native `transport01` fixture verifies the unchanged user-defined
ADS struct and native LyraVerbMessage, identity, nested broadcasts/copy isolation,
wrong-reader and outside-delivery rejection, legacy signal compatibility and
zero callbacks after idempotent close. This is transport proof, not real ADS/
kill gameplay or packaged typed-message support.

Closing is idempotent. It disarms callbacks before native unbind/cancel, attempts
every cleanup and reports cleanup failures. `closed` and `count` expose owned
state. Context-manager use is supported. UObject operations belong on the game
thread; no finalizer or interpreter-exit hook should call a destroyed UObject.

Gameplay messages are GameInstance-wide. The adapter must filter by its own
player/World and must not apply another player's data. The native async proxy
requires a valid World/GameInstance and the optional plugin; absence fails
explicitly. UEP does not add a C++ link dependency on GameplayMessageRouter.

## Lyra weapon adapter

Examples owns `uep_lyra_hud.weapon_observer`. Native QuickBar slot/index and
Pawn signals trigger immediate refresh. Lyra StatTags FastArray exposes no
public ammo-change delegate, so one shared read-only frame sampler caches each
controller/item read for that sample and emits changes only when values or
ownership change. Reports identify its source as `read-only-frame-sampler`.
This is not a replication-event subscription.

The last subscriber releases the sampler and each controller's reference-counted
scope. Native inventory, equipment, GAS, input, replication and authority remain
Lyra's responsibility. Widget Tick suppresses the original BP polling and only
resumes observation once after a live Profile switch. Ordinary frames use the
shared sampler.

Controlled reload removes widgets, unregisters routers, closes old observers,
reloads the modules, registers again and creates new widgets. Native lifecycle
events and arbitrary Python state are not replayed/migrated automatically.

Core host tests cover delegate identity, cancellation/disarm, activation failure,
invalid GC wrappers, optional-plugin absence and cleanup failures. Real UE tests
cover native message cancellation, live profile switches, three reload/GC cycles,
three PIE sessions and multiplayer travel/ownership. Packaging is an independent
gate; file staging alone is not runtime-import proof.
