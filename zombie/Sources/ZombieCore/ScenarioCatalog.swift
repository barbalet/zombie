import Foundation

#if SWIFT_PACKAGE
import FieldOfChaosEngine
#endif

public enum ScenarioCatalogError: Error, CustomStringConvertible {
    case missingBundledCatalog
    case decodeFailed(String)
    case mapLoadFailed(String)

    public var description: String {
        switch self {
        case .missingBundledCatalog:
            return "Bundled zombie scenario catalog was not found."
        case .decodeFailed(let message):
            return "Scenario catalog decode failed: \(message)"
        case .mapLoadFailed(let message):
            return "Scenario map load failed: \(message)"
        }
    }
}

public enum ScenarioCatalog {
    public static func bundled() throws -> ZombieScenarioCatalog {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif

        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw ScenarioCatalogError.missingBundledCatalog
        }
        return try load(from: url)
    }

    public static func load(from url: URL) throws -> ZombieScenarioCatalog {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let catalog = try decoder.decode(ZombieScenarioCatalog.self, from: data)
            return try applyExternalMaps(to: catalog, relativeTo: url.deletingLastPathComponent())
        } catch let error as ScenarioCatalogError {
            throw error
        } catch {
            throw ScenarioCatalogError.decodeFailed(error.localizedDescription)
        }
    }

    public static func validate(_ catalog: ZombieScenarioCatalog) -> [ScenarioValidationIssue] {
        var issues: [ScenarioValidationIssue] = []
        if catalog.schemaVersion != 1 {
            issues.append(ScenarioValidationIssue(scenarioID: "catalog", severity: .error, message: "catalog schemaVersion must be 1"))
        }

        let ids = catalog.scenarios.map(\.id)
        let duplicateIDs = Set(ids.filter { id in ids.filter { $0 == id }.count > 1 })
        for id in duplicateIDs.sorted() {
            issues.append(ScenarioValidationIssue(scenarioID: id, severity: .error, message: "scenario id is duplicated"))
        }

        for scenario in catalog.scenarios {
            issues.append(contentsOf: validate(scenario))
        }
        return issues
    }

    public static func validate(_ scenario: ZombieScenario) -> [ScenarioValidationIssue] {
        var issues: [ScenarioValidationIssue] = []

        func issue(_ severity: ScenarioValidationIssue.Severity, _ message: String) {
            issues.append(ScenarioValidationIssue(scenarioID: scenario.id, severity: severity, message: message))
        }

        if scenario.schemaVersion != 1 {
            issue(.error, "scenario schemaVersion must be 1")
        }
        if scenario.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issue(.error, "title is required")
        }
        if scenario.source.wikipedia.scheme?.hasPrefix("http") != true {
            issue(.error, "source wikipedia URL must be HTTP(S)")
        }
        if scenario.source.confidence.isEmpty {
            issue(.error, "source confidence is required")
        }
        if scenario.map.width < 4 || scenario.map.height < 4 {
            issue(.error, "map must be at least 4x4")
        }
        if scenario.map.cellYards < 1 {
            issue(.error, "cellYards must be positive")
        }
        if scenario.mapFile?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            issue(.error, "scenario requires an external map file")
        }
        if scenario.map.movement.defaultCost < 1 || scenario.map.movement.roadCost < 1 || scenario.map.movement.coverCost < 1 {
            issue(.error, "map movement costs must be positive")
        }
        if scenario.map.movement.blockedTags.isEmpty {
            issue(.error, "map movement profile must define blocked tags")
        }
        if !contains(scenario.objective.point, in: scenario.map) {
            issue(.error, "objective point is outside the map")
        }
        if scenario.forces.count < 2 {
            issue(.error, "at least two forces are required")
        }
        let forceSides = Set(scenario.forces.map(\.side))
        if !forceSides.contains(.player) || !forceSides.contains(.opponent) {
            issue(.error, "forces must include player and opponent sides")
        }
        let actorSides = Set(scenario.actors.map(\.side))
        if scenario.playable && (!actorSides.contains(.player) || !actorSides.contains(.opponent)) {
            issue(.error, "playable scenarios need actors on both sides")
        }
        for actor in scenario.actors {
            if !contains(actor.position, in: scenario.map) {
                issue(.error, "actor \(actor.id) starts outside the map")
            }
            if scenario.map.protectedCellSet.contains(actor.position) {
                issue(.error, "actor \(actor.id) starts in a protected cell")
            }
            if actor.stats.values.contains(where: { $0 < 0 || $0 > 10 }) {
                issue(.error, "actor \(actor.id) has stat outside 0...10")
            }
        }
        if scenario.tier == .vehicle || scenario.tier == .checkpoint {
            if scenario.mechanics.vehicles.isEmpty && scenario.mechanics.checkpoints.isEmpty {
                issue(.error, "vehicle/checkpoint scenarios require vehicle routes or checkpoint structures")
            }
        }
        if scenario.tier == .aircraft && scenario.mechanics.aircraft.isEmpty {
            issue(.error, "aircraft scenarios require at least one aircraft lane")
        }
        if scenario.tier == .mortar && scenario.mechanics.indirectFire.isEmpty {
            issue(.error, "mortar scenarios require at least one indirect-fire plan")
        }
        for vehicle in scenario.mechanics.vehicles {
            if vehicle.path.isEmpty {
                issue(.error, "vehicle \(vehicle.id) requires a route")
            }
            for point in vehicle.path where !contains(point, in: scenario.map) {
                issue(.error, "vehicle \(vehicle.id) route leaves the map")
            }
        }
        for hazard in scenario.mechanics.explosives where !contains(hazard.point, in: scenario.map) {
            issue(.error, "explosive \(hazard.id) is outside the map")
        }
        for checkpoint in scenario.mechanics.checkpoints where !contains(checkpoint.point, in: scenario.map) {
            issue(.error, "checkpoint \(checkpoint.id) is outside the map")
        }
        for aircraft in scenario.mechanics.aircraft {
            if aircraft.path.isEmpty {
                issue(.error, "aircraft \(aircraft.id) requires a lane")
            }
            if aircraft.entryTurn < 1 || aircraft.exitTurn < aircraft.entryTurn {
                issue(.error, "aircraft \(aircraft.id) has invalid entry/exit turns")
            }
            for point in aircraft.path where !contains(point, in: scenario.map) {
                issue(.error, "aircraft \(aircraft.id) lane leaves the map")
            }
        }
        for fire in scenario.mechanics.indirectFire {
            if fire.setupTurn < 1 || fire.warningTurn < fire.setupTurn || fire.impactTurn < fire.warningTurn {
                issue(.error, "indirect fire \(fire.id) has invalid timing")
            }
            if !contains(fire.target, in: scenario.map) {
                issue(.error, "indirect fire \(fire.id) target is outside the map")
            }
            for point in fire.scatter where !contains(point, in: scenario.map) {
                issue(.error, "indirect fire \(fire.id) scatter leaves the map")
            }
        }
        for structure in scenario.mechanics.structures {
            if !contains(structure.point, in: scenario.map) {
                issue(.error, "structure \(structure.id) is outside the map")
            }
            if structure.health < 1 {
                issue(.error, "structure \(structure.id) must have positive health")
            }
        }
        let confidenceValues = [scenario.dataConfidence.roster, scenario.dataConfidence.map, scenario.dataConfidence.weapons, scenario.dataConfidence.timing]
        if confidenceValues.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            issue(.error, "data confidence fields are required")
        }
        if (scenario.tier == .aircraft || scenario.tier == .mortar || scenario.tier == .deferred || scenario.sensitivityTags.contains("civilian-risk")) &&
            scenario.scopeWarning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issue(.error, "advanced, deferred, and civilian-risk scenarios require a scope warning")
        }
        if scenario.sensitivityTags.contains("civilian-risk") && !scenario.sensitivityTags.contains("protected-zone") {
            issue(.error, "civilian-risk scenarios must declare protected-zone handling")
        }
        if scenario.sensitivityTags.contains("contested") && scenario.implementationNotes.isEmpty {
            issue(.error, "contested scenarios require implementation notes")
        }
        if !scenario.playable && scenario.tier != .deferred && scenario.tier != .excluded && !scenario.sensitivityTags.contains("deferred") {
            issue(.warning, "non-playable scenario is not marked deferred or excluded")
        }

        return issues
    }

    private static func contains(_ point: GridPoint, in map: ScenarioMap) -> Bool {
        map.contains(point)
    }

    private static func applyExternalMaps(to catalog: ZombieScenarioCatalog, relativeTo baseURL: URL) throws -> ZombieScenarioCatalog {
        let decoder = JSONDecoder()
        var scenarios = catalog.scenarios
        for index in scenarios.indices {
            let defaultMapFile = "Maps/\(scenarios[index].id).map.json"
            let explicitMapFile = scenarios[index].mapFile?.trimmingCharacters(in: .whitespacesAndNewlines)
            let mapFile = explicitMapFile?.isEmpty == false ? explicitMapFile! : defaultMapFile
            let mapURL = resourceURL(for: mapFile, relativeTo: baseURL)
            do {
                let data = try Data(contentsOf: mapURL)
                let decodedMap = try decoder.decode(ScenarioMapFile.self, from: data)
                scenarios[index].map = try decodedMap.materializedMap(expectedScenarioID: scenarios[index].id)
                scenarios[index].mapFile = mapFile
            } catch {
                throw ScenarioCatalogError.mapLoadFailed("\(scenarios[index].id): \(error)")
            }
        }
        return ZombieScenarioCatalog(schemaVersion: catalog.schemaVersion, scenarios: scenarios)
    }

    private static func resourceURL(for mapFile: String, relativeTo baseURL: URL) -> URL {
        let nestedURL = baseURL.appendingPathComponent(mapFile)
        if FileManager.default.fileExists(atPath: nestedURL.path) {
            return nestedURL
        }
        return baseURL.appendingPathComponent(URL(fileURLWithPath: mapFile).lastPathComponent)
    }
}

