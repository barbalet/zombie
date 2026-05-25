import FieldOfChaosEngine
import XCTest
@testable import ZombieCore

final class ZombieCoreTests: XCTestCase {
    func testBundledCatalogValidates() throws {
        let catalog = try ScenarioCatalog.bundled()
        let issues = ScenarioCatalog.validate(catalog)
        let errors = issues.filter { $0.severity == .error }

        XCTAssertEqual(catalog.schemaVersion, 1)
        XCTAssertEqual(catalog.generatedFromPlanCycles, 1...100)
        XCTAssertGreaterThanOrEqual(catalog.scenarios.count, 20)
        XCTAssertTrue(errors.isEmpty, errors.map(\.description).joined(separator: "\n"))
        XCTAssertGreaterThanOrEqual(catalog.scenarios.filter { $0.tier == .early && $0.playable }.count, 8)
        XCTAssertGreaterThanOrEqual(catalog.scenarios.filter { ($0.tier == .vehicle || $0.tier == .checkpoint) && $0.playable }.count, 10)
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
