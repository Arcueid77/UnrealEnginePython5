[English](Original_Migration_Acceptance.en.md) | [简体中文](Original_Migration_Acceptance.md)

<a id="原定-python-替换范围验收"></a>

# Original scheduled Python Replacement scope acceptance

2026-10-28: The original **246 candidates and 22/22 acceptance criteria have passed **. The applicable scope is UE 5.8 / CPython 3.11, Win64 Development.

| Migration stage | original candidate | Condition passed |
| --- | ---: | ---: |
| 0.9.0 | 5 | 7/7 |
| 0.10.0 | 32 | 3/3 |
| 0.11.0 | 37 | 3/3 |
| 0.12.0 | 75 | 3/3 |
| 0.13.0 | 57 | 3/3 |
| 0.14.0 | 40 | 3/3 |

The original path, sequence, version assignments and original acceptance text of 22 remain unchanged. The 182 configuration shells, 63 reserved items and 11 scope reviews among the 491 audited assets continue to have their own clear processing reasons. The original ROADMAP is retained as the baseline, and the current receipt record can be found in the link below.

The last three batches completed the candidate regression matrix, supported API frozen review, and Explorer/TopDownArena comparative acceptance of the two Experiences. The last batch of reviews 49 original component operation records and a shared Cue parent class record; six groups of current original blueprint /Python process comparisons and 16 accepted UE processes all passed. They cover menus, scene interaction, follow navigation and cancel/cut, dual client prediction interaction and ownership, as well as dual local player natural bombs, death, quantity refund, HUD, opponent kills and scoring.

Six actual screenshots of both Arena modes have been verified: player 0's bomb count is 1→0→1, and player 1 maintains 1. Native debug text, warnings, and visual blurring of death transitions remain in evidence.

Adopt incremental verification: The original 21 item is reused after inputting fingerprints, Git source code differences and list comparisons to re-verify the affected Experience process. The last batch of 33 items Python directed checks and 16 control checks passed; no new compilation or Cook was added. Five sets of early network records, failed controllers, and their precise source code snapshots are retained, and together with the final acceptance, a total of 31 and UE processes are run, of which 16 are finally accepted. Failure records are not overwritten as successes.

The server local montage callback count alone cannot prove the end of GAS. The final check is related to the native active status of the same skill instance, the completed instance /Spec/ task status, the client completion callback and the actual authoritative result; it does not claim to be able to intercept any native C++ events. Only test observation and control were modified, not production game strategies, assets or normal startup logic.

This acceptance still requires batch 246 of approved, verified quarantined Lyra Hero initialization patches. The official Lyra catalog remains unchanged; official original issues and native NetShooter baseline differences continue to be clearly documented. Engine common systems, animation/layout/declarations that were originally intended to be retained, and wider game C++ migration continue to follow the original scope.

The `false` capability flag in the historical capture retains its original meaning, and the evidence is finally merged according to the original 22 condition and support matrix, without changing all historical flags to `true`. There is no expansion to other platforms/configurations, hardware inputs, full-frame pixels, or audio consistency, and no RC tags or releases have been created.

- [Item-by-item acceptance and evidence boundaries](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/ACCEPTANCE_REVIEW.md)
- [The 275 final batch of evidence ledger] (../Demos/UEPLyraIntegration/Migration/Acceptance/275-original-explorer-arena-and-final-migration-acceptance.json)
- [Migration Progress](https://github.com/Arcueid77/UnrealEnginePython5Examples/blob/dev/release-1.0.0/UEPLyraIntegration/Migration/PROGRESS.md)
- [Supported API List](Supported_API_Inventory.md)
- [API Freeze Review](RC_API_Review_0.9.md)
- [Mixin Call and life cycle boundaries](Mixin_Call_Lifecycle_Matrix.md)
