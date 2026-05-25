import Foundation

#if SWIFT_PACKAGE
import FieldOfChaosEngine
#endif

struct SimActor {
    var scenarioActor: ScenarioActor
    var character: FocCharacter
    var position: GridPoint
    var active: Bool {
        !character.dead && !character.unconscious
    }
}

public final class ZombieSkirmishSimulator {
    public init() { }

    public func run(_ scenario: ZombieScenario, maxTurns: Int? = nil) -> RegressionResult {
        let validation = ScenarioCatalog.validate(scenario)
        let validationErrors = validation.filter { $0.severity == .error }.count
        if validationErrors > 0 {
            return RegressionResult(
                scenarioID: scenario.id,
                tier: scenario.tier,
                outcome: "invalid",
                turns: 0,
                events: validation.enumerated().map { index, issue in
                    ScenarioEvent(id: index + 1, turn: 0, phase: "validation", actor: "", target: "", summary: issue.description)
                },
                validationErrors: validationErrors,
                protectedZoneViolations: 0
            )
        }

        if scenario.tier == .vehicle || scenario.tier == .checkpoint {
            return runVehicleScenario(scenario, maxTurns: maxTurns)
        }

        return runInfantryScenario(scenario, maxTurns: maxTurns)
    }

    public func runCatalog(_ catalog: ZombieScenarioCatalog, includeDeferred: Bool = false) -> [RegressionResult] {
        catalog.scenarios
            .filter { $0.playable || includeDeferred }
            .filter { includeDeferred || ($0.tier != .deferred && $0.tier != .excluded && $0.tier != .aircraft) }
            .map { run($0) }
    }

    private func runInfantryScenario(_ scenario: ZombieScenario, maxTurns: Int?) -> RegressionResult {
        let limit = maxTurns ?? scenario.objective.turnLimit
        let protectedCells = scenario.map.protectedCellSet
        let blocked = scenario.map.blockedCells.subtracting(protectedCells)
        let violations = 0
        var events: [ScenarioEvent] = []
        var actors = scenario.actors.enumerated().map { index, actor in
            SimActor(
                scenarioActor: actor,
                character: FieldOfChaosAdapter.makeCharacter(from: actor, seed: stableSeed(for: scenario.id, actorID: actor.id, index: index)),
                position: actor.position
            )
        }

        if actors.isEmpty {
            return RegressionResult(scenarioID: scenario.id, tier: scenario.tier, outcome: "no actors", turns: 0, events: [], validationErrors: 1, protectedZoneViolations: 0)
        }

        var eventID = 1
        for turn in 1...max(1, limit) {
            for index in actors.indices {
                guard actors[index].active else {
                    continue
                }
                guard let targetIndex = nearestOpponentIndex(for: index, actors: actors) else {
                    continue
                }

                let actorName = actors[index].scenarioActor.name
                let targetName = actors[targetIndex].scenarioActor.name
                let distanceCells = actors[index].position.distance(to: actors[targetIndex].position)
                let distanceYards = distanceCells * scenario.map.cellYards

                if distanceYards <= 12 || canAttack(attacker: actors[index], target: actors[targetIndex], distanceYards: distanceYards) {
                    var attacker = actors[index].character
                    var target = actors[targetIndex].character
                    var buffer = FocEventBuffer()
                    var message = [CChar](repeating: 0, count: Int(FOC_ACTION_MESSAGE_LEN))
                    let ok = message.withUnsafeMutableBufferPointer { ptr in
                        foc_board_ranged_attack(&attacker, &target, CInt(distanceYards), &buffer, ptr.baseAddress, ptr.count)
                    }
                    actors[index].character = attacker
                    actors[targetIndex].character = target
                    events.append(ScenarioEvent(
                        id: eventID,
                        turn: turn,
                        phase: ok ? "attack" : "attack-blocked",
                        actor: actorName,
                        target: targetName,
                        summary: String(cString: message)
                    ))
                    eventID += 1
                } else {
                    let next = actors[index].position.step(toward: actors[targetIndex].position)
                    if protectedCells.contains(next) {
                        events.append(ScenarioEvent(id: eventID, turn: turn, phase: "protected-zone", actor: actorName, target: "", summary: "\(actorName) blocked from protected cell \(next.id)."))
                        eventID += 1
                    } else if !blocked.contains(next) && !actors.contains(where: { $0.position == next && $0.active }) {
                        actors[index].position = next
                        events.append(ScenarioEvent(id: eventID, turn: turn, phase: "move", actor: actorName, target: "", summary: "\(actorName) moves to \(next.id)."))
                        eventID += 1
                    } else {
                        events.append(ScenarioEvent(id: eventID, turn: turn, phase: "wait", actor: actorName, target: "", summary: "\(actorName) waits."))
                        eventID += 1
                    }
                }

                if let outcome = outcome(for: actors) {
                    return RegressionResult(
                        scenarioID: scenario.id,
                        tier: scenario.tier,
                        outcome: outcome,
                        turns: turn,
                        events: events,
                        validationErrors: 0,
                        protectedZoneViolations: violations
                    )
                }
            }
        }

        let playerDistance = actors.filter { $0.scenarioActor.side == .player && $0.active }.map { $0.position.distance(to: scenario.objective.point) }.min() ?? Int.max
        let opponentDistance = actors.filter { $0.scenarioActor.side == .opponent && $0.active }.map { $0.position.distance(to: scenario.objective.point) }.min() ?? Int.max
        let outcome = playerDistance <= opponentDistance ? "player objective" : "opponent objective"
        return RegressionResult(scenarioID: scenario.id, tier: scenario.tier, outcome: outcome, turns: limit, events: events, validationErrors: 0, protectedZoneViolations: violations)
    }

