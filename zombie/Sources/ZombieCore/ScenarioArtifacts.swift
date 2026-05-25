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

public struct PlayableGameSave: Codable, Equatable, Identifiable {
    public static let currentSchemaVersion = 2

    public var id: String { state.scenarioID }
    public var schemaVersion: Int
    public var savedAt: Date
    public var state: PlayableGameState

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case savedAt
        case state
    }

    public init(state: PlayableGameState, savedAt: Date = Date()) {
        self.schemaVersion = Self.currentSchemaVersion
        self.savedAt = savedAt
        self.state = state
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        guard (1...Self.currentSchemaVersion).contains(schemaVersion) else {
            throw PlayableSaveError.unsupportedSchemaVersion(schemaVersion)
        }
        savedAt = try container.decode(Date.self, forKey: .savedAt)
        state = try container.decode(PlayableGameState.self, forKey: .state)
    }
}

public enum PlayableSaveError: Error, Equatable, CustomStringConvertible {
    case unsupportedSchemaVersion(Int)

    public var description: String {
        switch self {
        case .unsupportedSchemaVersion(let version):
            return "Unsupported Play Mode save schema version \(version)."
        }
    }
}

public enum PlayableSaveCodec {
    public static func encode(_ save: PlayableGameSave) throws -> Data {
        try JSONEncoder().encode(save)
    }

    public static func decodeState(from data: Data) -> PlayableGameState? {
        guard let save = try? JSONDecoder().decode(PlayableGameSave.self, from: data),
              save.state.outcome == nil else {
            return nil
        }
        return save.state
    }

    public static func recoveredState(primary: Data?, backup: Data?) -> PlayableGameState? {
        if let primary, let state = decodeState(from: primary) {
            return state
        }
        if let backup, let state = decodeState(from: backup) {
            return state
        }
        return nil
    }
}

public struct PlayableCompletionRecord: Codable, Equatable, Identifiable {
    public var id: String { "\(scenarioID)-\(humanSide.rawValue)-\(difficulty.rawValue)" }
    public var scenarioID: String
    public var humanSide: ForceSide
    public var difficulty: PlayableAIDifficulty
    public var lastOutcome: String
    public var lastSeed: UInt32
    public var completedRuns: Int
    public var updatedAt: Date

