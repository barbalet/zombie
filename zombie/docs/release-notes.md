# Release Notes

## Demo Candidate

This demo candidate includes a Mac Catalyst app, deterministic scenario catalog, unit/regression/UI tests, 24 Wikipedia-backed scenario records, and one fictional Play Mode tutorial. It is intended for local technical demonstration and source review.

## Implemented

- SwiftPM and Xcode Mac Catalyst targets.
- Field of Chaos C engine bridge.
- Scenario browser with search, tier filters, collections, source links, warnings, confidence fields, and tactical grid previews.
- Early infantry, vehicle, checkpoint, aircraft, and deferred mortar data.
- Deterministic regression simulator for infantry, vehicle/checkpoint, aircraft, and indirect-fire abstractions.
- Preview Mode for automated deterministic playback.
- Initial Play Mode spine for early infantry scenarios with side selection, manual commands, and deterministic AI stepping.
- Manual alpha Play Mode for Drummuckavall with actor inspection, action controls, board highlights, save/resume, reset, manual completion records, side comparison, side-aware objectives, and AI difficulty.
- Manual beta replay for all early infantry scenarios from either side, plus a fictional tutorial, visible turn order, actor status, log filters, replay seed display, and documented fog-of-war deferral.
- Abstract Play Mode for the first safe vehicle, checkpoint, and aircraft tier scenarios with route advance, hold, react, resolve, alarm state, aircraft markers, warning markers, damage state, and side-selectable smoke replay.
- Cycle-300 availability labels, deferred guardrails, versioned save recovery, JSONL play-log copy, human-readable summary copy, and release rehearsal coverage.
- Unit, UI, regression, packaging, and diagnostics scripts.

## Known Limits

- Preview Mode remains the automated validation path; Play Mode now covers every bundled scenario either tactically or through an abstract state model.
- Fog of war is deferred; actors and logs are visible for replay and review.
- Vehicle blasts, checkpoint damage, aircraft events, and mortar/indirect-fire events are abstract timing and state systems only.
- Mortar-only and complex staged vehicle scenarios are playable through abstract setup, warning, route, impact, and damage-state events.
- Save recovery uses local UserDefaults primary/backup payloads. It is sufficient for the demo baseline, not a multi-slot campaign save system.
- Screenshot baselines are documented but not yet stored as image snapshots.
- Packaged app signing is local debug signing only.
