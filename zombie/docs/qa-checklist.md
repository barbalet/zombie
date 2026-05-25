# QA Checklist

## Automated Gates

- `swift test` passes.
- `swift run ZombieRegression` reports zero failures.
- `xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' test` passes.
- `zombie/Scripts/package_demo.sh` produces a timestamped `Zombie.app` package.
- `git diff --check` is clean.

## Manual Smoke

- Launch the Mac Catalyst app.
- Search for `Play Mode Tutorial`, start Play Mode, and complete the tutorial.
- Search for `Drummuckavall`, start Play Mode from both side picker options, and confirm actor controls are enabled.
- Search for `Dungiven`, start Abstract Play Mode, use `Advance Route`, then `Resolve`.
- Search for `Crossmaglen`.
- Open `Battle of Newry Road`.
- Start Abstract Play Mode and confirm aircraft markers are visible.
- Open `1994 British Army Lynx Shootdown`.
- Run preview and confirm indirect-warning, indirect-impact, and structure-damage events appear.
- Filter to Deferred Review and confirm deferred rows are source-review content, not ordinary play.
- Confirm `Start Game` is disabled for `1985 Newry Mortar Attack`.

## Guardrails

- Civilian-risk scenarios include protected-zone tags.
- Deferred and out-of-region scenarios include scope warnings.
- No civilian actors are present in playable scenarios.
- Source links remain visible in detail views.
- Availability labels match the cycle-300 lock: Playable, Preview, Deferred, or Excluded.
- Copy Log produces JSONL with scenario ID, side, seed, outcome, and event fields.
- Copy Summary includes the source URL and scope warning.