    private func runVehicleScenario(_ scenario: ZombieScenario, maxTurns: Int?) -> RegressionResult {
        let limit = maxTurns ?? scenario.objective.turnLimit
        var eventID = 1
        var events: [ScenarioEvent] = []
        var triggered = Set<String>()
        var damagedVehicles = Set<String>()
        var protectedViolations = 0
        let protectedCells = scenario.map.protectedCellSet

        for turn in 1...max(1, limit) {
            for vehicle in scenario.mechanics.vehicles {
                guard let point = vehicle.path[safe: min(turn - 1, vehicle.path.count - 1)] else {
                    continue
                }
                if protectedCells.contains(point) {
                    protectedViolations += 1
                    events.append(ScenarioEvent(id: eventID, turn: turn, phase: "protected-zone", actor: vehicle.label, target: "", summary: "\(vehicle.label) route avoids protected cell \(point.id)."))
                    eventID += 1
                    continue
                }
                events.append(ScenarioEvent(id: eventID, turn: turn, phase: "vehicle-route", actor: vehicle.label, target: "", summary: "\(vehicle.label) reaches \(point.id)."))
                eventID += 1

                for hazard in scenario.mechanics.explosives where !triggered.contains(hazard.id) {
                    if point.distance(to: hazard.point) <= max(0, hazard.radius) {
                        triggered.insert(hazard.id)
                        damagedVehicles.insert(vehicle.id)
                        events.append(ScenarioEvent(id: eventID, turn: turn, phase: "abstract-blast", actor: hazard.label, target: vehicle.label, summary: "\(hazard.label) triggers against \(vehicle.label): \(hazard.abstractEffect)."))
                        eventID += 1
                    }
                }
            }

            for checkpoint in scenario.mechanics.checkpoints where checkpoint.alarmTurn == turn {
                events.append(ScenarioEvent(id: eventID, turn: turn, phase: "alarm", actor: checkpoint.label, target: "", summary: "\(checkpoint.label) enters alarm phase."))
                eventID += 1
            }
        }

        if events.isEmpty {
            events.append(ScenarioEvent(id: eventID, turn: 0, phase: "scenario", actor: scenario.title, target: "", summary: "No vehicle events were generated."))
        }

        let outcome = damagedVehicles.isEmpty ? "route completed" : "route interdicted"
        return RegressionResult(scenarioID: scenario.id, tier: scenario.tier, outcome: outcome, turns: limit, events: events, validationErrors: 0, protectedZoneViolations: protectedViolations)
    }

    private func canAttack(attacker: SimActor, target: SimActor, distanceYards: Int) -> Bool {
        var attackerCharacter = attacker.character
        var targetCharacter = target.character
        var preview = FocTargetingPreview()
        foc_make_targeting_preview(&attackerCharacter, &targetCharacter, CInt(distanceYards), &preview)
        return preview.can_attack
    }

    private func nearestOpponentIndex(for index: Int, actors: [SimActor]) -> Int? {
        let actor = actors[index]
        return actors.indices
            .filter { $0 != index && actors[$0].active && actors[$0].scenarioActor.side != actor.scenarioActor.side }
            .min { left, right in
                actor.position.distance(to: actors[left].position) < actor.position.distance(to: actors[right].position)
            }
    }

    private func outcome(for actors: [SimActor]) -> String? {
        let playerActive = actors.contains { $0.scenarioActor.side == .player && $0.active }
        let opponentActive = actors.contains { $0.scenarioActor.side == .opponent && $0.active }
        if playerActive && opponentActive {
            return nil
        }
        if playerActive {
            return "player force active"
        }
        if opponentActive {
            return "opponent force active"
        }
        return "both forces down"
    }

    private func stableSeed(for scenarioID: String, actorID: String, index: Int) -> UInt32 {
        var hash: UInt32 = 2_166_136_261
        for byte in "\(scenarioID):\(actorID):\(index)".utf8 {
            hash ^= UInt32(byte)
            hash &*= 16_777_619
        }
        return hash == 0 ? 1 : hash
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
