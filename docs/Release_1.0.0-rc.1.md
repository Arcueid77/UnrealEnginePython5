# UnrealEnginePython 1.0.0-rc.1

The release candidate targets Unreal Engine 5.8.1, its bundled CPython 3.11 and
Win64. The candidate retains the Beta descriptor flag. Development and Shipping
validation are recorded separately.

The accepted migration baseline covers the original twenty-two Blueprint
criteria, thirty selected game-C++ candidates (twenty-nine production groups and
one capability group), H01-H05, and actual Escape/Menu input. The candidate adds
a frozen supported API, current core/interpreter tests, a Shipping source build
and cooked runtime acceptance, source/archive installation, and checksummed
release artifacts.

Candidate validation is in progress. Source, engine, configuration, dependency,
archive and runtime fingerprints will identify each accepted gate. The Shipping
gate executes the package's inner game executable and checks actual Python
runtime locality, critical gameplay, frontend flow and orderly shutdown.

The supported API is described in [Supported API inventory](Supported_API_Inventory.md),
[Mixin API](Mixin_API.md), [lifecycle and threading](Lifecycle_Threading_API.md)
and [runtime subscriptions](Runtime_Subscriptions_API.md). These documents define
the callable signatures, ownership, reload and game-thread contracts.
