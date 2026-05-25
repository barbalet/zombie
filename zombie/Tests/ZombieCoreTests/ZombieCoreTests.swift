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
}
