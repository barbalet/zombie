import Foundation

#if SWIFT_PACKAGE
import FieldOfChaosEngine
#endif

public enum PlayableGamePhase: String, Codable, Equatable, CaseIterable {
    case setup
    case humanActivation
    case aiActivation
    case resolution
    case finished
}

public enum PlayableAIDifficulty: String, Codable, Equatable, CaseIterable, Identifiable {
    case easy
    case standard
    case hard

    public var id: String { rawValue }

    public var title: String {
        rawValue.capitalized
    }
}

public enum PlayableCommand: Codable, Equatable {
    case move(actorID: String, destination: GridPoint)
    case attack(actorID: String, targetID: String)
    case wait(actorID: String)
    case endTurn
}

public struct PlayableReplayResult: Codable, Equatable, Identifiable {
    public var id: String { "\(scenarioID)-\(humanSide.rawValue)-\(difficulty.rawValue)" }
    public var scenarioID: String
    public var humanSide: ForceSide
    public var difficulty: PlayableAIDifficulty
    public var finished: Bool
    public var turns: Int
    public var eventCount: Int
    public var outcome: String
    public var protectedZoneViolations: Int
    public var blockedAttackEvents: Int

    public var passed: Bool {
        finished && turns > 1 && protectedZoneViolations == 0
    }
}

public enum PlayableGameError: Error, CustomStringConvertible, Equatable {
    case scenarioNotPlayable(String)
    case unsupportedTier(ScenarioTier)
    case actorNotFound(String)
    case targetNotFound(String)
    case actorCannotAct(String)
    case notHumanActor(String)
    case invalidPhase(PlayableGamePhase)
    case illegalMove(String)
    case illegalAttack(String)
    case playthroughLimitReached(Int)

    public var description: String {
        switch self {
        case .scenarioNotPlayable(let id):
            return "\(id) is not available for Play Mode."
        case .unsupportedTier(let tier):
            return "\(tier.rawValue.capitalized) scenarios remain in Preview Mode for this cycle."
        case .actorNotFound(let id):
            return "Actor \(id) was not found."
        case .targetNotFound(let id):
            return "Target \(id) was not found."
        case .actorCannotAct(let id):
            return "Actor \(id) cannot act."
        case .notHumanActor(let id):
            return "Actor \(id) is controlled by the opponent."
        case .invalidPhase(let phase):
            return "Cannot perform that command during \(phase.rawValue)."
        case .illegalMove(let reason), .illegalAttack(let reason):
            return reason
        case .playthroughLimitReached(let limit):
            return "Manual smoke playthrough did not finish within \(limit) commands."
        }
    }
}

public struct PlayableWounds: Codable, Equatable {
    public var head: Int
    public var body: Int
    public var leftArm: Int
    public var rightArm: Int
    public var leftLeg: Int
    public var rightLeg: Int

    public static let defaultHuman = PlayableWounds(head: 1, body: 4, leftArm: 1, rightArm: 1, leftLeg: 2, rightLeg: 2)

    public init(head: Int, body: Int, leftArm: Int, rightArm: Int, leftLeg: Int, rightLeg: Int) {
        self.head = head
        self.body = body
        self.leftArm = leftArm
        self.rightArm = rightArm
        self.leftLeg = leftLeg
        self.rightLeg = rightLeg
    }

    public init(character: FocCharacter) {
        self.init(
            head: Int(character.wounds.head),
            body: Int(character.wounds.body),
            leftArm: Int(character.wounds.left_arm),
            rightArm: Int(character.wounds.right_arm),
            leftLeg: Int(character.wounds.left_leg),
            rightLeg: Int(character.wounds.right_leg)
        )
    }

    public var total: Int {
        head + body + leftArm + rightArm + leftLeg + rightLeg
    }
}

public struct PlayableActorState: Codable, Equatable, Identifiable {
    public var id: String
    public var side: ForceSide
    public var position: GridPoint
    public var acted: Bool
    public var wounds: PlayableWounds
    public var clips: Int
    public var roundsInClip: Int
    public var jammed: Bool
    public var unconscious: Bool
    public var dead: Bool

    public var active: Bool {
        !dead && !unconscious
    }
}

public struct PlayableGameState: Codable, Equatable, Identifiable {
    public var id: String { scenarioID }
    public var schemaVersion: Int
    public var scenarioID: String
    public var humanSide: ForceSide
    public var difficulty: PlayableAIDifficulty
    public var seed: UInt32
    public var turn: Int
    public var phase: PlayableGamePhase
    public var actors: [PlayableActorState]
    public var selectedActorID: String?
    public var moveTarget: GridPoint?
    public var attackTargetID: String?
    public var events: [ScenarioEvent]
    public var outcome: String?

    public var aiSide: ForceSide {
        humanSide == .player ? .opponent : .player
    }

    public var finished: Bool {
        phase == .finished || outcome != nil
    }

    public var remainingHumanActorIDs: [String] {
        actors
            .filter { $0.side == humanSide && $0.active && !$0.acted }
            .map(\.id)
            .sorted()
    }
}

public enum AbstractPlayableCommand: String, Codable, Equatable, CaseIterable, Identifiable {
    case advanceRoute
    case hold
    case react
    case resolve

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .advanceRoute:
            return "Advance Route"
        case .hold:
            return "Hold"
        case .react:
            return "React"
        case .resolve:
            return "Resolve"
        }
    }
}

public struct AbstractPlayableReplayResult: Codable, Equatable, Identifiable {
    public var id: String { "\(scenarioID)-\(humanSide.rawValue)" }
    public var scenarioID: String
    public var humanSide: ForceSide
    public var finished: Bool
    public var turns: Int
    public var eventCount: Int
    public var outcome: String
    public var protectedZoneViolations: Int

    public var passed: Bool {
        finished && turns > 0 && eventCount > 1 && protectedZoneViolations == 0
    }
}

public enum AbstractPlayableError: Error, CustomStringConvertible, Equatable {
    case scenarioNotPlayable(String)
    case unsupportedTier(ScenarioTier)
    case commandUnavailable(AbstractPlayableCommand)
    case invalidPhase(PlayableGamePhase)
    case playthroughLimitReached(Int)

    public var description: String {
        switch self {
        case .scenarioNotPlayable(let id):
            return "\(id) is not available for Abstract Play Mode."
        case .unsupportedTier(let tier):
            return "\(tier.rawValue.capitalized) scenarios remain in Preview Mode for this cycle."
        case .commandUnavailable(let command):
            return "\(command.title) is not available in the current abstract state."
        case .invalidPhase(let phase):
            return "Cannot perform that abstract command during \(phase.rawValue)."
        case .playthroughLimitReached(let limit):
            return "Abstract smoke playthrough did not finish within \(limit) commands."
        }
    }
}

