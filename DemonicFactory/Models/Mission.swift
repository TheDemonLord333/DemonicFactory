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
    let title: String
    let goalType: MissionGoalType
    let targetResource: ResourceType?
    let targetAmount: Int
    var progress: Int
    let rewardHellCoin: Int
    let rewardBloodCrystal: Int
    var isCompleted: Bool
    var isClaimed: Bool
    /// Only used by `.keepEfficiencyAbove`: seconds spent continuously above threshold.
    var continuousSeconds: Double

    init(
        id: UUID = UUID(),
        title: String,
        goalType: MissionGoalType,
        targetResource: ResourceType? = nil,
        targetAmount: Int,
        rewardHellCoin: Int,
        rewardBloodCrystal: Int = 0
    ) {
        self.id = id
        self.title = title
        self.goalType = goalType
        self.targetResource = targetResource
        self.targetAmount = targetAmount
        self.progress = 0
        self.rewardHellCoin = rewardHellCoin
        self.rewardBloodCrystal = rewardBloodCrystal
        self.isCompleted = false
        self.isClaimed = false
        self.continuousSeconds = 0
    }

    var progressFraction: Double {
        guard targetAmount > 0 else { return 1 }
        return min(1, Double(progress) / Double(targetAmount))
    }
}
