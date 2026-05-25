# Cycles 241-260 Execution

This block promotes early-infantry Play Mode from one manual alpha scenario to a deterministic manual beta across the early corpus. It keeps all combat decisions at the existing high-level actor, cell, and outcome abstraction.

| Cycle | Result |
|---:|---|
| 241 | Verified Glasdrumman from both sides through the deterministic Play Mode replay corpus. |
| 242 | Verified Kesh from both sides and asserted protected restaurant cells are never legal movement or target cells. |
| 243 | Verified Strabane from both sides and covered small-force exit-style play through the corpus. |
| 244 | Verified Drumnakilly from both sides while keeping vehicle approach as an infantry-tier abstraction. |
| 245 | Verified Operation Conservation from both sides using the same counter-ambush objective model. |
| 246 | Verified Coagh from both sides and checked protected village cells remain untargetable. |
| 247 | Verified Clonoe from both sides and kept contested-history handling in metadata and neutral game copy. |
| 248 | Added deterministic early-corpus replay for every early scenario and both sides. |
| 249 | Confirmed all early infantry scenarios are side-selectable and replayable from either side. |
| 250 | Added balance coverage that rejects early side-runs ending on turn 1. |
| 251 | Added fairness coverage for protected-zone violations in manual Play Mode replays. |
| 252 | Documented that fog of war stays out of scope for cycle 300; actors and logs remain visible. |
| 253 | Expanded actor status visibility through the inspector and status text. |
| 254 | Added active actor and remaining activation text to Play Mode. |
| 255 | Added Play Mode log filters for all, movement, attacks, AI, and outcome events while preserving the raw event log. |
| 256 | Added replay seed display and copy support. |
| 257 | Added explicit cancel-before-commit undo policy; movement and dice actions remain final. |
| 258 | Added a fictional Play Mode Tutorial scenario and map. |
| 259 | Added tutorial step guidance and UI smoke completion. |
| 260 | Established manual beta 1: the full early infantry set can finish from either side in deterministic replay. |

## Verification Intent

- Unit tests cover all early scenario side-runs, tutorial completion, protected-cell safety, fictional source handling, save/seed persistence, and blocked command copy.
- UI tests cover Play Mode launch, actor inspection, blocked-action messaging, and tutorial completion.
- Fog of war is deferred by policy rather than partially implemented.
