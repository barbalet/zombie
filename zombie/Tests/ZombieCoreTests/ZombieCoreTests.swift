import FieldOfChaosEngine
import XCTest
@testable import ZombieCore

final class ZombieCoreTests: XCTestCase {
    func testBundledCatalogValidates() throws {
        let catalog = try ScenarioCatalog.bundled()
        let issues = ScenarioCatalog.validate(catalog)
        let errors = issues.filter { $0.severity == .error }

        XCTAssertEqual(catalog.schemaVersion, 1)
        XCTAssertEqual(catalog.generatedFromPlanCycles, 1...200)
        XCTAssertGreaterThanOrEqual(catalog.scenarios.count, 24)
        XCTAssertTrue(errors.isEmpty, errors.map(\.description).joined(separator: "\n"))
        XCTAssertGreaterThanOrEqual(catalog.scenarios.filter { $0.tier == .early && $0.playable }.count, 8)
        XCTAssertGreaterThanOrEqual(catalog.scenarios.filter { ($0.tier == .vehicle || $0.tier == .checkpoint) && $0.playable }.count, 10)
        XCTAssertGreaterThanOrEqual(catalog.scenarios.filter { $0.tier == .aircraft && $0.playable }.count, 2)
    }

    func testWikipediaSourcesArePresentForPlayableBattles() throws {
        let catalog = try ScenarioCatalog.bundled()
        for scenario in catalog.scenarios where scenario.playable {
            XCTAssertEqual(scenario.source.wikipedia.host(), "en.wikipedia.org", scenario.id)
            XCTAssertFalse(scenario.source.title.isEmpty, scenario.id)
            XCTAssertFalse(scenario.source.notes.isEmpty, scenario.id)
        }
    }

    func testExternalMapFilesMaterializeEveryScenario() throws {
        let catalog = try ScenarioCatalog.bundled()

        for scenario in catalog.scenarios {
            XCTAssertEqual(scenario.mapFile, "Maps/\(scenario.id).map.json", scenario.id)
            XCTAssertEqual(scenario.map.cells.count, scenario.map.width * scenario.map.height, scenario.id)
            XCTAssertFalse(scenario.map.blockedCells.isEmpty, scenario.id)
            XCTAssertFalse(scenario.map.movement.blockedTags.isEmpty, scenario.id)

            let terrain = Set(scenario.map.cells.flatMap(\.tags))
            XCTAssertTrue(terrain.contains(.wall), scenario.id)
            XCTAssertFalse(terrain.isDisjoint(with: [.road, .lane, .rail, .exit]), scenario.id)
        }
    }

    func testMapMovementCostsDistinguishRoadCoverAndBlockers() throws {
        let catalog = try ScenarioCatalog.bundled()
        let scenario = try XCTUnwrap(catalog.scenarios.first { scenario in
            let cells = scenario.map.cells
            let blockedTags = Set(scenario.map.movement.blockedTags)
            return cells.contains { $0.tags.contains(.road) && scenario.map.movementCost(at: $0.point) != nil } &&
                cells.contains { $0.tags.contains(.cover) && Set($0.tags).isDisjoint(with: [.road, .lane, .rail, .exit]) && scenario.map.movementCost(at: $0.point) != nil } &&
                cells.contains { !blockedTags.isDisjoint(with: Set($0.tags)) }
        })
        let blockedTags = Set(scenario.map.movement.blockedTags)

        let road = try XCTUnwrap(scenario.map.cells.first { $0.tags.contains(.road) && scenario.map.movementCost(at: $0.point) != nil })
        let cover = try XCTUnwrap(scenario.map.cells.first { $0.tags.contains(.cover) && Set($0.tags).isDisjoint(with: [.road, .lane, .rail, .exit]) && scenario.map.movementCost(at: $0.point) != nil })
        let blocked = try XCTUnwrap(scenario.map.cells.first { !blockedTags.isDisjoint(with: Set($0.tags)) })

        XCTAssertEqual(scenario.map.movementCost(at: road.point), scenario.map.movement.roadCost)
        XCTAssertEqual(scenario.map.movementCost(at: cover.point), scenario.map.movement.coverCost)
        XCTAssertNil(scenario.map.movementCost(at: blocked.point))
    }

