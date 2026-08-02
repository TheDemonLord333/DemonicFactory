//
//  BuildingLevelConfig.swift
//  DemonicFactory
//
//  Central, pure-function source of truth for how machines, storage and belts
//  scale with level — mirrors the pattern already established by
//  MissionScaling.swift. Nothing else hard-codes a per-level number: raising
//  maxBuildingLevel/maxBeltLevel later, or tweaking a curve, only means
//  editing this file.
//

import Foundation

enum BuildingLevelConfig {
    static let maxBuildingLevel = 10
    static let maxBeltLevel = 5

    // MARK: - Storage (exact per-level table from the design spec)

    private static let storageCapacityTable = [100, 150, 225, 325, 450, 600, 800, 1050, 1350, 1700]
    private static let storageOutputIntervalTable: [Double] = [1.5, 1.3, 1.1, 0.9, 0.75, 0.65, 0.55, 0.45, 0.38, 0.3]

    static func storageCapacity(level: Int) -> Int {
        storageCapacityTable[clampedIndex(level, count: storageCapacityTable.count)]
    }

    /// Seconds between automatic outputs onto a connected belt.
    static func storageOutputInterval(level: Int) -> Double {
        storageOutputIntervalTable[clampedIndex(level, count: storageOutputIntervalTable.count)]
    }

    // MARK: - Generic machine scaling
    //
    // Smooth formulas instead of a per-level switch, so raising
    // maxBuildingLevel doesn't require adding new cases — levels beyond the
    // table just keep compounding.

    /// ~7% faster processing per level, floored at 35% of the base time.
    static func machineProcessingTimeMultiplier(level: Int) -> Double {
        max(pow(0.93, Double(level - 1)), 0.35)
    }

    /// ~4% less energy draw per level, floored at 50% of the base draw.
    static func machineEnergyDrawMultiplier(level: Int) -> Double {
        max(pow(0.96, Double(level - 1)), 0.5)
    }

    // MARK: - Belts

    private static let beltSpeedTable: [Double] = [1.0, 1.5, 2.25, 3.25, 4.5]

    /// Tiles travelled per second at this belt level.
    static func beltSpeed(level: Int) -> Double {
        beltSpeedTable[clampedIndex(level, count: beltSpeedTable.count)]
    }

    static let beltUpgradeBaseCost = 20

    static func beltUpgradeCost(fromLevel level: Int) -> Int {
        upgradeCost(baseCost: beltUpgradeBaseCost, fromLevel: level)
    }

    // MARK: - Shared upgrade cost formula

    /// upgradeCost = baseCost × 1.65^(currentLevel - 1)
    static func upgradeCost(baseCost: Int, fromLevel level: Int) -> Int {
        Int((Double(baseCost) * pow(1.65, Double(level - 1))).rounded())
    }

    private static func clampedIndex(_ level: Int, count: Int) -> Int {
        max(0, min(count - 1, level - 1))
    }
}
