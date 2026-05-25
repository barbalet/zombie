# zombie 200 Cycle Technical Plan

## Goal

Make zombie demoable early, then grow it into a historically sourced, testable Mac Catalyst tactical simulation using the existing Field of Chaos C engine and SwiftUI/Metal app shell as the starting point.

The first playable target is a `zombie.xcodeproj` Mac Catalyst app that launches from Xcode, opens a small scenario browser, loads one early infantry scenario, renders the board, lets a player take turns against a simple opponent, and records deterministic combat events. That early target should land by cycle 30.

## Scope Rules

- Use Wikipedia for the first battle index, then let later cycles add source review and data confidence fields.
- Only model bounded two-force armed engagements.
- Exclude civilian-targeted attacks and military/civilian crowd conflicts from playable scenarios.
- Treat civilian presence, when historically unavoidable, as protected map constraints or as a reason to defer the scenario.
- Keep the Field of Chaos C engine authoritative for dice, combat, event logs, and reusable tactical mechanics until zombie-specific mechanics are proven.

## Architecture Direction

- `foc/` remains the reusable rules and tactical engine.
- `zombie/` should be added as the game-specific app, scenario, and content layer.
- `zombie.xcodeproj` should be created early as a Mac Catalyst Xcode project or workspace target, linked to the local Field of Chaos engine module.
- Scenario data should be JSON first, with versioned schema and deterministic seeds.
- SwiftUI owns scenario browsing, source notes, rosters, inspectors, logs, settings, and packaging.
- Metal owns board rendering once the first app shell is stable.
- C owns reusable deterministic mechanics and event emission.

## Test Strategy

Testing is not a final hardening pass. It is part of every phase:

- Unit tests cover C engine rules, scenario parsing, validation, map conversion, weapon mapping, and deterministic AI choices.
- Regression tests replay fixed seeds for each implemented scenario and compare event summaries, outcomes, and invariants.
- UI tests launch the Mac Catalyst app, load scenarios, play a short turn sequence, inspect the log, and verify persistence.
- Snapshot or screenshot tests check board layout, source panels, roster panels, and responsive Mac Catalyst windows.
- Release smoke tests run from Xcode and command line before every milestone.

## Milestones

| Milestone | Cycles | Result |
|---|---:|---|
| Research Baseline | 1-10 | README battle scope, Wikipedia source index, and inclusion rules are in place. |
| Technical Skeleton | 11-20 | zombie folders, schemas, adapter shape, Xcode approach, and test harness are specified. |
| Early Playable Mac Catalyst Demo | 21-30 | `zombie.xcodeproj` launches a playable infantry skirmish through the Field of Chaos bridge. |
| Scenario Content Alpha | 31-50 | Early infantry scenario data, maps, rosters, and validation are implemented. |
| Play Loop Alpha | 51-70 | Board interaction, AI, logs, persistence, and regression seeds support repeatable play. |
| Vehicle and Checkpoint Systems | 71-100 | Vehicle routes, mines, checkpoints, base geometry, and blast abstractions unlock tier-2 scenarios. |
| Aircraft and Mortar Systems | 101-125 | Aircraft lanes, indirect fire, warning timing, and base damage unlock advanced scenarios. |
| Historical Scenario Browser | 126-145 | Source notes, filters, sensitivity tags, map previews, and scenario completion tracking are polished. |
| QA and Packaging Beta | 146-175 | Xcode schemes, CI scripts, UI automation, packaged app, and performance checks are stable. |
| Release Candidate | 176-200 | Content lock, regression lock, accessibility, docs, packaging, and demo release are complete. |

## Execution Status

Cycles 1-100 have been run into an executable prototype baseline:

- Added SwiftPM targets for `ZombieCore`, `ZombieApp`, `ZombieRegression`, and the local Field of Chaos C engine.
- Added `zombie.xcodeproj` with a shared `Zombie` Mac Catalyst scheme and Xcode bridging header for the C engine.
- Added a bundled JSON catalog with 20 playable Wikipedia-backed two-force scenarios across early infantry, vehicle, and checkpoint tiers.
- Added typed scenario models, catalog validation, Field of Chaos actor conversion, deterministic infantry simulation, and abstract vehicle/checkpoint simulation.
- Added a SwiftUI scenario browser, tactical grid preview, force/actor panels, source link, mechanics summary, and event log preview.
- Added unit, UI smoke, and regression coverage for catalog validity, Wikipedia links, engine adapter wiring, deterministic simulation, protected-zone handling, vehicle/checkpoint events, and app launch/run-preview flow.
- Added scripts under `zombie/Scripts/` and implementation notes under `zombie/docs/cycles-001-100-execution.md`.

Verified gates for cycles 1-100:

- `swift test`
- `swift run ZombieRegression`
- `xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' build`
- `git diff --check`

Cycles 101-200 have also been run into a local demo-candidate baseline:

- Added aircraft lanes, indirect-fire timing, structure health, advanced events, and playable advanced scenarios for Newry Road and the 1994 Lynx shootdown.
- Added deferred/review-only mortar content for Newry and Osnabruck with explicit scope warnings and release filters.
- Added data confidence, scope warnings, scenario collections, search, completion records, JSONL event export, catalog checksums, and diagnostic manifests.
- Expanded the Mac Catalyst browser with search, collection filtering, advanced tier filters, confidence display, source warnings, aircraft/mortar board markers, and mechanics details.
- Added unit coverage for advanced simulation, deferred filtering, search, collections, completeness, exports, and diagnostics.
- Added Xcode UI smoke coverage for launch, browse, run preview, and event-log display.
- Added release scripts and docs for QA, packaging, diagnostics, sensitivity review, performance notes, storage/privacy, license checks, demo script, release notes, and artifact manifests.