    func testFieldOfChaosAdapterProducesUsableCharacters() throws {
        let catalog = try ScenarioCatalog.bundled()
        let scenario = try XCTUnwrap(catalog.scenarios.first { $0.tier == .early })
        let actor = try XCTUnwrap(scenario.actors.first)
        let character = FieldOfChaosAdapter.makeCharacter(from: actor, seed: 42)

        XCTAssertFalse(FieldOfChaosAdapter.engineVersion.isEmpty)
        XCTAssertFalse(character.dead)
        XCTAssertFalse(character.unconscious)
        XCTAssertGreaterThan(character.loadout.rounds_in_clip, 0)
    }

    func testInfantrySimulationIsDeterministic() throws {
        let catalog = try ScenarioCatalog.bundled()
        let scenario = try XCTUnwrap(catalog.scenarios.first { $0.tier == .early && $0.playable })
        let simulator = ZombieSkirmishSimulator()

        let first = simulator.run(scenario)
        let second = simulator.run(scenario)

        XCTAssertTrue(first.passed, first.events.map(\.summary).joined(separator: "\n"))
        XCTAssertEqual(first, second)
    }

    func testRegressionCatalogPassesWithoutProtectedZoneViolations() throws {
        let catalog = try ScenarioCatalog.bundled()
        let simulator = ZombieSkirmishSimulator()
        let results = simulator.runCatalog(catalog)
        let failures = results.filter { !$0.passed }

        XCTAssertEqual(results.count, catalog.scenarios.filter(\.playable).count)
        XCTAssertTrue(failures.isEmpty, failures.map { "\($0.scenarioID): \($0.outcome)" }.joined(separator: "\n"))
        XCTAssertTrue(results.allSatisfy { $0.protectedZoneViolations == 0 })
    }

    func testAdvancedAircraftAndMortarSystemsRun() throws {
        let catalog = try ScenarioCatalog.bundled()
        let simulator = ZombieSkirmishSimulator()
        let newryRoad = try XCTUnwrap(catalog.scenarios.first { $0.id == "newry-road-1993" })
        let lynx = try XCTUnwrap(catalog.scenarios.first { $0.id == "lynx-shootdown-1994" })
        let newryMortar = try XCTUnwrap(catalog.scenarios.first { $0.id == "newry-mortar-1985" })

        let newryRoadPhases = Set(simulator.run(newryRoad).events.map(\.phase))
        XCTAssertTrue(newryRoadPhases.contains("aircraft-lane"))
        XCTAssertTrue(newryRoadPhases.contains("aircraft-damage"))

        let lynxPhases = Set(simulator.run(lynx).events.map(\.phase))
        XCTAssertTrue(lynxPhases.contains("indirect-warning"))
        XCTAssertTrue(lynxPhases.contains("indirect-impact"))
        XCTAssertTrue(lynxPhases.contains("structure-damage"))

        let mortarResult = simulator.run(newryMortar)
        XCTAssertTrue(mortarResult.passed)
        XCTAssertTrue(mortarResult.events.contains { $0.phase == "indirect-impact" })
    }

    func testSearchCollectionsCompletenessAndExports() throws {
        let catalog = try ScenarioCatalog.bundled()
        let simulator = ZombieSkirmishSimulator()
        let searchResults = ScenarioLibrary.search("Crossmaglen", in: catalog)
        let collections = ScenarioLibrary.collections(for: catalog)
        let completeness = ScenarioLibrary.completenessMatrix(for: catalog)
        let checksum = ScenarioLibrary.contentChecksum(for: catalog)
        let scenario = try XCTUnwrap(catalog.scenarios.first { $0.id == "newry-road-1993" })
        let result = simulator.run(scenario)
        let jsonLines = try ScenarioEventExporter.jsonLines(for: result)
        let scenarioJSON = try ScenarioEventExporter.scenarioJSON(scenario)
        let manifest = DiagnosticReport.manifest(catalog: catalog, results: simulator.runCatalog(catalog))

        XCTAssertTrue(searchResults.contains { $0.id == "newry-road-1993" })
        XCTAssertTrue(collections.contains { $0.id == "advanced" && $0.scenarioIDs.contains("newry-road-1993") })
        XCTAssertTrue(completeness.allSatisfy(\.complete))
        XCTAssertEqual(checksum.count, 16)
        XCTAssertTrue(jsonLines.contains("\"phase\":\"aircraft-lane\""))
        XCTAssertTrue(scenarioJSON.contains("\"newry-road-1993\""))
        XCTAssertTrue(manifest.contains("generatedCycles=1-200"))
    }

