import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

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

            CommandMenu("Play") {
                Button("Next Actor") {
                    store.selectNextHumanActor()
                }
                .keyboardShortcut("n", modifiers: [])

                Button("Cancel Selection") {
                    store.cancelPlaySelection()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("Wait") {
                    store.waitSelectedActorInActiveGame()
                }
                .keyboardShortcut("w", modifiers: [])

                Button("End Turn") {
                    store.endTurnInActiveGame()
                }
                .keyboardShortcut("e", modifiers: [])
            }
        }
    }
}

enum PlayActionMode: String, CaseIterable, Identifiable {
    case move
    case attack

    var id: String { rawValue }
}

enum PlayLogFilter: String, CaseIterable, Identifiable {
    case all
    case movement
    case attacks
    case ai
    case outcome

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    func includes(_ event: ScenarioEvent) -> Bool {
        switch self {
        case .all:
            return true
        case .movement:
            return event.phase.contains("move")
        case .attacks:
            return event.phase.contains("attack")
        case .ai:
            return event.phase.hasPrefix("ai-")
        case .outcome:
            return event.phase == "outcome"
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
    @Published var activeGame: PlayableGameState?
    @Published var savedGame: PlayableGameState?
    @Published var selectedHumanSide: ForceSide = .player
    @Published var selectedAIDifficulty: PlayableAIDifficulty = .standard
    @Published var selectedPlayAction: PlayActionMode = .move
    @Published var selectedPlayLogFilter: PlayLogFilter = .all
    @Published var playError: String?
    @Published var validationIssues: [ScenarioValidationIssue] = []
    @Published var status = "Loading scenarios..."
    @Published var completionRecords: [ScenarioCompletionRecord] = []
    @Published var playableCompletionRecords: [PlayableCompletionRecord] = []
    @Published var earlyReplayResults: [PlayableReplayResult] = []

    private let simulator = ZombieSkirmishSimulator()
    private let activeGameSaveKey = "zombie.activeGameSave.v1"
    private let playableCompletionRecordsKey = "zombie.playableCompletionRecords.v1"

    init() {
        do {
            catalog = try ScenarioCatalog.bundled()
            validationIssues = ScenarioCatalog.validate(catalog)
            savedGame = loadSavedGame()
            playableCompletionRecords = loadPlayableCompletionRecords()
            earlyReplayResults = PlayableGameEngine.runEarlyCorpusReplay(catalog)
            selectedScenarioID = filteredScenarios.first?.id
            if let savedGame {
                selectedScenarioID = savedGame.scenarioID
                selectedHumanSide = savedGame.humanSide
                selectedAIDifficulty = savedGame.difficulty
                status = "\(catalog.scenarios.count) scenarios loaded. Saved Play Mode run available."
            } else {
                status = "\(catalog.scenarios.count) scenarios loaded. Engine \(FieldOfChaosAdapter.engineVersion)."
            }
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

    func startSelectedGame() {
        guard let selectedScenario else {
            status = "No scenario selected."
            return
        }
        do {
            activeGame = try PlayableGameEngine.start(selectedScenario, humanSide: selectedHumanSide, difficulty: selectedAIDifficulty)
            result = nil
            selectedPlayAction = .move
            playError = nil
            persistActiveGame()
            status = "\(selectedScenario.title): Play Mode started."
        } catch {
            playError = String(describing: error)
            status = "\(selectedScenario.title): \(playError ?? "Play Mode unavailable")."
        }
    }

    func selectActor(_ actorID: String?) {
        activeGame?.selectedActorID = actorID
        activeGame?.moveTarget = nil
        activeGame?.attackTargetID = nil
        playError = nil
    }

    func cancelPlaySelection() {
        activeGame?.selectedActorID = nil
        activeGame?.moveTarget = nil
        activeGame?.attackTargetID = nil
        playError = nil
    }

    func selectNextHumanActor() {
        guard let activeGame else {
            playError = "Start or resume Play Mode before selecting an actor."
            return
        }
        let actors = activeGame.actors
            .filter { $0.side == activeGame.humanSide && $0.active && !$0.acted }
            .sorted { $0.id < $1.id }
        guard !actors.isEmpty else {
            playError = "No active human actors remain this turn."
            return
        }
        let currentIndex = actors.firstIndex { $0.id == activeGame.selectedActorID } ?? -1
        let next = actors[(currentIndex + 1) % actors.count]
        selectActor(next.id)
    }

    func selectPlayAction(_ action: PlayActionMode, in scenario: ZombieScenario) {
        selectedPlayAction = action
        guard let activeGame, activeGame.phase == .humanActivation else {
            playError = "Play Mode is not waiting for a human action."
            return
        }
        guard let actorID = activeGame.selectedActorID else {
            playError = "Select an actor before choosing an action."
            return
        }
        switch action {
        case .move:
            playError = legalMoves(for: scenario).isEmpty ? "No legal moves for \(actorName(actorID, in: scenario))." : nil
        case .attack:
            playError = legalTargets(for: scenario).isEmpty ? "No legal targets for \(actorName(actorID, in: scenario))." : nil
        }
    }

    func runEarlyReplayCorpus() {
        earlyReplayResults = PlayableGameEngine.runEarlyCorpusReplay(catalog, difficulty: selectedAIDifficulty)
        let failures = earlyReplayResults.filter { !$0.passed }
        status = failures.isEmpty ? "Early replay corpus passed from both sides." : "Early replay corpus has \(failures.count) issue(s)."
    }

    func legalMoves(for scenario: ZombieScenario) -> [GridPoint] {
        guard let activeGame, activeGame.scenarioID == scenario.id, let actorID = activeGame.selectedActorID else {
            return []
        }
        return PlayableGameEngine.legalMoveDestinations(for: actorID, in: activeGame, scenario: scenario)
    }

    func legalTargets(for scenario: ZombieScenario) -> [PlayableActorState] {
        guard let activeGame, activeGame.scenarioID == scenario.id, let actorID = activeGame.selectedActorID else {
            return []
        }
        return PlayableGameEngine.legalAttackTargets(for: actorID, in: activeGame, scenario: scenario)
    }

    func moveSelectedActor(to destination: GridPoint, in scenario: ZombieScenario) {
        guard let actorID = activeGame?.selectedActorID else {
            return
        }
        apply(.move(actorID: actorID, destination: destination), in: scenario)
    }

    func attackSelectedTarget(_ targetID: String, in scenario: ZombieScenario) {
        guard let actorID = activeGame?.selectedActorID else {
            return
        }
        apply(.attack(actorID: actorID, targetID: targetID), in: scenario)
    }

    func waitSelectedActor(in scenario: ZombieScenario) {
        guard let actorID = activeGame?.selectedActorID else {
            playError = "Select an actor before waiting."
            return
        }
        apply(.wait(actorID: actorID), in: scenario)
    }

    func waitSelectedActorInActiveGame() {
        guard let scenario = activeScenario else {
            playError = "Start or resume Play Mode before waiting."
            return
        }
        waitSelectedActor(in: scenario)
    }

    func endTurn(in scenario: ZombieScenario) {
        apply(.endTurn, in: scenario)
    }

    func endTurnInActiveGame() {
        guard let scenario = activeScenario else {
            playError = "Start or resume Play Mode before ending the turn."
            return
        }
        endTurn(in: scenario)
    }

    func completeTutorialRun(in scenario: ZombieScenario) {
        guard scenario.sensitivityTags.contains("fictional-training") else {
            playError = "Tutorial completion is only available for training scenarios."
            return
        }
        do {
            let finished = try PlayableGameEngine.runSmokePlaythrough(scenario, humanSide: selectedHumanSide, difficulty: selectedAIDifficulty)
            activeGame = finished
            playError = nil
            upsertPlayableCompletion(for: scenario, game: finished)
            clearSavedGame()
            status = "\(scenario.title): tutorial complete."
        } catch {
            playError = String(describing: error)
            status = "\(scenario.title): \(playError ?? "Tutorial blocked")."
        }
    }

    func resumeSavedGame() {
        guard let savedGame else {
            status = "No saved Play Mode run."
            return
        }
        activeGame = savedGame
        selectedScenarioID = savedGame.scenarioID
        selectedHumanSide = savedGame.humanSide
        selectedAIDifficulty = savedGame.difficulty
        selectedPlayAction = .move
        playError = nil
        status = "\(activeScenario?.title ?? savedGame.scenarioID): Play Mode resumed."
    }

    func filteredEvents(for game: PlayableGameState) -> [ScenarioEvent] {
        game.events.filter { selectedPlayLogFilter.includes($0) }
    }

    func copySeed(_ seed: UInt32) {
        let seedText = String(seed)
        #if canImport(UIKit)
        UIPasteboard.general.string = seedText
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(seedText, forType: .string)
        #endif
        status = "Replay seed copied: \(seedText)."
    }

    func abandonActiveGame() {
        guard let activeGame else {
            status = "No active Play Mode run."
            return
        }
        let scenarioTitle = catalog.scenarios.first { $0.id == activeGame.scenarioID }?.title ?? activeGame.scenarioID
        self.activeGame = nil
        selectedPlayAction = .move
        playError = nil
        clearSavedGame()
        status = "\(scenarioTitle): Play Mode abandoned."
    }

    private func apply(_ command: PlayableCommand, in scenario: ZombieScenario) {
        guard let activeGame else {
            return
        }
        do {
            let hadOutcome = activeGame.outcome != nil
            self.activeGame = try PlayableGameEngine.applying(command, to: activeGame, scenario: scenario)
            playError = nil
            if let outcome = self.activeGame?.outcome {
                if !hadOutcome, let game = self.activeGame {
                    upsertPlayableCompletion(for: scenario, game: game)
                }
                clearSavedGame()
                status = "\(scenario.title): \(outcome)."
            } else {
                persistActiveGame()
                status = "\(scenario.title): Play Mode turn \(self.activeGame?.turn ?? 1)."
            }
        } catch {
            playError = String(describing: error)
            status = "\(scenario.title): \(playError ?? "Command blocked")."
        }
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

    var selectedPlayableCompletion: PlayableCompletionRecord? {
        guard let id = selectedScenario?.id else {
            return nil
        }
        return playableCompletionRecords.first { $0.scenarioID == id && $0.humanSide == selectedHumanSide && $0.difficulty == selectedAIDifficulty }
    }

    var activeScenario: ZombieScenario? {
        guard let scenarioID = activeGame?.scenarioID else {
            return nil
        }
        return catalog.scenarios.first { $0.id == scenarioID }
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

    private func upsertPlayableCompletion(for scenario: ZombieScenario, game: PlayableGameState) {
        guard let outcome = game.outcome else {
            return
        }
        let id = "\(scenario.id)-\(game.humanSide.rawValue)-\(game.difficulty.rawValue)"
        let completedRuns = (playableCompletionRecords.first { $0.id == id }?.completedRuns ?? 0) + 1
        let record = PlayableCompletionRecord(
            scenarioID: scenario.id,
            humanSide: game.humanSide,
            difficulty: game.difficulty,
            lastOutcome: outcome,
            lastSeed: game.seed,
            completedRuns: completedRuns,
            updatedAt: Date()
        )
        playableCompletionRecords.removeAll { $0.id == id }
        playableCompletionRecords.append(record)
        persistPlayableCompletionRecords()
    }

    private func actorName(_ actorID: String, in scenario: ZombieScenario) -> String {
        scenario.actors.first { $0.id == actorID }?.name ?? actorID
    }

    private func persistActiveGame() {
        guard let activeGame, activeGame.outcome == nil else {
            clearSavedGame()
            return
        }
        do {
            let save = PlayableGameSave(state: activeGame)
            let data = try JSONEncoder().encode(save)
            UserDefaults.standard.set(data, forKey: activeGameSaveKey)
            savedGame = activeGame
        } catch {
            playError = "Could not save Play Mode run."
        }
    }

    private func clearSavedGame() {
        UserDefaults.standard.removeObject(forKey: activeGameSaveKey)
        savedGame = nil
    }

    private func loadSavedGame() -> PlayableGameState? {
        guard let data = UserDefaults.standard.data(forKey: activeGameSaveKey),
              let save = try? JSONDecoder().decode(PlayableGameSave.self, from: data),
              save.state.outcome == nil else {
            return nil
        }
        return save.state
    }

    private func persistPlayableCompletionRecords() {
        guard let data = try? JSONEncoder().encode(playableCompletionRecords) else {
            return
        }
        UserDefaults.standard.set(data, forKey: playableCompletionRecordsKey)
    }

    private func loadPlayableCompletionRecords() -> [PlayableCompletionRecord] {
        guard let data = UserDefaults.standard.data(forKey: playableCompletionRecordsKey),
              let records = try? JSONDecoder().decode([PlayableCompletionRecord].self, from: data) else {
            return []
        }
        return records
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

                    PlaySetupPanelView(scenario: scenario)

                    Text(PlayableGameEngine.objectiveBriefing(for: scenario, humanSide: store.selectedHumanSide))
                        .font(.headline)

                    ConfidenceView(confidence: scenario.dataConfidence)

                    if let game = store.activeGame, game.scenarioID == scenario.id {
                        PlayModeView(scenario: scenario, game: game)
                    } else {
                        ScenarioBoardView(scenario: scenario)
                            .frame(maxWidth: 760)
                    }

                    HStack(alignment: .top, spacing: 24) {
                        ForceListView(title: "Forces", forces: scenario.forces)
                        ActorListView(title: "Actors", actors: scenario.actors)
                    }

                    if scenario.hasVisibleMechanics {
                        MechanicsView(mechanics: scenario.mechanics)
                    }

                    if let completion = store.selectedCompletion {
                        Text("Previewed \(completion.completedRuns)x, latest outcome: \(completion.lastOutcome)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let completion = store.selectedPlayableCompletion {
                        Text("Manual plays \(completion.completedRuns)x as \(sideName(completion.humanSide, in: scenario)) on \(completion.difficulty.title), latest outcome: \(completion.lastOutcome)")
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

    private func sideName(_ side: ForceSide, in scenario: ZombieScenario) -> String {
        scenario.forces.first { $0.side == side }.map { "\($0.name) - \($0.unit)" } ?? side.rawValue.capitalized
    }
}

struct PlaySetupPanelView: View {
    @EnvironmentObject private var store: ZombieAppStore
    let scenario: ZombieScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Play Setup")
                    .font(.headline)
                Spacer()
                Button {
                    store.runEarlyReplayCorpus()
                } label: {
                    Label("Replay Early Corpus", systemImage: "arrow.triangle.2.circlepath")
                }

                Button {
                    store.startSelectedGame()
                } label: {
                    Label("Start Game", systemImage: "flag.checkered")
                }
                .disabled(!scenario.playable || scenario.tier != .early)

                if store.savedGame?.scenarioID == scenario.id {
                    Button {
                        store.resumeSavedGame()
                    } label: {
                        Label("Resume Game", systemImage: "arrow.clockwise")
                    }
                }
            }

            HStack(alignment: .top, spacing: 18) {
                Picker("Play Side", selection: $store.selectedHumanSide) {
                    ForEach(ForceSide.allCases, id: \.self) { side in
                        Text(sideName(side)).tag(side)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 260)

                Picker("AI", selection: $store.selectedAIDifficulty) {
                    ForEach(PlayableAIDifficulty.allCases) { difficulty in
                        Text(difficulty.title).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
            }

            HStack(alignment: .top, spacing: 16) {
                ForEach(ForceSide.allCases, id: \.self) { side in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sideName(side))
                            .font(.subheadline)
                            .fontWeight(side == store.selectedHumanSide ? .semibold : .regular)
                        Text(PlayableGameEngine.forceSummary(for: side, in: scenario))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack {
                Label(replaySummary, systemImage: store.earlyReplayResults.allSatisfy(\.passed) ? "checkmark.seal" : "exclamationmark.triangle")
                    .font(.caption)
                Spacer()
                Text(PlayableGameEngine.fogOfWarPolicy)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.04))
    }

    private var replaySummary: String {
        let relevant = store.earlyReplayResults.filter { result in
            scenario.tier != .early || result.scenarioID == scenario.id
        }
        guard !relevant.isEmpty else {
            return "No early replay results yet."
        }
        let passed = relevant.filter(\.passed).count
        return "Replay \(passed)/\(relevant.count) side runs passed."
    }

    private func sideName(_ side: ForceSide) -> String {
        scenario.forces.first { $0.side == side }.map { "\($0.name) - \($0.unit)" } ?? side.rawValue.capitalized
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

struct PlayModeView: View {
    @EnvironmentObject private var store: ZombieAppStore
    @State private var confirmAbandon = false
    let scenario: ZombieScenario
    let game: PlayableGameState

    var body: some View {
        let legalMoves = store.legalMoves(for: scenario)
        let legalTargets = store.legalTargets(for: scenario)

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Play Mode").font(.headline)
                Spacer()
                HStack(spacing: 10) {
                    Text("Turn \(game.turn) - \(game.phase.rawValue) - \(game.difficulty.title) AI")
                    Text("Seed \(game.seed)")
                        .monospacedDigit()
                    Button {
                        store.copySeed(game.seed)
                    } label: {
                        Label("Copy Seed", systemImage: "doc.on.doc")
                    }
                    .labelStyle(.iconOnly)
                }
                .foregroundStyle(.secondary)
            }

            Text(PlayableGameEngine.objectiveBriefing(for: scenario, humanSide: game.humanSide))
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("Active Actor: \(selectedActor.map { actorName($0.id) } ?? "None") - Remaining \(game.remainingHumanActorIDs.map(actorName).joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Cancel before commit; movement and dice actions are final.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let outcome = game.outcome {
                Text("Outcome: \(outcome)")
                    .fontWeight(.semibold)
            }

            if scenario.sensitivityTags.contains("fictional-training") {
                TutorialStepsView(scenario: scenario, game: game)
            }

            if let playError = store.playError {
                Text(playError)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            HStack(alignment: .top, spacing: 20) {
                PlayBoardView(
                    scenario: scenario,
                    game: game,
                    legalMoves: legalMoves,
                    legalTargets: legalTargets
                )
                .frame(maxWidth: 420)

                VStack(alignment: .leading, spacing: 8) {
                    Picker("Actor", selection: Binding(
                        get: { game.selectedActorID ?? "" },
                        set: { store.selectActor($0.isEmpty ? nil : $0) }
                    )) {
                        Text("Select actor").tag("")
                        ForEach(game.actors.filter { $0.side == game.humanSide && $0.active && !$0.acted }) { actor in
                            Text(actorName(actor.id)).tag(actor.id)
                        }
                    }
                    .frame(maxWidth: 280)

                    HStack(spacing: 8) {
                        Button {
                            store.selectPlayAction(.move, in: scenario)
                        } label: {
                            Label("Move", systemImage: "figure.walk")
                        }
                        .disabled(game.phase != .humanActivation)

                        Button {
                            store.selectPlayAction(.attack, in: scenario)
                        } label: {
                            Label("Attack", systemImage: "scope")
                        }
                        .disabled(game.phase != .humanActivation)

                        Button {
                            store.waitSelectedActor(in: scenario)
                        } label: {
                            Label("Wait", systemImage: "pause.fill")
                        }
                        .disabled(!selectedActorCanAct)

                        Button {
                            store.endTurn(in: scenario)
                        } label: {
                            Label("End Turn", systemImage: "forward.end.fill")
                        }
                        .disabled(game.phase != .humanActivation)

                        Button {
                            store.cancelPlaySelection()
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle")
                        }

                        Button(role: .destructive) {
                            confirmAbandon = true
                        } label: {
                            Label("Abandon", systemImage: "trash")
                        }
                    }
                    .labelStyle(.titleAndIcon)

                    if let selected = selectedActor {
                        ActorInspectorView(scenario: scenario, actor: selected)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.selectedPlayAction == .move ? "Move" : "Attack")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if store.selectedPlayAction == .move {
                            if legalMoves.isEmpty {
                                Text("No legal move selected.").font(.caption).foregroundStyle(.secondary)
                            } else {
                                ForEach(legalMoves) { point in
                                    Button(point.id) {
                                        store.moveSelectedActor(to: point, in: scenario)
                                    }
                                }
                            }
                        } else {
                            if legalTargets.isEmpty {
                                Text("No legal target selected.").font(.caption).foregroundStyle(.secondary)
                            } else {
                                ForEach(legalTargets) { target in
                                    Button(actorName(target.id)) {
                                        store.attackSelectedTarget(target.id, in: scenario)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Play Log").font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    Picker("Log Filter", selection: $store.selectedPlayLogFilter) {
                        ForEach(PlayLogFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 420)
                }
                ForEach(store.filteredEvents(for: game).suffix(12)) { event in
                    Text("T\(event.turn) \(event.phase): \(event.summary)")
                        .font(.caption)
                        .monospacedDigit()
                }
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.05))
        .confirmationDialog("Abandon this Play Mode run?", isPresented: $confirmAbandon, titleVisibility: .visible) {
            Button("Abandon Run", role: .destructive) {
                store.abandonActiveGame()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var selectedActor: PlayableActorState? {
        guard let selectedActorID = game.selectedActorID else {
            return nil
        }
        return game.actors.first { $0.id == selectedActorID }
    }

    private var selectedActorCanAct: Bool {
        guard let selectedActor else {
            return false
        }
        return game.phase == .humanActivation && selectedActor.side == game.humanSide && selectedActor.active && !selectedActor.acted
    }

    private func actorName(_ id: String) -> String {
        scenario.actors.first { $0.id == id }?.name ?? id
    }

    private func sideName(_ side: ForceSide) -> String {
        scenario.forces.first { $0.side == side }?.name ?? side.rawValue.capitalized
    }

}

struct TutorialStepsView: View {
    @EnvironmentObject private var store: ZombieAppStore
    let scenario: ZombieScenario
    let game: PlayableGameState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Tutorial Steps")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    store.completeTutorialRun(in: scenario)
                } label: {
                    Label("Complete Tutorial", systemImage: "checkmark.circle")
                }
            }
            Text(stepText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color.black.opacity(0.04))
    }

    private var stepText: String {
        if game.outcome != nil {
            return "Tutorial complete: review the outcome and play log."
        }
        if game.selectedActorID == nil {
            return "Step 1: choose an actor."
        }
        if !game.events.contains(where: { $0.phase == "move" }) {
            return "Step 2: choose Move and select a highlighted cell."
        }
        if !game.events.contains(where: { $0.phase == "attack" }) {
            return "Step 3: choose Attack when a target is highlighted, or Wait to spend the activation."
        }
        if !game.events.contains(where: { $0.phase == "wait" }) {
            return "Step 4: use Wait with a remaining actor."
        }
        if !game.events.contains(where: { $0.phase.hasPrefix("ai-") }) {
            return "Step 5: end the turn to let AI resolve."
        }
        return "Step 6: continue until the outcome appears."
    }
}

struct ActorInspectorView: View {
    let scenario: ZombieScenario
    let actor: PlayableActorState

    var body: some View {
        if let scenarioActor = scenario.actors.first(where: { $0.id == actor.id }) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Actor Inspector")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(scenarioActor.name)
                    .fontWeight(.semibold)
                Text("Status \(PlayableGameEngine.actorStatus(actor))")
                    .font(.caption)
                Text("Weapon \(displayName(scenarioActor.weapon.rawValue))")
                    .font(.caption)
                Text("Role \(displayName(scenarioActor.role.rawValue))")
                    .font(.caption)
                Text("Stats \(statsText(scenarioActor.stats))")
                    .font(.caption)
                    .monospacedDigit()
                Text("Skills \(scenarioActor.skills.map(displayName).joined(separator: ", "))")
                    .font(.caption)
                Text("Wounds \(actor.wounds.total), clips \(actor.clips), rounds \(actor.roundsInClip)")
                    .font(.caption)
                    .monospacedDigit()
            }
            .foregroundStyle(.primary)
        }
    }

    private func statsText(_ stats: [String: Int]) -> String {
        stats.keys.sorted().map { "\($0) \(stats[$0] ?? 0)" }.joined(separator: ", ")
    }

    private func displayName(_ rawValue: String) -> String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct PlayBoardView: View {
    let scenario: ZombieScenario
    let game: PlayableGameState
    let legalMoves: [GridPoint]
    let legalTargets: [PlayableActorState]

    var body: some View {
        let movePoints = Set(legalMoves)
        let targetIDs = Set(legalTargets.map(\.id))
        let columns = Array(repeating: GridItem(.fixed(26), spacing: 2), count: scenario.map.width)
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<(scenario.map.width * scenario.map.height), id: \.self) { index in
                let point = GridPoint(x: index % scenario.map.width, y: index / scenario.map.width)
                Rectangle()
                    .fill(color(for: point, movePoints: movePoints))
                    .overlay {
                        if let actor = actor(at: point) {
                            ZStack {
                                Circle()
                                    .fill(targetIDs.contains(actor.id) ? Color.red : (actor.side == game.humanSide ? Color.blue : Color.red))
                                    .padding(5)
                                if targetIDs.contains(actor.id) {
                                    Circle().stroke(Color.yellow, lineWidth: 2).padding(3)
                                }
                                if actor.acted {
                                    Circle().stroke(Color.white, lineWidth: 2).padding(4)
                                }
                            }
                        } else if movePoints.contains(point) {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue, lineWidth: 2)
                                .padding(3)
                        }
                    }
                    .frame(width: 26, height: 26)
                    .accessibilityLabel(accessibilityLabel(for: point, movePoints: movePoints, targetIDs: targetIDs))
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.08))
    }

    private func actor(at point: GridPoint) -> PlayableActorState? {
        game.actors.first { $0.position == point && $0.active }
    }

    private func color(for point: GridPoint, movePoints: Set<GridPoint>) -> Color {
        if movePoints.contains(point) { return .blue.opacity(0.32) }
        if game.moveTarget == point { return .blue.opacity(0.45) }
        if scenario.objective.point == point { return .purple.opacity(0.7) }
        if scenario.map.protectedCellSet.contains(point) { return .black.opacity(0.42) }
        let tags = scenario.map.tags(at: point)
        if tags.contains(.checkpoint) || tags.contains(.base) { return .gray.opacity(0.75) }
        if tags.contains(.building) { return .brown.opacity(0.6) }
        if tags.contains(.road) || tags.contains(.lane) { return .gray.opacity(0.35) }
        if tags.contains(.hedge) || tags.contains(.cover) || tags.contains(.wall) { return .green.opacity(0.45) }
        if tags.contains(.border) { return .orange.opacity(0.45) }
        if tags.contains(.river) { return .cyan.opacity(0.45) }
        if tags.contains(.rail) { return .mint.opacity(0.5) }
        return .green.opacity(0.18)
    }

    private func accessibilityLabel(for point: GridPoint, movePoints: Set<GridPoint>, targetIDs: Set<String>) -> String {
        if movePoints.contains(point) {
            return "Legal move cell \(point.x), \(point.y)"
        }
        if let actor = actor(at: point), targetIDs.contains(actor.id) {
            return "Legal target \(actor.id)"
        }
        return "Play cell \(point.x), \(point.y)"
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
