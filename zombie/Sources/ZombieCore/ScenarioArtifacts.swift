import Foundation

public struct ScenarioCollection: Codable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var scenarioIDs: [String]
}

public struct ScenarioCompleteness: Codable, Equatable, Identifiable {
    public var id: String { scenarioID }
    public var scenarioID: String
    public var hasSource: Bool
    public var hasMapNotes: Bool
    public var hasRosterNotes: Bool
    public var hasWeaponNotes: Bool
    public var hasDataConfidence: Bool
    public var hasScopeWarning: Bool

    public var complete: Bool {
        hasSource && hasMapNotes && hasRosterNotes && hasWeaponNotes && hasDataConfidence && hasScopeWarning
    }
}

public struct ScenarioCompletionRecord: Codable, Equatable, Identifiable {
    public var id: String { scenarioID }
    public var scenarioID: String
    public var lastOutcome: String
    public var lastSeed: UInt32
    public var completedRuns: Int
    public var updatedAt: Date

    public init(scenarioID: String, lastOutcome: String, lastSeed: UInt32, completedRuns: Int, updatedAt: Date) {
        self.scenarioID = scenarioID
        self.lastOutcome = lastOutcome
        self.lastSeed = lastSeed
        self.completedRuns = completedRuns
        self.updatedAt = updatedAt
    }
}

public struct ZombieAppSettings: Codable, Equatable {
    public var showAdvancedScenarios: Bool
    public var showSourcePanels: Bool
    public var preferredAI: String
    public var eventLogLimit: Int

    public static let defaults = ZombieAppSettings(
        showAdvancedScenarios: true,
        showSourcePanels: true,
        preferredAI: "standard",
        eventLogLimit: 200
    )
}

public enum ScenarioLibrary {
    public static func collections(for catalog: ZombieScenarioCatalog) -> [ScenarioCollection] {
        let baseIDs = catalog.scenarios.map(\.id)
        var collections: [ScenarioCollection] = [
            ScenarioCollection(id: "all", title: "All Scenarios", scenarioIDs: baseIDs),
            ScenarioCollection(id: "early-demo", title: "Early Demo", scenarioIDs: catalog.scenarios.filter { $0.tier == .early }.map(\.id)),
            ScenarioCollection(id: "vehicle-checkpoint", title: "Vehicle and Checkpoint", scenarioIDs: catalog.scenarios.filter { $0.tier == .vehicle || $0.tier == .checkpoint }.map(\.id)),
            ScenarioCollection(id: "advanced", title: "Aircraft and Mortar", scenarioIDs: catalog.scenarios.filter { $0.tier == .aircraft || $0.tier == .mortar }.map(\.id)),
            ScenarioCollection(id: "deferred-review", title: "Deferred Review", scenarioIDs: catalog.scenarios.filter { $0.tier == .deferred || $0.tier == .excluded }.map(\.id))
        ]

        let customIDs = Set(catalog.scenarios.flatMap(\.collections)).subtracting(collections.map(\.id))
        for id in customIDs.sorted() {
            collections.append(ScenarioCollection(id: id, title: id.replacingOccurrences(of: "-", with: " ").capitalized, scenarioIDs: catalog.scenarios.filter { $0.collections.contains(id) }.map(\.id)))
        }
        return collections.filter { !$0.scenarioIDs.isEmpty }
    }

    public static func search(_ query: String, in catalog: ZombieScenarioCatalog) -> [ZombieScenario] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            return catalog.scenarios
        }
        return catalog.scenarios.filter { scenario in
            let haystack = [
                scenario.title,
                scenario.date,
                scenario.place,
                scenario.source.title,
                scenario.forces.map(\.name).joined(separator: " "),
                scenario.forces.map(\.unit).joined(separator: " "),
                scenario.actors.map(\.name).joined(separator: " ")
            ].joined(separator: " ").lowercased()
            return haystack.contains(trimmed)
        }
    }

    public static func completenessMatrix(for catalog: ZombieScenarioCatalog) -> [ScenarioCompleteness] {
        catalog.scenarios.map { scenario in
            ScenarioCompleteness(
                scenarioID: scenario.id,
                hasSource: scenario.source.wikipedia.scheme?.hasPrefix("http") == true && !scenario.source.title.isEmpty,
                hasMapNotes: !scenario.map.notes.isEmpty,
                hasRosterNotes: scenario.forces.allSatisfy { !$0.sourceNote.isEmpty },
                hasWeaponNotes: scenario.actors.allSatisfy { !$0.sourceNote.isEmpty },
                hasDataConfidence: [scenario.dataConfidence.roster, scenario.dataConfidence.map, scenario.dataConfidence.weapons, scenario.dataConfidence.timing].allSatisfy { !$0.isEmpty },
                hasScopeWarning: !scenario.scopeWarning.isEmpty
            )
        }
    }

    public static func contentChecksum(for catalog: ZombieScenarioCatalog) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        let payload = catalog.scenarios.map { "\($0.id)|\($0.date)|\($0.tier.rawValue)|\($0.source.wikipedia.absoluteString)" }.joined(separator: "\n")
        for byte in payload.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }
}

public enum ScenarioEventExporter {
    public static func jsonLines(for result: RegressionResult) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try result.events.map { event in
            String(data: try encoder.encode(event), encoding: .utf8) ?? "{}"
        }.joined(separator: "\n")
    }

    public static func scenarioJSON(_ scenario: ZombieScenario) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(data: try encoder.encode(scenario), encoding: .utf8) ?? "{}"
    }
}

public enum DiagnosticReport {
    public static func manifest(catalog: ZombieScenarioCatalog, results: [RegressionResult]) -> String {
        let failed = results.filter { !$0.passed }
        let playable = catalog.scenarios.filter(\.playable)
        return [
            "zombie diagnostic manifest",
            "schemaVersion=\(catalog.schemaVersion)",
            "generatedCycles=\(catalog.generatedFromPlanCycles.lowerBound)-\(catalog.generatedFromPlanCycles.upperBound)",
            "scenarioCount=\(catalog.scenarios.count)",
            "playableCount=\(playable.count)",
            "regressionCount=\(results.count)",
            "failedCount=\(failed.count)",
            "contentChecksum=\(ScenarioLibrary.contentChecksum(for: catalog))"
        ].joined(separator: "\n")
    }
}
