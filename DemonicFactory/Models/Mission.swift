//
//  Mission.swift
//  DemonicFactory
//

import Foundation

enum MissionGoalType: String, Codable {
    case produceResource
    case buildBuildings
    case summonCreatures
    case reachEnergyProduction
    case keepEfficiencyAbove
}

final class Mission: Identifiable {
    let id: UUID
    let goalType: MissionGoalType
    let targetResource: ResourceType?

    var level: Int
    var targetAmount: Int
    var progress: Int
    var rewardHellCoin: Int
    var rewardBloodCrystal: Int
    var isCompleted: Bool
    var isClaimed: Bool
    /// Only used by `.keepEfficiencyAbove`: seconds spent continuously above threshold.
    var continuousSeconds: Double
    /// Lifetime count of stages fully claimed — never resets, unlike `progress`.
    var completedStages: Int

    /// `targetAmount`/`rewardHellCoin`/`rewardBloodCrystal` default to the
    /// scaling formula for `level` when omitted (fresh missions); persistence
    /// passes them explicitly so a restored save always matches what was saved.
    init(
        id: UUID = UUID(),
        goalType: MissionGoalType,
        targetResource: ResourceType? = nil,
        level: Int = 1,
        targetAmount: Int? = nil,
        rewardHellCoin: Int? = nil,
        rewardBloodCrystal: Int? = nil
    ) {
        self.id = id
        self.goalType = goalType
        self.targetResource = targetResource
        self.level = level
        self.targetAmount = targetAmount ?? MissionScaling.target(goalType: goalType, targetResource: targetResource, level: level)
        self.progress = 0
        self.rewardHellCoin = rewardHellCoin ?? MissionScaling.goldReward(goalType: goalType, targetResource: targetResource, level: level)
        self.rewardBloodCrystal = rewardBloodCrystal ?? MissionScaling.bloodCrystalReward(goalType: goalType, targetResource: targetResource, level: level)
        self.isCompleted = false
        self.isClaimed = false
        self.continuousSeconds = 0
        self.completedStages = 0
    }

    var title: String {
        MissionScaling.title(goalType: goalType, targetResource: targetResource, targetAmount: targetAmount)
    }

    var rank: MissionRank {
        MissionRank.forLevel(level)
    }

    var baseTargetAmount: Int { MissionScaling.baseTarget(goalType: goalType, targetResource: targetResource) }
    var baseGoldReward: Int { MissionScaling.baseGoldReward(goalType: goalType, targetResource: targetResource) }
    var baseBloodCrystalReward: Int { MissionScaling.baseBloodCrystalReward(goalType: goalType, targetResource: targetResource) }

    var progressFraction: Double {
        guard targetAmount > 0 else { return 1 }
        return min(1, Double(progress) / Double(targetAmount))
    }
}
