import SwiftUI

#if SWIFT_PACKAGE
import ZombieCore
#endif

@main
struct ZombieApp: App {
    @StateObject private var store = ZombieAppStore()

    var body: some Scene {
        WindowGroup("zombie") {
            ZombieRootView()
                .environmentObject(store)
        }
        .commands {
            CommandMenu("Scenario") {
                Button("Run Regression Preview") {
                    store.runSelectedScenario()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Show Early Scenarios") {
                    store.selectedTier = .early
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Show Vehicle Scenarios") {
                    store.selectedTier = .vehicle
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Show Aircraft Scenarios") {
                    store.selectedTier = .aircraft
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Show Mortar Scenarios") {
                    store.selectedTier = .mortar
                }
                .keyboardShortcut("4", modifiers: [.command])
            }
        }
    }
}

final class ZombieAppStore: ObservableObject {
    @Published var catalog = ZombieScenarioCatalog(schemaVersion: 1, scenarios: [])
    @Published var selectedScenarioID: String?
    @Published var selectedTier: ScenarioTier?
    @Published var selectedCollectionID = "all"
    @Published var searchText = ""
    @Published var result: RegressionResult?
    @Published var validationIssues: [ScenarioValidationIssue] = []
    @Published var status = "Loading scenarios..."
    @Published var completionRecords: [ScenarioCompletionRecord] = []

    private let simulator = ZombieSkirmishSimulator()

    init() {
        do {
            catalog = try ScenarioCatalog.bundled()
            validationIssues = ScenarioCatalog.validate(catalog)
            selectedScenarioID = filteredScenarios.first?.id
            status = "\(catalog.scenarios.count) scenarios loaded. Engine \(FieldOfChaosAdapter.engineVersion)."
        } catch {
            status = String(describing: error)
        }
    }

    var filteredScenarios: [ZombieScenario] {
        let searched = ScenarioLibrary.search(searchText, in: catalog)
        let selectedCollection = ScenarioLibrary.collections(for: catalog).first { $0.id == selectedCollectionID }
        let scenarios = searched.filter { scenario in
            if let selectedCollection, selectedCollection.id != "all", !selectedCollection.scenarioIDs.contains(scenario.id) {
                return false
            }
            guard let selectedTier else {
                return true
            }
            return scenario.tier == selectedTier
        }
        return scenarios.sorted { left, right in
            if left.date == right.date {
                return left.title < right.title
            }
            return left.date < right.date
        }
    }

    var selectedScenario: ZombieScenario? {
        if let selectedScenarioID,
           let scenario = catalog.scenarios.first(where: { $0.id == selectedScenarioID }) {
            return scenario
        }
        return filteredScenarios.first
    }

    func runSelectedScenario() {
        guard let selectedScenario else {
            status = "No scenario selected."
            return
        }
        result = simulator.run(selectedScenario)
        upsertCompletion(for: selectedScenario, result: result)
        status = "\(selectedScenario.title): \(result?.outcome ?? "no outcome")."
    }

    var collections: [ScenarioCollection] {
        ScenarioLibrary.collections(for: catalog)
    }

    var selectedCompletion: ScenarioCompletionRecord? {
        guard let id = selectedScenario?.id else {
            return nil
        }
        return completionRecords.first { $0.scenarioID == id }
    }

    private func upsertCompletion(for scenario: ZombieScenario, result: RegressionResult?) {
        guard let result else {
            return
        }
        let record = ScenarioCompletionRecord(
            scenarioID: scenario.id,
            lastOutcome: result.outcome,
            lastSeed: UInt32(result.events.count),
            completedRuns: (completionRecords.first { $0.scenarioID == scenario.id }?.completedRuns ?? 0) + 1,
            updatedAt: Date()
        )
        completionRecords.removeAll { $0.scenarioID == scenario.id }
        completionRecords.append(record)
    }
}

struct ZombieRootView: View {
    @EnvironmentObject private var store: ZombieAppStore