public struct AbstractPlayableGameState: Codable, Equatable, Identifiable {
    public var id: String { scenarioID }
    public var schemaVersion: Int
    public var scenarioID: String
    public var humanSide: ForceSide
    public var difficulty: PlayableAIDifficulty
    public var seed: UInt32
    public var turn: Int
    public var phase: PlayableGamePhase
    public var routeProgress: [String: Int]
    public var triggeredHazardIDs: Set<String>
    public var damagedVehicleIDs: Set<String>
    public var alarmedCheckpointIDs: Set<String>
    public var aircraftDamageStates: [String: AircraftDamageState]
    public var exitedAircraftIDs: Set<String>
    public var resolvedImpactIDs: Set<String>
    public var structureHealth: [String: Int]
    public var events: [ScenarioEvent]
    public var outcome: String?

    public var finished: Bool {
        phase == .finished || outcome != nil
    }
}

public enum PlayableAbstractEngine {
    public static let vehiclePlayPolicy = "Cycle 261 decision: vehicle Play Mode exposes route advance, hold, react, and resolve choices only; mine and blast effects remain abstract outcome events."
    public static let checkpointPlayPolicy = "Cycle 270 decision: checkpoint Play Mode exposes alarm, route, and damage-state decisions only; base layouts and breach details remain abstract."
    public static let advancedPlayPolicy = "Cycle 276 decision: aircraft Play Mode exposes lane timing, warning markers, damage state, and exits only; mortar-only scenarios remain Preview Mode."

    public static let vehiclePlayableScenarioIDs: Set<String> = [
        "dungiven-1972",
        "dungannon-1979",
        "altnaveigh-1981",
        "ballygawley-landmine-1983"
    ]

    public static let checkpointPlayableScenarioIDs: Set<String> = [
        "derryard-1989",
        "cloghoge-1992",
        "glenanne-1991",
        "loughgall-1987"
    ]

    public static let aircraftPlayableScenarioIDs: Set<String> = [
        "newry-road-1993",
        "lynx-shootdown-1994"
    ]

    public static var abstractPlayableScenarioIDs: Set<String> {
        vehiclePlayableScenarioIDs
            .union(checkpointPlayableScenarioIDs)
            .union(aircraftPlayableScenarioIDs)
    }

    public static func isPlayable(_ scenario: ZombieScenario) -> Bool {
        guard scenario.playable else {
            return false
        }
        switch scenario.tier {
        case .vehicle:
            return vehiclePlayableScenarioIDs.contains(scenario.id)
        case .checkpoint:
            return checkpointPlayableScenarioIDs.contains(scenario.id)
        case .aircraft:
            return aircraftPlayableScenarioIDs.contains(scenario.id)
        default:
            return false
        }
    }

    public static func availability(_ scenario: ZombieScenario) -> String {
        if isPlayable(scenario) {
            switch scenario.tier {
            case .vehicle:
                return "Abstract Play Mode available: \(vehiclePlayPolicy)"
            case .checkpoint:
                return "Abstract Play Mode available: \(checkpointPlayPolicy)"
            case .aircraft:
                return "Abstract Play Mode available: \(advancedPlayPolicy)"
            default:
                return "Use infantry Play Mode for this scenario."
            }
        }
        if scenario.tier == .mortar || scenario.tier == .deferred || scenario.tier == .excluded {
            return "Preview Mode only: deferred or mortar-only content is blocked from Play Mode."
        }
        if scenario.tier == .vehicle || scenario.tier == .checkpoint || scenario.tier == .aircraft {
            return "Preview Mode only for cycles 261-280: this scenario needs more review before manual play."
        }
        return "Use infantry Play Mode for early scenarios."
    }

    public static func sideBriefing(for scenario: ZombieScenario, humanSide: ForceSide) -> String {
        let side = sideName(humanSide, in: scenario)
        switch scenario.tier {
        case .vehicle:
            return "As \(side), choose when to advance, hold, react, or resolve the shared route state. Convoy survival and route interdiction are represented as high-level outcomes."
        case .checkpoint:
            return "As \(side), choose route, alarm, reaction, and damage-state timing. Checkpoint play stays at the level of alarms, positions, and abstract structure health."
        case .aircraft:
            return "As \(side), choose lane timing, reaction, and resolution around aircraft markers. The model records warnings, damage states, and exits without operational procedure detail."
        default:
            return PlayableGameEngine.objectiveBriefing(for: scenario, humanSide: humanSide)
        }
    }

    public static func start(_ scenario: ZombieScenario, humanSide: ForceSide, difficulty: PlayableAIDifficulty = .standard) throws -> AbstractPlayableGameState {
        guard scenario.playable else {
            throw AbstractPlayableError.scenarioNotPlayable(scenario.id)
        }
        guard isPlayable(scenario) else {
            throw AbstractPlayableError.unsupportedTier(scenario.tier)
        }

        var health = Dictionary(uniqueKeysWithValues: scenario.mechanics.structures.map { ($0.id, $0.health) })
        for checkpoint in scenario.mechanics.checkpoints {
            health[checkpoint.id] = max(1, checkpoint.armor + 1)
        }

        let seed = stableSeed(for: scenario.id, side: humanSide, index: 261)
        return AbstractPlayableGameState(
            schemaVersion: 1,
            scenarioID: scenario.id,
            humanSide: humanSide,
            difficulty: difficulty,
            seed: seed,
            turn: 1,
            phase: .humanActivation,
            routeProgress: Dictionary(uniqueKeysWithValues: scenario.mechanics.vehicles.map { ($0.id, 0) }),
            triggeredHazardIDs: [],
            damagedVehicleIDs: [],
            alarmedCheckpointIDs: [],
            aircraftDamageStates: Dictionary(uniqueKeysWithValues: scenario.mechanics.aircraft.map { ($0.id, AircraftDamageState.undamaged) }),
            exitedAircraftIDs: [],
            resolvedImpactIDs: [],
            structureHealth: health,
            events: [
                ScenarioEvent(
                    id: 1,
                    turn: 1,
                    phase: "abstract-start",
                    actor: sideName(humanSide, in: scenario),
                    target: scenario.title,
                    summary: "Abstract Play Mode started as \(sideName(humanSide, in: scenario))."
                )
            ],
            outcome: nil
        )
    }

    public static func commandAvailable(_ command: AbstractPlayableCommand, in state: AbstractPlayableGameState, scenario: ZombieScenario) -> Bool {
        guard !state.finished else {
            return false
        }
        switch command {
        case .advanceRoute:
            guard state.phase == .humanActivation else {
                return false
            }
            return hasRouteAvailable(in: state, scenario: scenario) || hasActiveAircraftLane(in: state, scenario: scenario)
        case .hold:
            return state.phase == .humanActivation
        case .react:
            guard state.phase == .humanActivation else {
                return false
            }
            return !scenario.mechanics.checkpoints.isEmpty || !scenario.mechanics.aircraft.isEmpty || !scenario.mechanics.indirectFire.isEmpty
        case .resolve:
            return state.phase == .resolution
        }
    }

