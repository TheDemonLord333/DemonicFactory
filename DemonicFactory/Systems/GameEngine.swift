//
//  GameEngine.swift
//  DemonicFactory
//
//  UI-agnostic simulation core. FactoryScene (SpriteKit) drives `tick(_:)` every
//  frame and forwards touch intents here; GameViewModel (SwiftUI) mirrors
//  `state` for the surrounding menus. Neither layer mutates `state` directly.
//

import Foundation

final class GameEngine {
    let state: GameState

    init() {
        let grid = FactoryGrid.startingGrid(width: 12, height: 12)
        state = GameState(grid: grid)
        bootstrapNewGame()
    }

    private func bootstrapNewGame() {
        state.resources[.hellCoin] = 300
        state.resources[.bloodCrystal] = 0
        state.resources[.voidEssence] = 0
        state.resources[.darkEnergy] = 0
        state.energy.stored = 40
        state.missions = MissionSystem.starterMissions()
    }

    // MARK: - Tick

    func tick(deltaTime: TimeInterval) {
        let dt = min(deltaTime, 1.0 / 15.0)
        state.elapsedPlayTime += dt
        ProductionSystem.advance(state: state, deltaTime: dt)
        ConveyorSystem.advance(state: state, deltaTime: dt)
        EnergySystem.recompute(state: state)
        EfficiencySystem.recompute(state: state, deltaTime: dt)
        MissionSystem.evaluate(state: state, deltaTime: dt)
        CreatureMovementSystem.advance(state: state, deltaTime: dt)
    }

    // MARK: - Building placement

    func beginPlacing(_ type: BuildingType) {
        state.interaction = .placingBuilding(type)
    }

    func beginDrawingBelt() {
        state.interaction = .drawingBelt
    }

    func cancelInteraction() {
        state.interaction = .idle
    }

    @discardableResult
    func tryPlaceBuilding(at point: GridPoint) -> Bool {
        guard case .placingBuilding(let type) = state.interaction else { return false }
        guard state.grid.isBuildable(at: point), state.building(at: point) == nil, !state.hasBelt(at: point) else { return false }
        guard state.spendResource(.hellCoin, amount: type.baseHellCoinCost) else { return false }

        let building = FactoryBuilding(type: type, gridPosition: point)
        state.buildings.append(building)
        state.lifetimeBuildingsBuilt += 1
        state.interaction = .idle
        return true
    }

    // MARK: - Selection / upgrade / sell / move

    func selectBuilding(id: UUID) {
        state.selectedBuildingID = id
        state.interaction = .selected(id)
    }

    func deselect() {
        state.selectedBuildingID = nil
        if case .selected = state.interaction { state.interaction = .idle }
    }

    @discardableResult
    func upgradeSelectedBuilding() -> Bool {
        guard let building = state.selectedBuilding, building.canUpgrade() else { return false }
        guard state.spendResource(.hellCoin, amount: building.upgradeCost()) else { return false }
        building.level += 1
        return true
    }

    func sellSelectedBuilding() {
        guard let building = state.selectedBuilding else { return }
        let refund = Int(Double(building.type.baseHellCoinCost) * 0.5)
        state.addResource(.hellCoin, amount: refund)
        state.beltLines.removeAll { $0.sourceBuildingID == building.id || $0.destinationBuildingID == building.id }
        state.buildings.removeAll { $0.id == building.id }
        deselect()
    }

    func beginMovingSelected() {
        guard let id = state.selectedBuildingID else { return }
        state.interaction = .movingBuilding(id)
    }

    @discardableResult
    func moveSelectedBuilding(to point: GridPoint) -> Bool {
        guard case .movingBuilding(let id) = state.interaction, let building = state.building(id: id) else { return false }
        guard state.grid.isBuildable(at: point), state.building(at: point) == nil, !state.hasBelt(at: point) else { return false }
        building.gridPosition = point
        state.interaction = .selected(id)
        return true
    }

    // MARK: - Belts

    @discardableResult
    func placeBeltLine(path: [GridPoint]) -> Bool {
        guard path.count >= 2 else { return false }
        for point in path {
            guard state.grid.isBuildable(at: point), state.building(at: point) == nil else { return false }
        }
        let cost = path.count * 5
        guard state.spendResource(.hellCoin, amount: cost) else { return false }

        let source = path.first?.neighbors.compactMap { state.building(at: $0) }.first
        let destination = path.last?.neighbors.compactMap { state.building(at: $0) }.first

        let line = ConveyorLine(path: path, sourceBuildingID: source?.id, destinationBuildingID: destination?.id)
        state.beltLines.append(line)
        return true
    }

    // MARK: - Missions

    func claimMission(id: UUID) {
        guard let mission = state.missions.first(where: { $0.id == id }),
              mission.isCompleted, !mission.isClaimed
        else { return }
        state.addResource(.hellCoin, amount: mission.rewardHellCoin)
        if mission.rewardBloodCrystal > 0 {
            state.addResource(.bloodCrystal, amount: mission.rewardBloodCrystal)
        }
        mission.isClaimed = true
    }

    // MARK: - Persistence

    func makeSnapshot() -> GameSnapshot { GameSnapshot(state: state) }

    func restore(from snapshot: GameSnapshot) { snapshot.apply(to: state) }

    /// Fast-forwards the simulation in coarse steps to approximate what would
    /// have happened while the app was closed. Capped at two hours; no attack
    /// waves run offline since combat isn't part of the first playable version.
    @discardableResult
    func applyOfflineProgress(elapsed: TimeInterval) -> OfflineReport {
        let cap: TimeInterval = 2 * 60 * 60
        let simulated = min(elapsed, cap)
        guard simulated > 5 else { return OfflineReport(duration: 0, gains: [:]) }

        let resourcesBefore = state.resources
        let producedBefore = state.lifetimeProduced

        let step: TimeInterval = 5
        var remaining = simulated
        while remaining > 0 {
            tick(deltaTime: min(step, remaining))
            remaining -= step
        }

        var gains: [ResourceType: Int] = [:]
        for type in ResourceType.allCases {
            if type.isGlobalCurrency {
                let delta = state.resources[type, default: 0] - resourcesBefore[type, default: 0]
                if delta > 0 { gains[type] = delta }
            } else {
                let delta = state.lifetimeProduced[type, default: 0] - producedBefore[type, default: 0]
                if delta > 0 { gains[type] = delta }
            }
        }
        return OfflineReport(duration: simulated, gains: gains)
    }
}

struct OfflineReport {
    let duration: TimeInterval
    let gains: [ResourceType: Int]
}
