//
//  CreatureNode.swift
//  DemonicFactory
//

import SpriteKit

final class CreatureNode: SKNode {
    let creatureID: UUID
    private let rarityRing: SKShapeNode

    init(creature: Creature) {
        creatureID = creature.id
        let radius: CGFloat = 14

        let shadow = SKShapeNode(ellipseOf: CGSize(width: radius * 1.6, height: radius * 0.6))
        shadow.fillColor = .black
        shadow.strokeColor = .clear
        shadow.alpha = 0.35
        shadow.position = CGPoint(x: 0, y: -radius * 0.9)
        shadow.zPosition = 0

        rarityRing = SKShapeNode(circleOfRadius: radius)
        rarityRing.fillColor = Palette.anthraciteUI
        rarityRing.strokeColor = creature.rarity.frameColorUI
        rarityRing.lineWidth = 2.5
        rarityRing.zPosition = 1

        let icon = SKSpriteNode.symbol(creature.type.iconSystemName, pointSize: radius * 1.1, color: creature.rarity.frameColorUI)
        icon.zPosition = 2

        super.init()
        position = creature.position
        zPosition = 20
        addChild(shadow)
        addChild(rarityRing)
        addChild(icon)

        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3, duration: 0.6),
            .moveBy(x: 0, y: -3, duration: 0.6)
        ])), withKey: "idleBob")

        if creature.rarity.hasFlickeringParticles {
            rarityRing.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.4, duration: 0.15),
                .fadeAlpha(to: 1.0, duration: 0.25)
            ])))
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func sync(with creature: Creature) {
        position = creature.position
    }
}