    public static func applying(_ command: AbstractPlayableCommand, to state: AbstractPlayableGameState, scenario: ZombieScenario) throws -> AbstractPlayableGameState {
        guard isPlayable(scenario) else {
            throw AbstractPlayableError.scenarioNotPlayable(scenario.id)
        }
        guard commandAvailable(command, in: state, scenario: scenario) else {
            if command == .resolve || state.phase != .humanActivation {
                throw AbstractPlayableError.invalidPhase(state.phase)
            }
            throw AbstractPlayableError.commandUnavailable(command)
        }

        var state = state
        switch command {
        case .advanceRoute:
            advanceRoutesAndLanes(&state, scenario: scenario)
            state.phase = .resolution
        case .hold:
            appendEvent(&state, phase: "abstract-hold", actor: sideName(state.humanSide, in: scenario), target: "", summary: "\(sideName(state.humanSide, in: scenario)) holds current abstract positions.")
            state.phase = .resolution
        case .react:
            applyReaction(&state, scenario: scenario)
            state.phase = .resolution
        case .resolve:
            resolveTurn(&state, scenario: scenario)
        }
        return state
    }

    public static func runSmokePlaythrough(_ scenario: ZombieScenario, humanSide: ForceSide, difficulty: PlayableAIDifficulty = .standard, maxCommands: Int = 80) throws -> AbstractPlayableGameState {
        var state = try start(scenario, humanSide: humanSide, difficulty: difficulty)
        var commandCount = 0

        while !state.finished && commandCount < maxCommands {
            let command: AbstractPlayableCommand
            if commandAvailable(.advanceRoute, in: state, scenario: scenario) {
                command = .advanceRoute
            } else if commandAvailable(.react, in: state, scenario: scenario) {
                command = .react
            } else {
                command = .hold
            }

            state = try applying(command, to: state, scenario: scenario)
            commandCount += 1

            if commandAvailable(.resolve, in: state, scenario: scenario) {
                state = try applying(.resolve, to: state, scenario: scenario)
                commandCount += 1
            }
        }

        guard state.finished else {
            throw AbstractPlayableError.playthroughLimitReached(maxCommands)
        }
        return state
    }

    public static func runReadyCorpusReplay(_ catalog: ZombieScenarioCatalog, difficulty: PlayableAIDifficulty = .standard) -> [AbstractPlayableReplayResult] {
        catalog.scenarios
            .filter(isPlayable)
            .sorted { $0.id < $1.id }
            .flatMap { scenario in
                ForceSide.allCases.map { side in
                    replayResult(for: scenario, humanSide: side, difficulty: difficulty)
                }
            }
    }

    public static func replayResult(for scenario: ZombieScenario, humanSide: ForceSide, difficulty: PlayableAIDifficulty = .standard) -> AbstractPlayableReplayResult {
        do {
            let state = try runSmokePlaythrough(scenario, humanSide: humanSide, difficulty: difficulty)
            return AbstractPlayableReplayResult(
                scenarioID: scenario.id,
                humanSide: humanSide,
                finished: state.finished,
                turns: state.turn,
                eventCount: state.events.count,
                outcome: state.outcome ?? "unfinished",
                protectedZoneViolations: state.events.filter { $0.phase == "protected-zone" }.count
            )
        } catch {
            return AbstractPlayableReplayResult(
                scenarioID: scenario.id,
                humanSide: humanSide,
                finished: false,
                turns: 0,
                eventCount: 0,
                outcome: String(describing: error),
                protectedZoneViolations: 0
            )
        }
    }

    private static func advanceRoutesAndLanes(_ state: inout AbstractPlayableGameState, scenario: ZombieScenario) {
        let protectedCells = scenario.map.protectedCellSet
        for vehicle in scenario.mechanics.vehicles.sorted(by: { $0.id < $1.id }) {
            guard !state.damagedVehicleIDs.contains(vehicle.id) else {
                continue
            }
            let currentProgress = state.routeProgress[vehicle.id, default: 0]
            guard currentProgress < vehicle.path.count else {
                continue
            }
            let point = vehicle.path[currentProgress]
            state.routeProgress[vehicle.id] = currentProgress + 1
            if protectedCells.contains(point) {
                appendEvent(&state, phase: "protected-zone", actor: vehicle.label, target: point.id, summary: "\(vehicle.label) route was blocked from protected cell \(point.id).")
            } else {
                appendEvent(&state, phase: "vehicle-route", actor: vehicle.label, target: point.id, summary: "\(vehicle.label) reaches route marker \(point.id).")
            }
        }

        for lane in scenario.mechanics.aircraft.sorted(by: { $0.id < $1.id }) where lane.entryTurn <= state.turn && state.turn <= lane.exitTurn {
            let damageState = state.aircraftDamageStates[lane.id, default: .undamaged]
            guard damageState != .damaged && damageState != .downed && damageState != .exited else {
                continue
            }
            guard let point = lanePoint(for: lane, turn: state.turn) else {
                continue
            }
            if protectedCells.contains(point) {
                appendEvent(&state, phase: "protected-zone", actor: lane.label, target: point.id, summary: "\(lane.label) lane marker was blocked from protected cell \(point.id).")
            } else {
                appendEvent(&state, phase: "aircraft-lane", actor: lane.label, target: point.id, summary: "\(lane.label) crosses marker \(point.id) at \(lane.altitudeBand) altitude.")
            }
        }
    }

    private static func applyReaction(_ state: inout AbstractPlayableGameState, scenario: ZombieScenario) {
        var emitted = false
        for checkpoint in scenario.mechanics.checkpoints.sorted(by: { $0.id < $1.id }) where checkpoint.alarmTurn <= state.turn && !state.alarmedCheckpointIDs.contains(checkpoint.id) {
            state.alarmedCheckpointIDs.insert(checkpoint.id)
            appendEvent(&state, phase: "alarm", actor: checkpoint.label, target: "", summary: "\(checkpoint.label) enters alarm phase.")
            emitted = true
        }

        for fire in scenario.mechanics.indirectFire.sorted(by: { $0.id < $1.id }) where fire.warningTurn == state.turn && !state.resolvedImpactIDs.contains(fire.id) {
            appendEvent(&state, phase: "indirect-warning", actor: fire.label, target: fire.target.id, summary: "\(fire.label) warning marker appears near \(fire.target.id).")
            emitted = true
        }

        for lane in scenario.mechanics.aircraft.sorted(by: { $0.id < $1.id }) where lane.entryTurn <= state.turn && state.turn <= lane.exitTurn {
            if state.aircraftDamageStates[lane.id, default: .undamaged] == .undamaged {
                state.aircraftDamageStates[lane.id] = .suppressed
                appendEvent(&state, phase: "aircraft-react", actor: lane.label, target: scenario.title, summary: "\(lane.label) receives an abstract reaction marker.")
                emitted = true
            }
        }

        if !emitted {
            appendEvent(&state, phase: "abstract-react", actor: sideName(state.humanSide, in: scenario), target: "", summary: "\(sideName(state.humanSide, in: scenario)) reacts, but no new marker changes state.")
        }
    }

