# Cycles 201-220 Execution

This block starts the cycle-300 playable-game plan. The goal is to preserve the existing deterministic preview while adding a separate Play Mode that can become a side-selectable, turn-by-turn game.

| Cycle | Result |
|---:|---|
| 201 | Renamed the existing automated flow conceptually as Preview Mode in README and release notes. |
| 202 | Locked the first Play Mode scope to early infantry scenarios; non-infantry tiers remain Preview Mode until their abstractions are safe as player decisions. |
| 203 | Added `PlayableGameState` as the persistent turn-by-turn state model. |
| 204 | Made the game state Codable and added round-trip test coverage. |
| 205 | Added human side selection using existing scenario force sides. |
| 206 | Kept side labels independent from human control so either historical side can be selected. |
| 207 | Added a `Start Game` path beside `Run Preview` in the scenario detail view. |
| 208 | Added `activeGame` state to the app store so Play Mode does not overwrite Preview Mode results. |
| 209 | Added explicit phases: setup, human activation, AI activation, resolution, and finished. |
| 210 | Added typed commands for move, attack, wait, and end turn. |
| 211 | Added legal movement calculation using map movement costs, occupancy, blocked cells, and protected cells. |
| 212 | Added legal target calculation through the Field of Chaos targeting preview. |
| 213 | Added selected actor, move target, and attack target state. |
| 214 | Added movement command execution and play-log events. |
| 215 | Added attack execution through the Field of Chaos ranged attack API. |
| 216 | Added wait command execution and play-log events. |
| 217 | Added end-turn execution that hands control to AI and returns to the human side. |
| 218 | Made Drummuckavall launchable in Play Mode from either side. |
| 219 | Added a deterministic AI adapter using the same high-level move/attack/wait behavior as the preview simulator. |
| 220 | Added AI activation looping for the opposing side. |

## Verification Intent

- Unit tests cover Play Mode start, side selection, Codable round-trip, movement, AI turn advancement, and Field of Chaos-backed attack execution.
- Existing regression preview remains unchanged and should continue to pass.
- Play Mode is intentionally limited to early infantry scenarios in this block.
