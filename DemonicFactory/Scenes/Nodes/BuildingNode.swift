//
//  BuildingNode.swift
//  DemonicFactory
//
//  Visual representation of a FactoryBuilding. Procedural shapes + SF Symbols
//  stand in for bespoke art: a themed base, a pulsing glow while active, a
//  per-cycle progress bar, a jam/energy warning glyph, and a small particle
//  puff that matches the building's theme color.
//

import SpriteKit

final class BuildingNode: SKNode {
    let buildingID: UUID

    private let base: SKShapeNode
    private let glow: SKShapeNode
    private let icon: SKSpriteNode
    private let progressFill: SKSpriteNode
    private let warningLabel: SKLabelNode
    private let levelLabel: SKLabelNode
    private let emitter: SKEmitterNode
    private let selectionRing: SKShapeNode
    private let progressBarWidth: CGFloat

    init(building: FactoryBuilding) {
        buildingID = building.id
        let size = GridMath.tileSize * 0.82
        progressBarWidth = size * 0.8

        base = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 10)
        base.fillColor = Palette.anthraciteUI
        base.strokeColor = building.type.themeColorUI
        base.lineWidth = 2
        base.zPosition = 1

        glow = SKShapeNode(rectOf: CGSize(width: size + 8, height: size + 8), cornerRadius: 13)
        glow.fillColor = .clear
        glow.strokeColor = building.type.themeColorUI
        glow.lineWidth = 3
        glow.alpha = 0
        glow.blendMode = .add
        glow.zPosition = 0

        selectionRing = SKShapeNode(rectOf: CGSize(width: size + 14, height: size + 14), cornerRadius: 15)
        selectionRing.strokeColor = .white
        selectionRing.lineWidth = 2
        selectionRing.fillColor = .clear
        selectionRing.isHidden = true
        selectionRing.zPosition = 2

        icon = SKSpriteNode.symbol(building.type.iconSystemName, pointSize: size * 0.42, color: building.type.themeColorUI)
        icon.zPosition = 3

        let barBackground = SKSpriteNode(color: Palette.voidBlackUI, size: CGSize(width: progressBarWidth, height: 5))
        barBackground.position = CGPoint(x: 0, y: -size / 2 - 9)
        barBackground.zPosition = 3

        progressFill = SKSpriteNode(color: Palette.soulGreenUI, size: CGSize(width: progressBarWidth, height: 5))
        progressFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        progressFill.position = CGPoint(x: -progressBarWidth / 2, y: 0)
        progressFill.xScale = 0.001

        warningLabel = SKLabelNode(text: "⚠")
        warningLabel.fontSize = 15
        warningLabel.position = CGPoint(x: size / 2 - 8, y: size / 2 - 8)
        warningLabel.isHidden = true
        warningLabel.zPosition = 5

        levelLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        levelLabel.text = "Lv\(building.level)"
        levelLabel.fontSize = 10
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: -size / 2 + 4, y: size / 2 - 13)
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.zPosition = 3

        emitter = SKEmitterNode()
        emitter.particleTexture = ParticleTextureFactory.softCircle()
        emitter.particleBirthRate = 0
        emitter.particleLifetime = 0.8
        emitter.particlePositionRange = CGVector(dx: size * 0.5, dy: size * 0.2)
        emitter.particleSpeed = 18
        emitter.particleSpeedRange = 10
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.16
        emitter.particleScaleRange = 0.08
        emitter.particleAlpha = 0.85
        emitter.particleAlphaSpeed = -1.1
        emitter.particleColor = building.type.themeColorUI
        emitter.particleColorBlendFactor = 1
        emitter.position = CGPoint(x: 0, y: size * 0.08)
        emitter.zPosition = 4

        super.init()
        position = GridMath.scenePosition(for: building.gridPosition)
        zPosition = 10

        addChild(glow)
        addChild(base)
        addChild(selectionRing)
        addChild(icon)
        addChild(barBackground)
        barBackground.addChild(progressFill)
        addChild(warningLabel)
        addChild(levelLabel)
        addChild(emitter)

        playPlacementAnimation()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func playPlacementAnimation() {
        setScale(0.8)
        alpha = 0
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.25)
        scaleUp.timingMode = .easeOut
        run(.group([.fadeIn(withDuration: 0.2), scaleUp]))
        glow.run(.sequence([.fadeAlpha(to: 0.9, duration: 0.12), .fadeAlpha(to: 0, duration: 0.4)]))
    }

    func playUpgradeFlash() {
        glow.run(.sequence([.fadeAlpha(to: 1.0, duration: 0.1), .fadeAlpha(to: 0, duration: 0.5)]))
        run(.sequence([.scale(to: 1.12, duration: 0.12), .scale(to: 1.0, duration: 0.18)]))
    }

    func setSelected(_ selected: Bool) {
        selectionRing.isHidden = !selected
    }

    func update(with building: FactoryBuilding) {
        levelLabel.text = "Lv\(building.level)"

        guard RecipeDatabase.recipe(for: building.type) != nil else {
            // Storage has no production cycle — show buffer fill level instead,
            // and only warn once it's actually full (matches "volles Lager blockiert").
            let ratio = building.bufferCapacity > 0 ? CGFloat(building.totalInputStored) / CGFloat(building.bufferCapacity) : 0
            progressFill.xScale = max(0.001, min(1, ratio))
            progressFill.color = ratio > 0.9 ? Palette.demonRedUI : Palette.goldUI
            warningLabel.isHidden = ratio < 0.95
            emitter.particleBirthRate = 0
            if glow.alpha > 0.05 { glow.run(.fadeAlpha(to: 0, duration: 0.4)) }
            return
        }

        progressFill.xScale = max(0.001, min(1, CGFloat(building.progress)))
        progressFill.color = building.isActive ? Palette.soulGreenUI : Palette.demonRedUI.withAlphaComponent(0.7)

        warningLabel.isHidden = building.isActive

        if building.isActive {
            if emitter.particleBirthRate < 1 { emitter.particleBirthRate = 6 }
            if glow.alpha < 0.3 { glow.run(.fadeAlpha(to: 0.35, duration: 0.4)) }
        } else {
            emitter.particleBirthRate = 0
            if glow.alpha > 0.05 { glow.run(.fadeAlpha(to: 0, duration: 0.4)) }
        }
    }
}
