import Foundation

public enum ScenarioTier: String, Codable, CaseIterable, Identifiable {
    case early
    case vehicle
    case checkpoint
    case aircraft
    case mortar
    case deferred
    case excluded

    public var id: String { rawValue }
}

public enum ForceSide: String, Codable, CaseIterable {
    case player
    case opponent
}

public enum ActorRole: String, Codable, CaseIterable {
    case rifleman
    case gunner
    case scout
    case commander
    case driver
    case sentry
    case support
}

public enum WeaponKind: String, Codable, CaseIterable {
    case rifle
    case submachineGun = "submachine_gun"
    case sniperRifle = "sniper_rifle"
    case shotgun
    case machineGun = "machine_gun"
    case heavyMachineGun = "heavy_machine_gun"
    case grenade
    case explosive
    case mortar
    case rocket
    case flamethrower
    case none

    public var isExplosive: Bool {
        switch self {
        case .explosive, .mortar, .rocket, .grenade:
            return true
        default:
            return false
        }
    }
}

public enum TerrainTag: String, Codable, CaseIterable {
    case road
    case lane
    case field
    case hedge
    case wall
    case building
    case checkpoint
    case base
    case border
    case river
    case rail
    case cover
    case elevation
    case protected
    case exit
    case objective
    case helipad
}

public struct GridPoint: Codable, Hashable, Identifiable {
    public var x: Int
    public var y: Int

    public var id: String { "\(x),\(y)" }

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public func distance(to other: GridPoint) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    public func step(toward other: GridPoint) -> GridPoint {
        if x != other.x {
            return GridPoint(x: x + (other.x > x ? 1 : -1), y: y)
        }
        if y != other.y {
            return GridPoint(x: x, y: y + (other.y > y ? 1 : -1))
        }
        return self
    }
}

public struct ScenarioSource: Codable, Equatable {
    public var title: String
    public var wikipedia: URL
    public var accessed: String
    public var confidence: String
    public var notes: String
}

public struct ScenarioObjective: Codable, Equatable {
    public var kind: String
    public var point: GridPoint
    public var description: String
    public var turnLimit: Int
}

public struct ScenarioMapCell: Codable, Equatable {
    public var point: GridPoint
    public var tags: [TerrainTag]
}

public struct ScenarioMap: Codable, Equatable {
    public var width: Int
    public var height: Int
    public var cellYards: Int
    public var cells: [ScenarioMapCell]
    public var protectedCells: [GridPoint]
    public var notes: String

    public var blockedCells: Set<GridPoint> {
        Set(cells.filter { $0.tags.contains(.building) || $0.tags.contains(.base) || $0.tags.contains(.checkpoint) }.map(\.point))
    }

    public var coverCells: Set<GridPoint> {
        Set(cells.filter { $0.tags.contains(.cover) || $0.tags.contains(.hedge) || $0.tags.contains(.wall) || $0.tags.contains(.building) }.map(\.point))
    }

    public var protectedCellSet: Set<GridPoint> {
        Set(protectedCells + cells.filter { $0.tags.contains(.protected) }.map(\.point))
    }
}

public struct ScenarioActor: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var side: ForceSide
    public var role: ActorRole
    public var position: GridPoint
    public var weapon: WeaponKind
    public var stats: [String: Int]
    public var skills: [String]
    public var sourceNote: String
}

public struct ScenarioForce: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var side: ForceSide
    public var unit: String
    public var sourceNote: String
}

public struct VehicleRoute: Codable, Identifiable, Equatable {
    public var id: String
    public var side: ForceSide
    public var label: String
    public var path: [GridPoint]
    public var armor: Int
    public var passengers: [String]
    public var sourceNote: String
}

public struct ExplosiveHazard: Codable, Identifiable, Equatable {
    public var id: String
    public var label: String
    public var point: GridPoint
    public var radius: Int
    public var trigger: String
    public var abstractEffect: String
    public var sourceNote: String
}

