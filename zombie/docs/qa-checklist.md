# QA Checklist

## Automated Gates

- `swift test` passes.
- `swift run ZombieRegression` reports zero failures.
- `xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' test` passes.
- `git diff --check` is clean.

## Manual Smoke

- Launch the Mac Catalyst app.
- Search for `Crossmaglen`.
- Open `Battle of Newry Road`.
- Run preview and confirm aircraft-lane and aircraft-damage events appear.
- Open `1994 British Army Lynx Shootdown`.
- Run preview and confirm indirect-warning, indirect-impact, and structure-damage events appear.
- Filter to Deferred Review and confirm deferred rows are source-review content, not ordinary play.

## Guardrails

- Civilian-risk scenarios include protected-zone tags.
- Deferred and out-of-region scenarios include scope warnings.
- No civilian actors are present in playable scenarios.
- Source links remain visible in detail views.