public enum FieldOfChaosAdapter {
    public static var engineVersion: String {
        String(cString: foc_engine_version())
    }

    public static func makeCharacter(from actor: ScenarioActor, seed: UInt32) -> FocCharacter {
        var character = FocCharacter()
        foc_seed(seed)
        actor.name.withCString { foc_init_default_character(&character, $0) }
        character.stats.re = CInt(actor.stats["RE"] ?? actor.stats["re"] ?? 5)
        character.stats.ir = CInt(actor.stats["IR"] ?? actor.stats["ir"] ?? 5)
        character.stats.ap = CInt(actor.stats["AP"] ?? actor.stats["ap"] ?? 5)
        character.stats.ph = CInt(actor.stats["PH"] ?? actor.stats["ph"] ?? 5)
        character.stats.me = CInt(actor.stats["ME"] ?? actor.stats["me"] ?? 5)
        character.loadout.weapon = focWeapon(for: actor.weapon)
        character.loadout.clips = CInt(actor.weapon == .none ? 0 : 4)
        character.loadout.rounds_in_clip = CInt(actor.weapon == .none ? 0 : FOC_DEFAULT_CLIP_SIZE)
        character.skills.firearm_basic = actor.weapon != .none
        character.skills.firearm_advanced = actor.skills.contains("firearm_advanced") || actor.weapon == .machineGun || actor.weapon == .heavyMachineGun
        character.skills.firearm_sniper = actor.weapon == .sniperRifle
        character.skills.evade = actor.skills.contains("evade") || actor.role == .scout
        character.skills.running = actor.skills.contains("running")
        character.skills.marching = actor.skills.contains("marching")
        character.skills.close_combat = actor.skills.contains("close_combat")
        character.loadout.in_cover = actor.skills.contains("in_cover")
        foc_refresh_character_state(&character)
        return character
    }

    public static func focWeapon(for weapon: WeaponKind) -> FocWeaponType {
        switch weapon {
        case .sniperRifle:
            return FOC_WEAPON_SNIPER_RIFLE
        case .submachineGun:
            return FOC_WEAPON_SUBMG
        case .shotgun:
            return FOC_WEAPON_SHOTGUN
        case .none:
            return FOC_WEAPON_NONE
        case .rifle, .machineGun, .heavyMachineGun, .grenade, .explosive, .mortar, .rocket, .flamethrower:
            return FOC_WEAPON_RIFLE
        }
    }
}
