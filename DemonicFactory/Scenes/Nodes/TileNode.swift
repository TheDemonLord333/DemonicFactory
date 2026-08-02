//
//  TileNode.swift
//  DemonicFactory
//

import SpriteKit

final class TileNode: SKShapeNode {
    let gridPoint: GridPoint

    init(gridPoint: GridPoint, terrain: TerrainType) {
        self.gridPoint = gridPoint
        super.init()

        let size = GridMath.tileSize
        path = CGPath(
            roundedRect: CGRect(x: -size / 2 + 1, y: -size / 2 + 1, width: size - 2, height: size - 2),
            cornerWidth: 6, cornerHeight: 6, transform: nil
        )
        position = GridMath.scenePosition(for: gridPoint)
        lineWidth = 1
        strokeColor = Palette.anthraciteUI.withAlphaComponent(0.7)
        zPosition = 0

        switch terrain {
        case .normal:
            fillColor = Palette.anthraciteUI.withAlphaComponent(0.55)
        case .blocked:
            fillColor = Palette.voidBlackUI
        case .lava:
            fillColor = Palette.lavaOrangeUI.withAlphaComponent(0.35)
            addGlow(color: Palette.lavaOrangeUI)
        case .crack:
            fillColor = Palette.demonRedUI.withAlphaComponent(0.18)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func addGlow(color: SKColor) {
        let glow = SKShapeNode(circleOfRadius: GridMath.tileSize * 0.28)
        glow.fillColor = color
        glow.strokeColor = .clear
        glow.alpha = 0.5
        glow.blendMode = .add
        glow.zPosition = -1
        addChild(glow)
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.2, duration: 1.2),
            .fadeAlpha(to: 0.5, duration: 1.2)
        ])))
    }

    func setHighlighted(_ highlighted: Bool, valid: Bool) {
        guard highlighted else {
            lineWidth = 1
            strokeColor = Palette.anthraciteUI.withAlphaComponent(0.7)
            return
        }
        lineWidth = 2.5
        strokeColor = valid ? Palette.soulGreenUI : Palette.demonRedUI
    }
}
