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

        if scenario.tier == .aircraft || scenario.tier == .mortar || !scenario.mechanics.aircraft.isEmpty || !scenario.mechanics.indirectFire.isEmpty {
            return runAdvancedScenario(scenario, maxTurns: maxTurns)
        }

        if scenario.tier == .vehicle || scenario.tier == .checkpoint {
            return runVehicleScenario(scenario, maxTurns: maxTurns)
        }

        return runInfantryScenario(scenario, maxTurns: maxTurns)
    }

    public func runCatalog(_ catalog: ZombieScenarioCatalog, includeDeferred: Bool = false) -> [RegressionResult] {
        catalog.scenarios
            .filter { $0.playable || includeDeferred }
            .map { run($0) }
    }

    private func runInfantryScenario(_ scenario: ZombieScenario, maxTurns: Int?) -> RegressionResult {
        let limit = maxTurns ?? scenario.objective.turnLimit
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
                    let occupied = Set(actors.enumerated().compactMap { actorIndex, actor in
                        actorIndex == index || !actor.active ? nil : actor.position
                    })
                    if let next = nextStep(from: actors[index].position, toward: actors[targetIndex].position, in: scenario.map, occupied: occupied) {
                        actors[index].position = next
                        let terrain = scenario.map.tags(at: next).map(\.rawValue).joined(separator: ",")
                        events.append(ScenarioEvent(id: eventID, turn: turn, phase: "move", actor: actorName, target: "", summary: "\(actorName) moves to \(next.id) via \(terrain)."))
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

    private func runAdvancedScenario(_ scenario: ZombieScenario, maxTurns: Int?) -> RegressionResult {
        let limit = maxTurns ?? scenario.objective.turnLimit
        var eventID = 1
        var events: [ScenarioEvent] = []
        var protectedViolations = 0
        var damagedAircraft = Set<String>()
        var resolvedImpacts = Set<String>()
        var structureHealth = Dictionary(uniqueKeysWithValues: scenario.mechanics.structures.map { ($0.id, $0.health) })
        let protectedCells = scenario.map.protectedCellSet
        let antiAirScore = scenario.actors.filter { actor in
            actor.weapon == .heavyMachineGun || actor.weapon == .machineGun || actor.weapon == .rocket || actor.weapon == .mortar
        }.count

        for turn in 1...max(1, limit) {
            for lane in scenario.mechanics.aircraft where turn >= lane.entryTurn && turn <= lane.exitTurn {
                let laneIndex = min(max(turn - lane.entryTurn, 0), max(0, lane.path.count - 1))
                guard let point = lane.path[safe: laneIndex] else {
                    continue
                }
                if protectedCells.contains(point) {
                    protectedViolations += 1
                    events.append(ScenarioEvent(id: eventID, turn: turn, phase: "protected-zone", actor: lane.label, target: "", summary: "\(lane.label) lane intersects protected cell \(point.id)."))
                    eventID += 1
                    continue
                }

                events.append(ScenarioEvent(id: eventID, turn: turn, phase: "aircraft-lane", actor: lane.label, target: "", summary: "\(lane.label) crosses \(point.id) at \(lane.altitudeBand) altitude."))
                eventID += 1

                if antiAirScore >= lane.damageThreshold && !damagedAircraft.contains(lane.id) && turn > lane.entryTurn {
                    damagedAircraft.insert(lane.id)
                    events.append(ScenarioEvent(id: eventID, turn: turn, phase: "aircraft-damage", actor: lane.label, target: scenario.title, summary: "\(lane.label) receives abstract damage and must exit the lane."))
                    eventID += 1
                }
            }

            for fire in scenario.mechanics.indirectFire {
                if turn == fire.setupTurn {
                    events.append(ScenarioEvent(id: eventID, turn: turn, phase: "indirect-setup", actor: fire.label, target: "", summary: "\(fire.label) enters setup phase."))
                    eventID += 1
                }
                if turn == fire.warningTurn {
                    events.append(ScenarioEvent(id: eventID, turn: turn, phase: "indirect-warning", actor: fire.label, target: fire.target.id, summary: "\(fire.label) warning marker appears near \(fire.target.id)."))
                    eventID += 1
                }
                if turn == fire.impactTurn && !resolvedImpacts.contains(fire.id) {
                    resolvedImpacts.insert(fire.id)
                    let impact = deterministicImpact(for: fire, scenarioID: scenario.id)
                    if protectedCells.contains(impact) {
                        protectedViolations += 1
                        events.append(ScenarioEvent(id: eventID, turn: turn, phase: "protected-zone", actor: fire.label, target: impact.id, summary: "\(fire.label) impact was blocked from protected cell \(impact.id)."))
                        eventID += 1
                        continue
                    }
                    events.append(ScenarioEvent(id: eventID, turn: turn, phase: "indirect-impact", actor: fire.label, target: impact.id, summary: "\(fire.label) resolves at \(impact.id): \(fire.abstractEffect)."))
                    eventID += 1

                    for structure in scenario.mechanics.structures where impact.distance(to: structure.point) <= max(0, fire.radius) {
                        let previous = structureHealth[structure.id] ?? structure.health
                        let damage = max(1, 3 - min(2, structure.armor))
                        structureHealth[structure.id] = max(0, previous - damage)
                        events.append(ScenarioEvent(id: eventID, turn: turn, phase: "structure-damage", actor: fire.label, target: structure.label, summary: "\(structure.label) health \(previous) -> \(structureHealth[structure.id] ?? 0)."))
                        eventID += 1
                    }
                }
            }
        }

        for lane in scenario.mechanics.aircraft where !damagedAircraft.contains(lane.id) {
            events.append(ScenarioEvent(id: eventID, turn: min(limit, lane.exitTurn), phase: "aircraft-exit", actor: lane.label, target: "", summary: "\(lane.label) exits the scenario lane."))
            eventID += 1
        }

        if events.isEmpty {
            events.append(ScenarioEvent(id: eventID, turn: 0, phase: "advanced", actor: scenario.title, target: "", summary: "No advanced events were generated."))
        }

        let damagedStructures = structureHealth.values.contains { $0 == 0 }
        let outcome: String
        if !damagedAircraft.isEmpty {
            outcome = "aircraft damaged"
        } else if damagedStructures {
            outcome = "structure disabled"
        } else if !resolvedImpacts.isEmpty {
            outcome = "indirect fire resolved"
        } else {
            outcome = "advanced route completed"
        }
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

    private func nextStep(from start: GridPoint, toward target: GridPoint, in map: ScenarioMap, occupied: Set<GridPoint>) -> GridPoint? {
        let destinations = Set(neighbors(of: target, in: map, toward: start).filter { point in
            map.movementCost(at: point) != nil && !occupied.contains(point)
        })
        guard !destinations.isEmpty, !destinations.contains(start) else {
            return nil
        }

        var frontier = [start]
        var cameFrom: [GridPoint: GridPoint] = [:]
        var costSoFar: [GridPoint: Int] = [start: 0]

        while !frontier.isEmpty {
            let currentIndex = frontier.indices.min { left, right in
                let leftPoint = frontier[left]
                let rightPoint = frontier[right]
                let leftCost = costSoFar[leftPoint, default: Int.max]
                let rightCost = costSoFar[rightPoint, default: Int.max]
                if leftCost == rightCost {
                    return leftPoint.distance(to: target) < rightPoint.distance(to: target)
                }
                return leftCost < rightCost
            } ?? frontier.startIndex
            let current = frontier.remove(at: currentIndex)

            if destinations.contains(current) {
                return firstStep(from: start, to: current, cameFrom: cameFrom)
            }

            for neighbor in neighbors(of: current, in: map, toward: target) {
                guard !occupied.contains(neighbor), let movementCost = map.movementCost(at: neighbor) else {
                    continue
                }
                let newCost = costSoFar[current, default: 0] + movementCost
                if newCost < costSoFar[neighbor, default: Int.max] {
                    costSoFar[neighbor] = newCost
                    cameFrom[neighbor] = current
                    if !frontier.contains(neighbor) {
                        frontier.append(neighbor)
                    }
                }
            }
        }

        return nil
    }

    private func firstStep(from start: GridPoint, to destination: GridPoint, cameFrom: [GridPoint: GridPoint]) -> GridPoint? {
        var current = destination
        var previous = cameFrom[current]
        while let previousPoint = previous, previousPoint != start {
            current = previousPoint
            previous = cameFrom[current]
        }
        return current == start ? nil : current
    }

    private func neighbors(of point: GridPoint, in map: ScenarioMap, toward target: GridPoint) -> [GridPoint] {
        [
            GridPoint(x: point.x + 1, y: point.y),
            GridPoint(x: point.x - 1, y: point.y),
            GridPoint(x: point.x, y: point.y + 1),
            GridPoint(x: point.x, y: point.y - 1)
        ]
        .filter { map.contains($0) }
        .sorted { left, right in
            let leftDistance = left.distance(to: target)
            let rightDistance = right.distance(to: target)
            if leftDistance == rightDistance {
                return left.id < right.id
            }
            return leftDistance < rightDistance
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

    private func deterministicImpact(for fire: IndirectFirePlan, scenarioID: String) -> GridPoint {
        guard !fire.scatter.isEmpty else {
            return fire.target
        }
        let seed = stableSeed(for: scenarioID, actorID: fire.id, index: fire.impactTurn)
        return fire.scatter[Int(seed % UInt32(fire.scatter.count))]
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
