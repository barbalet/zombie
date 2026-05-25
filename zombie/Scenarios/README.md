# zombie Scenario Data

The active scenario catalog for cycles 1-100 is bundled with `ZombieCore` at:

`zombie/Sources/ZombieCore/Resources/catalog.json`

This keeps the SwiftUI app, unit tests, and regression runner pointed at the same deterministic data. Future cycles can split the catalog into one JSON file per scenario if the content becomes too large for review.
