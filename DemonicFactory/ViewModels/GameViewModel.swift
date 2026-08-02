//
//  GameViewModel.swift
//  DemonicFactory
//
//  SwiftUI-facing presentation layer. Owns the single GameEngine + FactoryScene
//  instance for the app's lifetime, mirrors the parts of GameState the menus
//  need into @Published properties (via a lightweight polling timer — the
//  simulation itself is driven by FactoryScene's SpriteKit update loop, not by
//  this timer), and forwards user intents from SwiftUI back into the engine.
//

import SwiftUI
import Combine
import SwiftData

struct ResourceAmount: Identifiable {
    let resource: ResourceType
    let amount: Int
    var id: ResourceType { resource }
}

struct SelectedBuildingInfo: Identifiable {
    let id: UUID
    let type: BuildingType
    let level: Int
    let maxLevel: Int
    let isActive: Bool
    let isBlocked: Bool
    let progress: Double
    let inputs: [ResourceAmount]
    let outputs: [ResourceAmount]
    let recipeInputs: [ResourceAmount]
    let recipeOutput: ResourceType?
    let processingTime: Double
    let energyDraw: Double
    let upgradeCost: Int
    let canUpgrade: Bool
    let sellRefund: Int
}

enum BottomBarTab: String, CaseIterable, Identifiable {
    case build, machines, belts, defense, creatures, missions
    var id: String { rawValue }

    var title: String {
        switch self {
        case .build: return "Bauen"
        case .machines: return "Maschinen"
        case .belts: return "Förderbänder"
        case .defense: return "Verteidigung"
        case .creatures: return "Kreaturen"
        case .missions: return "Missionen"
        }
    }

    var iconSystemName: String {
        switch self {
        case .build: return "hammer.fill"
        case .machines: return "gearshape.2.fill"
        case .belts: return "arrow.right.square.fill"
        case .defense: return "shield.fill"
        case .creatures: return "pawprint.fill"
        case .missions: return "flag.checkered"
        }
    }
}

struct TutorialStep {
    let title: String
    let message: String
    let highlightTab: BottomBarTab?
}

@MainActor
final class GameViewModel: ObservableObject {
    let engine: GameEngine
    let scene: FactoryScene

    // Top bar
    @Published private(set) var hellCoin: Int = 0
    @Published private(set) var bloodCrystal: Int = 0
    @Published private(set) var energy = EnergyStatus()
    @Published private(set) var efficiency: Double = 100
    @Published private(set) var playerLevel: Int = 1
    @Published private(set) var playerXP: Int = 0
    @Published private(set) var xpNeeded: Int = 100

    // Panels
    @Published var activeTab: BottomBarTab?
    @Published var selectedBuilding: SelectedBuildingInfo?
    @Published var missions: [Mission] = []
    @Published var creatures: [Creature] = []
    @Published var efficiencyIssues: [String] = []
    @Published var showEfficiencyDetail = false

    // Interaction
    @Published private(set) var interaction: InteractionMode = .idle
    @Published var isDrawingBelt = false

    // Offline / tutorial
    @Published var offlineReport: OfflineReport?
    @Published var tutorialStepIndex: Int? = 0
    let tutorialSteps: [TutorialStep] = GameViewModel.buildTutorialSteps()

    private var saveManager: SaveGameManager?
    private var refreshTimer: Timer?
    private var autosaveTimer: Timer?

    init() {
        let engine = GameEngine()
        self.engine = engine
        self.scene = FactoryScene(engine: engine, size: CGSize(width: 800, height: 800))
        scene.onRequestBuildMenu = { [weak self] _ in
            self?.activeTab = .build
        }

        if UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
            tutorialStepIndex = nil
        }

