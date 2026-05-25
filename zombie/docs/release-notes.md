# Release Notes

## Demo Candidate

This demo candidate includes a Mac Catalyst app, deterministic scenario catalog, unit/regression/UI tests, and 24 Wikipedia-backed scenario records. It is intended for local technical demonstration and source review.

## Implemented

- SwiftPM and Xcode Mac Catalyst targets.
- Field of Chaos C engine bridge.
- Scenario browser with search, tier filters, collections, source links, warnings, confidence fields, and tactical grid previews.
- Early infantry, vehicle, checkpoint, aircraft, and deferred mortar data.
- Deterministic regression simulator for infantry, vehicle/checkpoint, aircraft, and indirect-fire abstractions.
- Preview Mode for automated deterministic playback.
- Initial Play Mode spine for early infantry scenarios with side selection, manual commands, and deterministic AI stepping.
- Manual alpha Play Mode for Drummuckavall with actor inspection, action controls, board highlights, save/resume, reset, manual completion records, side comparison, side-aware objectives, and AI difficulty.
- Unit, UI, regression, packaging, and diagnostics scripts.

## Known Limits

- Preview Mode remains the complete automated path; Play Mode is in active development and currently has Drummuckavall as the polished manual alpha.
- Aircraft and mortar events are abstract timing systems only.
- Screenshot baselines are documented but not yet stored as image snapshots.
- Packaged app signing is local debug signing only.
