# Performance Report

## Baseline

The current UI renders small fixed-grid scenario boards and event logs. The largest bundled maps are below 15 by 10 cells, and regression replay covers all playable scenarios without long-running AI loops.

## Measured Gates

- Unit suite: 30 tests after cycle 300.
- Regression suite: 23 playable preview scenarios.
- UI smoke: launches Mac Catalyst app, opens scenario browser, runs preview, starts infantry Play Mode, starts abstract Play Mode, completes the tutorial, and verifies deferred guardrails.
- Release rehearsal: tutorial, three early infantry scenarios, and one abstract vehicle scenario finish without intervention.

## Risks

- Event logs are currently displayed directly in SwiftUI and should be virtualized if scenarios grow much larger.
- Manual Xcode project wiring should be reviewed if many more source files are added.
- Screenshot baselines are documented but not yet stored as image artifacts.
- Play Mode boards are still fixed-grid SwiftUI views; current largest bundled map is small enough for responsive input, but larger maps should move to a virtualized or Metal-backed interaction layer.
