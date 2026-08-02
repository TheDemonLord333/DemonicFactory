//
//  FactoryScene.swift
//  DemonicFactory
//
//  The live factory floor. Owns no game logic itself — every frame it advances
//  GameEngine.tick(_:) and then mirrors GameState into SpriteKit nodes. Touch
//  handling turns gestures into GameEngine intents (place/select/move/draw belt);
//  pinch and long-press arrive from GameSceneContainer's UIKit gesture recognizers.
//

import SpriteKit
import UIKit

final class FactoryScene: SKScene {
    let engine: GameEngine
    /// Long-press on an empty tile asks the SwiftUI layer to present the build menu.
    var onRequestBuildMenu: ((GridPoint) -> Void)?

    private let cameraNode = SKCameraNode()
    private var tileNodes: [GridPoint: TileNode] = [:]
    private var buildingNodes: [UUID: BuildingNode] = [:]
    private var beltNodes: [UUID: BeltNode] = [:]
    private var creatureNodes: [UUID: CreatureNode] = [:]

    private var currentBeltPath: [GridPoint] = []
    private var beltPreviewNodes: [SKShapeNode] = []
    private var lastPanLocation: CGPoint?
    private var touchStartLocation: CGPoint?
    private var hasMovedSignificantly = false
    private var lastUpdateTime: TimeInterval?

    init(engine: GameEngine, size: CGSize) {
        self.engine = engine
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = Palette.voidBlackUI
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didMove(to view: SKView) {
        camera = cameraNode
        addChild(cameraNode)
        buildGrid()
        centerCameraOnGrid()
    }

    private func buildGrid() {
        for point in engine.state.grid.allPoints {
            let tile = TileNode(gridPoint: point, terrain: engine.state.grid.terrain(at: point))
            addChild(tile)
            tileNodes[point] = tile
        }
    }

    private func centerCameraOnGrid() {
        let size = GridMath.gridSize(for: engine.state.grid)
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    // MARK: - Frame loop

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard let last = lastUpdateTime else { return }
        let dt = currentTime - last
        guard dt > 0 else { return }
        engine.tick(deltaTime: dt)
        syncNodes()
    }

    private func syncNodes() {
        syncBuildings()
        syncBelts()
        syncCreatures()
    }

    private func syncBuildings() {
        var seen = Set<UUID>()
        for building in engine.state.buildings {
            seen.insert(building.id)
            let node = buildingNodes[building.id] ?? makeBuildingNode(for: building)
            node.update(with: building)
            node.setSelected(engine.state.selectedBuildingID == building.id)
        }
        for (id, node) in buildingNodes where !seen.contains(id) {
            node.removeFromParent()
            buildingNodes.removeValue(forKey: id)
        }
    }

    private func makeBuildingNode(for building: FactoryBuilding) -> BuildingNode {
        let node = BuildingNode(building: building)
        addChild(node)
        buildingNodes[building.id] = node
        return node
    }

    private func syncBelts() {
        var seen = Set<UUID>()
        for line in engine.state.beltLines {
            seen.insert(line.id)
            let node = beltNodes[line.id] ?? makeBeltNode(for: line)
            node.sync(items: line.itemsInTransit, pathLength: line.length, isJammed: line.isJammed)
        }
        for (id, node) in beltNodes where !seen.contains(id) {
            node.removeFromParent()
            beltNodes.removeValue(forKey: id)
        }
    }

    private func makeBeltNode(for line: ConveyorLine) -> BeltNode {
        let node = BeltNode(line: line)
        addChild(node)
        beltNodes[line.id] = node
        return node
    }

    private func syncCreatures() {
        var seen = Set<UUID>()
        for creature in engine.state.creatures {
            seen.insert(creature.id)
            let node = creatureNodes[creature.id] ?? makeCreatureNode(for: creature)
            node.sync(with: creature)
        }
        for (id, node) in creatureNodes where !seen.contains(id) {
            node.removeFromParent()
            creatureNodes.removeValue(forKey: id)
        }
    }

    private func makeCreatureNode(for creature: Creature) -> CreatureNode {
        let node = CreatureNode(creature: creature)
        addChild(node)
        creatureNodes[creature.id] = node
        return node
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartLocation = location
        hasMovedSignificantly = false

        if case .drawingBelt = engine.state.interaction {
            currentBeltPath = []
            appendBeltPoint(at: location)
        } else {
            lastPanLocation = location
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let start = touchStartLocation, location.beltDistance(to: start) > 8 {
            hasMovedSignificantly = true
        }

        if case .drawingBelt = engine.state.interaction {
            appendBeltPoint(at: location)
        } else if let last = lastPanLocation {
            let dx = last.x - location.x
            let dy = last.y - location.y
            cameraNode.position.x += dx
            cameraNode.position.y += dy
            lastPanLocation = location
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let gridPoint = GridMath.gridPoint(for: location)

        switch engine.state.interaction {
        case .placingBuilding:
            if !hasMovedSignificantly {
                engine.tryPlaceBuilding(at: gridPoint)
            }
        case .drawingBelt:
            if currentBeltPath.count >= 2 {
                engine.placeBeltLine(path: currentBeltPath)
            }
            clearBeltPreview()
            currentBeltPath = []
        case .movingBuilding:
            if !hasMovedSignificantly {
                _ = engine.moveSelectedBuilding(to: gridPoint)
            }
        default:
            if !hasMovedSignificantly {
                if let building = engine.state.building(at: gridPoint) {
                    engine.selectBuilding(id: building.id)
                } else {
                    engine.deselect()
                }
            }
        }
        lastPanLocation = nil
        touchStartLocation = nil
    }

    // MARK: - Belt drawing

    private func appendBeltPoint(at location: CGPoint) {
        let point = GridMath.gridPoint(for: location)
        guard engine.state.grid.isBuildable(at: point), engine.state.building(at: point) == nil else { return }
        if let last = currentBeltPath.last {
            guard last != point, last.isOrthogonallyAdjacent(to: point), !currentBeltPath.contains(point) else { return }
        }
        currentBeltPath.append(point)
        drawBeltPreview()
    }

    private func drawBeltPreview() {
        clearBeltPreview()
        for point in currentBeltPath {
            let marker = SKShapeNode(
                rectOf: CGSize(width: GridMath.tileSize * 0.5, height: GridMath.tileSize * 0.5),
                cornerRadius: 6
            )
            marker.fillColor = Palette.violetUI.withAlphaComponent(0.5)
            marker.strokeColor = Palette.violetUI
            marker.position = GridMath.scenePosition(for: point)
            marker.zPosition = 15
            addChild(marker)
            beltPreviewNodes.append(marker)
        }
    }

    private func clearBeltPreview() {
        beltPreviewNodes.forEach { $0.removeFromParent() }
        beltPreviewNodes.removeAll()
    }

    func buildingNode(for id: UUID?) -> BuildingNode? {
        guard let id else { return nil }
        return buildingNodes[id]
    }

    // MARK: - External gesture hooks (called by GameSceneContainer)

    func handlePinch(incrementalScale: CGFloat) {
        let newScale = cameraNode.xScale / incrementalScale
        cameraNode.setScale(max(0.6, min(2.5, newScale)))
    }

    func handleLongPress(at location: CGPoint) {
        let point = GridMath.gridPoint(for: location)
        if let building = engine.state.building(at: point) {
            engine.selectBuilding(id: building.id)
        } else if engine.state.grid.isBuildable(at: point) {
            onRequestBuildMenu?(point)
        }
    }
}

private extension CGPoint {
    func beltDistance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