    public init(
        scenarioID: String,
        humanSide: ForceSide,
        difficulty: PlayableAIDifficulty,
        lastOutcome: String,
        lastSeed: UInt32,
        completedRuns: Int,
        updatedAt: Date
    ) {
        self.scenarioID = scenarioID
        self.humanSide = humanSide
        self.difficulty = difficulty
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
    public static let playableCollectionID = "play-mode-ready"

    public static func collections(for catalog: ZombieScenarioCatalog) -> [ScenarioCollection] {
        let baseIDs = catalog.scenarios.map(\.id)
        var collections: [ScenarioCollection] = [
            ScenarioCollection(id: "all", title: "All Scenarios", scenarioIDs: baseIDs),
            ScenarioCollection(id: playableCollectionID, title: "Playable Games", scenarioIDs: playableScenarios(in: catalog).map(\.id)),
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

    public static func playableScenarios(in catalog: ZombieScenarioCatalog) -> [ZombieScenario] {
        catalog.scenarios.filter { ScenarioPlayAvailability.forScenario($0).allowsPlayMode }
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

public enum ScenarioPlayAvailability: String, Codable, Equatable, CaseIterable, Identifiable {
    case playable
    case preview
    case deferred
    case excluded

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .playable:
            return "Playable"
        case .preview:
            return "Preview"
        case .deferred:
            return "Deferred"
        case .excluded:
            return "Excluded"
        }
    }

    public var allowsPlayMode: Bool {
        self == .playable
    }

    public static func forScenario(_ scenario: ZombieScenario) -> ScenarioPlayAvailability {
        if scenario.tier == .excluded {
            return .excluded
        }
        if scenario.tier == .early || PlayableAbstractEngine.isPlayable(scenario) {
            return .playable
        }
        if scenario.tier == .deferred || scenario.tier == .mortar || !scenario.playable {
            return .deferred
        }
        return .preview
    }
}

public struct PlayableEventExportRecord: Codable, Equatable {
    public var schemaVersion: Int
    public var scenarioID: String
    public var scenarioTitle: String
    public var humanSide: ForceSide
    public var difficulty: PlayableAIDifficulty
    public var seed: UInt32
    public var outcome: String?
    public var event: ScenarioEvent
}

public enum PlayableLogExporter {
    public static func jsonLines(for game: PlayableGameState, scenario: ZombieScenario) throws -> String {
        try jsonLines(
            events: game.events,
            scenario: scenario,
            humanSide: game.humanSide,
            difficulty: game.difficulty,
            seed: game.seed,
            outcome: game.outcome
        )
    }

    public static func jsonLines(for game: AbstractPlayableGameState, scenario: ZombieScenario) throws -> String {
        try jsonLines(
            events: game.events,
            scenario: scenario,
            humanSide: game.humanSide,
            difficulty: game.difficulty,
            seed: game.seed,
            outcome: game.outcome
        )
    }

    public static func summary(for game: PlayableGameState, scenario: ZombieScenario) -> String {
        summary(
            title: "Play Mode Summary",
            scenario: scenario,
            humanSide: game.humanSide,
            difficulty: game.difficulty,
            seed: game.seed,
            turn: game.turn,
            outcome: game.outcome,
            eventCount: game.events.count
        )
    }

    public static func summary(for game: AbstractPlayableGameState, scenario: ZombieScenario) -> String {
        summary(
            title: "Abstract Play Mode Summary",
            scenario: scenario,
            humanSide: game.humanSide,
            difficulty: game.difficulty,
            seed: game.seed,
            turn: game.turn,
            outcome: game.outcome,
            eventCount: game.events.count
        )
    }

    private static func jsonLines(
        events: [ScenarioEvent],
        scenario: ZombieScenario,
        humanSide: ForceSide,
        difficulty: PlayableAIDifficulty,
        seed: UInt32,
        outcome: String?
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try events.map { event in
            let record = PlayableEventExportRecord(
                schemaVersion: 1,
                scenarioID: scenario.id,
                scenarioTitle: scenario.title,
                humanSide: humanSide,
                difficulty: difficulty,
                seed: seed,
                outcome: outcome,
                event: event
            )
            return String(data: try encoder.encode(record), encoding: .utf8) ?? "{}"
        }.joined(separator: "\n")
    }

    private static func summary(
        title: String,
        scenario: ZombieScenario,
        humanSide: ForceSide,
        difficulty: PlayableAIDifficulty,
        seed: UInt32,
        turn: Int,
        outcome: String?,
        eventCount: Int
    ) -> String {
        let side = scenario.forces.first { $0.side == humanSide }.map { "\($0.name) - \($0.unit)" } ?? humanSide.rawValue.capitalized
        return [
            "# \(title)",
            "",
            "Scenario: \(scenario.title)",
            "Scenario ID: \(scenario.id)",
            "Source: \(scenario.source.wikipedia.absoluteString)",
            "Human side: \(side)",
            "Difficulty: \(difficulty.title)",
            "Seed: \(seed)",
            "Turn: \(turn)",
            "Outcome: \(outcome ?? "unfinished")",
            "Events: \(eventCount)",
            "Availability: \(ScenarioPlayAvailability.forScenario(scenario).title)",
            "Scope warning: \(scenario.scopeWarning)"
        ].joined(separator: "\n")
    }
}

public struct PlayableReleaseRehearsalResult: Codable, Equatable, Identifiable {
    public var id: String { "\(scenarioID)-\(humanSide.rawValue)" }
    public var scenarioID: String
    public var humanSide: ForceSide
    public var outcome: String
    public var finished: Bool
    public var eventCount: Int
}

public enum PlayableReleaseRehearsal {
    public static let scenarioIDs = [
        "play-mode-tutorial",
        "drummuckavall-1975",
        "glasdrumman-1981",
        "kesh-1984",
        "strabane-1985",
        "drumnakilly-1988",
        "operation-conservation-1990",
        "coagh-1991",
        "clonoe-1992",
        "dungiven-1972",
        "dungannon-1979",
        "altnaveigh-1981",
        "ballygawley-landmine-1983",
        "mullacreevie-1991",
        "warrenpoint-1979",
        "fivemiletown-1993",
        "killeeshil-1994",
        "derryard-1989",
        "cloghoge-1992",
        "glenanne-1991",
        "loughgall-1987",
        "newry-road-1993",
        "lynx-shootdown-1994",
        "newry-mortar-1985",
        "osnabruck-mortar-1996"
    ]

    public static func run(_ catalog: ZombieScenarioCatalog, side: ForceSide = .player) -> [PlayableReleaseRehearsalResult] {
        scenarioIDs.compactMap { id in
            guard let scenario = catalog.scenarios.first(where: { $0.id == id }) else {
                return nil
            }
            do {
                if scenario.tier == .early {
                    let game = try PlayableGameEngine.runSmokePlaythrough(scenario, humanSide: side, difficulty: .standard)
                    return PlayableReleaseRehearsalResult(
                        scenarioID: scenario.id,
                        humanSide: side,
                        outcome: game.outcome ?? "unfinished",
                        finished: game.finished,
                        eventCount: game.events.count
                    )
                }
                let game = try PlayableAbstractEngine.runSmokePlaythrough(scenario, humanSide: side, difficulty: .standard)
                return PlayableReleaseRehearsalResult(
                    scenarioID: scenario.id,
                    humanSide: side,
                    outcome: game.outcome ?? "unfinished",
                    finished: game.finished,
                    eventCount: game.events.count
                )
            } catch {
                return PlayableReleaseRehearsalResult(
                    scenarioID: scenario.id,
                    humanSide: side,
                    outcome: String(describing: error),
                    finished: false,
                    eventCount: 0
                )
            }
        }
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
