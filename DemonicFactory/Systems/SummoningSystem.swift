//
//  SummoningSystem.swift
//  DemonicFactory
//
//  Weighted-random creature summoning. Uses GameplayKit's random source so the
//  roll is easy to swap for a seeded/deterministic source later (e.g. for
//  pity timers or scripted mission rewards) without touching call sites.
//

import GameplayKit

enum SummoningSystem {
    static let blueprints: [CreatureBlueprint] = [
        CreatureBlueprint(
            type: .imp, rarity: .common, maxHP: 20, attack: 3, speed: 1.2,
            specialAbility: "Flink", sellValue: 15, energyUpkeep: 0.5, role: .worker
        ),
        CreatureBlueprint(
            type: .skeletonWorker, rarity: .uncommon, maxHP: 35, attack: 5, speed: 0.9,
            specialAbility: "Lastenträger", sellValue: 30, energyUpkeep: 1.0, role: .worker
        ),
        CreatureBlueprint(
            type: .shadowHound, rarity: .rare, maxHP: 50, attack: 12, speed: 1.6,
            specialAbility: "Schattensprung", sellValue: 70, energyUpkeep: 2.0, role: .guardian
        )
    ]

    /// Percentage weights, aligned index-for-index with `blueprints`.
    private static let weights = [65, 25, 10]

    @discardableResult
    static func summon(near point: GridPoint, state: GameState) -> Creature {
        let roll = GKRandomSource.sharedRandom().nextInt(upperBound: 100) + 1
        var cumulative = 0
        var chosen = blueprints[0]
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if roll <= cumulative {
                chosen = blueprints[index]
                break
            }
        }

        let name = "\(chosen.type.displayName) #\(state.lifetimeCreaturesSummoned + 1)"
        let creature = Creature(blueprint: chosen, name: name, gridPosition: point)
        state.creatures.append(creature)
        state.lifetimeCreaturesSummoned += 1
        return creature
    }
}
