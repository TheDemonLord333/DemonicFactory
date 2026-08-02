//
//  HexColor.swift
//  DemonicFactory
//
//  Central color palette shared by SwiftUI (menus) and SpriteKit (factory scene).
//

import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    /// Linear RGB interpolation towards `other`. UIKit has no equivalent of
    /// AppKit's `NSColor.blended(withFraction:of:)`, so this fills the gap.
    func mixed(with other: UIColor, fraction: CGFloat) -> UIColor {
        let t = max(0, min(1, fraction))
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red: r1 + (r2 - r1) * t,
            green: g1 + (g2 - g1) * t,
            blue: b1 + (b2 - b1) * t,
            alpha: a1 + (a2 - a1) * t
        )
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// Shared "hell-industrial" palette. Defined once in hex so SwiftUI (`Color`) and
/// SpriteKit (`UIColor`, aliased as `SKColor` on iOS) always agree.
enum Palette {
    static let voidBlackHex: UInt32 = 0x09090D
    static let anthraciteHex: UInt32 = 0x16161F
    static let darkVioletHex: UInt32 = 0x2B174A
    static let violetHex: UInt32 = 0x7B2CFF
    static let blurpleHex: UInt32 = 0x5865F2
    static let soulGreenHex: UInt32 = 0x1ED760
    static let demonRedHex: UInt32 = 0xD51C3F
    static let lavaOrangeHex: UInt32 = 0xFF5A1F
    static let magentaHex: UInt32 = 0xD946EF
    static let goldHex: UInt32 = 0xF5B942

    static let voidBlack = Color(hex: voidBlackHex)
    static let anthracite = Color(hex: anthraciteHex)
    static let darkViolet = Color(hex: darkVioletHex)
    static let violet = Color(hex: violetHex)
    static let blurple = Color(hex: blurpleHex)
    static let soulGreen = Color(hex: soulGreenHex)
    static let demonRed = Color(hex: demonRedHex)
    static let lavaOrange = Color(hex: lavaOrangeHex)
    static let magenta = Color(hex: magentaHex)
    static let gold = Color(hex: goldHex)

    static let voidBlackUI = UIColor(hex: voidBlackHex)
    static let anthraciteUI = UIColor(hex: anthraciteHex)
    static let darkVioletUI = UIColor(hex: darkVioletHex)
    static let violetUI = UIColor(hex: violetHex)
    static let blurpleUI = UIColor(hex: blurpleHex)
    static let soulGreenUI = UIColor(hex: soulGreenHex)
    static let demonRedUI = UIColor(hex: demonRedHex)
    static let lavaOrangeUI = UIColor(hex: lavaOrangeHex)
    static let magentaUI = UIColor(hex: magentaHex)
    static let goldUI = UIColor(hex: goldHex)
}
