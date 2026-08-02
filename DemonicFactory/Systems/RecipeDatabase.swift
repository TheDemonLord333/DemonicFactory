//
//  RecipeDatabase.swift
//  DemonicFactory
//
//  Central definition of every production chain in the game:
//
//    Seelenfragment --(Seelenpresse)--> Verdichtete Seele
//    Verdichtete Seele --(Höllenofen)--> Dunkle Energie (feeds the power grid)
//    (Dunkle Energie) --(Dämonenschmiede)--> Dämonenkern
//    Dämonenkern --(Beschwörungsportal)--> Kreatur
//
//  Nothing outside this file should hard-code processing times, inputs or
//  outputs — machines just look up their recipe here.
//

import Foundation

enum RecipeDatabase {
    static let all: [Recipe] = [
        Recipe(
            id: "soulSource",
            building: .soulSource,
            inputs: [:],
            output: .soulFragment,
            outputAmount: 1,
            processingTime: 4.0,
            energyDrawPerSecond: 0,
            feedsEnergyPool: false,
            producesCreature: false,
            experienceReward: 1
        ),
        Recipe(
            id: "soulPress",
            building: .soulPress,
            inputs: [.soulFragment: 3],
            output: .compressedSoul,
            outputAmount: 1,
            processingTime: 3.5,
            energyDrawPerSecond: 0,
            feedsEnergyPool: false,
            producesCreature: false,
            experienceReward: 2
        ),
        Recipe(
            id: "hellFurnace",
            building: .hellFurnace,
            inputs: [.compressedSoul: 2],
            output: .darkEnergy,
            outputAmount: 4,
            processingTime: 4.0,
            energyDrawPerSecond: 0,
            feedsEnergyPool: true,
            producesCreature: false,
            experienceReward: 4
        ),
        Recipe(
            id: "demonForge",
            building: .demonForge,
            inputs: [:],
            output: .demonCore,
            outputAmount: 1,
            processingTime: 6.0,
            energyDrawPerSecond: 6.0,
            feedsEnergyPool: false,
            producesCreature: false,
            experienceReward: 8
        ),
        Recipe(
            id: "summoningPortal",
            building: .summoningPortal,
            inputs: [.demonCore: 1],
            output: nil,
            outputAmount: 0,
            processingTime: 5.0,
            energyDrawPerSecond: 10.0,
            feedsEnergyPool: false,
            producesCreature: true,
            experienceReward: 15
        )
    ]

    private static let byBuilding: [BuildingType: Recipe] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.building, $0) }
    )

    static func recipe(for building: BuildingType) -> Recipe? {
        byBuilding[building]
    }
}
