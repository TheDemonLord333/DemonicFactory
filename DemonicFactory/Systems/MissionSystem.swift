//
//  MissionSystem.swift
//  DemonicFactory
//

import Foundation

enum MissionSystem {
    /// Efficiency threshold (%) the `.keepEfficiencyAbove` starter mission tracks.
    static let efficiencyMissionThreshold: Double = 80

    static func starterMissions() -> [Mission] {
        [
            Mission(
                title: "Produziere 50 Seelenfragmente",
                goalType: .produceResource,
                targetResource: .soulFragment,
                targetAmount: 50,
                rewardHellCoin: 100
            ),
            Mission(
                title: "Stelle 10 verdichtete Seelen her",
                goalType: .produceResource,
                targetResource: .compressedSoul,
                targetAmount: 10,
                rewardHellCoin: 150
            ),
            Mission(
                title: "Baue 5 Maschinen",
                goalType: .buildBuildings,
                targetAmount: 5,
                rewardHellCoin: 120,
                rewardBloodCrystal: 3
            ),
            Mission(
                title: "Erreiche eine Energieproduktion von 2",
                goalType: .reachEnergyProduction,
                targetAmount: 2,
                rewardHellCoin: 200
            ),
            Mission(
                title: "Beschwöre 3 Kreaturen",
                goalType: .summonCreatures,
                targetAmount: 3,
                rewardHellCoin: 250,
                rewardBloodCrystal: 5
            ),
            Mission(
                title: "Halte die Effizienz 2 Minuten über 80%",
                goalType: .keepEfficiencyAbove,
                targetAmount: 120,
                rewardHellCoin: 300,
                rewardBloodCrystal: 10
            )
        ]
    }

    static func evaluate(state: GameState, deltaTime: TimeInterval) {
        for mission in state.missions where !mission.isCompleted {
            switch mission.goalType {
            case .produceResource:
                if let resource = mission.targetResource {
                    mission.progress = state.lifetimeProduced[resource, default: 0]
                }
            case .buildBuildings:
                mission.progress = state.lifetimeBuildingsBuilt
            case .summonCreatures:
                mission.progress = state.lifetimeCreaturesSummoned
            case .reachEnergyProduction:
                mission.progress = Int(state.energy.production)
            case .keepEfficiencyAbove:
                if state.efficiency >= efficiencyMissionThreshold {
                    mission.continuousSeconds += deltaTime
                } else {
                    mission.continuousSeconds = 0
                }
                mission.progress = Int(mission.continuousSeconds)
            }

            if mission.progress >= mission.targetAmount {
                mission.isCompleted = true
            }
        }
    }
}
