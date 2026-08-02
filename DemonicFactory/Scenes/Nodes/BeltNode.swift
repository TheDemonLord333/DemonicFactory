//
//  BeltNode.swift
//  DemonicFactory
//
//  Draws a conveyor line's tiles and directional arrows, and keeps a
//  ResourceItemNode alive for every item currently in transit — including a
//  visible pulsing marker when the line is jammed (destination full).
//

import SpriteKit

final class BeltNode: SKNode {
    let lineID: UUID
    private let path: [GridPoint]
    private var itemNodes: [UUID: ResourceItemNode] = [:]
    private let jamIndicator: SKShapeNode
    private var segmentNodes: [SKShapeNode] = []

    init(line: ConveyorLine) {
        lineID = line.id
        path = line.path

        jamIndicator = SKShapeNode(circleOfRadius: 6)
        jamIndicator.fillColor = Palette.demonRedUI
        jamIndicator.strokeColor = .clear
        jamIndicator.isHidden = true
        jamIndicator.zPosition = 8
        if let last = path.last {
            jamIndicator.position = GridMath.scenePosition(for: last)
        }

        super.init()
        zPosition = 3
        drawSegments()
        addChild(jamIndicator)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func drawSegments() {
        for (index, point) in path.enumerated() {
            let segment = SKShapeNode(
                rectOf: CGSize(width: GridMath.tileSize * 0.7, height: GridMath.tileSize * 0.7),
                cornerRadius: 8
            )
            segment.fillColor = Palette.darkVioletUI.withAlphaComponent(0.55)
            segment.strokeColor = Palette.violetUI.withAlphaComponent(0.6)
            segment.lineWidth = 1.5
            segment.position = GridMath.scenePosition(for: point)
            segment.zPosition = 1
            addChild(segment)
            segmentNodes.append(segment)

            if index < path.count - 1 {
                let direction = BeltDirection.from(point, to: path[index + 1])
                let arrow = SKSpriteNode.symbol("chevron.right", pointSize: 14, color: Palette.violetUI)
                arrow.zRotation = direction.rotationRadians
                arrow.position = GridMath.scenePosition(for: point)
                arrow.alpha = 0.8
                arrow.zPosition = 2
                addChild(arrow)
            }
        }
    }

    func setSelected(_ selected: Bool) {
        for segment in segmentNodes {
            segment.strokeColor = selected ? .white : Palette.violetUI.withAlphaComponent(0.6)
            segment.lineWidth = selected ? 2.5 : 1.5
        }
    }

    func sync(items: [BeltItem], pathLength: Double, isJammed: Bool) {
        jamIndicator.isHidden = !isJammed
        if isJammed && jamIndicator.action(forKey: "pulse") == nil {
            jamIndicator.run(
                .repeatForever(.sequence([.scale(to: 1.4, duration: 0.4), .scale(to: 1.0, duration: 0.4)])),
                withKey: "pulse"
            )
        } else if !isJammed {
            jamIndicator.removeAction(forKey: "pulse")
            jamIndicator.setScale(1.0)
        }

        var seen = Set<UUID>()
        for item in items {
            seen.insert(item.id)
            let node = itemNodes[item.id] ?? makeItemNode(for: item)
            let fraction = pathLength > 0 ? item.distanceAlongPath / pathLength : 0
            node.position = positionAlongPath(fraction: fraction)
        }
        for (id, node) in itemNodes where !seen.contains(id) {
            node.removeFromParent()
            itemNodes.removeValue(forKey: id)
        }
    }

    private func makeItemNode(for item: BeltItem) -> ResourceItemNode {
        let node = ResourceItemNode(resource: item.resource)
        node.zPosition = 6
        addChild(node)
        itemNodes[item.id] = node
        return node
    }

    private func positionAlongPath(fraction: Double) -> CGPoint {
        guard path.count > 1 else { return GridMath.scenePosition(for: path.first ?? .zero) }
        let clamped = max(0, min(1, fraction))
        let totalSegments = Double(path.count - 1)
        let scaledPosition = clamped * totalSegments
        let segmentIndex = min(path.count - 2, Int(scaledPosition))
        let segmentFraction = scaledPosition - Double(segmentIndex)
        let start = GridMath.scenePosition(for: path[segmentIndex])
        let end = GridMath.scenePosition(for: path[segmentIndex + 1])
        return CGPoint(
            x: start.x + (end.x - start.x) * CGFloat(segmentFraction),
            y: start.y + (end.y - start.y) * CGFloat(segmentFraction)
        )
    }
}
