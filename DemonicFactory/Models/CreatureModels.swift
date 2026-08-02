//
//  CreatureModels.swift
//  DemonicFactory
//

import SwiftUI
import UIKit
import CoreGraphics

enum CreatureType: String, Codable, CaseIterable, Identifiable {
    case imp
    case skeletonWorker
    case shadowHound
    // Reserved for later content — DemonGuardian, SoulMage, LavaGolem, VoidBeast,
    // DemonLord — the summoning system just needs a new case + entry in
    // SummoningSystem.pool to unlock them.

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .imp: return "Imp"
        case .skeletonWorker: return "Skelettarbeiter"
        case .shadowHound: return "Schattenhund"
        }
    }

    var iconSystemName: String {
        switch self {
        case .imp: return "flame"
        case .skeletonWorker: return "figure.walk"
        case .shadowHound: return "pawprint.fill"
        }
    }
}

enum Rarity: String, Codable, CaseIterable, Comparable {
    case common, uncommon, rare, epic, legendary, cursed

    private var sortOrder: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        case .cursed: return 5
        }
    }

    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.sortOrder < rhs.sortOrder }

    var displayName: String {
        switch self {
        case .common: return "Gewöhnlich"
        case .uncommon: return "Ungewöhnlich"
        case .rare: return "Selten"
        case .epic: return "Episch"
        case .legendary: return "Legendär"
        case .cursed: return "Verflucht"
        }
    }

    var frameColor: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return Palette.soulGreen
        case .rare: return Palette.blurple
        case .epic: return Palette.violet
        case .legendary: return Palette.gold
        case .cursed: return Palette.demonRed
        }
    }

    var frameColorUI: UIColor {
        switch self {
        case .common: return .gray
        case .uncommon: return Palette.soulGreenUI
        case .rare: return Palette.blurpleUI
        case .epic: return Palette.violetUI
        case .legendary: return Palette.goldUI
        case .cursed: return Palette.demonRedUI
        }
    }

    /// Cursed creatures get a flickering particle treatment; everything else stays static.
    var hasFlickeringParticles: Bool { self == .cursed }
}

enum CreatureRole: String, Codable, CaseIterable {
    case worker
    case guardian
    case mage
    case sacrifice
    case collector

    var displayName: String {
        switch self {
        case .worker: return "Arbeiter"
        case .guardian: return "Wächter"
        case .mage: return "Magier"
        case .sacrifice: return "Opferkreatur"
        case .collector: return "Sammler"
        }
    }
}

struct CreatureBlueprint {
    let type: CreatureType
    let rarity: Rarity
    let maxHP: Int
    let attack: Int
    let speed: Double
    let specialAbility: String
    let sellValue: Int
    let energyUpkeep: Double
    let role: CreatureRole
}

final class Creature: Identifiable {
    let id: UUID
    let type: CreatureType
    let rarity: Rarity
    var name: String
    let maxHP: Int
    var hp: Int
    let attack: Int
    let speed: Double
    let specialAbility: String
    let sellValue: Int
    let energyUpkeep: Double
    let role: CreatureRole
    var gridPosition: GridPoint
    var wanderTarget: GridPoint
    /// Continuous scene-space position, interpolated towards `wanderTarget` each tick.
    var position: CGPoint

    init(id: UUID = UUID(), blueprint: CreatureBlueprint, name: String, gridPosition: GridPoint) {
        self.id = id
        self.type = blueprint.type
        self.rarity = blueprint.rarity
        self.name = name
        self.maxHP = blueprint.maxHP
        self.hp = blueprint.maxHP
        self.attack = blueprint.attack
        self.speed = blueprint.speed
        self.specialAbility = blueprint.specialAbility
        self.sellValue = blueprint.sellValue
        self.energyUpkeep = blueprint.energyUpkeep
        self.role = blueprint.role
        self.gridPosition = gridPosition
        self.wanderTarget = gridPosition
        self.position = GridMath.scenePosition(for: gridPosition)
    }
}
