//
//  MissionSystem.swift
//  DemonicFactory
//

import Foundation

enum MissionSystem {
    /// Efficiency threshold (%) the `.keepEfficiencyAbove` mission tracks.
    static let efficiencyMissionThreshold: Double = 80

    static func starterMissions() -> [Mission] {
        [
            Mission(goalType: .produceResource, targetResource: .soulFragment),
            Mission(goalType: .produceResource, targetResource: .compressedSoul),
            Mission(goalType: .buildBuildings),
            Mission(goalType: .reachEnergyProduction),
            Mission(goalType: .summonCreatures),
            Mission(goalType: .keepEfficiencyAbove)
        ]
    }

    // MARK: - Progress hooks (the central, reusable ways a mission can move)

    private static func applyProgress(_ newProgress: Int, to mission: Mission) {
        mission.progress = min(mission.targetAmount, max(0, newProgress))
        if mission.progress >= mission.targetAmount {
            mission.isCompleted = true
        }
    }

    /// Adds incremental progress to every active mission of this type —
    /// available for event-driven callers; the built-in missions below use
    /// `updateThresholdMission` instead since they already track a lifetime
    /// counter in GameState.
    static func addProgress(to goalType: MissionGoalType, targetResource: ResourceType? = nil, amount: Int, in state: GameState) {
        guard amount != 0 else { return }
        for mission in state.missions
        where mission.goalType == goalType && mission.targetResource == targetResource && !mission.isCompleted {
            applyProgress(mission.progress + amount, to: mission)
        }
    }

    /// Syncs progress to an absolute external value (e.g. a lifetime counter
    /// or the current energy production rate) rather than accumulating deltas.
    /// Progress never regresses — once a value has been reached, it sticks,
    /// even if the underlying value dips again before the mission completes.
    static func updateThresholdMission(goalType: MissionGoalType, targetResource: ResourceType? = nil, currentValue: Int, in state: GameState) {
        for mission in state.missions
        where mission.goalType == goalType && mission.targetResource == targetResource && !mission.isCompleted {
            applyProgress(max(mission.progress, currentValue), to: mission)
        }
    }

    /// Efficiency missions pause (not reset) below the threshold and resume
    /// counting the moment efficiency recovers.
    static func updateEfficiencyMission(currentEfficiency: Double, elapsedTime: TimeInterval, in state: GameState) {
        for mission in state.missions where mission.goalType == .keepEfficiencyAbove && !mission.isCompleted {
            if currentEfficiency >= efficiencyMissionThreshold {
                mission.continuousSeconds += elapsedTime
            }
            applyProgress(Int(mission.continuousSeconds), to: mission)
        }
    }

    static func evaluate(state: GameState, deltaTime: TimeInterval) {
        updateThresholdMission(goalType: .produceResource, targetResource: .soulFragment, currentValue: state.lifetimeProduced[.soulFragment, default: 0], in: state)
        updateThresholdMission(goalType: .produceResource, targetResource: .compressedSoul, currentValue: state.lifetimeProduced[.compressedSoul, default: 0], in: state)
        updateThresholdMission(goalType: .buildBuildings, currentValue: state.lifetimeBuildingsBuilt, in: state)
        updateThresholdMission(goalType: .summonCreatures, currentValue: state.lifetimeCreaturesSummoned, in: state)
        updateThresholdMission(goalType: .reachEnergyProduction, currentValue: Int(state.energy.production), in: state)
        updateEfficiencyMission(currentEfficiency: state.efficiency, elapsedTime: deltaTime, in: state)
    }

    // MARK: - Claiming

    /// Pays out the mission's current reward and immediately advances it to
    /// the next level (new target, new rewards, progress reset to 0, active
    /// again). Returns nil if the mission wasn't actually claimable.
    ///
    /// This is what keeps a rapid double-tap on "Abholen" from paying out
    /// twice: `isClaimed` flips to true as the very first mutation, before
    /// anything else happens, and every call re-checks it — since Swift/UIKit
    /// dispatches are single-threaded on the main actor, a second call can
    /// never interleave inside the first.
    @discardableResult
    static func claimReward(_ mission: Mission) -> (gold: Int, bloodCrystal: Int)? {
        guard mission.isCompleted, !mission.isClaimed else { return nil }
        let payout = (gold: mission.rewardHellCoin, bloodCrystal: mission.rewardBloodCrystal)
        mission.isClaimed = true

        mission.level += 1
        mission.completedStages += 1
        mission.targetAmount = MissionScaling.target(goalType: mission.goalType, targetResource: mission.targetResource, level: mission.level)
        mission.rewardHellCoin = MissionScaling.goldReward(goalType: mission.goalType, targetResource: mission.targetResource, level: mission.level)
        mission.rewardBloodCrystal = MissionScaling.bloodCrystalReward(goalType: mission.goalType, targetResource: mission.targetResource, level: mission.level)
        mission.progress = 0
        mission.continuousSeconds = 0
        mission.isCompleted = false
        mission.isClaimed = false

        return payout
    }
}