    private static func resolveTurn(_ state: inout AbstractPlayableGameState, scenario: ZombieScenario) {
        resolveHazards(&state, scenario: scenario)
        resolveCheckpointAlarms(&state, scenario: scenario)
        resolveAircraft(&state, scenario: scenario)
        resolveIndirectFire(&state, scenario: scenario)

        if let outcome = outcome(for: state, scenario: scenario) {
            finish(&state, scenario: scenario, outcome: outcome)
            return
        }

        if state.turn >= max(1, scenario.objective.turnLimit) {
            finish(&state, scenario: scenario, outcome: limitOutcome(for: state, scenario: scenario))
            return
        }

        state.turn += 1
        state.phase = .humanActivation
    }

    private static func resolveHazards(_ state: inout AbstractPlayableGameState, scenario: ZombieScenario) {
        for vehicle in scenario.mechanics.vehicles.sorted(by: { $0.id < $1.id }) {
            guard let point = currentPoint(for: vehicle, in: state) else {
                continue
            }
            for hazard in scenario.mechanics.explosives.sorted(by: { $0.id < $1.id }) where !state.triggeredHazardIDs.contains(hazard.id) {
                guard point.distance(to: hazard.point) <= max(0, hazard.radius) else {
                    continue
                }
                state.triggeredHazardIDs.insert(hazard.id)
                state.damagedVehicleIDs.insert(vehicle.id)
                appendEvent(&state, phase: "abstract-blast", actor: hazard.label, target: vehicle.label, summary: "\(hazard.label) resolves against \(vehicle.label): \(hazard.abstractEffect).")
                damageStructures(at: hazard.point, radius: hazard.radius, actor: hazard.label, state: &state, scenario: scenario)
            }
        }
    }

    private static func resolveCheckpointAlarms(_ state: inout AbstractPlayableGameState, scenario: ZombieScenario) {
        for checkpoint in scenario.mechanics.checkpoints.sorted(by: { $0.id < $1.id }) where checkpoint.alarmTurn == state.turn && !state.alarmedCheckpointIDs.contains(checkpoint.id) {
            state.alarmedCheckpointIDs.insert(checkpoint.id)
            appendEvent(&state, phase: "alarm", actor: checkpoint.label, target: "", summary: "\(checkpoint.label) enters alarm phase.")
        }
    }

    private static func resolveAircraft(_ state: inout AbstractPlayableGameState, scenario: ZombieScenario) {
        let antiAirScore = scenario.actors.filter { actor in
            actor.weapon == .heavyMachineGun || actor.weapon == .machineGun || actor.weapon == .rocket || actor.weapon == .mortar
        }.count

        for lane in scenario.mechanics.aircraft.sorted(by: { $0.id < $1.id }) where lane.entryTurn <= state.turn && state.turn <= lane.exitTurn {
            let damageState = state.aircraftDamageStates[lane.id, default: .undamaged]
            if antiAirScore >= lane.damageThreshold && damageState != .damaged && damageState != .downed && damageState != .exited && state.turn > lane.entryTurn {
                state.aircraftDamageStates[lane.id] = .damaged
                appendEvent(&state, phase: "aircraft-damage", actor: lane.label, target: scenario.title, summary: "\(lane.label) receives abstract damage and must leave the lane.")
            } else if state.turn >= lane.exitTurn && damageState != .damaged && damageState != .downed && damageState != .exited {
                state.aircraftDamageStates[lane.id] = .exited
                state.exitedAircraftIDs.insert(lane.id)
                appendEvent(&state, phase: "aircraft-exit", actor: lane.label, target: "", summary: "\(lane.label) exits the scenario lane.")
            }
        }
    }

    private static func resolveIndirectFire(_ state: inout AbstractPlayableGameState, scenario: ZombieScenario) {
        let protectedCells = scenario.map.protectedCellSet
        for fire in scenario.mechanics.indirectFire.sorted(by: { $0.id < $1.id }) {
            if fire.setupTurn == state.turn && !hasEvent("indirect-setup", actor: fire.label, turn: state.turn, in: state) {
                appendEvent(&state, phase: "indirect-setup", actor: fire.label, target: "", summary: "\(fire.label) enters setup phase.")
            }
            if fire.warningTurn == state.turn && !hasEvent("indirect-warning", actor: fire.label, turn: state.turn, in: state) {
                appendEvent(&state, phase: "indirect-warning", actor: fire.label, target: fire.target.id, summary: "\(fire.label) warning marker appears near \(fire.target.id).")
            }
            guard fire.impactTurn == state.turn && !state.resolvedImpactIDs.contains(fire.id) else {
                continue
            }
            state.resolvedImpactIDs.insert(fire.id)
            let impact = deterministicImpact(for: fire, scenarioID: scenario.id)
            if protectedCells.contains(impact) {
                appendEvent(&state, phase: "protected-zone", actor: fire.label, target: impact.id, summary: "\(fire.label) impact was blocked from protected cell \(impact.id).")
                continue
            }
            appendEvent(&state, phase: "indirect-impact", actor: fire.label, target: impact.id, summary: "\(fire.label) resolves at \(impact.id): \(fire.abstractEffect).")
            damageStructures(at: impact, radius: fire.radius, actor: fire.label, state: &state, scenario: scenario)
        }
    }

    private static func damageStructures(at point: GridPoint, radius: Int, actor: String, state: inout AbstractPlayableGameState, scenario: ZombieScenario) {
        for structure in scenario.mechanics.structures.sorted(by: { $0.id < $1.id }) where point.distance(to: structure.point) <= max(0, radius) {
            let previous = state.structureHealth[structure.id] ?? structure.health
            let damage = max(1, 3 - min(2, structure.armor))
            state.structureHealth[structure.id] = max(0, previous - damage)
            appendEvent(&state, phase: "structure-damage", actor: actor, target: structure.label, summary: "\(structure.label) health \(previous) -> \(state.structureHealth[structure.id] ?? 0).")
        }

        for checkpoint in scenario.mechanics.checkpoints.sorted(by: { $0.id < $1.id }) where point.distance(to: checkpoint.point) <= max(0, radius) {
            let previous = state.structureHealth[checkpoint.id] ?? max(1, checkpoint.armor + 1)
            let damage = max(1, 3 - min(2, checkpoint.armor))
            state.structureHealth[checkpoint.id] = max(0, previous - damage)
            appendEvent(&state, phase: "structure-damage", actor: actor, target: checkpoint.label, summary: "\(checkpoint.label) health \(previous) -> \(state.structureHealth[checkpoint.id] ?? 0).")
        }
    }

    private static func outcome(for state: AbstractPlayableGameState, scenario: ZombieScenario) -> String? {
        if scenario.tier == .checkpoint && !state.triggeredHazardIDs.isEmpty {
            return "checkpoint damage resolved"
        }
        if scenario.tier == .vehicle && !state.damagedVehicleIDs.isEmpty {
            return "route interdicted"
        }
        if state.structureHealth.values.contains(where: { $0 == 0 }) {
            return "structure disabled"
        }
        let hasUnresolvedIndirectFire = scenario.mechanics.indirectFire.contains { !state.resolvedImpactIDs.contains($0.id) }
        if !scenario.mechanics.vehicles.isEmpty && allRoutesComplete(in: state, scenario: scenario) && scenario.tier == .vehicle {
            return "route completed"
        }
        if !scenario.mechanics.aircraft.isEmpty && allAircraftResolved(in: state, scenario: scenario) && !hasUnresolvedIndirectFire {
            return state.aircraftDamageStates.values.contains(.damaged) ? "aircraft damaged" : "advanced route completed"
        }
        return nil
    }