    var body: some View {
        NavigationSplitView {
            List(selection: $store.selectedScenarioID) {
                Section("Search") {
                    TextField("Search", text: $store.searchText)
                    Picker("Collection", selection: $store.selectedCollectionID) {
                        ForEach(store.collections) { collection in
                            Text(collection.title).tag(collection.id)
                        }
                    }
                }
                Section("Filters") {
                    Button("All") { store.selectedTier = nil }
                    ForEach(ScenarioTier.allCases) { tier in
                        Button(tier.rawValue.capitalized) {
                            store.selectedTier = tier
                            store.selectedScenarioID = store.filteredScenarios.first?.id
                        }
                    }
                }
                Section("Scenarios") {
                    ForEach(store.filteredScenarios) { scenario in
                        Label(scenario.title, systemImage: symbol(for: scenario.tier))
                            .tag(Optional(scenario.id))
                    }
                }
            }
            .navigationTitle("zombie")
        } detail: {
            ScenarioDetailView(scenario: store.selectedScenario)
                .frame(minWidth: 820, minHeight: 620)
        }
    }

    private func symbol(for tier: ScenarioTier) -> String {
        switch tier {
        case .early: return "scope"
        case .vehicle: return "car"
        case .checkpoint: return "building.columns"
        case .aircraft: return "airplane"
        case .mortar: return "scope"
        case .deferred: return "clock"
        case .excluded: return "xmark.octagon"
        }
    }
}

struct ScenarioDetailView: View {
    @EnvironmentObject private var store: ZombieAppStore
    let scenario: ZombieScenario?

    var body: some View {
        guard let scenario else {
            return AnyView(Text("No scenario selected.").padding())
        }

        return AnyView(
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scenario.title)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                            Text("\(scenario.date) - \(scenario.place)")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(scenario.tier.rawValue.uppercased())
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial)
                    }

                    Text(store.status)
                        .foregroundStyle(.secondary)

                    Text(scenario.scopeWarning)
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    HStack {
                        Link("Wikipedia", destination: scenario.source.wikipedia)
                        Button {
                            store.runSelectedScenario()
                        } label: {
                            Label("Run Preview", systemImage: "play.fill")
                        }
                        .disabled(!scenario.playable)
                    }

                    Text(scenario.objective.description)
                        .font(.headline)

                    ConfidenceView(confidence: scenario.dataConfidence)

                    ScenarioBoardView(scenario: scenario)
                        .frame(maxWidth: 760)

                    HStack(alignment: .top, spacing: 24) {
                        ForceListView(title: "Forces", forces: scenario.forces)
                        ActorListView(title: "Actors", actors: scenario.actors)
                    }

                    if scenario.hasVisibleMechanics {
                        MechanicsView(mechanics: scenario.mechanics)
                    }

                    if let completion = store.selectedCompletion {
                        Text("Played \(completion.completedRuns)x, latest outcome: \(completion.lastOutcome)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let result = store.result, result.scenarioID == scenario.id {
                        EventLogView(result: result)
                    }

                    Text(scenario.implementationNotes)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
        )
    }
}

struct ScenarioBoardView: View {
    let scenario: ZombieScenario

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(26), spacing: 2), count: scenario.map.width)
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<(scenario.map.width * scenario.map.height), id: \.self) { index in
                let point = GridPoint(x: index % scenario.map.width, y: index / scenario.map.width)
                Rectangle()
                    .fill(color(for: point))
                    .overlay {
                        if actor(at: point) != nil {
                            Circle().fill(actor(at: point)?.side == .player ? Color.blue : Color.red).padding(5)
                        } else if vehicleTouches(point) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.yellow.opacity(0.75)).padding(7)
                        } else if aircraftTouches(point) {
                            Image(systemName: "airplane").font(.caption2).foregroundStyle(.blue)
                        } else if indirectImpact(at: point) != nil {
                            Image(systemName: "scope").font(.caption2).foregroundStyle(.red)
                        } else if explosive(at: point) != nil {
                            Image(systemName: "burst.fill").font(.caption2).foregroundStyle(.orange)
                        }
                    }
                    .frame(width: 26, height: 26)
                    .accessibilityLabel("Cell \(point.x), \(point.y)")
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.08))
    }

    private func actor(at point: GridPoint) -> ScenarioActor? {
        scenario.actors.first { $0.position == point }
    }

    private func explosive(at point: GridPoint) -> ExplosiveHazard? {
        scenario.mechanics.explosives.first { $0.point == point }
    }

    private func vehicleTouches(_ point: GridPoint) -> Bool {
        scenario.mechanics.vehicles.contains { $0.path.contains(point) }
    }

    private func aircraftTouches(_ point: GridPoint) -> Bool {
        scenario.mechanics.aircraft.contains { $0.path.contains(point) }
    }

    private func indirectImpact(at point: GridPoint) -> IndirectFirePlan? {
        scenario.mechanics.indirectFire.first { $0.target == point || $0.scatter.contains(point) }
    }

    private func color(for point: GridPoint) -> Color {
        if scenario.objective.point == point { return .purple.opacity(0.7) }
        if scenario.map.protectedCellSet.contains(point) { return .black.opacity(0.42) }
        let tags = scenario.map.cells.first { $0.point == point }?.tags ?? []
        if tags.contains(.checkpoint) || tags.contains(.base) { return .gray.opacity(0.75) }
        if tags.contains(.building) { return .brown.opacity(0.6) }
        if tags.contains(.road) || tags.contains(.lane) { return .gray.opacity(0.35) }
        if tags.contains(.hedge) || tags.contains(.cover) || tags.contains(.wall) { return .green.opacity(0.45) }
        if tags.contains(.border) { return .orange.opacity(0.45) }
        if tags.contains(.river) { return .cyan.opacity(0.45) }
        if tags.contains(.rail) { return .mint.opacity(0.5) }
        if tags.contains(.helipad) { return .blue.opacity(0.35) }
        return .green.opacity(0.18)
    }
}

