# zombie

The project is named after the Cranberries song, "Zombie":

https://www.youtube.com/watch?v=6Ejga4kJUts

The purpose of zombie is to simulate and refight selected armed engagements from [The Troubles](https://en.wikipedia.org/wiki/The_Troubles), focused on identifiable armed forces meeting in a bounded military action. The project is not intended to simulate attacks on civilians, sectarian killings, punishment attacks, riots as crowd violence, or military action against civilian crowds.

The first research pass uses Wikipedia as a scenario index, especially the [List of Provisional IRA ambushes](https://en.wikipedia.org/wiki/List_of_Provisional_IRA_ambushes), [List of attacks on British aircraft during The Troubles](https://en.wikipedia.org/wiki/List_of_attacks_on_British_aircraft_during_The_Troubles), and individual battle, ambush, checkpoint, aircraft, and barracks articles.

## Technical Stack

### field of chaos engine

The project is based around the technical stack of the Field of Chaos engine (foc):

https://github.com/barbalet/fieldofchaos/

The local `foc` tree already has the important wiring for a playable tactical game:

- C engine API: `foc/src/engine/include/fieldofchaos_engine.h`
- C implementation: `foc/src/engine/fieldofchaos_engine.c`
- Swift package bridge: `foc/Package.swift`
- Swift/C interop layer: `foc/AppShell/CInterop.swift`
- App state and persistence: `foc/AppShell/GameStore.swift`
- Tactical model: `foc/AppShell/SkirmishModel.swift`
- SwiftUI skirmish UI: `foc/AppShell/SkirmishViews.swift`
- Metal board renderer: `foc/AppShell/BoardRenderer.swift`
- Existing Mac Xcode project: `foc/FieldOfChaos.xcodeproj`

For zombie, the short path to a demo is to keep `foc` as the deterministic tactical kernel while adding a zombie scenario layer that supplies historical scenario metadata, map geometry, rosters, weapons, and victory conditions. The current Field of Chaos project is a macOS SwiftUI/Metal project; zombie should add an early `zombie.xcodeproj` Mac Catalyst target that links the same engine API, opens a scenario browser, and launches a small two-force skirmish.

### zombie engine

The zombie engine represents a finite set of Troubles-era engagements where two identifiable armed forces met with defined positions, weapons, and unit roles. The initial implementation should model history at a high level for tabletop-style simulation, not as operational instruction.

Scenario data should include:

- Wikipedia source link and title.
- Date and place.
- Armed forces involved.
- Historical unit labels when available.
- High-level weapon categories mapped to the game engine.
- Map needs: road, border, checkpoint, base, village, observation post, cover, elevation, vehicle route, aircraft lane, or evacuation edge.
- Civilian handling note: excluded, abstracted as protected no-fire space, or not present in the scenario slice.
- Implementation tier: infantry-ready, vehicle/explosive module, aircraft/mortar module, or excluded/deferred.

## Current Demo State

The first 200-cycle implementation now includes a local SwiftPM workspace and `zombie.xcodeproj` Mac Catalyst app. The app loads the bundled catalog, searches and filters scenarios, shows source links, warnings, force/actor panels, tactical grid previews, confidence metadata, and deterministic regression previews.

Cycle 201 starts the playable-game pass. The existing automated path is now treated as **Preview Mode**: it runs deterministic scenario playback for validation, demonstrations, and regression checks. The new **Play Mode** path is being added beside it so a user can choose a side and step through a scenario manually.

Cycles 221-240 add the first manual alpha: Drummuckavall can be started from either side, played through by deterministic smoke runner, inspected with actor details, controlled with move/attack/wait/end-turn/cancel actions, saved locally, resumed, abandoned, and recorded separately from Preview Mode completions. Play Mode now includes side-aware objective text, force comparison, easy/standard/hard AI, board highlights for legal moves and targets, and live event logs.

Cycles 241-260 add the first early-infantry manual beta. All early infantry scenarios can finish from either side through deterministic replay, protected cells remain untargetable, fog of war is explicitly deferred, actor status and turn order are visible, play logs can be filtered without altering raw events, replay seeds can be copied, and a fictional tutorial scenario guides the basic controls.

Cycles 261-280 add Abstract Play Mode for non-infantry scenarios. Vehicle, checkpoint, aircraft, warning, damage, and exit states stay high-level, using route advance, hold, react, and resolve commands instead of detailed operational procedures.

Cycles 281-300 complete the playable-game baseline. The app now opens on a `Playable Games` collection backed by the same availability rules that gate `Start Game`, so the first browser view is the side-selectable game set rather than the full research catalog. All catalog scenarios can start Play Mode from either side and reach an outcome. Manual runs now have versioned save recovery, copyable JSONL logs, copyable summaries with source and scope warning, and release rehearsal coverage across the full catalog.

The bundled catalog currently contains 25 scenarios:

- 9 early infantry/tutorial scenarios.
- 8 vehicle scenarios.
- 4 checkpoint/base scenarios.
- 2 playable aircraft/advanced scenarios.
- 2 indirect-fire/source-review scenarios.

The Play Mode content set is now all 25 side-selectable scenarios: 9 early infantry/tutorial scenarios plus 16 abstract vehicle/checkpoint/aircraft/indirect-fire scenarios. Advanced aircraft and mortar content uses abstract lanes, warning markers, impact events, and structure health. It does not model operational weapon procedures. Civilian-risk content is represented only through protected noncombat cells and scope warnings.

## Candidate Battles

These are the current Wikipedia-backed candidates. "Early" means suitable for the first playable demo using a small infantry board. "Vehicle" needs convoy, mine, checkpoint, or vehicle rules. "Aircraft" needs helicopter/air lane rules. "Defer" means useful historically but not for the first demo, usually because the page centers civilian disorder, off-duty/civilian presence, or a one-sided bombing rather than a bounded two-force skirmish.

| Scenario | Date | Forces | Game Tier | Notes |
|---|---:|---|---|---|
| [Dungiven landmine and gun attack](https://en.wikipedia.org/wiki/Dungiven_landmine_and_gun_attack) | 1972-06-24 | Provisional IRA vs British Army convoy | Vehicle | Road ambush with follow-up fire; needs convoy and command-detonated explosive abstraction. |
| [Drummuckavall ambush](https://en.wikipedia.org/wiki/Drummuckavall_ambush) | 1975-11-22 | Provisional IRA South Armagh Brigade vs British Army observation post | Early | Strong first-map candidate: observation post, border edge, fire lanes, withdrawal. |
| [1978 Crossmaglen ambush](https://en.wikipedia.org/wiki/1978_Crossmaglen_ambush) | 1978-12-21 | Provisional IRA vs British Army foot patrol | Early | Foot patrol ambush; compact board once patrol movement and covered firing positions exist. |
| [Warrenpoint ambush](https://en.wikipedia.org/wiki/Warrenpoint_ambush) | 1979-08-27 | Provisional IRA South Armagh Brigade vs British Army convoy and reinforcements | Vehicle | Historically central but complex: two blasts, reinforcement timing, helicopter damage, civilian-risk guardrails. |
| [Dungannon land mine attack](https://en.wikipedia.org/wiki/Dungannon_land_mine_attack) | 1979-12-16 | Provisional IRA East Tyrone Brigade vs British Army mobile patrol | Vehicle | Convoy mine scenario; not early until route and vehicle damage are implemented. |
| [Altnaveigh landmine attack](https://en.wikipedia.org/wiki/Altnaveigh_landmine_attack) | 1981-05-19 | Provisional IRA South Armagh Brigade vs British Army armoured vehicles | Vehicle | Culvert mine against armoured vehicles; useful for explosive/vehicle rules. |
| [Glasdrumman ambush](https://en.wikipedia.org/wiki/Glasdrumman_ambush) | 1981-07-17 | Provisional IRA South Armagh Brigade vs British Army close observation platoon | Early | Excellent early technical fit: hidden observation team, firing positions, withdrawal edge. |
| [Ballygawley land mine attack](https://en.wikipedia.org/wiki/Ballygawley_land_mine_attack) | 1983-07-13 | Provisional IRA vs Ulster Defence Regiment convoy | Vehicle | UDR was part of the British Army; needs armoured convoy and road-mine mechanics. |
| [Kesh ambush](https://en.wikipedia.org/wiki/Kesh_ambush) | 1984-12-02 | Provisional IRA vs British Army SAS | Early | Small-force engagement with both sides armed; suitable for stealth/ambush testing. |
| [Strabane ambush](https://en.wikipedia.org/wiki/Strabane_ambush) | 1985-02-23 | Provisional IRA West Tyrone Brigade vs British Army SAS | Early | Three-person IRA unit against SAS ambush; compact and deterministic. |
| [1985 Newry mortar attack](https://en.wikipedia.org/wiki/1985_Newry_mortar_attack) | 1985-02-28 | Provisional IRA vs RUC base | Defer | Security-force target, but primarily indirect mortar/barracks damage rather than a skirmish. |
| [Loughgall ambush](https://en.wikipedia.org/wiki/Loughgall_ambush) | 1987-05-08 | Provisional IRA East Tyrone Brigade vs British Army SAS and RUC | Vehicle | Major candidate after vehicles, base attack, and civilian exclusion zones exist. |
| [Ballygawley bus bombing](https://en.wikipedia.org/wiki/Ballygawley_bus_bombing) | 1988-08-20 | Provisional IRA vs British Army personnel in transit | Defer | Military target, but mostly a bus bombing; low first-demo skirmish value. |
| [Ambush at Drumnakilly](https://en.wikipedia.org/wiki/Ambush_at_Drumnakilly) | 1988-08-30 | Provisional IRA East Tyrone Brigade vs British Army SAS | Early | Small armed unit, concealed positions, vehicle approach, clear two-force structure. |
| [1989 Jonesborough ambush](https://en.wikipedia.org/wiki/1989_Jonesborough_ambush) | 1989-03-20 | Provisional IRA South Armagh Brigade vs RUC officers | Vehicle | Security-force ambush; include only if RUC scenarios are in scope beyond British Army. |
| [Attack on Derryard checkpoint](https://en.wikipedia.org/wiki/Attack_on_Derryard_checkpoint) | 1989-12-13 | Provisional IRA vs British Army and RUC checkpoint | Vehicle | Strong later scenario: checkpoint assault, improvised armoured vehicle, garrison defense. |
| [Operation Conservation](https://en.wikipedia.org/wiki/Operation_Conservation) | 1990-05-06 | Provisional IRA South Armagh Brigade vs British Army | Early | Good early-to-mid scenario: counter-ambush, hidden positions, terrain and withdrawal. |
| [1990 Lough Neagh ambush](https://en.wikipedia.org/wiki/1990_Lough_Neagh_ambush) | 1990-11-10 | Provisional IRA vs off-duty RUC/former UDR party and civilian | Defer | Not a clean military engagement because off-duty and civilian presence dominate the scenario risk. |
| [Mullacreevie ambush](https://en.wikipedia.org/wiki/Mullacreevie_ambush) | 1991-03-01 | Provisional IRA North Armagh Brigade vs British Army UDR mobile patrol | Vehicle | Patrol ambush with horizontal mortar; later vehicle/explosive test case. |
| [Glenanne barracks bombing](https://en.wikipedia.org/wiki/Glenanne_barracks_bombing) | 1991-05-31 | Provisional IRA vs British Army UDR base | Vehicle | Base and vehicle bomb scenario; defer until barracks, alarms, and blast modeling exist. |
| [Coagh ambush](https://en.wikipedia.org/wiki/Coagh_ambush) | 1991-06-03 | Provisional IRA East Tyrone Brigade vs British Army SAS | Early | Small SAS ambush against armed IRA unit; useful for contested line-of-fire and vehicle arrival. |
| [Clonoe ambush](https://en.wikipedia.org/wiki/Clonoe_ambush) | 1992-02-16 | Provisional IRA East Tyrone Brigade vs British Army SAS | Early | Compact armed engagement; high sensitivity because of later legal findings, so implement with neutral historical framing. |
| [Attack on Cloghoge checkpoint](https://en.wikipedia.org/wiki/Attack_on_Cloghoge_checkpoint) | 1992-05-01 | Provisional IRA vs British Army checkpoint | Vehicle | Later checkpoint/railway bomb scenario; not an early infantry skirmish. |
| [1992 Coalisland riots](https://en.wikipedia.org/wiki/1992_Coalisland_riots) | 1992-05-12 | Provisional IRA attack on British Army patrol, followed by civilian clashes | Defer | Only the Cappagh patrol attack is potentially usable; the riot/civilian confrontation is out of scope. |
| [Occupation of Cullaville](https://en.wikipedia.org/wiki/Occupation_of_Cullaville) | 1993-04-22 | Provisional IRA armed checkpoint near British Army watchtower | Defer | Useful for map/control mechanics, but not a direct battle because security forces did not engage. |
| [Battle of Newry Road](https://en.wikipedia.org/wiki/Battle_of_Newry_Road) | 1993-09-23 | Provisional IRA South Armagh Brigade vs British Army helicopters and soldiers | Aircraft | Strong advanced scenario after aircraft, technical vehicles, and moving fire lanes are implemented. |
| [1993 Fivemiletown ambush](https://en.wikipedia.org/wiki/1993_Fivemiletown_ambush) | 1993-12-12 | Provisional IRA East Tyrone Brigade vs RUC patrol, British Army helicopter follow-up | Vehicle | Include if RUC patrol scenarios are in scope; good for follow-up search and aircraft reaction. |
| [1994 British Army Lynx shootdown](https://en.wikipedia.org/wiki/1994_British_Army_Lynx_shootdown) | 1994-03-19 | Provisional IRA South Armagh Brigade vs British Army helicopter/base | Aircraft | Later aircraft/mortar scenario, not first-demo infantry. |
| [Killeeshil ambush](https://en.wikipedia.org/wiki/Killeeshil_ambush) | 1994-07-15 | Provisional IRA East Tyrone Brigade vs RUC mobile patrol | Vehicle | Security-force target, but civilian wounds mean strict civilian exclusion and historical sensitivity checks. |
| [Osnabruck mortar attack](https://en.wikipedia.org/wiki/Osnabr%C3%BCck_mortar_attack) | 1996-06-28 | Provisional IRA vs British Army barracks in Germany | Defer | Barracks mortar incident outside Northern Ireland; useful only after indirect fire and base damage. |
| [1997 Coalisland attack](https://en.wikipedia.org/wiki/1997_Coalisland_attack) | 1997-03-26 | Provisional IRA attack, SAS/RUC response, civilian crowd | Defer | Exclude from playable battle set until the project has a way to omit civilian crowd conflict entirely. |

## Exclusion Guidance

The Troubles include many events that are historically important but not appropriate for zombie's playable scenario set. Excluded or heavily deferred pages include:

- Riots and military/civilian confrontations such as [Falls Curfew](https://en.wikipedia.org/wiki/Falls_Curfew), [Battle at Springmartin](https://en.wikipedia.org/wiki/Battle_at_Springmartin), [Battle of Lenadoon](https://en.wikipedia.org/wiki/Battle_of_Lenadoon), and the civilian portions of the Coalisland riot pages.
- Civilian-targeted bombings, pub attacks, sectarian killings, massacres, punishment attacks, assassinations, and proxy bombings.
- Events where one side is not an identifiable armed formation in the scenario slice.

## Early Demo Scenario Set

The first playable zombie demo should use infantry-sized, bounded engagements that fit the current Field of Chaos board loop:

1. [Drummuckavall ambush](https://en.wikipedia.org/wiki/Drummuckavall_ambush)
2. [Glasdrumman ambush](https://en.wikipedia.org/wiki/Glasdrumman_ambush)
3. [Kesh ambush](https://en.wikipedia.org/wiki/Kesh_ambush)
4. [Strabane ambush](https://en.wikipedia.org/wiki/Strabane_ambush)
5. [Ambush at Drumnakilly](https://en.wikipedia.org/wiki/Ambush_at_Drumnakilly)
6. [Operation Conservation](https://en.wikipedia.org/wiki/Operation_Conservation)
7. [Coagh ambush](https://en.wikipedia.org/wiki/Coagh_ambush)
8. [Clonoe ambush](https://en.wikipedia.org/wiki/Clonoe_ambush)

The first Mac Catalyst proof should not attempt Warrenpoint, Derryard, Cloghoge, Newry Road, or aircraft/mortar-heavy actions. Those need additional vehicle, blast, checkpoint, aircraft, and scenario timing systems.

### back absorption

It is intended that some of the code generated through zombie will be absorbed back into field of chaos, allowing the projects to inform each other.

Candidate back-absorption areas:

- Scenario schema and deterministic scenario loader.
- Civilian exclusion/protected-zone map annotations.
- Terrain tags for roads, cover, elevation, walls, checkpoints, and structures.
- Battle event log improvements.
- Mac Catalyst packaging lessons.
- Regression seeds and UI smoke tests for playable skirmishes.

### c bridge between field of chaos and zombie

The zombie bridge should start as a thin adapter around the existing `FieldOfChaosEngine` C API. The adapter should translate zombie scenario JSON into Field of Chaos characters, board actors, terrain cells, objective zones, and event-log labels. Only after the scenario adapter is stable should zombie add new C mechanics for mines, vehicles, checkpoints, indirect fire, aircraft, and civilian exclusion zones.

### SwiftUI Mac Catalyst interface

The first zombie interface should be a Mac Catalyst app with:

- Scenario browser grouped by implementation tier.
- Historical source panel with the Wikipedia link and neutral context.
- Roster preview for both forces.
- Board preview generated from scenario JSON.
- Play button that launches the skirmish loop.
- Dice/event log visible from the first demo.
- Unit, UI, and regression smoke hooks built into Xcode schemes.

The technical plan for this development lives in [PLAN.md](PLAN.md).

### Contact

If you are interested in being involved please contact Tom Barbalet at `barbalet at gmail dot com`. Many thanks.
