//
//  GameState.swift
//  DemonicFactory
//
//  Single source of truth for a running game. Owned by GameEngine; read by
//  FactoryScene (SpriteKit) and mirrored into GameViewModel (SwiftUI) each tick.
//

import Foundation

final class GameState {
    var grid: FactoryGrid
    var buildings: [FactoryBuilding] = []
    var beltLines: [ConveyorLine] = []
    var creatures: [Creature] = []
    var missions: [Mission] = []

    /// Global warehouse — hell coins, blood crystals, void essence, and a mirror
    /// of the dark-energy pool for display purposes.
    var resources: [ResourceType: Int] = [:]
    var energy = EnergyStatus()

    var playerLevel: Int = 1
    var playerXP: Int = 0

    var efficiency: Double = 100
    var efficiencyIssues: [String] = []

    var interaction: InteractionMode = .idle
    var selectedBuildingID: UUID?
    var selectedBeltID: UUID?

    var elapsedPlayTime: TimeInterval = 0
    var lastSavedAt: Date = .now

    /// Cumulative counters used by the mission system (stock alone can't answer
    /// "produce 100 soul fragments" once fragments get consumed downstream).
    var lifetimeProduced: [ResourceType: Int] = [:]
    var lifetimeBuildingsBuilt: Int = 0
    var lifetimeCreaturesSummoned: Int = 0

    init(grid: FactoryGrid) {
        self.grid = grid
    }

    func building(id: UUID) -> FactoryBuilding? { buildings.first { $0.id == id } }
    func building(at point: GridPoint) -> FactoryBuilding? { buildings.first { $0.gridPosition == point } }
    func hasBelt(at point: GridPoint) -> Bool { beltLines.contains { $0.path.contains(point) } }
    func belt(id: UUID) -> ConveyorLine? { beltLines.first { $0.id == id } }
    func belt(at point: GridPoint) -> ConveyorLine? { beltLines.first { $0.path.contains(point) } }

    var selectedBuilding: FactoryBuilding? {
        guard let id = selectedBuildingID else { return nil }
        return building(id: id)
    }

    var selectedBelt: ConveyorLine? {
        guard let id = selectedBeltID else { return nil }
        return belt(id: id)
    }

    func resourceAmount(_ type: ResourceType) -> Int { resources[type, default: 0] }

    func addResource(_ type: ResourceType, amount: Int) {
        resources[type, default: 0] += amount
    }

    @discardableResult
    func spendResource(_ type: ResourceType, amount: Int) -> Bool {
        guard resourceAmount(type) >= amount else { return false }
        resources[type, default: 0] -= amount
        return true
    }

    func xpNeeded(forLevel level: Int) -> Int { 80 + level * 40 }

    func grantXP(_ amount: Int) {
        playerXP += amount
        while playerXP >= xpNeeded(forLevel: playerLevel) {
            playerXP -= xpNeeded(forLevel: playerLevel)
            playerLevel += 1
        }
    }
}
