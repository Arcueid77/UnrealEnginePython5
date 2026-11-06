[English](Lyra_Network_Acceptance_Plan.en.md) | [简体中文](Lyra_Network_Acceptance_Plan.md)

<a id="lyra-联机验收方案"></a>

# Lyra Online acceptance plan

Baseline date: 2026-09-12. Scope of application: UEP 0.8.0 candidate version, UE 5.8, engine built-in CPython 3.11, Win64 Development.

This article defines the execution contract; see [Validation history](Validation_History.md) for actual pass records. 2026-09-12 The multi-player Bridge, probes and build-free drivers have been completed according to user authorization, and have started to run in real life; the engine source code or the official Lyra project will not be modified and will not be packaged. Multi-client is a required item for the 0.8 online special project. The minimum baseline is one server and two customers; the corresponding threshold is recorded simultaneously in [Roadmap](../ROADMAP.md).

Execution results: `20260912-network-run-05` has passed the A layer, 20 stage and the four processes are finally cleared and completed, `multi_client_acceptance: true`. The first four rounds of failures and repairs are retained in the Validation history; `full_acceptance` is still false, and the B/C layer has not been run.

<a id="1-验收目标与边界"></a>

## 1. Acceptance goals and boundaries

Complete the automatic acceptance of "one local independent server + two independent clients A/B". The two clients must be independent UE processes, not two Pawn, AI bots or split-screen players in the same process. Must prove:

- The client actually joins the Lyra match, with the correct network roles, Pawn, PlayerState, ASC and Health.
- Python Precisely select the A/B driver Lyra GAS on the server through the restricted bridge interface. Each client receives its own blood volume changes through UE native replication; another person's Health and local HUD will not be tampered with.
- The two clients' Python and HUD respectively only subscribe to their own current Pawn; rebirth, Experience replacement and image cutting will not repeatedly create presenters or legacy subscriptions.
- When one person exits, the other one continues to run normally; players who rejoin use the new connection identity, and the old goals, old ACK, and old subscriptions cannot be mistakenly used for the new connection.
- After all started processes in this round actually exit, all callbacks, statuses and widget references held by Python presenter are reset to zero.

This does not prove that "Python rewrites the Lyra network layer". GAS, Health storage and copying are still the responsibility of Lyra native code; Python method calls, ordinary Python fields and Mixin Profile do not gain automatic RPC or copying capabilities because of this test.

The acceptance layer is as follows, and the results of the previous layer cannot be used to replace the latter layer:

| Hierarchy | range | Positioning of this plan |
| --- | --- | --- |
| P: Single customer pre-check | Native Dedicated Server + 1 Client, reuse existing tests to eliminate basic problems | Diagnosis that can be run first is not a condition for online special completion. |
| A: Multi-client baseline | Native Dedicated Server + 2 Clients, target isolation, interleaved commands, join/exit/reconnect, HUD life cycle | 0.8 The online special project must be completed; it will not pass without any client evidence. |
| B: Supplementary acceptance | Visible network client, continuous and repeated operations | Arranged independently, does not replace Tier A |
| C: Network environment | Delay, packet loss, cross-machine LAN/WAN, long-term stability | We will arrange this when there is a specific support statement, and there is currently no commitment to cover it. |
| release matrix | Universal Binding, Standalone, Online, Rendering and Packaging from the same release candidate | Press Roadmap to execute; passing A does not mean that the entire 0.8 can be released |

The existing `Package` runs the packaged Standalone, not the packaged server/client pair; even if `All` passes, it cannot claim to have verified "packaged online". `Network/All` has been connected to the dual-client threshold; the old single-customer entrance was renamed `NetworkPrecheck`, and its green result is not enough to pass the multi-client threshold.

<a id="2-当前状态与阻碍"></a>

## 2. Current status and obstacles

<a id="21-现有能力"></a>

### 2.1 Current capabilities