Verified gates for cycles 101-200:

- `swift test`
- `swift run ZombieRegression`
- `swift run ZombieRegression --include-deferred`
- `xcodebuild -project zombie.xcodeproj -scheme Zombie -configuration Debug -destination 'platform=macOS,variant=Mac Catalyst' test`
- `zombie/Scripts/package_demo.sh`
- `zombie/Scripts/collect_diagnostics.sh`
- `git diff --check`

## 200 Cycle Map

| Cycle | Focus | Deliverable | Test Gate |
|---:|---|---|---|
| 1 | Read project docs | Confirm root README scope and current `foc` structure. | Documentation review complete. |
| 2 | Wikipedia source index | Capture primary battle index links and source categories. | Source links resolve in README. |
| 3 | Inclusion rules | Define two-force, non-civilian playable criteria. | README scope checklist reviewed. |
| 4 | Candidate battle table | Add all first-pass candidate battles and Wikipedia links. | Link table checked manually. |
| 5 | Exclusion rules | Mark riot, civilian-targeted, and off-duty/civilian-heavy cases. | Excluded examples documented. |
| 6 | Field of Chaos wiring review | Document C API, Swift bridge, state store, skirmish model, and renderer. | File paths verified locally. |
| 7 | Data taxonomy | Define scenario fields for date, forces, map, weapons, source, and tier. | Schema requirements listed. |
| 8 | Early demo choice | Select infantry-ready scenarios for the first playable slice. | Early set has at least 3 candidates. |
| 9 | Testing policy | Add unit, UI, and regression testing expectations. | Test policy appears in README/PLAN. |
| 10 | Plan baseline | Create this 200-cycle plan and milestone map. | PLAN.md committed to docs review. |
| 11 | Repository layout | Add planned `zombie/` folder map for app, data, tests, and tools. | Layout can be reviewed before code. |
| 12 | Scenario schema draft | Define `scenario.schema.json` fields and validation rules. | Unit-test cases written as fixtures. |
| 13 | Force schema draft | Define force, unit, actor, weapon, and side labels. | Invalid-force fixtures planned. |
| 14 | Map schema draft | Define grid, terrain, roads, buildings, cover, elevation, and exits. | Map validation cases planned. |
| 15 | Source metadata schema | Add source URL, revision date, confidence, and sensitivity tags. | Bad URL and missing-source cases planned. |
| 16 | Field of Chaos adapter plan | Design scenario-to-engine translation boundary. | Adapter API reviewed against `fieldofchaos_engine.h`. |
| 17 | Event log contract | Define zombie event labels over Field of Chaos events. | Deterministic event assertions planned. |
| 18 | Xcode project strategy | Decide project vs workspace and target names for Mac Catalyst. | Build settings checklist drafted. |
| 19 | Automation strategy | Define command-line build, unit, UI, and smoke scripts. | Script names and expected outputs listed. |
| 20 | Skeleton readiness review | Freeze early-demo acceptance criteria. | Demo checklist signed off in PLAN. |
| 21 | Create app project | Add `zombie.xcodeproj` Mac Catalyst target or workspace. | Xcode opens project successfully. |
| 22 | Link engine | Link Field of Chaos C engine into zombie target. | Unit test calls `foc_engine_version()`. |
| 23 | App launch | Add minimal SwiftUI Mac Catalyst app shell. | UI test launches app to first screen. |
| 24 | Scenario browser shell | Show grouped scenario list with tier badges. | UI test sees seeded scenario row. |
| 25 | Scenario fixture | Add one Drummuckavall or Glasdrumman JSON fixture. | Unit test validates fixture schema. |
| 26 | Board preview | Convert fixture map to a simple rendered board. | Screenshot test confirms nonblank board. |
| 27 | Roster preview | Show both forces and generated Field of Chaos actors. | Unit test validates actor conversion. |
| 28 | First board actions | Route select, move, wait, and attack through the engine. | Regression test replays one turn. |
| 29 | Event log panel | Display deterministic dice/combat events in-app. | UI test opens and filters log. |
| 30 | Early playable demo | Play one infantry skirmish from scenario browser to outcome. | Smoke test covers launch, play, log, quit. |
| 31 | Scenario loader hardening | Load scenario files from bundle and support directory. | Unit tests cover missing and malformed files. |
| 32 | Scenario validation UI | Show actionable errors for invalid scenario data. | UI test loads a bad fixture. |
| 33 | Map conversion | Convert terrain tags into movement and cover modifiers. | Regression test checks legal cells. |
| 34 | Force balancing metadata | Add rough difficulty and side selection fields. | Unit test validates difficulty bounds. |
| 35 | Weapon mapping | Map historical weapon categories to current engine choices. | Unit test checks every fixture weapon maps. |
| 36 | Civilian exclusion zones | Add protected/no-fire/no-entry map annotations. | Unit test rejects attacks into protected cells. |
| 37 | Scenario source panel | Show Wikipedia link, source title, and neutral context. | UI test opens source panel. |
| 38 | Scenario filters | Filter by early, vehicle, aircraft, deferred, and excluded. | UI test changes filters. |
| 39 | Deterministic seeds | Persist visible seed per scenario run. | Regression test repeats identical first turn. |
| 40 | Content alpha review | Validate first three early scenarios against schema. | All alpha fixtures pass validation. |
| 41 | Drummuckavall map | Implement first pass map, forces, and objective. | Regression test completes seeded run. |
| 42 | Drummuckavall polish | Tune cover, elevation, and withdrawal zones. | Screenshot comparison reviewed. |
| 43 | Glasdrumman map | Implement first pass map, forces, and objective. | Regression test completes seeded run. |
| 44 | Glasdrumman polish | Tune hidden observation post and firing lanes. | Unit test checks hidden/deployed states. |
| 45 | Kesh map | Implement first pass map, forces, and objective. | Regression test completes seeded run. |
| 46 | Kesh polish | Add restaurant/road/river constraints as abstract terrain. | UI smoke covers Kesh start. |
| 47 | Strabane map | Implement first pass map, forces, and objective. | Regression test completes seeded run. |
| 48 | Drumnakilly map | Implement first pass map, forces, and objective. | Regression test completes seeded run. |
| 49 | Operation Conservation map | Implement first pass map, forces, and objective. | Regression test completes seeded run. |
| 50 | Scenario content alpha | Ship six infantry scenario fixtures as alpha content. | Batch regression runs all fixtures. |
| 51 | Turn controller | Improve initiative, activation, and action availability. | Unit tests cover invalid turn actions. |
| 52 | AI baseline | Add deterministic opponent behavior for early scenarios. | AI seed tests pick expected actions. |
| 53 | AI objectives | Add defend, withdraw, patrol, and delay objective scoring. | Regression checks no AI stalls. |
| 54 | Action explanations | Show why movement or attacks are available. | UI test checks disabled action text. |
| 55 | Combat log links | Link combat events back to scenario and rule notes. | UI test opens event detail. |
| 56 | Save and resume | Autosave active skirmish and restore on launch. | UI test relaunches and resumes. |
| 57 | Manual save slots | Add named skirmish saves. | Unit test validates save schema. |
| 58 | End screen | Show outcome, source link, and event summary. | UI test reaches end screen. |
| 59 | Accessibility pass 1 | Add labels for board cells, actors, and log rows. | Accessibility UI smoke runs. |
| 60 | Play loop alpha | Complete one-hour playtest on early infantry set. | Regression baseline captured. |
| 61 | Coagh map | Add Coagh as a sensitive early scenario. | Regression test seeded run. |
| 62 | Clonoe map | Add Clonoe as a sensitive early scenario. | Regression test seeded run. |
| 63 | Sensitivity notes | Add legal/history note fields for contested events. | Unit test requires notes on tagged scenarios. |
| 64 | Scenario difficulty | Add easy, standard, hard AI presets per scenario. | AI regression covers all presets. |
| 65 | Roster editing | Allow scenario-local roster stat tweaks in debug mode. | Unit test validates stat bounds. |
| 66 | Import/export scenario | Export scenario JSON and import from disk. | Unit test round-trips fixture. |
| 67 | Debug overlay | Add seed, coordinates, actor IDs, and terrain under cursor. | UI test toggles overlay. |
| 68 | Event export | Export JSONL event logs. | Regression compares exported event shape. |
| 69 | Crash-safe persistence | Write saves atomically and recover corrupt saves. | Unit test corrupts save fixture. |
| 70 | Alpha QA checkpoint | Run full early infantry smoke pass. | Smoke report has no release blockers. |
| 71 | Vehicle model draft | Define vehicle actors, routes, armor, passengers, and wrecks. | Unit tests cover vehicle schema. |
| 72 | Road route model | Add road lanes, choke points, and convoy paths. | Map validation checks connected routes. |
| 73 | Explosive abstraction | Add blast radius, cover reduction, and event labels. | C unit tests cover blast invariants. |
| 74 | Mine trigger model | Add command-triggered and route-triggered explosive events. | Regression test uses fixed convoy seed. |
| 75 | Vehicle UI | Render vehicles and route previews on board. | Screenshot test checks vehicle glyphs. |
| 76 | Convoy turn flow | Add convoy movement and reaction phases. | Unit test prevents illegal phase order. |
| 77 | Dungiven prototype | Implement Dungiven as first vehicle scenario. | Regression replay validates route. |
| 78 | Dungiven polish | Tune convoy spacing and follow-up fire. | UI smoke completes scenario. |
| 79 | Dungannon prototype | Implement Dungannon land mine scenario. | Regression replay validates blast outcome. |
| 80 | Vehicle alpha | Stabilize vehicle mechanics across two scenarios. | Batch vehicle regression passes. |
| 81 | Altnaveigh prototype | Add Altnaveigh vehicle/mine scenario. | Regression replay validates route. |
| 82 | Ballygawley land mine | Add Ballygawley land mine scenario. | Regression replay validates convoy damage. |
| 83 | Mullacreevie prototype | Add horizontal mortar patrol ambush mechanics. | Unit test covers directional blast. |
| 84 | Mullacreevie polish | Tune patrol route and response. | UI smoke completes scenario. |
| 85 | Checkpoint model | Add checkpoint structures, gates, sangars, and alarm zones. | Map validation covers checkpoint tags. |
| 86 | Base defense phases | Add alarm, breach, defense, and withdrawal phases. | Unit tests cover phase transitions. |
| 87 | Derryard prototype | Add Derryard checkpoint assault scenario. | Regression replay covers breach phase. |
| 88 | Derryard polish | Add improvised armoured vehicle abstraction. | UI smoke checks checkpoint assault. |
| 89 | Cloghoge prototype | Add railway/vehicle bomb path abstraction. | Regression replay validates path timing. |
| 90 | Cloghoge polish | Tune checkpoint destruction and survival checks. | Unit tests cover protected cells. |
| 91 | Glenanne prototype | Add barracks truck-bomb scenario as non-early tier. | Regression replay validates alarm timing. |
| 92 | Glenanne polish | Add base closure/outcome metadata. | UI test checks source and warning panel. |
| 93 | Loughgall prototype | Add vehicle plus base assault scenario. | Regression replay covers deployment. |
| 94 | Loughgall civilian guardrails | Add protected route and accidental-entry exclusion abstraction. | Unit test blocks civilian-cell targeting. |
| 95 | Warrenpoint prototype | Add convoy and reinforcement timing model. | Regression replay checks two-stage event timing. |
| 96 | Warrenpoint polish | Add helicopter damage as abstract event. | Unit test validates staged objective. |
| 97 | Fivemiletown prototype | Add RUC patrol and helicopter follow-up as optional scope. | Regression replay covers follow-up trigger. |
| 98 | Killeeshil prototype | Add strict civilian exclusion and RUC patrol route. | Unit test validates civilian hazard flag. |
| 99 | Vehicle content review | Audit all vehicle scenarios for scope compliance. | Review checklist saved. |
| 100 | Vehicle/checkpoint beta | Batch-run vehicle, checkpoint, and early infantry scenarios. | Full regression green. |
| 101 | Aircraft model draft | Define aircraft lanes, altitude bands, damage states, and exit paths. | Unit tests cover aircraft schema. |
| 102 | Anti-air abstraction | Add heavy weapon vs aircraft resolution without operational detail. | C unit test covers hit/damage table. |
| 103 | Aircraft renderer | Render lanes, aircraft markers, and danger arcs. | Screenshot test checks lanes. |
| 104 | Newry Road prototype | Add Battle of Newry Road advanced scenario. | Regression replay covers moving lanes. |
| 105 | Newry Road polish | Tune armed trucks and helicopter response. | UI smoke completes advanced scenario. |
| 106 | Lynx shootdown prototype | Add 1994 Lynx shootdown as aircraft/mortar scenario. | Regression replay checks damage state. |
| 107 | Lynx shootdown polish | Add base helipad and rescue outcome metadata. | UI smoke checks source panel. |
| 108 | Mortar model draft | Define indirect fire setup, warning, scatter, and blast. | C unit tests cover deterministic scatter. |
| 109 | Newry mortar prototype | Add Newry mortar attack as deferred indirect-fire scenario. | Regression test validates source tags. |
| 110 | Osnabruck prototype | Add Osnabruck as out-of-region deferred scenario. | Unit test validates location metadata. |
| 111 | Indirect fire UI | Show warnings, impact markers, and safe cells. | Screenshot test checks impact preview. |
| 112 | Base damage model | Track damaged structures, disabled assets, and repair states. | Unit tests cover structure health. |
| 113 | Advanced scenario filters | Separate infantry, vehicle, checkpoint, aircraft, mortar, deferred. | UI test toggles each filter. |
| 114 | Scenario warnings | Require scope warning on deferred/civilian-risk scenarios. | Unit test rejects missing warning. |
| 115 | Advanced AI | Teach AI to withdraw, hold, evade, and avoid protected zones. | AI regression covers protected-zone avoidance. |
| 116 | Advanced logs | Add phase, vehicle, aircraft, and blast event types. | Regression checks event schema. |
| 117 | Performance pass 1 | Profile board draw and event list on advanced scenarios. | Performance smoke records baseline. |
| 118 | Rules documentation | Add in-app explanation of abstractions without tactical instructions. | UI test opens documentation panel. |
| 119 | Aircraft content review | Audit advanced scenarios for scope compliance. | Review checklist saved. |
| 120 | Advanced beta | Newry Road and Lynx scenarios are playable as advanced demos. | Advanced regression green. |
| 121 | Scenario completeness matrix | Track which historical fields are present per scenario. | Unit test checks required fields. |
| 122 | Data confidence | Add confidence levels for rosters, weapons, maps, and timings. | Validation rejects missing confidence. |
| 123 | Map source notes | Add geodata/source notes for each map abstraction. | Unit test checks source note presence. |
| 124 | Roster source notes | Add source notes for force and unit labels. | Unit test checks roster notes. |
| 125 | Weapon source notes | Add source notes for historical weapon categories. | Unit test checks weapon notes. |
| 126 | Historical browser redesign | Build rich scenario browser with source, tier, and scope filters. | UI test covers browser navigation. |
| 127 | Scenario detail page | Add neutral timeline, forces, map, and sensitivity sections. | UI test opens details for 3 tiers. |
| 128 | Map preview page | Show board preview before launching play. | Screenshot test checks preview. |
| 129 | Force comparison panel | Compare sides, actors, weapons, and objectives. | UI test reads force panel. |
| 130 | Source link handling | Open source URLs externally and copy citations. | UI test validates source button exists. |
| 131 | Completion tracking | Mark played scenarios and outcomes locally. | Unit test round-trips completion data. |
| 132 | Replay seeds | Let users replay previous seed and compare logs. | Regression test repeats saved seed. |
| 133 | Scenario search | Add search across title, date, place, and force. | UI test searches by place. |
| 134 | Scenario collections | Group early demo, infantry, vehicle, aircraft, deferred. | Unit test validates collection membership. |
| 135 | Content QA panel | Add developer-only validation dashboard. | UI test opens dashboard in debug. |
| 136 | Accessibility pass 2 | Improve focus order, dynamic text, contrast, and keyboard play. | Accessibility smoke passes. |
| 137 | Save migration | Add migration path for scenario and save schema versions. | Unit tests cover old fixtures. |
| 138 | Error recovery UI | Show recovery options for bad saves and missing content. | UI test loads corrupt save. |
| 139 | Localization readiness | Centralize user-visible strings without translating yet. | Unit test checks missing string keys. |
| 140 | Browser beta | Scenario browser and details are beta-quality. | UI regression suite green. |
| 141 | Unit test expansion | Increase C and Swift unit coverage on schema and adapter. | Coverage report baseline saved. |
| 142 | Regression corpus | Freeze seed corpus across all implemented scenarios. | Batch replay is deterministic. |
| 143 | UI smoke expansion | Add launch, browse, play, save, resume, export paths. | UI smoke green locally. |
| 144 | Screenshot suite | Add screenshots for main windows and common breakpoints. | Snapshot diffs reviewed. |
| 145 | CI preparation | Add scripts for build, unit, regression, UI smoke. | Scripts run from clean checkout. |
| 146 | Xcode scheme cleanup | Add clear schemes for app, unit tests, UI tests, regression. | `xcodebuild -list` shows schemes. |
| 147 | Mac Catalyst signing | Configure local signing and bundle identifiers. | Debug signed app launches. |
| 148 | App icon and metadata | Add icon, Info.plist fields, and bundle resources. | Package inspection passes. |
| 149 | Asset bundling | Bundle scenarios, docs, shaders, and sample saves. | Unit test finds bundled assets. |
| 150 | Packaging alpha | Produce local packaged Mac Catalyst app. | Smoke launches packaged app. |
| 151 | Performance pass 2 | Profile largest maps, longest logs, and AI turns. | Performance report under targets. |
| 152 | Memory pass | Check leaks, large logs, and save/load churn. | Stress test runs repeated scenarios. |
| 153 | Renderer resilience | Verify nonblank board after resize, sleep, and relaunch. | Screenshot regression green. |
| 154 | Input polish | Add keyboard shortcuts and stable command menu. | UI test uses keyboard path. |
| 155 | Settings polish | Add defaults for AI, logs, accessibility, and source panels. | Unit test persists settings. |
| 156 | Log export polish | Export filtered logs and scenario metadata. | Regression checks exported file shape. |
| 157 | Scenario export polish | Export scenario plus source metadata for review. | Unit test round-trips export. |
| 158 | Crash reporting notes | Add local diagnostic bundle command. | Smoke creates diagnostic bundle. |
| 159 | QA checklist | Create release candidate QA checklist. | Checklist covers all milestones. |
| 160 | Beta packaging | Produce beta package with test report. | Beta smoke green. |
| 161 | Historical copy edit | Review neutral language across app and docs. | Text audit complete. |
| 162 | Sensitivity audit | Recheck each scenario for civilian/crowd exclusion. | Audit notes saved. |
| 163 | Gameplay balance pass | Tune early infantry and vehicle outcomes for demo value. | Regression invariants updated. |
| 164 | AI fairness pass | Remove stalls, loops, and protected-zone violations. | AI regression green. |
| 165 | Tutorial design | Add a short tutorial using fictionalized training data, not a real tragedy. | UI test starts tutorial. |
| 166 | Tutorial implementation | Implement selection, movement, attack, log, and end-turn steps. | UI test completes tutorial. |
| 167 | Help and rules | Add concise in-app help for controls and abstractions. | UI test opens help. |
| 168 | First-run flow | Let new users choose tutorial or early scenario. | UI test covers first-run choices. |
| 169 | Restore defaults | Add reset for settings, saves, and scenario completion. | Unit test clears support data. |
| 170 | Beta QA checkpoint | Run full beta playthrough with tutorial and three scenarios. | QA report has triaged issues. |
| 171 | Bug fix buffer 1 | Fix beta blockers in app launch, play loop, and saves. | Targeted regression green. |
| 172 | Bug fix buffer 2 | Fix beta blockers in scenario data and renderer. | Screenshot regression green. |
| 173 | Bug fix buffer 3 | Fix beta blockers in AI and event logs. | AI and event regression green. |
| 174 | Bug fix buffer 4 | Fix beta blockers in packaging and Xcode schemes. | Packaged smoke green. |
| 175 | Release candidate branch | Create release candidate branch and freeze scope. | Full test suite green. |
| 176 | RC content lock | Lock scenario fixtures and source metadata. | Content checksum saved. |
| 177 | RC schema lock | Lock scenario, save, and event schema versions. | Migration tests green. |
| 178 | RC regression lock | Lock seed replay expected outputs. | Regression corpus green. |
| 179 | RC UI lock | Lock UI screenshots and accessibility baselines. | UI suite green. |
| 180 | RC package 1 | Produce first release candidate package. | Manual smoke passes. |
| 181 | External review prep | Prepare notes for testers and historians. | Review package contains docs. |
| 182 | Feedback triage | Triage review feedback into blocker, follow-up, or out of scope. | Triage list approved. |
| 183 | Blocker fixes 1 | Fix only release-blocking defects. | Targeted tests green. |
| 184 | Blocker fixes 2 | Fix only release-blocking defects. | Targeted tests green. |
| 185 | RC package 2 | Produce second release candidate package. | Full smoke passes. |
| 186 | Documentation pass | Update README, PLAN, and user-facing docs. | Link check passes. |
| 187 | License and credits | Verify licenses for Field of Chaos, content, and assets. | License checklist complete. |
| 188 | Privacy and storage | Document local files, saves, logs, and exports. | Storage audit complete. |
| 189 | Accessibility signoff | Final keyboard, screen reader, contrast, and text-size pass. | Accessibility smoke green. |
| 190 | Performance signoff | Final responsiveness and memory check. | Performance report accepted. |
| 191 | Historical signoff | Confirm playable set still follows two-force scope. | Sensitivity audit accepted. |
| 192 | Regression signoff | Run all unit, regression, and UI tests. | All automated tests green. |
| 193 | Packaging signoff | Build final local package from clean checkout. | Package smoke green. |
| 194 | Demo script | Write exact demo path for early and advanced scenarios. | Script rehearsed once. |
| 195 | Demo rehearsal | Run tutorial, early scenario, vehicle scenario, and log export. | Demo rehearsal passes. |
| 196 | Release notes | Write release notes with known limits and deferred scenarios. | Notes reviewed. |
| 197 | Final bug buffer | Fix only critical issues found during rehearsal. | Targeted tests green. |
| 198 | Final package | Produce final demoable Mac Catalyst package. | Final smoke passes. |
| 199 | Archive artifacts | Archive package, logs, screenshots, and regression outputs. | Artifact list complete. |
| 200 | Demo release | Tag/demo handoff with follow-up backlog. | User can launch, play, and inspect logs. |

