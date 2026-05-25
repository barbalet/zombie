# Privacy and Storage

The demo stores no network credentials and sends no telemetry.

Local generated data may include:

- SwiftPM build output under `.build/`.
- Xcode DerivedData outside the repository.
- Optional package output under `zombie/build/`.
- Optional diagnostic output under `zombie/reports/`.
- UserDefaults Play Mode saves under `zombie.activeGameSave.v1` and `zombie.activeGameSave.backup.v1`.
- UserDefaults manual completion records under `zombie.playableCompletionRecords.v1`.
- Clipboard contents when the user presses copy seed, copy log, or copy summary.

The catalog, scenario schemas, docs, and tests are bundled local files. Wikipedia links open externally when selected by the user.