| Ability | Current implementation | Usage restrictions |
| --- | --- | --- |
| One server, one customer pre-check | [Main Authentication Script](../Validation/Run-UEP58LyraValidation.ps1)’s `NetworkPrecheck` mode | Staging and calling UBT will be done first; `-Incremental` does not mean skipping the build. |
| Multi-customer replication and life cycle probes | [uep_lyra_network.py](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Overlay/Content/Scripts/uep_lyra_network.py) | 20 stages, A/B0/B1 independent receipt; old `uep_lyra_probe.py` retain single customer process |
| HUD Counting, Final Cleanup and Logging Contract | [LyraHUDContracts.ps1](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/Validation/LyraHUDContracts.ps1) | The four processes of this round can only be accepted after exiting; `All` Mandatory check of the double passenger special results |
| No need to build online portal | [Run-UEP58FocusedNetworkValidation.ps1](https://github.com/Arcueid77/UnrealEnginePython5/blob/dev/release-1.0.0/Validation/Run-UEP58FocusedNetworkValidation.ps1) | Requires a matched stage; does not execute UBT/UAT, does not repair BuildId, and does not generate assets |
| HUD Asset Semantic Audit | [audit_hud.py](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Tools/audit_hud.py) | Read-only auditing can be performed by the existing Editor; the `HUDAudit` entry of the main script still has a build preset |
| Multiple players damage target | [UEPLyraWorldSubsystem.cpp](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Plugins/UEPLyraBridge/Source/UEPLyraBridge/Private/UEPLyraWorldSubsystem.cpp) | `ApplyAuthorityHealthDeltaToPlayer` Use opaque PlayerToken of current World; old local/remote API Preserve ambiguity reject |
| Multiplayer snapshots and respawns | `CapturePlayerSnapshots`、`RequestPlayerRestart` | Each real PlayerController identity and Pawn/Health path; rebirth also accurately selects players by token |

Shuangke Portal automatically runs the read-only HUD audit in each round, and associates the before and after hashes of the actual assets used to this round of reports. It does not directly load the main script with the staging/build top-level side effect.

<a id="22-2026-09-12-实施前的只读核对快照历史不是当前-buildid"></a>

### 2.2 2026-09-12 Read-only reconciliation snapshot before implementation (historical, not current BuildId)

- Core HEAD：`980587e4bf2d449a4154a7ba2b25ef500829cdc3`。
- Examples HEAD：`0395f360136070d96dd3ad17e1fb1023c4cc2595`。
- Both working trees have uncommitted modifications; the above HEAD cannot independently identify the actual source code under test.
- Current Engine BuildId: `038ca067-a15c-47cf-a35d-073bd334643e`.
- Modules BuildId for Lyra stage, UEP and UEPLyraBridge: `347adf8a-0e10-4046-9bb4-c7a62877a03a`.
- The hashes in the evidence for `UnrealEditor-NetCore.dll` and 9 are different from 10; the three DLL hashes of LyraGame, UEP, and UEPLyraBridge are still the same.
- The 408 native source files and 8 Python scripts checked against the warehouse are consistent with the stage. But source code consistency does not prove that the old DLL is compatible with the new engine.

This pre-implementation snapshot prevents direct reuse of old binaries. Subsequently, the official UBT completed the incremental compilation and metadata update of Bridge (5 actions, 51.06 seconds); the engine NetCore DLL hash remains unchanged. Compilation costs are recorded independently and cannot be hidden due to subsequent runner build-free. The BuildId and source code /DLL hashes are still read dynamically each round, without hardcoding old values.

Historical evidence:

- The legacy version of `20260903-033426`, server/client, both exited 0, observed 90, and recovered 100; but lacked the currently required audit correlation and final `shutdown` evidence.
- `20260910-hud-native-closeout` and `standalone-native-final-20260910-summary.json` cover the latest fixed projects and Standalone, not online pass records.
- The original record is retained in `.build/LyraValidation/Full/Results`; see [Validation history](Validation_History.md) for explanation.

<a id="3-前置检查与操作边界"></a>

## 3. Pre-checking and operating boundaries

<a id="31-固定输入"></a>

### 3.1 Fixed input

| Project | Native default |
| --- | --- |
| engine | `F:\UnrealEngine` |
| Read-only reference project | `F:\LyraStarterGame\LyraStarterGame.uproject` |
| Writable verification project | `F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject` |
| Run the map | `/ShooterMaps/Maps/L_Expanse?NumBots=3` |
| Experience | `B_ShooterGame_Elimination` |
| Listening and connecting | `127.0.0.1:7788`; Stop when port is occupied or explicitly select free port |
| Number of clients | 2 independent clients A/B; 3 AI bots are only used for normal promotion of Warmup and are not counted as network clients |
| Default operating mode | There is already `UnrealEditor-Cmd.exe`, the server `-server`, the client each `-game`, and the third party `-Multiprocess -NullRHI` |
| Reconnection sub-scenario | B's first connection B0 exits normally, and then starts B1; up to 3 UE processes can be used at the same time, but the exit evidence of 4 process instances needs to be verified in the entire round |

Deterministic Isolation: Three bots still participate in native Warmup, but the test probe stops their autonomous combat via the existing `BrainComponent.StopLogic` to avoid random fire mixed into the Health assertion. Each stage records three brains that are not running; no changes to the real person Pawn health, damage immunity or GAS copy. This behavior is only enabled by `-UEPLyraMultiClient` and does not enter the normal demo.

Only use verification copies tagged with `.uep-lyra-full-stage.json`; create new results and sync directories each round and partition by client/connection/phase, do not reuse old ACK or release files.

<a id="32-启动前必须完成"></a>

### 3.2 Must be completed before starting

1. Record the commits, branches, dirty status, related diffs and content hashes of untracked test files of the two warehouses; the release record cannot only record HEAD.
2. Check the module records of UE version, CPython 3.11, Engine version/modules, Lyra/UEP/Bridge and the existence of dependent DLLs. The build must be stopped even if the source is unclear. Consistency of BuildId is only a necessary condition.
3. Verify staged native source code, Python scripts, configurations, and overlay assets are consistent with the candidate version; record actual DLL, scripts, and asset hashes. Unchanged assets are not regenerated.
4. Check reference Lyra asset hash; do not write overlay back to reference project, do not read or import internal reference binding code.
5. Runs current host tests and contract negatives, including multi-guest identity, old ACK, subscription attribution, and publishing threshold negatives. In addition to the number, the use case name, failure item, and exit code should be retained.
6. Run a read-only HUD audit with a matching existing Editor, checking the Interface, Mixin Set, Profile, selector and AddWidgets configurations. The audit results must correspond to the actual asset hash used.
7. When the asset registry cache is missing, it is prepared sequentially by an Editor commandlet and then starts three running processes that share the read-only cache. This step will write the stage cache, not compilation or packaging, nor pure file reading.
8. Check the port, available memory, disk and existing UE/UBT tasks to prevent the shared engine from being updated in this round; do not terminate other project processes.

Compare engines, plugin DLLs, scripts, configurations and asset hashes again before and after testing. If a change occurs during the run, the source of the round is no longer reliable and cannot be counted as passed.

<a id="33-多玩家身份与接口前置"></a>

### 3.3 Multi-player identity and interface front-end

The following capabilities are implemented in Examples Bridge and dual guest probes without changing the general copy semantics of UEP:

- Establish a verifiable identity mapping for A/B: test tag, server actual connection, PlayerState identification, current Controller/Pawn, connection epoch, and world generation. The A/B label is only a test orchestration label and is not used as a production authentication credential; the mapping must be confirmed by the actual object on the server and the local PlayerState of the client, and cannot rely on the connection sequence, object name or controller array subscript.
- Add a restricted interface for explicit targets in `UEPLyraBridge` of Examples, giving priority to the verified server Controller/PlayerState or the parsed player identity. Damage, Snapshot, and Respawn all use the same target; object validity, ownership World, current connection, Authority, and original magnitude/non-lethal rules must be checked.
- Existing interfaces uniquely matched by local/remote are retained; dual clients should still return `RejectedAmbiguousTarget`. May not be changed to "take first player" to eliminate ambiguity.
- Server reporting changed to per-player logging; client only drives local HUD with its own local player. The Health broadcast of the first player on the server cannot be filled in all client reports.
- Command ID contains run/phase/peer/operation; the corresponding packet simultaneously fixes WorldToken, PlayerToken and the target Pawn, both of which jointly determine the world/connection/target namespace. The same ID cannot be applied again if retried; the consumed ID cannot become a new write even if it is submitted to a different target. The idempotent state remains only within the current World.
- ACK contains run ID, scenario, phase, world generation, connection epoch, player mapping and association command ID, and is written to their respective directories. Late arrival, wrong end, old World, and B0 connection legacy ACK cannot satisfy B1 or the barrier of the current stage.
- By default, reconnection is accepted by "New Connection, New Pawn", and there is no requirement to restore the old blood volume or retain the old PlayerState ID. The new Pawn baseline requirement for Fixed Experience is currently 100; the expired B0 target cannot be automatically resolved to A or B1.

Test tags A/B0/B1 from startup parameters of a separate process; client local PlayerState ID cross-matches with server-side actual PlayerController/PlayerState and cannot rely on `?Name=` (online subsystems may override nicknames). PlayerToken is mapped to a weak Controller reference with serial, and the current World and the actual Controller collection are checked each time it is parsed; World The old token becomes invalid after reconstruction and offline. These tokens are test positioning credentials, not client business authentication protocols.

<a id="34-构建与系统设置"></a>

### 3.4 Build and System Setup

- The first choice is to add a special online entry that explicitly does not call UBT and reuse the matched program; if a mismatch is found, exit immediately without automatically repairing the metadata.
- For situations that must be handled by the official UBT, first explain the expected scope: only metadata, plug-in /Lyra increments, or engine recompilation involved. When the scope needs to be expanded, the confirmation is suspended and the general entrance test is not run directly.
- Do not modify BuildId/GUID by hand, do not treat `-WriteOutdatedActions` as an absolutely side-effect-free dry-run; UBT may also delete expired products when generating action records.
- Controlled builds can use `-NoEngineChanges` to limit engine product changes, but cannot claim that UBT is overall read-only. The current build parameters for the main script do not yet provide this hard limit.
- The source code and official template of UE will not be changed; this online special project will not call Cook, UAT or Package. Release packaging is another task that is informed in advance.
- Do not close the Windows firewall or notification globally, and do not automatically open the public network /LAN inbound. Check the existing rules for the actual test exe first; if a policy is missing, state the precise target, impact, and recovery method before proceeding.
- Auxiliary processes are started hiddenly. Irrelevant monitoring such as AndroidFileServer, UdpMessaging, TcpMessaging and tracing can be disabled according to the existing verification agreement, but the game NetDriver cannot be disabled to "avoid pop-ups". Connectability must be proven by a real handshake.

<a id="4-a-层一服两客自动验收"></a>

## 4. Level A: One server and two customers automatically accepted

<a id="41-确定性时序"></a>

### 4.1 Deterministic timing

1. The driver starts the server bound to the loopback, waits for the listening log and `UEP_LYRA_BRIDGE_ATTACHED`; starts A, and then starts B0 after it is ready, covering the fact that A will not be reset when the second player joins.
2. The three parties establish and verify the identity mapping of A/B. Each waits for the real Experience, Pawn, ASC, and Health to be ready, and waits for the native Warmup/damage immunity to end normally; do not forcefully rewrite the game stage.
3. A and B respectively request writing from the client and must return `RejectedNotAuthority`; their local Health is still 100. Server calls to old ambiguous interfaces should be rejected before testing the explicit target interface.
4. The server only subtracts 10 health from A and retries with ID. A must receive the copied 90 and Python `health_changed`; B’s own Health/HUD remains 100 and cannot subscribe to A’s Health.
5. Recover A after receiving damage observation ACK from A; A observes 100. B provides independent evidence of its own unchanged state and cannot infer that B is normal just by looking at A's report.
6. Exchange target: only reduce 20 health to B and recover, B is 100 → 80 → 100, A maintains 100. Different damage values ​​are used to expose wrong targets/wrong reporting routes without broadening the existing 25 point limit of the interface.
7. Then stagger the submissions of A -10 and B -20, let both ends observe 90/80 before either recovery, and retry their respective commands ID. Recover separately according to their respective valid ACK; exchange ACK and the arrival order cannot be released in advance or repeated damage. Here are the interleaved commands on the game thread, which do not declare a restricted interface for multi-threaded calls.
8. Initiate Pawn restart for A and B respectively. The target client removes the old subscription and binds the new Pawn; the other end continues to be ready, and its own Pawn/HUD will not be replaced due to the other party's rebirth.
9. The first time the server drives the Experience with the map travel, the real AddWidgets action is destroyed/rebuilt; the second time it is independent, the travel is checked again. A/B Both must follow the server, confirm the new world generation, and each maintain a unique presenter.
10. Save A/B0 After completing the snapshot of the dual-passenger basic scenario, let it exit normally through the B0 dedicated stage exit signal, and check its final cleanup. Server and A continue to run and the number of clients should change from 2 to 1.
11. While B is offline, perform limited damage/recovery on A again to verify that A is still normal; the operation on the old B0 target must be rejected and cannot accidentally fall to the only remaining A.
12. Start B1 to rejoin and allocate new connection epochs. After confirming the new Pawn/HUD and subscription, perform damage/restoration only on B1; A remains normal. Neither the old B0 object nor ACK can act on B1.
13. After servers, A, and B1 meet all current stage conditions, the driver writes the final release signal. B0 is an old participant that has settled. It cannot replace B1 with its ready, nor can it wait for B0 that has exited.
14. Check the actual exit and final report of all 4 process instances in this round, and then summarize the status of the three parties and all scenarios; you cannot just check the last remaining server and a certain client.

The JSON of the sync directory is only used for testing orchestration and recording "what the other end has observed". It cannot be written to client Health, cannot replace UE network replication, and cannot replace business RPC. Each ACK must be triggered by the end's read and delegate events of the real UObject.

Here, the life cycle of the AddWidgets action is triggered through Experience replacement. It does not claim to have verified that the ShooterCore plug-in is completely hot uninstalled/reloaded in place; traveling on the same map twice does not mean that all cross-map and seamless travel paths have been covered.

<a id="42-用例与通过标准"></a>

### 4.2 Use Cases and Pass Criteria

The following are hard target criteria; the presence of an implementation does not equate to the current candidate passing. The actual results must come from the same round of reporting and cannot be automatically counted based on the presence of code.

| ID | scene | results that must be met | Current status of automation |
| --- | --- | --- | --- |
| N01 | Sources and Assets | Section 3 passed the inspection; the audit matched the actual assets; there was no source drift before and after the test | runner’s dynamics BuildId, source code/asset /DLL hash and this round of audit |
| N02 | Connections and Roles | In the dual-client stage, the Server is DedicatedServer, there are exactly 2 remote human players and their respective Authority Pawn; A/B each is Client, 1 local players and AutonomousProxy; each player is ready and their identities do not overlap. | CapturePlayerSnapshots + roster/ACK per stage |
| N03 | Client exceeds authority | A/B got `RejectedNotAuthority` and accepted/applied respectively, all false, and no RPC was sent on behalf of them; their Health has not changed. | authority stage |
| N04 | Server-side damage and idempotence | Applied once after clarifying the target; the same ID Retry cannot reduce the blood again or change to another player | Each damage/heal records the original order and both duplicate submissions |
| N05 | Client replication and recovery | A observes 100 → 90 → 100, B observes 100 → 80 → 100; both have their own snapshot and `health_changed`, and recover later than their respective injuries. ACK | New event number + local HealthComponent path |
| N06 | HUD Uniqueness and Ownership | A/B Each active presenter/reference is exactly 1/1, only bound to the local current Pawn; Server is always 0/0, and there is no UI event | HUD Ownership and Callback Difference Contracts per Phase |
| N07 | Rebirth/Replacement Pawn | A/B are reborn separately; the target’s old subscription is removed and the other Pawn/Health/HUD is not replaced | respawn_a / respawn_b |
| N08 | Two life cycle switches | A/B0 After two trips, it has at least 3 Construct times and 2 Destruct times. The active presenter is still 1; the identity is re-confirmed under the new World | travel_one / travel_two |
| N09 | Final cleanup and exit | server/A/B0/B1 All process instances exit 0, and their respective final `shutdown.hud` is 0/0, binding/unbinding are equal; cross-process splicing counts cannot be | atexit report + actual process exit + ordered log |
| N10 | Strict failure handling | None fatal/assert/unhandled exception/unexpected `Log*: Error`; it cannot pass if there is a missing client report, timeout or abnormal exit. | Shared log assertion; failure will only recycle the process of this round |
| N11 | Two-way target isolation | When only damaging A, B itself always maintains the baseline, and the reverse is the same; the old role-only interface still rejects ambiguity; expired/crossed World target rejection | Player-by-player expected value + authority/travel/rejoin token negative example |
| N12 | Interleave commands with ACK | 90/80 exists at the same time, each is idempotent; the reverse order ACK is still correct; the wrong player, the old World/connection, and the wrong command ACK will not be released. | damage_both / heal_both + host contract negative example |
| N13 | Second person joins | B0 joins the ready A; the number of servers changes from 1 to 2, A is not reset, and B0 independently initializes a copy of HUD | join_a / join_b |
| N14 | Exiting alone does not affect others | B0 exits and cleans up normally, the number of servers changes from 2 to 1; A can still complete damage/recovery, and the old B0 target is not redirected to A | exit_b / damage_a_solo / heal_a_solo |
| N15 | Reconnection and old state isolation | B1 new connection/new Pawn, HUD is exactly 1; damage/recovery can be completed based on the new Pawn initial value; B0 objects, ACK, and callbacks cannot be reused | rejoin_b / damage_b1 / heal_b1; old token rejected again |
| N16 | full participant barrier | Participants are declared in advance for each stage; failure if there is one less current participant; all started process instances have final proof | Fixed 20 stage participant, standalone ACK path, quad report cross-check |

The count is verified against the currently implemented ledger definition:

- Running period: `controller_bind_count - controller_unbind_count = active_widget_count`, Health count is also established.
- Final exit: The differences between the two groups are both 0; here is "all resources of the presenter returned to zero", not claiming that UE all the memory of the entire process has been released.
- The health volume comparison follows the 0.05 tolerance of the existing contract; A subtracts/adds 10, and B subtracts/adds 20. Baselines and expectations are recorded player by player and scenario by scenario, with no tolerances or sequence changes due to failure.
- Cross-process UObject path strings are not required to be exactly equal. Associate players, connection generations, characters, Pawn replacement and command targets, and retain each end's own object path to prevent bots, opponents or old Pawn from being mistakenly targeted.
- N08 of at least 3/2 times Construct/Destruct is applicable to A/B0 who have traveled twice. B1 is a new process. When there is no additional travel, it only needs to complete its own initialization, uniqueness and final cleanup. It cannot borrow the B0 count to recharge.

The final log sequence must contain:

```text
UEP_LYRA_AWAITING_SHUTDOWN
  → Goodbye Python
  → UEP_LYRA_HUD_SHUTDOWN_PASSED
  → Log file closed
```

If either end only writes `awaiting_shutdown`, or if it first outputs PASSED and then crashes, it will not pass.

<a id="43-超时与失败规则"></a>

### 4.3 Timeout and failure rules

- The single-customer P layer still uses the original script boundary; the fixed upper limit of each stage of the A layer server probe is 180 seconds, and the total running limit is 900 seconds, including the process exit wait. The driver can shorten the total upper limit and does not automatically renew during the test process; the asset prime upper limit is 600 seconds and the audit upper limit is 300 seconds, both of which are executed serially before starting the online process.
- Preparing the asset cache may take time; record the configuration in advance so that it does not extend silently after failure. If a machine load or cold start problem is discovered, the failed round will be retained, and a new round will be opened after clarifying the reasons for adjustment.
- If it fails, the current status, participant set, pending requirements, final log and each process result will be saved first, and then the PID/child process recorded in this round will be recycled; all UnrealEditor will be terminated in batches without process name.
- Use a new directory and a new run ID to rerun; historical failures will not be deleted, and problems will not be covered up by infinite retries.
- Native damage immunity/target ambiguity is a normal safety boundary and cannot be bypassed to pass tests. If it still cannot be completed after normal Warmup, record the blocking stage and locate it.

<a id="5-已实现的执行入口"></a>

## 5. Implemented execution entry

A matching native build is required before first launch. Then use the build-free entry to execute layer A:

```powershell
.\Validation\Run-UEP58FocusedNetworkValidation.ps1 `
    -StageProject F:\UnrealEnginePython5\.build\LyraValidation\Full\Stage\Lyra\LyraStarterGame.uproject `
    -OutputDirectory F:\UnrealEnginePython5\.build\LyraValidation\Full\Results\Network-NewRun `
    -ClientCount 2 -ServerPort 7788
```

It only accepts ClientCount=2; it does not call UBT/Cook/UAT, automatically generate assets, modify firewalls, or fix BuildId. The public process assistant is in `Validation/UEPValidationProcesses.ps1`, the pure reporting contract is in `uep_lyra_network_protocol.py`, and the offline cross-check entry is `Tools/validate_network_reports.py`. Windows Synchronization messages use atomic replacement, shared lock exception up to 10 limited retries; permanent access error or bad JSON still fails.

This specialization is also called for the main entrances `Network` and `All`, of which `All` is no longer allowed without double passenger pass results full_acceptance. The main entrance still has staging/build prefixed, and `All` will also be packaged; it will not be executed this time.

The existing single-customer pre-check entry with construction is as follows, which can only be used after confirming the execution scope; it only runs the P layer, and is not a multi-client acceptance command, nor a build-free command:

```powershell
.\Validation\Run-UEP58LyraValidation.ps1 `
    -EngineRoot F:\UnrealEngine `
    -LyraProject F:\LyraStarterGame\LyraStarterGame.uproject `
    -OutputRoot F:\UnrealEnginePython5\.build\LyraValidation\Full `
    -Mode NetworkPrecheck `
    -Incremental `
    -ServerPort 7788 `
    -MaxParallelActions 2 `
    -RuntimeTimeoutSeconds 180
```

Do not switch to `-Mode All` for connection purpose, and do not pass `-SkipGameplaySlice` or `-SkipHUDSlice` and still claim that layer A passed. Single customer `NetworkPrecheck` retains the old diagnostic behavior and will not meet the dual customer threshold.

<a id="6-bc-层不替代多客基线的补充场景"></a>

## 6. B/C Layer: Supplementary scenario that does not replace the multi-passenger baseline

These scenarios are first recorded as unexecuted and are not advertised as capabilities that layer A already possesses.

| scene | Extra preparation | pass standard |
| --- | --- | --- |
| Visible network client | Keep the one-server-two-client topology and change at least one client to non- NullRHI;Record screenshots, object values and event timing | The local health bar and numbers correspond to their own copied values and are not linked to another player; screenshots cannot only be taken from isolated fixtures |
| Continuous repeat run | The same freezing source continues for 3 rounds of layer A, with new processes/directories in each round | Passed all three rounds, no count increase and residual testing process; a single pass is not called repeated stability certification |
| Weak network | Verify the current network simulation entry of UE, fixed delay/jitter/packet loss parameters, seeds or reproducible settings, and keep the non-simulation control group | Restore consistency within the pre-declared environment and time budget; only commit to measured parameters, and do not temporarily relax the threshold for failure |
| Across machines/WAN | A second authorized machine, same source programs and content, test coordination method for non-shared directories, and clear network/firewall policies | Role, copy and cleanup evidence closure for two real machines; native loopback cannot be replaced |
| Package online | Clarify server/client build configuration and goals, separately approve build/packaging costs | Actually package the exe to form one server and two customers and repeat layer A; the existing packaged Standalone cannot be replaced |

Dual clients, target isolation, second person joining, normal exit and reconnection are already mandatory items for layer A and are no longer listed as extensions. 4 Or more clients, Listen Server, split screen, abnormal network disconnection recovery and stress testing still require independent scenarios and support statements.

Moving, firing, hitting, dying, and scoring are more complete acceptance of multiplayer gameplay and are not automatically covered by the current health bar. If real death is arranged, use Lyra native gameplay or a separately designed isolation fixture, and do not relax existing non-lethal bridging to create death.

0.8 The required damage/healing/death/rebirth rendering regression is still performed according to [HUD Special Document](Lyra_Python_HUD_0.8.0.md); the current isolation UMG fixture is not connected to the real Pawn/ASC and cannot be used as online copy evidence.

<a id="7-证据结论与交付"></a>

## 7. Evidence, Conclusions and Delivery

<a id="71-每轮证据"></a>

### 7.1Evidence per round

Keep the JSON, Unreal log, stdout, exit code and time consumption of `server`, `client-A`, `client-B0`, `client-B1` respectively, as well as their respective ACK, stage release, ready and final cleanup snapshots. PID, startup parameters, run ID, connection /World identity mapping and hash are written into the unified manifest, and associated host tests, HUD audit and each round of output. A single `client.json` cannot serve as the result of two clients.

Special summary and its associated end-to-end report records:

- `scope: loopback-dedicated-two-clients`, `required_client_count: 2`; protocol_validation List N01–N16 after all cross-checks are passed, and specific evidence is recorded according to the stage mapped to server/A/B0/B1 in Section 4.2. There is no multi-passenger pass sign on level P.
- Two repositories revision + dirty content identification, UE version /BuildId/ build source, Python version, configuration, script/asset /DLL hash.
- `cpp_compile_executed`, `cook_package_executed`, whether to perform cache preparation, and whether to display the client window.
- Pre-blocking, failed rounds, unexecuted B/C scenarios.
- `full_acceptance: false`; Online projects must not set the entire release pass flag.
- Stage-by-stage expected participants, actual number of connections, B0/B1 generation and final settlement of all started processes; cannot just save the last minute A/B1 roster.

Screenshots are only generated during supplementary testing with a visible network, and the original images and SHA-256 are retained. The results of NullRHI that are not rendered are clearly recorded as "Unchecked network images" and do not borrow images from other runs.

<a id="72-结论分类"></a>

### 7.2 Conclusion Classification

- **Passed**: A complete A layer from the same candidate source, N01–N16 all have verifiable evidence, A/B participates independently, server/A/B0/B1 the contracts after each process instance exits are met; only then can `multi_client_acceptance: true` be set.
- **Blocked**: Binary mismatch, unknown build source, and insufficient port/resource/authorization conditions were found before startup; it cannot be marked as a product and cannot be directly attributed to UEP functional defects.
- **Failed**: After starting to run, assertion failure, timeout, abnormal exit, lack of key evidence or source drift occur; keep the reason and start a new round after positioning.
- **Not run**: Scenario not yet executed; cannot be filled with host tests, old reports, Standalone, or screenshots.

Passed of dirty-tree can be recorded during the development period, but it must be associated with reproducible code/asset content before release; relevant use cases after changes need to be re-run. When only the document changes and the run input hash remains unchanged, the original run evidence can be retained and the relationship explained.

<a id="73-实施顺序与完成定义"></a>

### 7.3 Implementation sequence and completion definition

1. Enter implementation and operation from the plan according to user authorization; retain the source relationship of each failure and subsequent repairs.
2. Replenishing multiple players Bridge/probe, eliminating the need to build Network entries and invalid negative examples; first verify that explicit targets and drivers will reject untrusted input.
3. Resolve engine /stage mismatch and build necessary native adaptation, UBT Specify scope before starting; repin candidate sources.
4. Complete host checks, origin HUD audit and cache preparation; you can run P layer troubleshooting first, but you must continue to complete A layer. If it fails, locate it first and then start a new round.
5. Output special reports: N01–N16 player-by-player results, all process exit evidence, unexecuted items, actual compilation/packaging status.
6. Make separate arrangements for visible networking, weak networking, or release matrix; do not downgrade the two clients to optional, nor quietly expand to larger stress tests during execution.

The only conclusion of the completion of **A layer is: this candidate version passes Win64 Development, local one server and two customers’ Lyra Health replication, player target isolation, join/exit/reconnect and Python HUD Life cycle acceptance. ** One server and one customer can only be pre-checked; passing the A layer does not mean passing cross-machine, more client stress tests or packaging online, and does not automatically close the entire 0.8 release threshold.