public struct CheckpointStructure: Codable, Identifiable, Equatable {
    public var id: String
    public var label: String
    public var point: GridPoint
    public var armor: Int
    public var alarmTurn: Int
    public var sourceNote: String
}

public enum AircraftDamageState: String, Codable, CaseIterable {
    case undamaged
    case suppressed
    case damaged
    case downed
    case exited
}

public struct AircraftLane: Codable, Identifiable, Equatable {
    public var id: String
    public var side: ForceSide
    public var label: String
    public var path: [GridPoint]
    public var altitudeBand: String
    public var entryTurn: Int
    public var exitTurn: Int
    public var damageThreshold: Int
    public var sourceNote: String
}

public struct IndirectFirePlan: Codable, Identifiable, Equatable {
    public var id: String
    public var side: ForceSide
    public var label: String
    public var setupTurn: Int
    public var warningTurn: Int
    public var impactTurn: Int
    public var target: GridPoint
    public var scatter: [GridPoint]
    public var radius: Int
    public var abstractEffect: String
    public var sourceNote: String
}

public struct StructureState: Codable, Identifiable, Equatable {
    public var id: String
    public var label: String
    public var point: GridPoint
    public var armor: Int
    public var health: Int
    public var sourceNote: String
}

public struct ScenarioMechanics: Codable, Equatable {
    public var vehicles: [VehicleRoute]
    public var explosives: [ExplosiveHazard]
    public var checkpoints: [CheckpointStructure]
    public var aircraft: [AircraftLane]
    public var indirectFire: [IndirectFirePlan]
    public var structures: [StructureState]
    public var phases: [String]

    enum CodingKeys: String, CodingKey {
        case vehicles
        case explosives
        case checkpoints
        case aircraft
        case indirectFire
        case structures
        case phases
    }

    public init(
        vehicles: [VehicleRoute],
        explosives: [ExplosiveHazard],
        checkpoints: [CheckpointStructure],
        aircraft: [AircraftLane] = [],
        indirectFire: [IndirectFirePlan] = [],
        structures: [StructureState] = [],
        phases: [String]
    ) {
        self.vehicles = vehicles
        self.explosives = explosives
        self.checkpoints = checkpoints
        self.aircraft = aircraft
        self.indirectFire = indirectFire
        self.structures = structures
        self.phases = phases
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vehicles = try container.decodeIfPresent([VehicleRoute].self, forKey: .vehicles) ?? []
        explosives = try container.decodeIfPresent([ExplosiveHazard].self, forKey: .explosives) ?? []
        checkpoints = try container.decodeIfPresent([CheckpointStructure].self, forKey: .checkpoints) ?? []
        aircraft = try container.decodeIfPresent([AircraftLane].self, forKey: .aircraft) ?? []
        indirectFire = try container.decodeIfPresent([IndirectFirePlan].self, forKey: .indirectFire) ?? []
        structures = try container.decodeIfPresent([StructureState].self, forKey: .structures) ?? []
        phases = try container.decodeIfPresent([String].self, forKey: .phases) ?? []
    }
}

public struct DataConfidence: Codable, Equatable {
    public var roster: String
    public var map: String
    public var weapons: String
    public var timing: String

    public init(roster: String, map: String, weapons: String, timing: String) {
        self.roster = roster
        self.map = map
        self.weapons = weapons
        self.timing = timing
    }

    public static func from(sourceConfidence: String) -> DataConfidence {
        DataConfidence(roster: sourceConfidence, map: sourceConfidence, weapons: sourceConfidence, timing: sourceConfidence)
    }
}