## Early Demo Acceptance

By cycle 30:

- `zombie.xcodeproj` opens in Xcode.
- A Mac Catalyst app target builds and launches.
- The app links the local Field of Chaos engine.
- At least one early infantry scenario loads from bundled JSON.
- The player can select an actor, move, attack, wait, and end turns.
- A simple deterministic opponent can complete turns.
- The event log shows dice/combat events.
- A regression script replays the same seed deterministically.
- A UI smoke test launches the app and reaches the skirmish board.

## Release Candidate Acceptance

By cycle 200:

- The packaged Mac Catalyst app launches on a clean machine profile.
- All early infantry scenarios are playable.
- Vehicle/checkpoint scenarios are playable where marked implemented.
- Aircraft/mortar scenarios are playable only where their abstractions pass sensitivity review.
- Excluded and deferred scenarios cannot be accidentally launched as ordinary playable battles.
- Unit, regression, UI, screenshot, packaging, accessibility, and performance tests pass.
- README and in-app source panels keep Wikipedia links and neutral historical notes visible.

## Playable Game 100-Cycle Plan

Cycles 201-300 turn the current automated preview into a game a person can play through. For this section, "playable" means the user can choose a scenario, pick either side, select actors, move, attack, wait, end turns, face a deterministic AI opponent, reach a win/loss/draw outcome, inspect the event log, and replay or resume the run.

