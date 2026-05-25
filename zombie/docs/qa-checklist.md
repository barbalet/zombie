# QA Checklist

## Automated Gates

- `swift test` passes.
- `swift run ZombieRegression` reports zero failures.
- `xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' test` passes.
- `zombie/Scripts/package_demo.sh` produces a timestamped `Zombie.app` package.
- `git diff --check` is clean.

## Manual Smoke

- Launch the Mac Catalyst app.
- Confirm the sidebar offers `Playable Games`, shows the playable-games-ready count, and has an enabled `Start Game` button for the selected game.
- Search for `Play Mode Tutorial`, start Play Mode, and complete the tutorial.
- Search for `Drummuckavall`, start Play Mode from both side picker options, and confirm actor controls are enabled.
- Search for `Dungiven`, start Abstract Play Mode, use `Advance Route`, then `Resolve`.
- Search for `Crossmaglen`, open `Battle of Newry Road`, start Abstract Play Mode, and confirm aircraft markers are visible.
- Search for `Warrenpoint`, start Abstract Play Mode, use one abstract command, and confirm route/blast state is visible.
- Search for `1985 Newry Mortar Attack`, start Abstract Play Mode, use `React`, then `Resolve`.
- Open `1994 British Army Lynx Shootdown`.
- Run preview and confirm indirect-warning, indirect-impact, and structure-damage events appear.
- Filter to Deferred Review and confirm source-review rows can still start abstract Play Mode.

## Guardrails

- Civilian-risk scenarios include protected-zone tags.
- Deferred and out-of-region scenarios include scope warnings and abstract-only play text.
- No civilian actors are present in playable scenarios.
- Source links remain visible in detail views.
- Availability labels mark all bundled scenarios as Playable.
- Copy Log produces JSONL with scenario ID, side, seed, outcome, and event fields.
- Copy Summary includes the source URL and scope warning.
