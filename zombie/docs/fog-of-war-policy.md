# Fog of War Policy

Cycle 252 decision: fog of war remains out of scope for the cycle-300 playable milestone.

Play Mode keeps all actors visible, all turn events public, and all deterministic replay logs inspectable. This avoids half-hidden state that would make manual replay, source review, and regression checks harder to trust. Hidden units, concealed movement, and partial-information UI can be reconsidered after the early-infantry campaign is playable, saved, resumed, exported, and packaged.

The current default is therefore:

- Visible actors on the board.
- Visible legal movement and target highlights.
- Public event logs.
- Deterministic replay seeds.
- No hidden combat resolution.
