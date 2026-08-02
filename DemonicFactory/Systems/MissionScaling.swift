//
//  MissionScaling.swift
//  DemonicFactory
//
//  Central, pure-function source of truth for mission leveling: base values,
//  per-level target tables (with a formula beyond the last defined level),
//  reward curves, and title text. Nothing else in the app hard-codes a
//  mission number — Mission.swift and MissionSystem.swift both call through
//  here, so adding a new mission type only means adding a case below.
//

import Foundation

enum MissionScaling {

    // MARK: - Base values (level 1)

    static func baseTarget(goalType: MissionGoalType, targetResource: ResourceType?) -> Int {
        switch (goalType, targetResource) {
        case (.produceResource, .some(.soulFragment)): return 50
        case (.produceResource, .some(.compressedSoul)): return 10
        case (.buildBuildings, _): return 5
        case (.reachEnergyProduction, _): return 2
        case (.summonCreatures, _): return 3
        case (.keepEfficiencyAbove, _): return 120
        default: return 1
        }
    }

    static func baseGoldReward(goalType: MissionGoalType, targetResource: ResourceType?) -> Int {
        switch (goalType, targetResource) {
        case (.produceResource, .some(.soulFragment)): return 100
        case (.produceResource, .some(.compressedSoul)): return 150
        case (.buildBuildings, _): return 120
        case (.reachEnergyProduction, _): return 200
        case (.summonCreatures, _): return 250
        case (.keepEfficiencyAbove, _): return 300
        default: return 50
        }
    }

    static func baseBloodCrystalReward(goalType: MissionGoalType, targetResource: ResourceType?) -> Int {
        switch (goalType, targetResource) {
        case (.buildBuildings, _): return 3
        case (.summonCreatures, _): return 5
        case (.keepEfficiencyAbove, _): return 10
        default: return 0
        }
    }

    // MARK: - Level-scaled target

    static func target(goalType: MissionGoalType, targetResource: ResourceType?, level: Int) -> Int {
        switch (goalType, targetResource) {
        case (.produceResource, .some(.soulFragment)):
            return scaledTarget(table: soulFragmentTable, multiplier: 1.25, level: level, round: MissionRounding.tieredSmall)
        case (.produceResource, .some(.compressedSoul)):
            return scaledTarget(table: compressedSoulTable, multiplier: 1.23, level: level, round: MissionRounding.tieredMedium)
        case (.buildBuildings, _):
            return scaledTarget(table: buildMachinesTable, multiplier: 1.22, level: level, round: MissionRounding.ceilInt)
        case (.reachEnergyProduction, _):
            return scaledTarget(table: energyTable, multiplier: 1.22, level: level, round: MissionRounding.ceilInt)
        case (.summonCreatures, _):
            return scaledTarget(table: summonTable, multiplier: 1.24, level: level, round: MissionRounding.ceilInt)
        case (.keepEfficiencyAbove, _):
            return scaledTarget(table: efficiencyTable, multiplier: 1.20, level: level, round: MissionRounding.nearestUp30)
        default:
            return baseTarget(goalType: goalType, targetResource: targetResource)
        }
    }

    // MARK: - Rewards

    /// goldReward = baseGoldReward × 1.22^(level-1), rounded to a player-friendly step.
    static func goldReward(goalType: MissionGoalType, targetResource: ResourceType?, level: Int) -> Int {
        let base = baseGoldReward(goalType: goalType, targetResource: targetResource)
        let raw = Double(base) * pow(1.22, Double(level - 1))
        return MissionRounding.goldRounding(raw)
    }

