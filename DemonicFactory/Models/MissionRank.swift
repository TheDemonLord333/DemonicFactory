//
//  MissionRank.swift
//  DemonicFactory
//
//  Purely derived from a mission's level — never stored. Levels 1-30 map to
//  six five-step tiers (Bronze I ... Höllisch V); level 31+ is the uncapped
//  "Dämonisch" tier.
//

import SwiftUI

enum MissionRankTier: Int, CaseIterable {
    case bronze, silver, gold, platinum, diamond, hellish, demonic

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silber"
        case .gold: return "Gold"
        case .platinum: return "Platin"
        case .diamond: return "Diamant"
        case .hellish: return "Höllisch"
        case .demonic: return "Dämonisch"
        }
    }

    var color: Color {
        switch self {
        case .bronze: return Color(hex: 0xB8763B)
        case .silver: return Color(hex: 0xC9CDD3)
        case .gold: return Palette.gold
        case .platinum: return Color(hex: 0x9FE0FF)
        case .diamond: return Color(hex: 0x4BE0D6)
        case .hellish: return Color(hex: 0x8B0F1E)
        case .demonic: return Palette.demonRed
        }
    }

    /// Only Dämonisch gets the extra "kräftiges Rot mit violettem Leuchten" glow.
    var glowColor: Color? {
        self == .demonic ? Palette.violet : nil
    }
}

struct MissionRank: Equatable {
    let tier: MissionRankTier
    /// 1...5 for Bronze through Höllisch; nil for the uncapped Dämonisch tier.
    let subLevel: Int?

    var displayName: String {
        guard let subLevel else { return tier.displayName }
        return "\(tier.displayName) \(Self.roman(subLevel))"
    }

    var color: Color { tier.color }
    var glowColor: Color? { tier.glowColor }

    static func forLevel(_ level: Int) -> MissionRank {
        guard level < 31 else { return MissionRank(tier: .demonic, subLevel: nil) }
        let zeroBased = max(0, level - 1)
        let tierIndex = zeroBased / 5
        let sub = zeroBased % 5 + 1
        let tier = MissionRankTier(rawValue: tierIndex) ?? .demonic
        return MissionRank(tier: tier, subLevel: sub)
    }

    private static func roman(_ n: Int) -> String {
        ["I", "II", "III", "IV", "V"][max(0, min(4, n - 1))]
    }
}
