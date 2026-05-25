# Cycles 221-240 Execution

This block turns the Play Mode spine into the first manual alpha. It keeps the scope limited to early infantry scenarios and treats vehicle, checkpoint, aircraft, mortar, deferred, and excluded scenarios as Preview Mode or future-playable work.

| Cycle | Result |
|---:|---|
| 221 | Reworked outcome text so finished games name the force outcome, objective distance result, or draw state. |
| 222 | Added a deterministic Drummuckavall smoke playthrough that can finish from either side. |
| 223 | Promoted Play Mode into a dedicated panel with board, side, turn, phase, difficulty, objective, controls, inspector, and log. |
| 224 | Added an actor inspector with status, role, weapon, stats, skills, wound total, clips, and rounds. |
| 225 | Added action controls for Move, Attack, Wait, End Turn, Cancel, and Abandon. |
| 226 | Highlighted legal movement cells on the play board. |
| 227 | Highlighted legal attack targets on the play board. |
| 228 | Kept the live Play Mode log in the panel and consistently shows the latest events at the bottom. |
| 229 | Added keyboard/menu commands for next actor, cancel, wait, and end turn. |
| 230 | Added user-facing blocked-action messages for missing actor selection and illegal commands. |
| 231 | Added `PlayableGameSave` for saved scenario, side, actors, turn, log, seed, and difficulty state. |
| 232 | Added local resume from the last saved Play Mode run. |
| 233 | Added abandon/reset flow with confirmation and save cleanup. |
| 234 | Added manual completion records separate from regression preview completions. |
| 235 | Added a clearer play setup area with side selection. |
| 236 | Added side-aware objective briefing text. |
| 237 | Added force comparison summaries before launch. |
| 238 | Added easy, standard, and hard AI difficulty settings that persist in play state and saves. |
| 239 | Added scored AI movement and target preference using objective distance, cover, active targets, and difficulty. |
| 240 | Marked Drummuckavall as the first manual alpha path, verified from either side. |

## Verification Intent

- Unit tests cover save/restore, difficulty persistence, side-aware objective copy, blocked command text, and complete Drummuckavall smoke runs from both sides.
- UI smoke covers Play Mode launch, actor inspector visibility, and one blocked action message.
- Regression Preview remains separate from manual Play Mode completion records.
