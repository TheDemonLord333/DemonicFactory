//
//  SKSymbol.swift
//  DemonicFactory
//
//  Renders SF Symbols as SKSpriteNodes so machines, resources and UI elements
//  share one icon set without bundling custom art for the prototype.
//

import SpriteKit
import UIKit

extension SKSpriteNode {
    static func symbol(_ name: String, pointSize: CGFloat, color: UIColor) -> SKSpriteNode {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let base = UIImage(systemName: name, withConfiguration: config) ?? UIImage()
        let tinted = base.withTintColor(color, renderingMode: .alwaysOriginal)
        return SKSpriteNode(texture: SKTexture(image: tinted))
    }
}
