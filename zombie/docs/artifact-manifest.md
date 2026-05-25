# Artifact Manifest

Release-candidate artifacts should include:

- `Zombie.app` from the timestamped `zombie/build/ZombieDemo-*` directory created by `zombie/Scripts/package_demo.sh`.
- `README.md`.
- `PLAN.md`.
- `zombie/docs/release-notes.md`.
- `zombie/docs/demo-script.md`.
- `zombie/docs/playtest-script.md`.
- `zombie/docs/qa-checklist.md`.
- `zombie/docs/sensitivity-audit.md`.
- `zombie/docs/privacy-storage.md`.
- `zombie/docs/license-checklist.md`.
- Regression output from `zombie/Scripts/collect_diagnostics.sh`.

The content checksum is reported by the diagnostic manifest generated from the catalog.
