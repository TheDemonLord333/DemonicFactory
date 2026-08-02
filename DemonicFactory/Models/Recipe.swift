//
//  Recipe.swift
//  DemonicFactory
//
//  Production recipes are pure data, never hard-coded inside a view or system.
//  RecipeDatabase (Systems/RecipeDatabase.swift) is the single place that wires
//  a BuildingType to its Recipe.
//

import Foundation

struct Recipe: Identifiable {
    let id: String
    let building: BuildingType
    /// Resources consumed from the machine's input buffer per cycle.
    let inputs: [ResourceType: Int]
    /// Resource produced per cycle, written to the output buffer — unless
    /// `producesCreature` or `feedsEnergyPool` redirect it (see ProductionSystem).
    let output: ResourceType?
    let outputAmount: Int
    let processingTime: TimeInterval
    /// Continuous power draw from the global energy pool while a cycle is active.
    let energyDrawPerSecond: Double
    /// When true, output is added to GameState.energy.stored instead of a buffer
    /// (this is how Höllenöfen feed the factory's power grid).
    let feedsEnergyPool: Bool
    /// When true, a finished cycle summons a creature instead of producing a resource.
    let producesCreature: Bool
    let experienceReward: Int

    func processingTime(level: Int) -> TimeInterval {
        processingTime * BuildingLevelConfig.machineProcessingTimeMultiplier(level: level)
    }

    func energyDraw(level: Int) -> Double {
        energyDrawPerSecond * BuildingLevelConfig.machineEnergyDrawMultiplier(level: level)
    }
}