    /// Blood crystals scale far slower than gold: a fixed percent table through
    /// level 10, then a flatter formula. Missions with a 0 base never grant any.
    static func bloodCrystalReward(goalType: MissionGoalType, targetResource: ResourceType?, level: Int) -> Int {
        let base = baseBloodCrystalReward(goalType: goalType, targetResource: targetResource)
        guard base > 0 else { return 0 }
        if level <= bloodCrystalPercentTable.count {
            return Int((Double(base) * bloodCrystalPercentTable[level - 1]).rounded(.up))
        }
        let multiplier = 1.0 + 0.20 * Double((level - 1) / 2)
        // The raw formula dips below the level-10 percentage for several levels
        // (integer floor division stalls at each odd level) before catching back
        // up — a mission stage should never pay less than the previous one, so
        // floor at the last table percentage instead of letting it regress.
        let flooredMultiplier = max(multiplier, bloodCrystalPercentTable[bloodCrystalPercentTable.count - 1])
        return Int((Double(base) * flooredMultiplier).rounded(.up))
    }

    // MARK: - Title

    static func title(goalType: MissionGoalType, targetResource: ResourceType?, targetAmount: Int) -> String {
        switch (goalType, targetResource) {
        case (.produceResource, .some(.soulFragment)):
            return "Produziere \(NumberFormat.german(targetAmount)) Seelenfragmente"
        case (.produceResource, .some(.compressedSoul)):
            return "Stelle \(NumberFormat.german(targetAmount)) verdichtete Seelen her"
        case (.buildBuildings, _):
            return "Baue \(NumberFormat.german(targetAmount)) Maschinen"
        case (.reachEnergyProduction, _):
            return "Erreiche eine Energieproduktion von \(NumberFormat.german(targetAmount))"
        case (.summonCreatures, _):
            return "Beschwöre \(NumberFormat.german(targetAmount)) Kreaturen"
        case (.keepEfficiencyAbove, _):
            return "Halte die Effizienz \(NumberFormat.minutesSeconds(targetAmount)) über 80% aktiv"
        default:
            return "Mission"
        }
    }

    // MARK: - Level 1-10 tables (level 11+ uses the formula above each table)

    private static let soulFragmentTable = [50, 75, 100, 130, 170, 220, 280, 350, 440, 550]
    private static let compressedSoulTable = [10, 15, 20, 30, 40, 55, 70, 90, 120, 150]
    private static let buildMachinesTable = [5, 7, 10, 13, 17, 22, 28, 35, 45, 60]
    private static let energyTable = [2, 4, 7, 11, 16, 22, 30, 40, 52, 67]
    private static let summonTable = [3, 5, 8, 12, 17, 24, 32, 42, 55, 70]
    private static let efficiencyTable = [120, 180, 240, 300, 420, 540, 720, 900, 1200, 1500]
    private static let bloodCrystalPercentTable: [Double] = [1.0, 1.0, 1.2, 1.2, 1.4, 1.6, 1.8, 2.0, 2.4, 3.0]

    private static func scaledTarget(table: [Int], multiplier: Double, level: Int, round: (Double) -> Int) -> Int {
        guard level > table.count else { return table[max(0, level - 1)] }
        var current = table[table.count - 1]
        var reachedLevel = table.count
        while reachedLevel < level {
            current = round(Double(current) * multiplier)
            reachedLevel += 1
        }
        return current
    }
}

private enum MissionRounding {
    /// <100 -> nearest 5, 100..<1000 -> nearest 10, >=1000 -> nearest 50.
    static func tieredSmall(_ value: Double) -> Int {
        let step: Double = value < 100 ? 5 : (value < 1000 ? 10 : 50)
        return Int((value / step).rounded()) * Int(step)
    }

    /// <100 -> nearest 5, >=100 -> nearest 10.
    static func tieredMedium(_ value: Double) -> Int {
        let step: Double = value < 100 ? 5 : 10
        return Int((value / step).rounded()) * Int(step)
    }

    static func ceilInt(_ value: Double) -> Int { Int(value.rounded(.up)) }

    static func nearestUp30(_ value: Double) -> Int {
        Int((value / 30).rounded(.up)) * 30
    }

    /// <500 -> nearest 5, 500..<2000 -> nearest 10, 2000..<10000 -> nearest 50, else nearest 100.
    static func goldRounding(_ value: Double) -> Int {
        let step: Double
        switch value {
        case ..<500: step = 5
        case ..<2000: step = 10
        case ..<10000: step = 50
        default: step = 100
        }
        return Int((value / step).rounded()) * Int(step)
    }
}
