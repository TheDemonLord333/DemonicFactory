//
//  BuildingType.swift
//  DemonicFactory
//
//  Central catalog of buildable machines. Adding a new machine to the game means
//  adding a case here plus a matching Recipe in RecipeDatabase — no view or system
//  code needs to change.
//

import SwiftUI
import UIKit

enum BuildingCategory: String, Codable {
    case production
    case logistics
    case portal
}

enum BuildingType: String, Codable, CaseIterable, Identifiable {
    case soulSource
    case soulPress
    case hellFurnace
    case demonForge
    case summoningPortal
    case storage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .soulSource: return "Seelenquelle"
        case .soulPress: return "Seelenpresse"
        case .hellFurnace: return "Höllenofen"
        case .demonForge: return "Dämonenschmiede"
        case .summoningPortal: return "Beschwörungsportal"
        case .storage: return "Lager"
        }
    }

    var flavorText: String {
        switch self {
        case .soulSource: return "Zieht automatisch Seelenfragmente aus dem Höllenboden."
        case .soulPress: return "Presst Seelenfragmente zu verdichteten Seelen."
        case .hellFurnace: return "Verbrennt verdichtete Seelen zu dunkler Energie."
        case .demonForge: return "Formt aus dunkler Energie einen Dämonenkern."
        case .summoningPortal: return "Beschwört Kreaturen aus Dämonenkernen."
        case .storage: return "Lagert überschüssige Materialien."
        }
    }

    var category: BuildingCategory {
        switch self {
        case .storage: return .logistics
        case .summoningPortal: return .portal
        default: return .production
        }
    }

    var iconSystemName: String {
        switch self {
        case .soulSource: return "sparkles"
        case .soulPress: return "arrow.down.to.line"
        case .hellFurnace: return "flame.fill"
        case .demonForge: return "hammer.fill"
        case .summoningPortal: return "tornado"
        case .storage: return "shippingbox.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .soulSource: return Palette.violet
        case .soulPress: return Palette.blurple
        case .hellFurnace: return Palette.lavaOrange
        case .demonForge: return Palette.demonRed
        case .summoningPortal: return Palette.magenta
        case .storage: return Palette.gold
        }
    }

    var themeColorUI: UIColor {
        switch self {
        case .soulSource: return Palette.violetUI
        case .soulPress: return Palette.blurpleUI
        case .hellFurnace: return Palette.lavaOrangeUI
        case .demonForge: return Palette.demonRedUI
        case .summoningPortal: return Palette.magentaUI
        case .storage: return Palette.goldUI
        }
    }

    /// Footprint in tiles. All 1x1 for the first playable version; larger machines
    /// can extend this later without touching placement logic (see FactoryScene).
    var footprint: (width: Int, height: Int) { (1, 1) }

    var baseHellCoinCost: Int {
        switch self {
        case .soulSource: return 60
        case .soulPress: return 40
        case .hellFurnace: return 120
        case .demonForge: return 220
        case .summoningPortal: return 300
        case .storage: return 25
        }
    }

    var maxLevel: Int { BuildingLevelConfig.maxBuildingLevel }

    /// Internal input/output buffer capacity per unit before the machine blocks.
    /// Storage uses its own much larger table since it *is* the buffer.
    func bufferCapacity(level: Int) -> Int {
        switch self {
        case .storage: return BuildingLevelConfig.storageCapacity(level: level)
        default: return 12 + (level - 1) * 6
        }
    }

    func upgradeCost(fromLevel level: Int) -> Int {
        BuildingLevelConfig.upgradeCost(baseCost: baseHellCoinCost, fromLevel: level)
    }

    /// Machines the player can already build at the very start of the game.
    static var starterAvailable: [BuildingType] { allCases }
}