    private static func limitOutcome(for state: AbstractPlayableGameState, scenario: ZombieScenario) -> String {
        if scenario.tier == .vehicle {
            return state.damagedVehicleIDs.isEmpty ? "route completed" : "route interdicted"
        }
        if scenario.tier == .checkpoint {
            return state.triggeredHazardIDs.isEmpty ? "checkpoint held" : "checkpoint damage resolved"
        }
        if state.aircraftDamageStates.values.contains(.damaged) {
            return "aircraft damaged"
        }
        if !state.resolvedImpactIDs.isEmpty {
            return "indirect fire resolved"
        }
        return "abstract scenario resolved"
    }

    private static func finish(_ state: inout AbstractPlayableGameState, scenario: ZombieScenario, outcome: String) {
        state.outcome = outcome
        state.phase = .finished
        appendEvent(&state, phase: "outcome", actor: sideName(state.humanSide, in: scenario), target: scenario.title, summary: outcome)
    }

    private static func hasRouteAvailable(in state: AbstractPlayableGameState, scenario: ZombieScenario) -> Bool {
        scenario.mechanics.vehicles.contains { vehicle in
            !state.damagedVehicleIDs.contains(vehicle.id) && state.routeProgress[vehicle.id, default: 0] < vehicle.path.count
        }
    }

    private static func hasActiveAircraftLane(in state: AbstractPlayableGameState, scenario: ZombieScenario) -> Bool {
        scenario.mechanics.aircraft.contains { lane in
            let damageState = state.aircraftDamageStates[lane.id, default: .undamaged]
            return lane.entryTurn <= state.turn &&
                state.turn <= lane.exitTurn &&
                damageState != .damaged &&
                damageState != .downed &&
                damageState != .exited
        }
    }

    private static func allRoutesComplete(in state: AbstractPlayableGameState, scenario: ZombieScenario) -> Bool {
        scenario.mechanics.vehicles.allSatisfy { vehicle in
            state.routeProgress[vehicle.id, default: 0] >= vehicle.path.count || state.damagedVehicleIDs.contains(vehicle.id)
        }
    }

    private static func allAircraftResolved(in state: AbstractPlayableGameState, scenario: ZombieScenario) -> Bool {
        scenario.mechanics.aircraft.allSatisfy { lane in
            let damageState = state.aircraftDamageStates[lane.id, default: .undamaged]
            return damageState == .damaged || damageState == .downed || damageState == .exited
        }
    }

    private static func currentPoint(for vehicle: VehicleRoute, in state: AbstractPlayableGameState) -> GridPoint? {
        let progress = state.routeProgress[vehicle.id, default: 0]
        guard progress > 0, !vehicle.path.isEmpty else {
            return nil
        }
        return vehicle.path[min(progress - 1, vehicle.path.count - 1)]
    }

    private static func lanePoint(for lane: AircraftLane, turn: Int) -> GridPoint? {
        let laneIndex = min(max(turn - lane.entryTurn, 0), max(0, lane.path.count - 1))
        return lane.path[safe: laneIndex]
    }

    private static func deterministicImpact(for fire: IndirectFirePlan, scenarioID: String) -> GridPoint {
        guard !fire.scatter.isEmpty else {
            return fire.target
        }
        let seed = stableSeed(for: scenarioID, side: fire.side, index: fire.impactTurn)
        return fire.scatter[Int(seed % UInt32(fire.scatter.count))]
    }

    private static func hasEvent(_ phase: String, actor: String, turn: Int, in state: AbstractPlayableGameState) -> Bool {
        state.events.contains { $0.phase == phase && $0.actor == actor && $0.turn == turn }
    }

    private static func sideName(_ side: ForceSide, in scenario: ZombieScenario) -> String {
        scenario.forces.first { $0.side == side }.map { "\($0.name) \($0.unit)" } ?? side.rawValue
    }

    private static func appendEvent(_ state: inout AbstractPlayableGameState, phase: String, actor: String, target: String, summary: String) {
        state.events.append(ScenarioEvent(id: state.events.count + 1, turn: state.turn, phase: phase, actor: actor, target: target, summary: summary))
    }

    private static func stableSeed(for scenarioID: String, side: ForceSide, index: Int) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in "\(scenarioID):\(side.rawValue):\(index)".utf8 {
            hash ^= UInt32(byte)
            hash &*= 16_777_619
        }
        return hash == 0 ? 1 : hash
    }
}

public enum PlayableGameEngine {
    public static let fogOfWarPolicy = "Cycle 252 decision: hidden units stay out of scope for cycle 300; Play Mode uses visible actors and deterministic public logs."

    public static func start(_ scenario: ZombieScenario, humanSide: ForceSide, difficulty: PlayableAIDifficulty = .standard) throws -> PlayableGameState {
        guard scenario.playable else {
            throw PlayableGameError.scenarioNotPlayable(scenario.id)
        }
        guard scenario.tier == .early else {
            throw PlayableGameError.unsupportedTier(scenario.tier)
        }
        let seed = stableSeed(for: scenario.id, actorID: "\(humanSide.rawValue)-\(difficulty.rawValue)", index: 0)

        let actorStates = scenario.actors.enumerated().map { index, actor in
            let character = FieldOfChaosAdapter.makeCharacter(from: actor, seed: stableSeed(for: scenario.id, actorID: actor.id, index: index))
            return PlayableActorState(
                id: actor.id,
                side: actor.side,
                position: actor.position,
                acted: false,
                wounds: PlayableWounds(character: character),
                clips: Int(character.loadout.clips),
                roundsInClip: Int(character.loadout.rounds_in_clip),
                jammed: character.jammed,
                unconscious: character.unconscious,
                dead: character.dead
            )
        }

        return PlayableGameState(
            schemaVersion: 2,
            scenarioID: scenario.id,
            humanSide: humanSide,
            difficulty: difficulty,
            seed: seed,
            turn: 1,
            phase: .humanActivation,
            actors: actorStates,
            selectedActorID: actorStates.first { $0.side == humanSide && $0.active }?.id,
            moveTarget: nil,
            attackTargetID: nil,
            events: [
                ScenarioEvent(
                    id: 1,
                    turn: 1,
                    phase: "play-start",
                    actor: sideName(humanSide, in: scenario),
                    target: scenario.title,
                    summary: "Play Mode started as \(sideName(humanSide, in: scenario)) on \(difficulty.title) AI."
                )
            ],
            outcome: nil
        )
    }

    public static func objectiveBriefing(for scenario: ZombieScenario, humanSide: ForceSide) -> String {
        "As \(sideName(humanSide, in: scenario)), objective: \(scenario.objective.description)"
    }

