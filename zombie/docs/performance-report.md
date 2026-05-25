# Performance Report

## Baseline

The current UI renders small fixed-grid scenario boards and event logs. The largest bundled maps are below 15 by 10 cells, and regression replay covers all playable scenarios without long-running AI loops.

## Measured Gates

- Unit suite: sub-second after build.
- Regression suite: 22 playable scenarios plus optional deferred coverage in tests.
- UI smoke: launches Mac Catalyst app, opens scenario browser, runs preview, and verifies log output.

## Risks

- Event logs are currently displayed directly in SwiftUI and should be virtualized if scenarios grow much larger.
- Manual Xcode project wiring should be reviewed if many more source files are added.
- Screenshot baselines are documented but not yet stored as image artifacts.