        refresh()
        startTimers()
    }

    deinit {
        refreshTimer?.invalidate()
        autosaveTimer?.invalidate()
    }

    private func startTimers() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.saveNow() }
        }
    }

    // MARK: - Persistence

    func attachPersistence(_ context: ModelContext) {
        let manager = SaveGameManager(context: context)
        saveManager = manager

        if let (snapshot, offlineDuration) = manager.load() {
            engine.restore(from: snapshot)
            let report = engine.applyOfflineProgress(elapsed: offlineDuration)
            if report.duration > 5 {
                offlineReport = report
            }
        }
        refresh()
    }

    func saveNow() {
        saveManager?.save(engine: engine)
    }

    // MARK: - Refresh (engine -> published state)

    private func refresh() {
        let state = engine.state
        hellCoin = state.resourceAmount(.hellCoin)
        bloodCrystal = state.resourceAmount(.bloodCrystal)
        energy = state.energy
        efficiency = state.efficiency
        efficiencyIssues = state.efficiencyIssues
        playerLevel = state.playerLevel
        playerXP = state.playerXP
        xpNeeded = state.xpNeeded(forLevel: state.playerLevel)
        missions = state.missions
        creatures = state.creatures
        interaction = state.interaction
        isDrawingBelt = (state.interaction == .drawingBelt)
        selectedBuilding = makeSelectedBuildingInfo(state: state)
    }

    private func makeSelectedBuildingInfo(state: GameState) -> SelectedBuildingInfo? {
        guard let building = state.selectedBuilding else { return nil }
        let recipe = RecipeDatabase.recipe(for: building.type)
        // Storage has no production cycle to be "active" in; treat it as always
        // running so its status label doesn't misleadingly read "waiting".
        let isActive = recipe == nil ? true : building.isActive
        return SelectedBuildingInfo(
            id: building.id,
            type: building.type,
            level: building.level,
            maxLevel: building.type.maxLevel,
            isActive: isActive,
            isBlocked: building.isBlocked,
            progress: min(1, max(0, building.progress)),
            inputs: building.inputBuffer.map { ResourceAmount(resource: $0.key, amount: $0.value) }.sorted { $0.resource.rawValue < $1.resource.rawValue },
            outputs: building.outputBuffer.map { ResourceAmount(resource: $0.key, amount: $0.value) }.sorted { $0.resource.rawValue < $1.resource.rawValue },
            recipeInputs: (recipe?.inputs ?? [:]).map { ResourceAmount(resource: $0.key, amount: $0.value) },
            recipeOutput: recipe?.producesCreature == true ? nil : recipe?.output,
            processingTime: recipe?.processingTime(level: building.level) ?? 0,
            energyDraw: recipe?.energyDraw(level: building.level) ?? 0,
            upgradeCost: building.upgradeCost(),
            canUpgrade: building.canUpgrade(),
            sellRefund: Int(Double(building.type.baseHellCoinCost) * 0.5)
        )
    }

    // MARK: - Intents

    func beginPlacing(_ type: BuildingType) {
        engine.beginPlacing(type)
        activeTab = nil
        refresh()
    }

    func toggleBeltDrawing() {
        if case .drawingBelt = engine.state.interaction {
            engine.cancelInteraction()
        } else {
            engine.beginDrawingBelt()
        }
        refresh()
    }

    func cancelInteraction() {
        engine.cancelInteraction()
        refresh()
    }

    func deselectBuilding() {
        engine.deselect()
        refresh()
    }

    func upgradeSelected() {
        _ = engine.upgradeSelectedBuilding()
        if let node = scene.buildingNode(for: engine.state.selectedBuildingID) {
            node.playUpgradeFlash()
        }
        refresh()
    }

    func sellSelected() {
        engine.sellSelectedBuilding()
        refresh()
    }

    func beginMovingSelected() {
        engine.beginMovingSelected()
        refresh()
    }

    func claimMission(_ mission: Mission) {
        engine.claimMission(id: mission.id)
        refresh()
    }

    // MARK: - Tutorial

    func advanceTutorial() {
        guard let index = tutorialStepIndex else { return }
        if index + 1 < tutorialSteps.count {
            tutorialStepIndex = index + 1
        } else {
            skipTutorial()
        }
    }

    func skipTutorial() {
        tutorialStepIndex = nil
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
    }

    private static func buildTutorialSteps() -> [TutorialStep] {
        [
            TutorialStep(title: "Willkommen, Beschwörer", message: "Tippe unten auf „Bauen“ und wähle die Seelenquelle aus.", highlightTab: .build),
            TutorialStep(title: "Seelenquelle platzieren", message: "Tippe auf ein freies Feld, um die Seelenquelle zu bauen.", highlightTab: .build),
            TutorialStep(title: "Förderband ziehen", message: "Wähle „Förderbänder“ und ziehe mit dem Finger eine Linie von der Seelenquelle weg.", highlightTab: .belts),
            TutorialStep(title: "Seelenpresse bauen", message: "Baue eine Seelenpresse am Ende des Förderbands.", highlightTab: .build),
            TutorialStep(title: "Maschinen verbinden", message: "Verbinde Seelenpresse und weitere Maschinen ebenfalls mit Förderbändern.", highlightTab: .belts),
            TutorialStep(title: "Produktion beobachten", message: "Sobald genug Seelenfragmente ankommen, presst die Maschine automatisch verdichtete Seelen.", highlightTab: nil),
            TutorialStep(title: "Lager bauen", message: "Ein Lager speichert überschüssige Materialien, damit nichts blockiert.", highlightTab: .build),
            TutorialStep(title: "Energie im Blick behalten", message: "Oben siehst du deine dunkle Energie. Reicht sie nicht, arbeiten Maschinen langsamer.", highlightTab: nil),
            TutorialStep(title: "Maschine verbessern", message: "Tippe eine Maschine an und verbessere sie im Infofenster für mehr Leistung.", highlightTab: .machines),
            TutorialStep(title: "Beschwörungsportal bauen", message: "Baue dein erstes Beschwörungsportal, um später Kreaturen zu beschwören.", highlightTab: .build)
        ]
    }
}
