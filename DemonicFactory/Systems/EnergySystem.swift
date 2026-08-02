//
//  EnergySystem.swift
//  DemonicFactory
//
//  Recomputes the factory-wide production/consumption rates shown in the top
//  bar. The actual stored pool is mutated by ProductionSystem as machines run;
//  this system only reports rates and mirrors the pool into `resources` so the
//  rest of the game (missions, UI) can treat dark energy like any other stock.
//

import Foundation

enum EnergySystem {
    static func recompute(state: GameState) {
        var production: Double = 0
        var consumption: Double = 0

        for building in state.buildings {
            guard let recipe = RecipeDatabase.recipe(for: building.type), building.isActive else { continue }
            if recipe.feedsEnergyPool {
                production += Double(recipe.outputAmount) / recipe.processingTime(level: building.level)
            }
            let draw = recipe.energyDraw(level: building.level)
            if draw > 0 {
                consumption += draw
            }
        }

        state.energy.production = production
        state.energy.consumption = consumption
        state.resources[.darkEnergy] = Int(state.energy.stored)
    }
}
