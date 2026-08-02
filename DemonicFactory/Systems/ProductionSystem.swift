//
//  ProductionSystem.swift
//  DemonicFactory
//
//  Advances every machine's recipe cycle by one tick. A machine only progresses
//  when its inputs are available, the global energy pool can cover its draw, and
//  there's room for its output — otherwise it freezes (visibly, via isActive) and
//  EfficiencySystem reports why.
//

import Foundation

enum ProductionSystem {
    static func advance(state: GameState, deltaTime: TimeInterval) {
        for building in state.buildings {
            guard let recipe = RecipeDatabase.recipe(for: building.type) else {
                building.isActive = false
                continue
            }

            let inputsReady = recipe.inputs.allSatisfy { building.inputBuffer[$0.key, default: 0] >= $0.value }
            let energyReady = recipe.energyDrawPerSecond == 0 || state.energy.stored > 0
            let outputHasRoom = hasOutputRoom(building: building, recipe: recipe, state: state)

            guard inputsReady && energyReady && outputHasRoom else {
                building.isActive = false
                building.isBlocked = inputsReady && energyReady && !outputHasRoom
                continue
            }

            building.isActive = true
            building.isBlocked = false

            let time = recipe.processingTime(level: building.level)
            building.progress += deltaTime / time

            let draw = recipe.energyDraw(level: building.level)
            if draw > 0 {
                state.energy.stored = max(0, state.energy.stored - draw * deltaTime)
            }

            if building.progress >= 1 {
                building.progress = 0
                for (resource, amount) in recipe.inputs {
                    building.inputBuffer[resource, default: 0] -= amount
                }
                completeCycle(building: building, recipe: recipe, state: state)
                state.grantXP(recipe.experienceReward)
            }
        }
    }

    private static func hasOutputRoom(building: FactoryBuilding, recipe: Recipe, state: GameState) -> Bool {
        if recipe.producesCreature { return true }
        if recipe.feedsEnergyPool { return state.energy.stored < state.energy.capacity }
        guard let output = recipe.output else { return true }
        return building.outputBuffer[output, default: 0] + recipe.outputAmount <= building.bufferCapacity
    }

    private static func completeCycle(building: FactoryBuilding, recipe: Recipe, state: GameState) {
        if recipe.producesCreature {
            SummoningSystem.summon(near: building.gridPosition, state: state)
            return
        }
        if recipe.feedsEnergyPool {
            state.energy.stored = min(state.energy.capacity, state.energy.stored + Double(recipe.outputAmount))
            state.lifetimeProduced[.darkEnergy, default: 0] += recipe.outputAmount
            return
        }
        guard let output = recipe.output else { return }
        building.outputBuffer[output, default: 0] += recipe.outputAmount
        state.lifetimeProduced[output, default: 0] += recipe.outputAmount
    }
}
