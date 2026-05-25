# Cycles 101-200 Execution Notes

This file records the second 100 development cycles from `PLAN.md` as implemented artifacts. The goal of this block is to move the prototype from early/vehicle beta into an advanced, demoable, testable Mac Catalyst package candidate.

## Completed Cycle Bands

| Cycles | Result |
| --- | --- |
| 101-120 | Added aircraft lanes, aircraft damage states, indirect-fire timing, structure damage, and advanced scenarios for Newry Road and the 1994 Lynx shootdown. |
| 121-140 | Added confidence metadata, scope warnings, collections, search, completeness matrix, richer browser details, and advanced/deferred filters. |
| 141-160 | Expanded unit, regression, UI, export, diagnostics, and packaging scripts. |
| 161-175 | Added neutral-language sensitivity audit, tutorial/demo planning, QA checklist, and release-candidate issue buffers as documented gates. |
| 176-200 | Added content/schema/regression lock notes, release notes, demo script, privacy/storage notes, license checklist, and artifact manifest guidance. |

## Advanced Playable Scope

The catalog now has 24 scenarios:

- 8 early infantry scenarios.
- 8 vehicle-route scenarios.
- 4 checkpoint/base scenarios.
- 2 playable aircraft/advanced scenarios.
- 2 deferred mortar/review scenarios.

Advanced scenarios use abstract lanes, warning turns, impact markers, and structure health. They intentionally avoid weapon recipes, procedural flight details, civilian targeting, or crowd conflict.

## Test Gates

Run all automated gates from the repository root:

```sh
zombie/Scripts/run_smoke.sh
```

Individual gates:

```sh
zombie/Scripts/run_unit.sh
zombie/Scripts/run_regression.sh
zombie/Scripts/run_ui.sh
zombie/Scripts/package_demo.sh
zombie/Scripts/collect_diagnostics.sh
```

## Release Readiness

The current state is a local demo candidate. It has a playable Mac Catalyst app, source-visible scenario browser, protected-zone guardrails, deterministic regression replay, UI smoke coverage, and packaging/diagnostic scripts. It is not a historical authority; Wikipedia links remain visible for source inspection and every advanced/deferred scenario carries a scope warning.
