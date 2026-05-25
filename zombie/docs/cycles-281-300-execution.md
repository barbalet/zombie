# Cycles 281-300 Execution Notes

Date: 2026-05-25

## Scope

Cycles 281-300 close the playable-game baseline. The work focuses on launch guardrails, final availability labels, save recovery, export surfaces, playtest documentation, package verification, and release rehearsal.

## Implemented

- Added cycle-300 availability labels: `Playable`, `Preview`, `Deferred`, and `Excluded`.
- Blocked Play Mode launch for Preview, Deferred, mortar-only, and excluded content.
- Added versioned `PlayableGameSave` decoding and safe rejection of unsupported save schemas.
- Added primary/backup save recovery for active Play Mode saves.
- Added copyable Play Mode JSONL exports for infantry and abstract games.
- Added copyable human-readable Play Mode summaries with scenario ID, source URL, side, seed, outcome, and scope warning.
- Added release rehearsal coverage for the tutorial, three early scenarios, and one non-infantry abstract scenario.
- Updated demo, QA, performance, privacy/storage, README, release notes, and package script documentation.

## Content Lock

Cycle-300 Play Mode content:

- All early infantry/tutorial scenarios.
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

Preview-only content:

- `mullacreevie-1991`
- `warrenpoint-1979`
- `fivemiletown-1993`
- `killeeshil-1994`

Deferred content:

- `newry-mortar-1985`
- `osnabruck-mortar-1996`

## Verification

Final closeout gates:

- `swift test` passed with 30 tests.
- `swift run ZombieRegression` passed with 23 scenarios, 0 failures, and checksum `cf751efcebc2222a`.
- `xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' test` passed with 6 UI tests. Xcode also emitted a low-disk result-bundle warning while writing test summaries, but the test run itself completed with `** TEST SUCCEEDED **`.
- `zombie/Scripts/package_demo.sh` built and packaged `zombie/build/ZombieDemo-20260525-080822/Zombie.app`.
- `git diff --check` passed.