    public static func actorStatus(_ actor: PlayableActorState) -> String {
        if actor.dead { return "Dead" }
        if actor.unconscious { return "Unconscious" }
        if actor.acted { return "Acted" }
        return "Active"
    }

    public static func forceSummary(for side: ForceSide, in scenario: ZombieScenario) -> String {
        let force = scenario.forces.first { $0.side == side }
        let actors = scenario.actors.filter { $0.side == side }
        let weapons = Set(actors.map { displayName($0.weapon.rawValue) }).sorted().joined(separator: ", ")
        let name = force.map { "\($0.name) - \($0.unit)" } ?? side.rawValue.capitalized
        return "\(name): \(actors.count) actors; \(weapons.isEmpty ? "no weapons listed" : weapons)."
    }

    public static func runSmokePlaythrough(_ scenario: ZombieScenario, humanSide: ForceSide, difficulty: PlayableAIDifficulty = .standard, maxCommands: Int = 200) throws -> PlayableGameState {
        var state = try start(scenario, humanSide: humanSide, difficulty: difficulty)
        var commandCount = 0

        while !state.finished && commandCount < maxCommands {
            let actorIDs = state.actors
                .filter { $0.side == state.humanSide && $0.active && !$0.acted }
                .map(\.id)
                .sorted()

            guard let actorID = actorIDs.first else {
                state = try applying(.endTurn, to: state, scenario: scenario)
                commandCount += 1
                continue
            }

            if let target = legalAttackTargets(for: actorID, in: state, scenario: scenario).first {
                state = try applying(.attack(actorID: actorID, targetID: target.id), to: state, scenario: scenario)
            } else if let destination = preferredHumanMove(for: actorID, in: state, scenario: scenario) {
                state = try applying(.move(actorID: actorID, destination: destination), to: state, scenario: scenario)
            } else {
                state = try applying(.wait(actorID: actorID), to: state, scenario: scenario)
            }
            commandCount += 1
        }

        guard state.finished else {
            throw PlayableGameError.playthroughLimitReached(maxCommands)
        }
        return state
    }

    public static func runEarlyCorpusReplay(_ catalog: ZombieScenarioCatalog, difficulty: PlayableAIDifficulty = .standard) -> [PlayableReplayResult] {
        catalog.scenarios
            .filter { $0.playable && $0.tier == .early }
            .sorted { $0.id < $1.id }
            .flatMap { scenario in
                ForceSide.allCases.map { side in
                    replayResult(for: scenario, humanSide: side, difficulty: difficulty)
                }
            }
    }

    public static func replayResult(for scenario: ZombieScenario, humanSide: ForceSide, difficulty: PlayableAIDifficulty = .standard) -> PlayableReplayResult {
        do {
            let state = try runSmokePlaythrough(scenario, humanSide: humanSide, difficulty: difficulty)
            return PlayableReplayResult(
                scenarioID: scenario.id,
                humanSide: humanSide,
                difficulty: difficulty,
                finished: state.finished,
                turns: state.turn,
                eventCount: state.events.count,
                outcome: state.outcome ?? "unfinished",
                protectedZoneViolations: protectedZoneViolations(in: state, scenario: scenario),
                blockedAttackEvents: state.events.filter { $0.phase.contains("attack-blocked") }.count
            )
        } catch {
            return PlayableReplayResult(
                scenarioID: scenario.id,
                humanSide: humanSide,
                difficulty: difficulty,
                finished: false,
                turns: 0,
                eventCount: 0,
                outcome: String(describing: error),
                protectedZoneViolations: 0,
                blockedAttackEvents: 0
            )
        }
    }

    public static func legalMoveDestinations(for actorID: String, in state: PlayableGameState, scenario: ZombieScenario) -> [GridPoint] {
        guard let actor = state.actors.first(where: { $0.id == actorID }), actor.active, !actor.acted else {
            return []
        }
        let occupied = Set(state.actors.filter { $0.id != actorID && $0.active }.map(\.position))
        return neighbors(of: actor.position, in: scenario.map)
            .filter { scenario.map.movementCost(at: $0) != nil && !occupied.contains($0) }
            .sorted { $0.id < $1.id }
    }

    public static func legalAttackTargets(for actorID: String, in state: PlayableGameState, scenario: ZombieScenario) -> [PlayableActorState] {
        guard let actor = state.actors.first(where: { $0.id == actorID }), actor.active, !actor.acted else {
            return []
        }
        return state.actors
            .filter { $0.side != actor.side && $0.active }
            .filter { canAttack(actor, target: $0, state: state, scenario: scenario) }
            .sorted { $0.id < $1.id }
    }

    public static func applying(_ command: PlayableCommand, to state: PlayableGameState, scenario: ZombieScenario) throws -> PlayableGameState {
        var state = state
        guard state.phase == .humanActivation else {
            throw PlayableGameError.invalidPhase(state.phase)
        }
        guard state.outcome == nil else {
            return state
        }

        switch command {
        case .move(let actorID, let destination):
            try validateHumanActor(actorID, in: state)
            guard legalMoveDestinations(for: actorID, in: state, scenario: scenario).contains(destination) else {
                throw PlayableGameError.illegalMove("Move to \(destination.id) is not legal.")
            }
            let index = try actorIndex(actorID, in: state)
            state.actors[index].position = destination
            state.actors[index].acted = true
            state.selectedActorID = actorID
            state.moveTarget = destination
            state.attackTargetID = nil
            appendEvent(&state, phase: "move", actor: actorName(actorID, in: scenario), target: destination.id, summary: "\(actorName(actorID, in: scenario)) moves to \(destination.id).")

        case .attack(let actorID, let targetID):
            try validateHumanActor(actorID, in: state)
            guard legalAttackTargets(for: actorID, in: state, scenario: scenario).contains(where: { $0.id == targetID }) else {
                throw PlayableGameError.illegalAttack("Attack against \(targetID) is not legal.")
            }
            try executeAttack(actorID: actorID, targetID: targetID, state: &state, scenario: scenario, phase: "attack")
            let index = try actorIndex(actorID, in: state)
            state.actors[index].acted = true
            state.selectedActorID = actorID
            state.moveTarget = nil
            state.attackTargetID = targetID

        case .wait(let actorID):
            try validateHumanActor(actorID, in: state)
            let index = try actorIndex(actorID, in: state)
            state.actors[index].acted = true
            state.selectedActorID = actorID
            state.moveTarget = nil
            state.attackTargetID = nil
            appendEvent(&state, phase: "wait", actor: actorName(actorID, in: scenario), target: "", summary: "\(actorName(actorID, in: scenario)) waits.")

        case .endTurn:
            state = runAIActivation(from: state, scenario: scenario)
        }

        updateOutcome(&state, scenario: scenario)
        return state
    }

