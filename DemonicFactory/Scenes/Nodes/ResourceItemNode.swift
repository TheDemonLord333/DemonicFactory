//
//  ResourceItemNode.swift
//  DemonicFactory
//
//  A single animated resource unit riding a conveyor belt.
//

import SpriteKit

final class ResourceItemNode: SKNode {
    init(resource: ResourceType) {
        super.init()

        let circle = SKShapeNode(circleOfRadius: 8)
        circle.fillColor = resource.colorUI
        circle.strokeColor = SKColor.white.withAlphaComponent(0.5)
        circle.lineWidth = 1
        circle.glowWidth = 2
        addChild(circle)

        let icon = SKSpriteNode.symbol(resource.iconSystemName, pointSize: 8, color: .white)
        icon.alpha = 0.9
        addChild(icon)

        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 2, duration: 0.5),
            .moveBy(x: 0, y: -2, duration: 0.5)
        ])))
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
