# Cycles 001-100 Execution Notes

This file records the first 100 development cycles from `PLAN.md` as implemented artifacts. The goal of this block is an early playable Mac Catalyst-oriented `zombie` app wired to the existing `fieldofchaos` engine, backed by Wikipedia-sourced two-force battle data and repeatable regression checks.

## Completed Cycle Bands

| Cycles | Result |
| --- | --- |
| 001-010 | Added SwiftPM workspace, C engine target wiring, shared `ZombieCore` module, and bundled catalog resources. |
| 011-020 | Added scenario schema, typed Swift scenario models, catalog loading, validation, and source metadata rules. |
| 021-040 | Added 20 playable Wikipedia-backed scenarios spanning early infantry, vehicle-route, and checkpoint tiers. |
| 041-050 | Added Field of Chaos adapter for actor-to-`FocCharacter` conversion and engine version exposure. |
| 051-070 | Added deterministic infantry simulator with movement, targeting preview, ranged attacks, objective outcomes, and protected-zone blocking. |
| 071-090 | Added abstract vehicle/checkpoint simulator with route events, blast triggers, alarm phases, and protected-route violation detection. |
| 091-100 | Added SwiftUI app shell, regression runner, unit/UI tests, script entry points, and documentation for repeatable demo gates. |

## Playable Scope

The first playable catalog contains 20 scenarios:

- 8 early infantry skirmishes for board movement and Field of Chaos ranged combat.
- 8 vehicle-route interdiction scenarios for convoy, patrol, and route survival mechanics.
- 4 checkpoint and base-attack scenarios for alarm phases, structures, and combined route/structure pressure.

Civilian harm and public-space risk are represented as protected noncombat cells. The simulator blocks movement into protected cells and never creates civilian actors.

## Test Gates

Run all first-100 gates from the repository root:

```sh
zombie/Scripts/run_smoke.sh
```

Individual gates:

```sh
zombie/Scripts/run_unit.sh
zombie/Scripts/run_regression.sh
```

The unit suite covers catalog validation, Wikipedia source coverage, Field of Chaos adapter sanity, deterministic infantry simulation, all-playable regression outcomes, vehicle/checkpoint event emission, and protected-zone declarations. The Xcode UI smoke target launches the Mac Catalyst app, checks the scenario browser, runs a preview, and verifies that the regression preview appears.

## Demo Readiness

The SwiftUI app loads the bundled catalog, filters scenarios by tier, renders a tactical grid, shows force and actor panels, and can run the deterministic simulator for the selected scenario. It is intentionally still prototype-simple, but it proves the engine, data, UI, and regression loop are connected for the next 100 cycles.
