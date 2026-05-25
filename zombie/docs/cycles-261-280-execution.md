# Cycles 261-280 Execution Notes

Date: 2026-05-25

## Scope

Cycles 261-280 extend Play Mode beyond early infantry while keeping non-infantry actions at a safe abstraction level. The new path is called Abstract Play Mode in code and UI. It exposes scenario decisions as route advance, hold, react, and resolve commands rather than operational weapon procedures.

## Implemented

- Added `AbstractPlayableGameState`, `AbstractPlayableCommand`, `AbstractPlayableReplayResult`, and `PlayableAbstractEngine`.
- Added explicit play policies for vehicles, checkpoints, and aircraft.
- Added side-selectable starts for these ready scenarios:
  - `dungiven-1972`
  - `dungannon-1979`
  - `altnaveigh-1981`
  - `ballygawley-landmine-1983`
  - `derryard-1989`
  - `cloghoge-1992`
  - `glenanne-1991`
  - `loughgall-1987`
  - `newry-road-1993`
  - `lynx-shootdown-1994`
- Added stepable route progress, hazard triggers, damaged vehicle IDs, checkpoint alarm IDs, aircraft damage states, exited aircraft IDs, indirect-fire warning/impact state, and structure health.
- Added Abstract Play Mode UI with route state, checkpoint alarm state, aircraft markers, warning markers, damage state, and live log.
- Kept mortar-only and more complex staged vehicle scenarios out of Play Mode for this block.

## Preview-Only Decisions

These scenarios remain Preview Mode only in cycles 261-280:

- `mullacreevie-1991`
- `warrenpoint-1979`
- `fivemiletown-1993`
- `killeeshil-1994`
- `newry-mortar-1985`
- `osnabruck-mortar-1996`

The reason is not data absence. It is play-policy caution: staged reinforcements, civilian-risk guardrails, horizontal mortar abstractions, and mortar-only content need a later review pass before they become manual decisions.

Later update: the all-games playable pass added those manual decisions as abstract Play Mode paths with source/scope warnings.

## Verification

- `swift test` passes with 26 tests.
- `swift run ZombieRegression` passes with 23 scenarios, 0 failed, checksum `cf751efcebc2222a`.
- `xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' test` passes with 5 UI tests.
- `git diff --check` passes.
