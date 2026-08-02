//
//  TileNode.swift
//  DemonicFactory
//

import SpriteKit

final class TileNode: SKShapeNode {
    let gridPoint: GridPoint
    private let terrain: TerrainType
    private var highlightState: GridHighlightState = .hidden

    init(gridPoint: GridPoint, terrain: TerrainType) {
        self.gridPoint = gridPoint
        self.terrain = terrain
        super.init()

        let size = GridMath.tileSize
        path = CGPath(
            roundedRect: CGRect(x: -size / 2 + 1, y: -size / 2 + 1, width: size - 2, height: size - 2),
            cornerWidth: 6, cornerHeight: 6, transform: nil
        )
        position = GridMath.scenePosition(for: gridPoint)
        lineWidth = 1
        strokeColor = Palette.anthraciteUI.withAlphaComponent(0.7)
        fillColor = baseFillColor
        zPosition = 0

        if terrain == .lava {
            addGlow(color: Palette.lavaOrangeUI)
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var baseFillColor: SKColor {
        switch terrain {
        case .normal: return Palette.anthraciteUI.withAlphaComponent(0.55)
        case .blocked: return Palette.voidBlackUI
        case .lava: return Palette.lavaOrangeUI.withAlphaComponent(0.35)
        case .crack: return Palette.demonRedUI.withAlphaComponent(0.18)
        }
    }

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

    /// Drives every build/move-mode tile look from one place. Cheap to call
    /// every frame — it no-ops once the state already matches.
    func setHighlightState(_ state: GridHighlightState) {
        guard state != highlightState else { return }
        highlightState = state
        removeAction(forKey: "buildPulse")

        switch state {
        case .hidden, .validPlacement, .invalidPlacement, .selected:
            // The latter three are rendered by dedicated overlay nodes
            // (footprint ghost / selection ring), not a per-tile fill.
            alpha = 1
            lineWidth = 1
            strokeColor = Palette.anthraciteUI.withAlphaComponent(0.7)
            fillColor = baseFillColor

        case .available:
            alpha = 0.35
            lineWidth = 1.5
            strokeColor = Palette.violetUI.withAlphaComponent(0.85)
            fillColor = Palette.violetUI.withAlphaComponent(0.14)
            run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.45, duration: 1.3),
                .fadeAlpha(to: 0.25, duration: 1.3)
            ])), withKey: "buildPulse")

        case .occupied:
            alpha = 1
            lineWidth = 1.5
            strokeColor = Palette.demonRedUI.withAlphaComponent(0.55)
            fillColor = Palette.demonRedUI.withAlphaComponent(0.22)

        case .originalPosition:
            alpha = 1
            lineWidth = 2
            strokeColor = Palette.violetUI
            fillColor = Palette.violetUI.withAlphaComponent(0.2)
        }
    }
}
