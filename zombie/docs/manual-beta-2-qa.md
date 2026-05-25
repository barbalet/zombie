# Manual Beta 2 QA Notes

Date: 2026-05-25

## Rehearsed Paths

- `play-mode-tutorial` completed through the tutorial shortcut.
- `drummuckavall-1975`, `glasdrumman-1981`, and `kesh-1984` complete through deterministic Play Mode rehearsal.
- `dungiven-1972` completes through Abstract Play Mode rehearsal.
- Deferred guardrail is covered by `newry-mortar-1985` availability checks.

## Results

- No untriaged blocker remains in side selection or launch.
- Early Play Mode command validation remains deterministic and protected cells stay untargetable.
- Abstract Play Mode route and resolve commands reach an outcome.
- Save recovery falls back to the backup payload if the primary save is invalid.
- Play log export and summary export include scenario ID, side, seed, outcome, source URL, and scope warning.

## Follow-Up Backlog

- Multi-slot manual saves.
- A real file export picker instead of clipboard-based export.
- Stored screenshot baselines for board states.
- Larger-map interaction profiling once maps exceed the current small fixed-grid boards.