    func testDeferredContentIsNotOrdinaryPlayableScope() throws {
        let catalog = try ScenarioCatalog.bundled()
        let regularResults = ZombieSkirmishSimulator().runCatalog(catalog)
        let deferredResults = ZombieSkirmishSimulator().runCatalog(catalog, includeDeferred: true)
        let deferred = catalog.scenarios.filter { $0.tier == .deferred || !$0.playable }

        XCTAssertFalse(deferred.isEmpty)
        XCTAssertFalse(regularResults.contains { $0.scenarioID == "newry-mortar-1985" || $0.scenarioID == "osnabruck-mortar-1996" })
        XCTAssertTrue(deferredResults.contains { $0.scenarioID == "newry-mortar-1985" })
        XCTAssertTrue(deferred.allSatisfy { !$0.scopeWarning.isEmpty })
    }

    func testVehicleAndCheckpointScenariosEmitRouteOrAlarmEvents() throws {
        let catalog = try ScenarioCatalog.bundled()
        let simulator = ZombieSkirmishSimulator()
        let scenarios = catalog.scenarios.filter { $0.playable && ($0.tier == .vehicle || $0.tier == .checkpoint) }

        XCTAssertFalse(scenarios.isEmpty)
        for scenario in scenarios {
            let phases = Set(simulator.run(scenario).events.map(\.phase))
            XCTAssertFalse(phases.isDisjoint(with: ["vehicle-route", "abstract-blast", "alarm"]), scenario.id)
        }
    }

    func testCivilianRiskScenariosDeclareProtectedCells() throws {
        let catalog = try ScenarioCatalog.bundled()
        let sensitive = catalog.scenarios.filter { $0.sensitivityTags.contains("civilian-risk") }

        XCTAssertFalse(sensitive.isEmpty)
        for scenario in sensitive {
            XCTAssertTrue(scenario.sensitivityTags.contains("protected-zone"), scenario.id)
            XCTAssertFalse(scenario.map.protectedCellSet.isEmpty, scenario.id)
        }
    }

    func testPlayableGameStartsFromEitherSideAndRoundTrips() throws {
        let catalog = try ScenarioCatalog.bundled()
        let scenario = try XCTUnwrap(catalog.scenarios.first { $0.id == "drummuckavall-1975" })

        let playerState = try PlayableGameEngine.start(scenario, humanSide: .player)
        let opponentState = try PlayableGameEngine.start(scenario, humanSide: .opponent)

        XCTAssertEqual(playerState.phase, .humanActivation)
        XCTAssertEqual(opponentState.phase, .humanActivation)
        XCTAssertEqual(playerState.humanSide, .player)
        XCTAssertEqual(opponentState.humanSide, .opponent)
        XCTAssertNotEqual(playerState.selectedActorID, opponentState.selectedActorID)

        let data = try JSONEncoder().encode(playerState)
        let restored = try JSONDecoder().decode(PlayableGameState.self, from: data)
        XCTAssertEqual(restored, playerState)
    }

    func testPlayableMoveWaitAndAITurnAdvance() throws {
        let catalog = try ScenarioCatalog.bundled()
        let scenario = try XCTUnwrap(catalog.scenarios.first { $0.id == "drummuckavall-1975" })
        var state = try PlayableGameEngine.start(scenario, humanSide: .player)
        let actorID = try XCTUnwrap(state.selectedActorID)
        let destination = try XCTUnwrap(PlayableGameEngine.legalMoveDestinations(for: actorID, in: state, scenario: scenario).first)

        state = try PlayableGameEngine.applying(.move(actorID: actorID, destination: destination), to: state, scenario: scenario)
        XCTAssertEqual(state.actors.first { $0.id == actorID }?.position, destination)
        XCTAssertTrue(state.events.contains { $0.phase == "move" })

        state = try PlayableGameEngine.applying(.endTurn, to: state, scenario: scenario)
        XCTAssertEqual(state.phase, .humanActivation)
        XCTAssertEqual(state.turn, 2)
        XCTAssertTrue(state.events.contains { $0.phase.hasPrefix("ai-") })
    }