The first target is side-selectable manual play for early infantry scenarios. Vehicle, checkpoint, and aircraft scenarios become playable only where the current abstractions can be presented as safe, high-level game decisions without adding operational weapon procedures.

Cycles 201-220 have been run into the first Play Mode spine:

- The automated simulator path is now documented as Preview Mode.
- `PlayableGameState`, side selection, phases, commands, movement, attack, wait, end-turn, and deterministic AI activation are implemented.
- The app has a `Start Game` path beside `Run Preview` for early infantry scenarios.
- Tests cover side selection, Codable state round-trip, legal movement, AI turn advancement, and Field of Chaos-backed attacks.
- Execution notes are recorded in [zombie/docs/cycles-201-220-execution.md](zombie/docs/cycles-201-220-execution.md).

| Cycle | Work | Goal | Acceptance |
|---:|---|---|---|
| 201 | Current-state correction | Rename the existing automated path as Preview Mode. | README and release notes distinguish Preview Mode from Play Mode. |
| 202 | Playable scope lock | Define manual-play scope for cycle 300. | Scope says early infantry is required; other tiers are conditional. |
| 203 | Game state model | Add a persistent turn-by-turn `PlayableGameState`. | Unit test initializes state from one scenario. |
| 204 | Game state fixtures | Add deterministic fixtures for early infantry starts. | Fixtures round-trip through encode/decode. |
| 205 | Side selection model | Add selected side independent of scenario historical labels. | Unit test selects either force as human side. |
| 206 | Side inversion rules | Make actor ownership, objectives, and log names invert safely. | Same scenario can launch from either side. |
| 207 | Play launch route | Add `Start Game` beside `Run Preview`. | UI test sees both launch options. |
| 208 | Play session store | Keep active game state separate from catalog browsing. | Switching scenarios does not corrupt an active run. |
| 209 | Turn phase enum | Define setup, human activation, AI activation, resolution, finished. | Illegal phase transitions are rejected. |
| 210 | Command validation | Add typed commands for move, attack, wait, and end turn. | Invalid command tests explain why blocked. |
| 211 | Legal movement service | Calculate legal cells from terrain, occupancy, and movement costs. | Protected and blocked cells are never legal. |
| 212 | Legal attack service | Calculate legal targets from range, side, and protected zones. | Protected-zone attack test fails closed. |
| 213 | Board selection state | Track selected actor, move target, and attack target. | Selection can be cleared without ending turn. |
| 214 | Movement execution | Apply one legal move and emit a log event. | Actor position changes deterministically. |
| 215 | Attack execution | Route manual attacks through Field of Chaos combat. | Combat log includes dice/combat message. |
| 216 | Wait execution | Let an actor spend activation without movement or attack. | Wait event appears in log. |
| 217 | End-turn execution | Advance from human phase to AI phase. | Turn count increments only after both sides resolve. |
| 218 | First manual scenario | Make Drummuckavall playable by one human side. | Local smoke completes a short manual sequence. |
| 219 | AI adapter | Reuse simulator decision rules as stepable AI commands. | AI emits move, attack, or wait commands. |
| 220 | AI activation loop | Let AI complete a full side turn. | AI cannot act with human-controlled actors. |
| 221 | Outcome evaluator | Evaluate force survival, objective distance, and turn limit. | Scenario ends with stable outcome text. |
| 222 | Early manual smoke | Script one complete Drummuckavall playthrough. | Smoke reaches finished state. |
| 223 | Play board shell | Add a dedicated play screen. | Board, side, turn, phase, and objective are visible. |
| 224 | Actor inspector | Show selected actor stats, weapon, skills, and status. | UI test reads selected actor details. |
| 225 | Action toolbar | Add Move, Attack, Wait, End Turn, and Cancel controls. | Buttons enable only when legal. |
| 226 | Move highlights | Highlight legal movement cells. | Screenshot check shows nonblank move markers. |
| 227 | Target highlights | Highlight legal attack targets. | Screenshot check shows target markers. |
| 228 | Event log integration | Show live play log, not only regression output. | Latest command appears at top or bottom consistently. |
| 229 | Keyboard controls | Add keyboard paths for selection, cancel, wait, and end turn. | UI smoke can play without mouse-only steps. |
| 230 | Error messages | Explain blocked movement, attacks, and turn actions. | UI test triggers one blocked action message. |
| 231 | Save model | Save active scenario, side, actors, turn, log, and seed. | Unit test saves and restores a mid-turn game. |
| 232 | Resume flow | Add resume from last local game. | Relaunch can restore the saved run. |
| 233 | New game reset | Let the user abandon a run and start over. | Reset clears active state after confirmation. |
| 234 | Completion records | Record finished manual games separately from previews. | Completion panel shows side and outcome. |
| 235 | Side-select UI | Add clear force picker before starting play. | User can start as either historical side. |
| 236 | Objective copy | Rewrite objective text for the selected side. | Objective text does not assume the original player side. |
| 237 | Force comparison | Show force size, weapons, and difficulty before launch. | Side picker includes comparison panel. |
| 238 | Difficulty baseline | Add easy, standard, and hard AI settings for early infantry. | AI setting persists into play state. |
| 239 | AI scoring | Teach AI to prefer objectives, cover, and active targets. | Regression proves no idle loop on early maps. |
| 240 | Manual alpha 1 | Ship one polished early infantry manual scenario. | Drummuckavall is playable from either side. |
| 241 | Glasdrumman manual pass | Tune terrain, objectives, and AI for Glasdrumman. | Scenario completes from both sides. |
| 242 | Kesh manual pass | Tune protected cells and break-contact objective. | Protected restaurant area remains untargetable. |
| 243 | Strabane manual pass | Tune exit objective and small-force AI. | Scenario completes from both sides. |
| 244 | Drumnakilly manual pass | Tune vehicle-approach abstraction for infantry play. | Scenario completes from both sides. |
| 245 | Operation Conservation pass | Tune counter-ambush objective and terrain. | Scenario completes from both sides. |
| 246 | Coagh manual pass | Tune village protection and engagement ranges. | Scenario completes from both sides. |
| 247 | Clonoe manual pass | Tune sensitivity copy and protected areas. | Scenario completes from both sides. |
| 248 | Early corpus replay | Add deterministic replay for all manual early scenarios. | Replay corpus is green. |
| 249 | Manual alpha 2 | All 8 early infantry scenarios are side-selectable. | Batch UI smoke starts each from both sides. |
| 250 | Balance review 1 | Review early outcomes and turn limits. | No early scenario ends trivially in 1 turn. |
| 251 | AI fairness review | Check AI avoids protected zones and impossible attacks. | AI protected-zone violations stay at zero. |
| 252 | Fog-of-war decision | Decide whether hidden units are in scope for cycle 300. | Decision is documented; default remains visible units if deferred. |
| 253 | Actor status UI | Show active, down, unconscious, or dead states clearly. | Status changes are visible after attacks. |
| 254 | Turn order UI | Show current actor and remaining activations. | UI test reads active actor label. |
| 255 | Log filters | Filter log by movement, attacks, AI, and outcome. | Filters do not alter saved raw log. |
| 256 | Replay seed UI | Show and copy the deterministic seed. | Restored seed reproduces same AI decisions. |
| 257 | Undo policy | Add cancel-before-commit; no full undo after dice. | UI makes the policy clear. |
| 258 | Tutorial scenario | Add a fictional training scenario for controls. | Tutorial has no real-world tragedy content. |
| 259 | Tutorial steps | Guide selection, movement, attack, wait, and end turn. | UI test completes tutorial. |
| 260 | Manual beta 1 | Early infantry campaign is playable end to end. | Human can finish any early scenario from either side. |
| 261 | Vehicle play design | Define human decisions for vehicle/checkpoint abstractions. | Design avoids operational weapon procedures. |
| 262 | Vehicle state model | Represent route progress, hazards, alarms, and outcomes stepably. | Unit test steps one route turn. |
| 263 | Vehicle side selection | Let human choose convoy/security or opposing side where appropriate. | Side picker explains asymmetric decisions. |
| 264 | Vehicle command set | Add route advance, hold, react, and resolve abstraction commands. | Invalid route commands are blocked. |
| 265 | Dungiven vehicle pass | Make Dungiven playable with abstract route decisions. | Scenario finishes from both sides if safe. |
| 266 | Dungannon vehicle pass | Make Dungannon playable with route/hazard decisions. | Scenario finishes from both sides if safe. |
| 267 | Altnaveigh vehicle pass | Make Altnaveigh playable with route/hazard decisions. | Scenario finishes from both sides if safe. |
| 268 | Ballygawley vehicle pass | Make Ballygawley playable with route/hazard decisions. | Scenario finishes from both sides if safe. |
| 269 | Vehicle beta review | Decide which vehicle scenarios are ready for cycle 300. | Non-ready vehicle scenarios remain preview-only. |
| 270 | Checkpoint play design | Define checkpoint/base decision layer. | Design uses alarms, positions, and damage states only. |
| 271 | Checkpoint state model | Represent alarm, route, structure, and response state. | Unit test steps alarm transition. |
| 272 | Derryard checkpoint pass | Make Derryard playable if abstraction is sufficient. | Scenario finishes or remains marked preview-only. |
| 273 | Cloghoge checkpoint pass | Make Cloghoge playable if abstraction is sufficient. | Scenario finishes or remains marked preview-only. |
| 274 | Glenanne checkpoint pass | Make Glenanne playable if abstraction is sufficient. | Scenario finishes or remains marked preview-only. |
| 275 | Loughgall checkpoint pass | Make Loughgall playable if abstraction is sufficient. | Scenario finishes or remains marked preview-only. |
| 276 | Advanced play policy | Decide human-facing aircraft and mortar decisions. | Policy rejects any operational procedure detail. |
| 277 | Aircraft step model | Represent lanes, warnings, damage, and exits stepably. | Unit test steps Newry Road lane events. |
| 278 | Aircraft UI markers | Show lane, timing, and damage state in Play Mode. | Screenshot shows lane markers and turn timing. |
| 279 | Newry Road play pass | Make Newry Road playable if policy allows. | Scenario finishes or remains preview-only. |
| 280 | Lynx play pass | Make Lynx scenario playable if policy allows. | Scenario finishes or remains preview-only. |
| 281 | Deferred guardrails | Keep deferred mortar review scenarios out of Play Mode. | UI cannot start deferred scenarios. |
| 282 | Scenario availability labels | Label Playable, Preview, Deferred, and Excluded clearly. | Browser labels match scenario state. |
| 283 | Accessibility pass 1 | Check board focus, labels, controls, and dynamic text. | Accessibility smoke covers Play Mode. |
| 284 | Performance pass 1 | Profile manual play on largest early maps. | Board input remains responsive. |
| 285 | Save migration | Add schema versioning for play saves. | Old or invalid saves fail safely. |
| 286 | Crash-safe saves | Write saves atomically. | Interrupted save test does not corrupt previous save. |
| 287 | Export play log | Export manual play logs as JSONL. | Export includes side, seed, scenario, and outcome. |
| 288 | Export summary | Export human-readable after-action summary. | Summary includes source link and sensitivity warning. |
| 289 | Playtest script | Write exact playtest paths for tutorial and 3 scenarios. | Script can be followed by a fresh tester. |
| 290 | Manual beta 2 | Playtest tutorial, 3 early scenarios, and 1 non-infantry scenario. | QA notes contain no untriaged blocker. |
| 291 | Bug buffer 1 | Fix blockers in side selection and launch. | Targeted UI tests green. |
| 292 | Bug buffer 2 | Fix blockers in commands and AI. | Manual replay corpus green. |
| 293 | Bug buffer 3 | Fix blockers in saves and resume. | Save/resume smoke green. |
| 294 | Bug buffer 4 | Fix blockers in event logs and exports. | Export tests green. |
| 295 | Content lock | Lock cycle-300 playable scenario list. | Browser availability labels are final. |
| 296 | Documentation pass | Update README, demo script, and release notes. | Docs say exactly what is playable. |
| 297 | Full regression | Run unit, regression, UI, and manual replay tests. | All required automated tests pass. |
| 298 | Package candidate | Build a local Mac Catalyst package. | Packaged app launches and starts Play Mode. |
| 299 | Final rehearsal | Play tutorial and at least 3 side-selectable scenarios. | Rehearsal reaches outcomes without intervention. |
| 300 | Playable game release | Tag the playable-game milestone. | User can pick either side and play through to an outcome. |

## Playable Game Acceptance

By cycle 300:

- The app has distinct `Run Preview` and `Start Game` paths.
- A user can pick either side before launching a playable scenario.
- All 8 early infantry scenarios can be played from either side to a win/loss/draw outcome.
- At least one non-infantry scenario tier is playable if its abstraction remains safe and understandable.
- Deferred and excluded scenarios cannot be launched in Play Mode.
- The other side is controlled by deterministic AI with no protected-zone violations.
- The player can select actors, move, attack, wait, end turns, save, resume, and export the event log.
- The packaged Mac Catalyst app launches locally and passes unit, regression, UI, replay, and smoke checks.