struct ConfidenceView: View {
    let confidence: DataConfidence

    var body: some View {
        HStack {
            Label("Roster \(confidence.roster)", systemImage: "person.2")
            Label("Map \(confidence.map)", systemImage: "map")
            Label("Weapons \(confidence.weapons)", systemImage: "scope")
            Label("Timing \(confidence.timing)", systemImage: "clock")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

struct ForceListView: View {
    let title: String
    let forces: [ScenarioForce]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(forces) { force in
                VStack(alignment: .leading) {
                    Text(force.name).fontWeight(.semibold)
                    Text(force.unit).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ActorListView: View {
    let title: String
    let actors: [ScenarioActor]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(actors) { actor in
                HStack {
                    Circle().fill(actor.side == .player ? Color.blue : Color.red).frame(width: 8, height: 8)
                    Text(actor.name)
                    Text(actor.weapon.rawValue).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct MechanicsView: View {
    let mechanics: ScenarioMechanics

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vehicle and Checkpoint Systems").font(.headline)
            ForEach(mechanics.vehicles) { vehicle in
                Text("\(vehicle.label): \(vehicle.path.count) route cells").font(.callout)
            }
            ForEach(mechanics.explosives) { hazard in
                Text("\(hazard.label): \(hazard.abstractEffect)").font(.callout)
            }
            ForEach(mechanics.checkpoints) { checkpoint in
                Text("\(checkpoint.label): alarm turn \(checkpoint.alarmTurn)").font(.callout)
            }
            ForEach(mechanics.aircraft) { aircraft in
                Text("\(aircraft.label): turns \(aircraft.entryTurn)-\(aircraft.exitTurn), \(aircraft.altitudeBand) lane").font(.callout)
            }
            ForEach(mechanics.indirectFire) { fire in
                Text("\(fire.label): warning T\(fire.warningTurn), impact T\(fire.impactTurn)").font(.callout)
            }
            ForEach(mechanics.structures) { structure in
                Text("\(structure.label): health \(structure.health), armor \(structure.armor)").font(.callout)
            }
        }
    }
}

struct EventLogView: View {
    let result: RegressionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Regression Preview").font(.headline)
            Text("\(result.outcome), \(result.turns) turns, \(result.events.count) events")
                .foregroundStyle(.secondary)
            ForEach(result.events.prefix(12)) { event in
                Text("T\(event.turn) \(event.phase): \(event.summary)")
                    .font(.caption)
                    .monospacedDigit()
            }
        }
    }
}

extension ZombieScenario {
    var hasVisibleMechanics: Bool {
        !mechanics.vehicles.isEmpty ||
            !mechanics.explosives.isEmpty ||
            !mechanics.checkpoints.isEmpty ||
            !mechanics.aircraft.isEmpty ||
            !mechanics.indirectFire.isEmpty ||
            !mechanics.structures.isEmpty
    }
}