    public static func runAIActivation(from state: PlayableGameState, scenario: ZombieScenario) -> PlayableGameState {
        var state = state
        guard state.outcome == nil else {
            return state
        }

        state.phase = .aiActivation
        let aiIDs = state.actors.filter { $0.side == state.aiSide && $0.active }.map(\.id)
        for actorID in aiIDs {
            guard let actor = state.actors.first(where: { $0.id == actorID }), actor.active else {
                continue
            }
            if let target = legalAttackTargetsForAnySide(actorID: actorID, in: state, scenario: scenario).first {
                try? executeAttack(actorID: actorID, targetID: target.id, state: &state, scenario: scenario, phase: "ai-attack")
                if let index = try? actorIndex(actorID, in: state) {
                    state.actors[index].acted = true
                }
            } else if let destination = nextAIMove(for: actorID, in: state, scenario: scenario) {
                if let index = try? actorIndex(actorID, in: state) {
                    state.actors[index].position = destination
                    state.actors[index].acted = true
                    appendEvent(&state, phase: "ai-move", actor: actorName(actorID, in: scenario), target: destination.id, summary: "\(actorName(actorID, in: scenario)) moves to \(destination.id).")
                }
            } else if let index = try? actorIndex(actorID, in: state) {
                state.actors[index].acted = true
                appendEvent(&state, phase: "ai-wait", actor: actorName(actorID, in: scenario), target: "", summary: "\(actorName(actorID, in: scenario)) waits.")
            }
            updateOutcome(&state, scenario: scenario)
            if state.finished {
                return state
            }
        }

        state.turn += 1
        state.phase = .humanActivation
        state.actors = state.actors.map { actor in
            var copy = actor
            copy.acted = false
            return copy
        }
        state.selectedActorID = state.actors.first { $0.side == state.humanSide && $0.active }?.id
        state.moveTarget = nil
        state.attackTargetID = nil
        updateOutcome(&state, scenario: scenario)
        return state
    }

    private static func validateHumanActor(_ actorID: String, in state: PlayableGameState) throws {
        guard let actor = state.actors.first(where: { $0.id == actorID }) else {
            throw PlayableGameError.actorNotFound(actorID)
        }
        guard actor.side == state.humanSide else {
            throw PlayableGameError.notHumanActor(actorID)
        }
        guard actor.active && !actor.acted else {
            throw PlayableGameError.actorCannotAct(actorID)
        }
    }

    private static func executeAttack(actorID: String, targetID: String, state: inout PlayableGameState, scenario: ZombieScenario, phase: String) throws {
        let attackerIndex = try actorIndex(actorID, in: state)
        let targetIndex = try actorIndex(targetID, in: state)
        guard let attackerActor = scenario.actors.first(where: { $0.id == actorID }) else {
            throw PlayableGameError.actorNotFound(actorID)
        }
        guard let targetActor = scenario.actors.first(where: { $0.id == targetID }) else {
            throw PlayableGameError.targetNotFound(targetID)
        }

        var attacker = makeCharacter(from: attackerActor, state: state.actors[attackerIndex], scenarioID: scenario.id, index: attackerIndex)
        var target = makeCharacter(from: targetActor, state: state.actors[targetIndex], scenarioID: scenario.id, index: targetIndex)
        var buffer = FocEventBuffer()
        var message = [CChar](repeating: 0, count: Int(FOC_ACTION_MESSAGE_LEN))
        let distanceYards = state.actors[attackerIndex].position.distance(to: state.actors[targetIndex].position) * scenario.map.cellYards
        let ok = message.withUnsafeMutableBufferPointer { ptr in
            foc_board_ranged_attack(&attacker, &target, CInt(distanceYards), &buffer, ptr.baseAddress, ptr.count)
        }
        state.actors[attackerIndex].apply(attacker)
        state.actors[targetIndex].apply(target)
        appendEvent(
            &state,
            phase: ok ? phase : "\(phase)-blocked",
            actor: actorName(actorID, in: scenario),
            target: actorName(targetID, in: scenario),
            summary: String(cString: message)
        )
    }

    private static func canAttack(_ actor: PlayableActorState, target: PlayableActorState, state: PlayableGameState, scenario: ZombieScenario) -> Bool {
        guard !scenario.map.protectedCellSet.contains(actor.position),
              !scenario.map.protectedCellSet.contains(target.position) else {
            return false
        }
        guard let actorScenario = scenario.actors.first(where: { $0.id == actor.id }),
              let targetScenario = scenario.actors.first(where: { $0.id == target.id }) else {
            return false
        }
        var attacker = makeCharacter(from: actorScenario, state: actor, scenarioID: scenario.id, index: state.actors.firstIndex(where: { $0.id == actor.id }) ?? 0)
        var defender = makeCharacter(from: targetScenario, state: target, scenarioID: scenario.id, index: state.actors.firstIndex(where: { $0.id == target.id }) ?? 0)
        var preview = FocTargetingPreview()
        foc_make_targeting_preview(&attacker, &defender, CInt(actor.position.distance(to: target.position) * scenario.map.cellYards), &preview)
        return preview.can_attack
    }

    private static func legalAttackTargetsForAnySide(actorID: String, in state: PlayableGameState, scenario: ZombieScenario) -> [PlayableActorState] {
        guard let actor = state.actors.first(where: { $0.id == actorID }), actor.active, !actor.acted else {
            return []
        }
        return state.actors
            .filter { $0.side != actor.side && $0.active }
            .filter { canAttack(actor, target: $0, state: state, scenario: scenario) }
            .sorted { left, right in
                let leftScore = targetScore(left, for: actor, difficulty: state.difficulty)
                let rightScore = targetScore(right, for: actor, difficulty: state.difficulty)
                if leftScore == rightScore {
                    return left.id < right.id
                }
                return leftScore > rightScore
            }
    }

    private static func nextAIMove(for actorID: String, in state: PlayableGameState, scenario: ZombieScenario) -> GridPoint? {
        guard let actor = state.actors.first(where: { $0.id == actorID }) else {
            return nil
        }
        return scoredMove(from: actor.position, actorID: actorID, side: actor.side, in: state, scenario: scenario, difficulty: state.difficulty)
    }

    private static func scoredMove(from start: GridPoint, actorID: String, side: ForceSide, in state: PlayableGameState, scenario: ZombieScenario, difficulty: PlayableAIDifficulty) -> GridPoint? {
        let occupied = Set(state.actors.filter { $0.id != actorID && $0.active }.map(\.position))
        let enemies = state.actors.filter { $0.side != side && $0.active }
        guard !enemies.isEmpty else {
            return nil
        }

        return neighbors(of: start, in: scenario.map)
            .filter { scenario.map.movementCost(at: $0) != nil && !occupied.contains($0) }
            .sorted { left, right in
                let leftScore = moveScore(left, enemies: enemies, scenario: scenario, difficulty: difficulty)
                let rightScore = moveScore(right, enemies: enemies, scenario: scenario, difficulty: difficulty)
                if leftScore == rightScore {
                    return left.id < right.id
                }
                return leftScore > rightScore
            }
            .first
    }

