//
//  EfficiencySystem.swift
//  DemonicFactory
//
//  Computes the factory efficiency percentage and a human-readable list of
//  concrete problems, shown when the player taps the efficiency readout.
//

import Foundation

enum EfficiencySystem {
    static func recompute(state: GameState, deltaTime: TimeInterval) {
        let productionBuildings = state.buildings.filter { $0.type != .storage }

        guard !productionBuildings.isEmpty else {
            state.efficiency = 100
            state.efficiencyIssues = []
            return
        }

        var issues: [String] = []
        var seenCount: [BuildingType: Int] = [:]
        var idleCount = 0

        for building in productionBuildings {
            seenCount[building.type, default: 0] += 1
            let label = "\(building.type.displayName) \(seenCount[building.type]!)"

            guard !building.isActive else { continue }
            idleCount += 1

            if building.isBlocked {
                issues.append("\(label): Ausgang ist blockiert oder Lager voll")
            } else if let recipe = RecipeDatabase.recipe(for: building.type), !recipe.inputs.isEmpty {
                issues.append("\(label): wartet auf Eingangsressourcen")
            } else if let recipe = RecipeDatabase.recipe(for: building.type), recipe.energyDrawPerSecond > 0 {
                issues.append("\(label): nicht genug Energie")
            }
        }

        var score = 100.0
        score -= (Double(idleCount) / Double(productionBuildings.count)) * 60

        if state.energy.isDeficit {
            score -= 15
            issues.append("Energieverbrauch übersteigt die Produktion")
        }

        let jammedLines = state.beltLines.filter(\.isJammed)
        if !jammedLines.isEmpty {
            score -= Double(jammedLines.count) * 5
            issues.append("\(jammedLines.count) Förderbandbereich(e) sind blockiert")
        }

        state.efficiency = max(0, min(100, score))
        state.efficiencyIssues = issues
    }
}
