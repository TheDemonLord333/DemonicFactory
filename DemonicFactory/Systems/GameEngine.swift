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
        if case .movingBuilding(let id) = state.interaction {
            cancelMovingBuilding(id: id)
            return
        }
        state.interaction = .idle
    }

    @discardableResult
    func tryPlaceBuilding(at point: GridPoint) -> Bool {
        guard case .placingBuilding(let type) = state.interaction else { return false }
        guard state.isAreaFree(origin: point, footprint: type.footprint) else { return false }
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
        state.selectedBeltID = nil
        state.interaction = .selected(id)
    }

    func deselect() {
        state.selectedBuildingID = nil
        state.selectedBeltID = nil
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
        beginMovingBuilding(id: id)
    }

    /// Enters drag-to-move for a building: pauses its production/output and
    /// marks it as the active move target. Safe to call again for the same
    /// building (e.g. long-press after the info panel's "Verschieben" button
    /// already primed it) — it just re-confirms the state.
    func beginMovingBuilding(id: UUID) {
        guard let building = state.building(id: id) else { return }
        building.isBeingMoved = true
        state.selectedBuildingID = id
        state.selectedBeltID = nil
        state.interaction = .movingBuilding(id)
    }

    /// Validates and applies the drop position as one atomic step: on success
    /// the building's new position is saved and it resumes normal operation;
    /// on failure nothing about the building changes at all. Either way
    /// `isBeingMoved` clears and the building becomes selected again.
    @discardableResult
    func commitMove(buildingID: UUID, to point: GridPoint) -> Bool {
        guard let building = state.building(id: buildingID) else { return false }
        defer {
            building.isBeingMoved = false
            state.interaction = .selected(buildingID)
        }
        guard state.isAreaFree(origin: point, footprint: building.type.footprint, ignoring: buildingID) else {
            return false
        }
        building.gridPosition = point
        return true
    }

    /// Backs out of move mode without touching the building's position.
    func cancelMovingBuilding(id: UUID) {
        guard let building = state.building(id: id) else {
            state.interaction = .idle
            return
        }
        building.isBeingMoved = false
        state.interaction = .selected(id)
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

    func selectBelt(id: UUID) {
        state.selectedBeltID = id
        state.selectedBuildingID = nil
        if case .selected = state.interaction { state.interaction = .idle }
    }

    /// Refunds half the original placement cost, mirroring sellSelectedBuilding.
    func removeSelectedBelt() {
        guard let belt = state.selectedBelt else { return }
        let refund = Int(Double(belt.path.count * 5) * 0.5)
        state.addResource(.hellCoin, amount: refund)
        state.beltLines.removeAll { $0.id == belt.id }
        state.selectedBeltID = nil
    }

    /// Upgrades the whole drawn line at once (segment-by-segment upgrades are
    /// a natural follow-up once belts stop being one-line-one-speed).
    @discardableResult
    func upgradeSelectedBelt() -> Bool {
        guard let belt = state.selectedBelt, belt.canUpgrade else { return false }
        guard state.spendResource(.hellCoin, amount: belt.upgradeCost()) else { return false }
        belt.level += 1
        return true
    }

    // MARK: - Missions

    func claimMission(id: UUID) {
        guard let mission = state.missions.first(where: { $0.id == id }) else { return }
        guard let payout = MissionSystem.claimReward(mission) else { return }
        state.addResource(.hellCoin, amount: payout.gold)
        if payout.bloodCrystal > 0 {
            state.addResource(.bloodCrystal, amount: payout.bloodCrystal)
        }
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