    func testPlayableAttackUsesFieldOfChaosCombat() throws {
        let catalog = try ScenarioCatalog.bundled()
        var selectedScenario: ZombieScenario?
        var selectedState: PlayableGameState?
        var selectedActorID: String?
        var selectedTargetID: String?

        for scenario in catalog.scenarios where scenario.tier == .early && scenario.playable {
            var state = try PlayableGameEngine.start(scenario, humanSide: .player)
            for actor in state.actors where actor.side == .player && actor.active {
                let targets = PlayableGameEngine.legalAttackTargets(for: actor.id, in: state, scenario: scenario)
                if let target = targets.first {
                    state.selectedActorID = actor.id
                    selectedScenario = scenario
                    selectedState = state
                    selectedActorID = actor.id
                    selectedTargetID = target.id
                    break
                }
            }
            if selectedScenario != nil {
                break
            }
        }

        let scenario = try XCTUnwrap(selectedScenario)
        let state = try XCTUnwrap(selectedState)
        let actorID = try XCTUnwrap(selectedActorID)
        let targetID = try XCTUnwrap(selectedTargetID)

        let after = try PlayableGameEngine.applying(.attack(actorID: actorID, targetID: targetID), to: state, scenario: scenario)
        XCTAssertTrue(after.events.contains { $0.phase == "attack" })
        XCTAssertLessThan(after.actors.first { $0.id == actorID }?.roundsInClip ?? Int.max, state.actors.first { $0.id == actorID }?.roundsInClip ?? 0)
    }

    func testPlayableSaveRestoresMidTurnDifficultyAndSeed() throws {
        let catalog = try ScenarioCatalog.bundled()
        let scenario = try XCTUnwrap(catalog.scenarios.first { $0.id == "drummuckavall-1975" })
        var state = try PlayableGameEngine.start(scenario, humanSide: .opponent, difficulty: .hard)
        let actorID = try XCTUnwrap(state.selectedActorID)
        let destination = try XCTUnwrap(PlayableGameEngine.legalMoveDestinations(for: actorID, in: state, scenario: scenario).first)

        state = try PlayableGameEngine.applying(.move(actorID: actorID, destination: destination), to: state, scenario: scenario)
        let save = PlayableGameSave(state: state, savedAt: Date(timeIntervalSince1970: 1_800_000_000))
        let data = try JSONEncoder().encode(save)
        let restored = try JSONDecoder().decode(PlayableGameSave.self, from: data)

        XCTAssertEqual(restored.state, state)
        XCTAssertEqual(restored.state.difficulty, .hard)
        XCTAssertEqual(restored.state.humanSide, .opponent)
        XCTAssertEqual(restored.state.seed, state.seed)
        XCTAssertEqual(restored.state.events.last?.phase, "move")
    }

    func testPlayableSmokeCompletesDrummuckavallFromBothSides() throws {
        let catalog = try ScenarioCatalog.bundled()
        let scenario = try XCTUnwrap(catalog.scenarios.first { $0.id == "drummuckavall-1975" })

        let playerRun = try PlayableGameEngine.runSmokePlaythrough(scenario, humanSide: .player, difficulty: .standard)
        let opponentRun = try PlayableGameEngine.runSmokePlaythrough(scenario, humanSide: .opponent, difficulty: .standard)

        XCTAssertEqual(playerRun.phase, .finished)
        XCTAssertEqual(opponentRun.phase, .finished)
        XCTAssertNotNil(playerRun.outcome)
        XCTAssertNotNil(opponentRun.outcome)
        XCTAssertTrue(playerRun.events.contains { $0.phase == "outcome" })
        XCTAssertTrue(opponentRun.events.contains { $0.phase == "outcome" })
    }

    func testPlayableObjectiveBriefingAndBlockedCommandsExplainState() throws {
        let catalog = try ScenarioCatalog.bundled()
        let scenario = try XCTUnwrap(catalog.scenarios.first { $0.id == "drummuckavall-1975" })
        let state = try PlayableGameEngine.start(scenario, humanSide: .opponent, difficulty: .easy)
        let opponentForce = try XCTUnwrap(scenario.forces.first { $0.side == .opponent })
        let humanActor = try XCTUnwrap(state.actors.first { $0.side == .opponent && $0.active })
        let aiActor = try XCTUnwrap(state.actors.first { $0.side == .player && $0.active })

        XCTAssertTrue(PlayableGameEngine.objectiveBriefing(for: scenario, humanSide: .opponent).contains(opponentForce.name))
        XCTAssertEqual(state.difficulty, .easy)
        XCTAssertThrowsError(try PlayableGameEngine.applying(.wait(actorID: aiActor.id), to: state, scenario: scenario)) { error in
            XCTAssertEqual(String(describing: error), "Actor \(aiActor.id) is controlled by the opponent.")
        }
        XCTAssertFalse(PlayableGameEngine.actorStatus(humanActor).isEmpty)
    }
}
