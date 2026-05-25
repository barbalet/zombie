import Foundation

public enum ScenarioTier: String, Codable, CaseIterable, Identifiable {
    case early
    case vehicle
    case checkpoint
    case aircraft
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

public struct ScenarioMechanics: Codable, Equatable {
    public var vehicles: [VehicleRoute]
    public var explosives: [ExplosiveHazard]
    public var checkpoints: [CheckpointStructure]
    public var phases: [String]
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
    public var implementationNotes: String
}

public struct ZombieScenarioCatalog: Codable, Equatable {
    public var schemaVersion: Int
    public var generatedFromPlanCycles: ClosedRange<Int> {
        1...100
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
