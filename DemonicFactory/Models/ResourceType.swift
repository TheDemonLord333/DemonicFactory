//
//  ResourceType.swift
//  DemonicFactory
//

import SwiftUI
import UIKit

enum ResourceType: String, Codable, CaseIterable, Identifiable {
    case soulFragment
    case compressedSoul
    case hellsteel
    case darkEnergy
    case bloodCrystal
    case demonCore
    case voidEssence
    case hellCoin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .soulFragment: return "Seelenfragment"
        case .compressedSoul: return "Verdichtete Seele"
        case .hellsteel: return "Höllenstahl"
        case .darkEnergy: return "Dunkle Energie"
        case .bloodCrystal: return "Blutkristall"
        case .demonCore: return "Dämonenkern"
        case .voidEssence: return "Leerenessenz"
        case .hellCoin: return "Höllenmünze"
        }
    }

    var iconSystemName: String {
        switch self {
        case .soulFragment: return "circle.fill"
        case .compressedSoul: return "hexagon.fill"
        case .hellsteel: return "square.fill"
        case .darkEnergy: return "bolt.fill"
        case .bloodCrystal: return "diamond.fill"
        case .demonCore: return "seal.fill"
        case .voidEssence: return "moon.stars.fill"
        case .hellCoin: return "dollarsign.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .soulFragment: return Palette.violet
        case .compressedSoul: return Palette.blurple
        case .hellsteel: return .gray
        case .darkEnergy: return Palette.soulGreen
        case .bloodCrystal: return Palette.demonRed
        case .demonCore: return Palette.magenta
        case .voidEssence: return Palette.blurple
        case .hellCoin: return Palette.gold
        }
    }

    var colorUI: UIColor {
        switch self {
        case .soulFragment: return Palette.violetUI
        case .compressedSoul: return Palette.blurpleUI
        case .hellsteel: return .gray
        case .darkEnergy: return Palette.soulGreenUI
        case .bloodCrystal: return Palette.demonRedUI
        case .demonCore: return Palette.magentaUI
        case .voidEssence: return Palette.blurpleUI
        case .hellCoin: return Palette.goldUI
        }
    }

    /// True for resources that live in the player's global warehouse (shown in the
    /// top bar) rather than only inside local machine/belt buffers.
    var isGlobalCurrency: Bool {
        switch self {
        case .hellCoin, .bloodCrystal, .voidEssence, .darkEnergy: return true
        default: return false
        }
    }
}