    private static func preferredHumanMove(for actorID: String, in state: PlayableGameState, scenario: ZombieScenario) -> GridPoint? {
        guard let actor = state.actors.first(where: { $0.id == actorID }) else {
            return nil
        }
        let enemies = state.actors.filter { $0.side != actor.side && $0.active }
        return legalMoveDestinations(for: actorID, in: state, scenario: scenario)
            .sorted { left, right in
                let leftScore = moveScore(left, enemies: enemies, scenario: scenario, difficulty: .standard)
                let rightScore = moveScore(right, enemies: enemies, scenario: scenario, difficulty: .standard)
                if leftScore == rightScore {
                    return left.id < right.id
                }
                return leftScore > rightScore
            }
            .first
    }

    private static func updateOutcome(_ state: inout PlayableGameState, scenario: ZombieScenario) {
        guard state.outcome == nil else {
            state.phase = .finished
            return
        }
        let humanActive = state.actors.contains { $0.side == state.humanSide && $0.active }
        let aiActive = state.actors.contains { $0.side == state.aiSide && $0.active }
        if humanActive && aiActive && state.turn <= scenario.objective.turnLimit {
            return
        }

        let outcome: String
        if humanActive && !aiActive {
            outcome = "\(sideName(state.humanSide, in: scenario)) holds the field"
        } else if aiActive && !humanActive {
            outcome = "\(sideName(state.aiSide, in: scenario)) holds the field"
        } else if !humanActive && !aiActive {
            outcome = "Both forces unable to continue"
        } else {
            let humanDistance = state.actors.filter { $0.side == state.humanSide && $0.active }.map { $0.position.distance(to: scenario.objective.point) }.min() ?? Int.max
            let aiDistance = state.actors.filter { $0.side == state.aiSide && $0.active }.map { $0.position.distance(to: scenario.objective.point) }.min() ?? Int.max
            if humanDistance == aiDistance {
                outcome = "Draw at objective distance \(humanDistance)"
            } else if humanDistance < aiDistance {
                outcome = "\(sideName(state.humanSide, in: scenario)) closest to objective"
            } else {
                outcome = "\(sideName(state.aiSide, in: scenario)) closest to objective"
            }
        }

        state.outcome = outcome
        state.phase = .finished
        appendEvent(&state, phase: "outcome", actor: sideName(state.humanSide, in: scenario), target: scenario.title, summary: outcome)
    }

    private static func actorIndex(_ actorID: String, in state: PlayableGameState) throws -> Int {
        guard let index = state.actors.firstIndex(where: { $0.id == actorID }) else {
            throw PlayableGameError.actorNotFound(actorID)
        }
        return index
    }

    private static func actorName(_ actorID: String, in scenario: ZombieScenario) -> String {
        scenario.actors.first { $0.id == actorID }?.name ?? actorID
    }

    private static func sideName(_ side: ForceSide, in scenario: ZombieScenario) -> String {
        scenario.forces.first { $0.side == side }.map { "\($0.name) \($0.unit)" } ?? side.rawValue
    }

    private static func protectedZoneViolations(in state: PlayableGameState, scenario: ZombieScenario) -> Int {
        let protectedCells = scenario.map.protectedCellSet
        let actorByName = Dictionary(uniqueKeysWithValues: scenario.actors.map { ($0.name, $0.id) })
        return state.events.filter { event in
            guard event.phase.contains("attack"),
                  let actorID = actorByName[event.actor],
                  let targetID = actorByName[event.target],
                  let actor = state.actors.first(where: { $0.id == actorID }),
                  let target = state.actors.first(where: { $0.id == targetID }) else {
                return false
            }
            return protectedCells.contains(actor.position) || protectedCells.contains(target.position)
        }.count
    }

    private static func targetScore(_ target: PlayableActorState, for actor: PlayableActorState, difficulty: PlayableAIDifficulty) -> Int {
        let distanceScore = max(0, 20 - actor.position.distance(to: target.position))
        let vulnerability = 12 - target.wounds.total
        switch difficulty {
        case .easy:
            return distanceScore
        case .standard:
            return distanceScore * 2 + vulnerability
        case .hard:
            return distanceScore * 3 + vulnerability * 2 + (target.acted ? 2 : 0)
        }
    }

    private static func moveScore(_ point: GridPoint, enemies: [PlayableActorState], scenario: ZombieScenario, difficulty: PlayableAIDifficulty) -> Int {
        let enemyDistance = enemies.map { point.distance(to: $0.position) }.min() ?? 0
        let objectiveDistance = point.distance(to: scenario.objective.point)
        let coverBonus = scenario.map.coverCells.contains(point) ? 3 : 0
        let movementPenalty = scenario.map.movementCost(at: point) ?? 9

        switch difficulty {
        case .easy:
            return -enemyDistance
        case .standard:
            return -enemyDistance * 2 - objectiveDistance + coverBonus - movementPenalty
        case .hard:
            return -enemyDistance * 3 - objectiveDistance * 2 + coverBonus * 2 - movementPenalty
        }
    }

    private static func displayName(_ rawValue: String) -> String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private static func appendEvent(_ state: inout PlayableGameState, phase: String, actor: String, target: String, summary: String) {
        state.events.append(ScenarioEvent(id: state.events.count + 1, turn: state.turn, phase: phase, actor: actor, target: target, summary: summary))
    }

    private static func neighbors(of point: GridPoint, in map: ScenarioMap) -> [GridPoint] {
        [
            GridPoint(x: point.x + 1, y: point.y),
            GridPoint(x: point.x - 1, y: point.y),
            GridPoint(x: point.x, y: point.y + 1),
            GridPoint(x: point.x, y: point.y - 1)
        ]
        .filter { map.contains($0) }
    }

    private static func makeCharacter(from actor: ScenarioActor, state: PlayableActorState, scenarioID: String, index: Int) -> FocCharacter {
        var character = FieldOfChaosAdapter.makeCharacter(from: actor, seed: stableSeed(for: scenarioID, actorID: actor.id, index: index))
        character.wounds.head = CInt(state.wounds.head)
        character.wounds.body = CInt(state.wounds.body)
        character.wounds.left_arm = CInt(state.wounds.leftArm)
        character.wounds.right_arm = CInt(state.wounds.rightArm)
        character.wounds.left_leg = CInt(state.wounds.leftLeg)
        character.wounds.right_leg = CInt(state.wounds.rightLeg)
        character.loadout.clips = CInt(state.clips)
        character.loadout.rounds_in_clip = CInt(state.roundsInClip)
        character.jammed = state.jammed
        character.unconscious = state.unconscious
        character.dead = state.dead
        foc_refresh_character_state(&character)
        return character
    }

    private static func stableSeed(for scenarioID: String, actorID: String, index: Int) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in "\(scenarioID):\(actorID):\(index)".utf8 {
            hash ^= UInt32(byte)
            hash &*= 16_777_619
        }
        return hash == 0 ? 1 : hash
    }
}

private extension PlayableActorState {
    mutating func apply(_ character: FocCharacter) {
        wounds = PlayableWounds(character: character)
        clips = Int(character.loadout.clips)
        roundsInClip = Int(character.loadout.rounds_in_clip)
        jammed = character.jammed
        unconscious = character.unconscious
        dead = character.dead
    }
}