public struct ZombieScenario: Codable, Identifiable, Equatable {
    public var schemaVersion: Int
    public var id: String
    public var title: String
    public var date: String
    public var place: String
    public var tier: ScenarioTier
    public var playable: Bool
    public var forces: [ScenarioForce]
    public var actors: [ScenarioActor]
    public var map: ScenarioMap
    public var objective: ScenarioObjective
    public var mechanics: ScenarioMechanics
    public var source: ScenarioSource
    public var sensitivityTags: [String]
    public var dataConfidence: DataConfidence
    public var scopeWarning: String
    public var collections: [String]
    public var implementationNotes: String

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case id
        case title
        case date
        case place
        case tier
        case playable
        case forces
        case actors
        case map
        case objective
        case mechanics
        case source
        case sensitivityTags
        case dataConfidence
        case scopeWarning
        case collections
        case implementationNotes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(String.self, forKey: .date)
        place = try container.decode(String.self, forKey: .place)
        tier = try container.decode(ScenarioTier.self, forKey: .tier)
        playable = try container.decode(Bool.self, forKey: .playable)
        forces = try container.decode([ScenarioForce].self, forKey: .forces)
        actors = try container.decode([ScenarioActor].self, forKey: .actors)
        map = try container.decode(ScenarioMap.self, forKey: .map)
        objective = try container.decode(ScenarioObjective.self, forKey: .objective)
        mechanics = try container.decode(ScenarioMechanics.self, forKey: .mechanics)
        source = try container.decode(ScenarioSource.self, forKey: .source)
        sensitivityTags = try container.decode([String].self, forKey: .sensitivityTags)
        dataConfidence = try container.decodeIfPresent(DataConfidence.self, forKey: .dataConfidence) ?? DataConfidence.from(sourceConfidence: source.confidence)
        scopeWarning = try container.decodeIfPresent(String.self, forKey: .scopeWarning) ?? ZombieScenario.defaultScopeWarning(tier: tier, tags: sensitivityTags)
        collections = try container.decodeIfPresent([String].self, forKey: .collections) ?? ZombieScenario.defaultCollections(tier: tier, tags: sensitivityTags)
        implementationNotes = try container.decode(String.self, forKey: .implementationNotes)
    }

    static func defaultScopeWarning(tier: ScenarioTier, tags: [String]) -> String {
        if tier == .deferred || tier == .excluded {
            return "Not part of ordinary playable scope; retained for source review and future design only."
        }
        if tags.contains("civilian-risk") {
            return "Civilian presence is represented only as protected noncombat map space."
        }
        if tier == .aircraft || tier == .mortar {
            return "Advanced abstraction: aircraft and indirect-fire effects are represented as high-level timing events."
        }
        return "Playable two-force scenario with neutral historical framing."
    }

    static func defaultCollections(tier: ScenarioTier, tags: [String]) -> [String] {
        var result = ["all", tier.rawValue]
        if tags.contains("protected-zone") {
            result.append("protected-zone")
        }
        if tags.contains("civilian-risk") {
            result.append("civilian-risk-review")
        }
        return result
    }
}

public struct ZombieScenarioCatalog: Codable, Equatable {
    public var schemaVersion: Int
    public var generatedFromPlanCycles: ClosedRange<Int> {
        1...200
    }
    public var scenarios: [ZombieScenario]

    public init(schemaVersion: Int, scenarios: [ZombieScenario]) {
        self.schemaVersion = schemaVersion
        self.scenarios = scenarios
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case scenarios
    }
}

public struct ScenarioValidationIssue: Error, Equatable, CustomStringConvertible {
    public enum Severity: String, Equatable {
        case warning
        case error
    }

    public var scenarioID: String
    public var severity: Severity
    public var message: String

    public var description: String {
        "[\(severity.rawValue)] \(scenarioID): \(message)"
    }
}

public struct ScenarioEvent: Codable, Equatable, Identifiable {
    public var id: Int
    public var turn: Int
    public var phase: String
    public var actor: String
    public var target: String
    public var summary: String
}

public struct RegressionResult: Codable, Equatable {
    public var scenarioID: String
    public var tier: ScenarioTier
    public var outcome: String
    public var turns: Int
    public var events: [ScenarioEvent]
    public var validationErrors: Int
    public var protectedZoneViolations: Int

    public var passed: Bool {
        validationErrors == 0 && protectedZoneViolations == 0 && !events.isEmpty
    }
}
