//
//  CapacityBadgeNode.swift
//  DemonicFactory
//
//  Small "48/100" pill shown above a Storage building. Color shifts with
//  fill ratio and pulses red once full. Zoom-compensated separately from its
//  own fill-state pulse (two different things want to scale it), so the pulse
//  animates an inner `content` node while `applyZoomCompensation` scales the
//  outer node — they never fight over the same transform.
//

import SpriteKit

final class CapacityBadgeNode: SKNode {
    private let content = SKNode()
    private let background: SKShapeNode
    private let label: SKLabelNode

    override init() {
        background = SKShapeNode(rectOf: CGSize(width: 56, height: 20), cornerRadius: 8)
        background.fillColor = Palette.voidBlackUI.withAlphaComponent(0.78)
        background.lineWidth = 1

        label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = 11
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.fontColor = .white
        label.zPosition = 1

        super.init()
        content.addChild(background)
        content.addChild(label)
        addChild(content)
        zPosition = 30
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(current: Int, capacity: Int) {
        label.text = "\(current)/\(capacity)"
        let ratio = capacity > 0 ? Double(current) / Double(capacity) : 0

        let color: SKColor
        switch ratio {
        case ..<0.7: color = Palette.blurpleUI
        case 0.7..<0.9: color = Palette.lavaOrangeUI
        case 0.9..<1.0: color = Palette.demonRedUI
        default: color = Palette.demonRedUI
        }
        background.strokeColor = color
        label.fontColor = ratio < 0.7 ? .white : color

        if ratio >= 1.0 {
            if content.action(forKey: "pulse") == nil {
                content.run(
                    .repeatForever(.sequence([.scale(to: 1.1, duration: 0.4), .scale(to: 1.0, duration: 0.4)])),
                    withKey: "pulse"
                )
            }
        } else {
            content.removeAction(forKey: "pulse")
            content.setScale(1.0)
        }
    }

    /// Cancels out world-space shrinkage once the camera zooms past its
    /// neutral scale (1.0), so the badge never gets smaller than its
    /// authored size — still shrinks normally while zoomed in, though.
    func applyZoomCompensation(cameraScale: CGFloat) {
        setScale(max(1.0, cameraScale))
    }
}
