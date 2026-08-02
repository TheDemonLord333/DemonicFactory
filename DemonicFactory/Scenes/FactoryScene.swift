//
//  FactoryScene.swift
//  DemonicFactory
//
//  The live factory floor. Owns no game logic itself — every frame it advances
//  GameEngine.tick(_:) and then mirrors GameState into SpriteKit nodes. Touch
//  handling turns gestures into GameEngine intents (place/select/move/draw belt);
//  pinch and long-press arrive from GameSceneContainer's UIKit gesture recognizers.
//
//  Build/move mode drives two shared visuals: a per-tile grid highlight
//  (TileNode.setHighlightState, computed from the same GameState.isAreaFree
//  check GameEngine itself uses to validate a drop) and a footprint preview
//  ghost that follows the touch — both read from one source of truth, so the
//  displayed grid can never disagree with what actually happens on release.
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

    // Drag-to-move state
    private var draggedBuildingID: UUID?
    private var dragOriginalScenePosition: CGPoint?

    // Shared build/move-mode overlays
    private var placementGhost: SKShapeNode?
    private var highlightsActive = false

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
        updateBuildHighlights()
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
            node.applyZoomCompensation(cameraScale: cameraNode.xScale)
            // While a node is being live-dragged, its position is driven by
            // the touch, not by the model — don't snap it back mid-drag.
            if building.id != draggedBuildingID {
                node.position = GridMath.centerScenePosition(origin: building.gridPosition, footprint: node.footprint)
            }
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
            node.setSelected(engine.state.selectedBeltID == line.id)
            node.setLevel(line.level)
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

    // MARK: - Build/move mode grid highlight

    private func updateBuildHighlights() {
        let interaction = engine.state.interaction
        let active: Bool
        switch interaction {
        case .placingBuilding, .drawingBelt: active = true
        case .movingBuilding: active = draggedBuildingID != nil
        default: active = false
        }

        guard active else {
            if highlightsActive {
                for tile in tileNodes.values { tile.setHighlightState(.hidden) }
                highlightsActive = false
            }
            return
        }
        highlightsActive = true

        let ignoringID: UUID? = {
            if case .movingBuilding(let id) = interaction { return id }
            return nil
        }()

        for (point, tile) in tileNodes {
            let occupant = engine.state.building(at: point)
            let free = engine.state.grid.isBuildable(at: point)
                && (occupant == nil || occupant?.id == ignoringID)
                && !engine.state.hasBelt(at: point)
            tile.setHighlightState(free ? .available : .occupied)
        }

        if let ignoringID, let building = engine.state.building(id: ignoringID) {
            for point in building.occupiedTiles {
                tileNodes[point]?.setHighlightState(.originalPosition)
            }
        }
    }

    // MARK: - Footprint preview ghost (build placement + drag-to-move)

    private func updateFootprintGhost(origin: GridPoint, footprint: (width: Int, height: Int), ignoring buildingID: UUID? = nil) {
        let valid = engine.state.isAreaFree(origin: origin, footprint: footprint, ignoring: buildingID)
        placementGhost?.removeFromParent()

        let size = CGSize(
            width: GridMath.tileSize * CGFloat(footprint.width) - 4,
            height: GridMath.tileSize * CGFloat(footprint.height) - 4
        )
        let ghost = SKShapeNode(rectOf: size, cornerRadius: 8)
        ghost.position = GridMath.centerScenePosition(origin: origin, footprint: footprint)
        ghost.zPosition = 25
        ghost.lineWidth = 2.5
        let color = valid ? Palette.soulGreenUI : Palette.demonRedUI
        ghost.fillColor = color.withAlphaComponent(0.28)
        ghost.strokeColor = color
        ghost.alpha = 0.7
        if !valid {
            ghost.run(.repeatForever(.sequence([.fadeAlpha(to: 0.4, duration: 0.3), .fadeAlpha(to: 0.7, duration: 0.3)])))
        }
        addChild(ghost)
        placementGhost = ghost
    }

    private func clearFootprintGhost() {
        placementGhost?.removeFromParent()
        placementGhost = nil
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartLocation = location
        hasMovedSignificantly = false

        switch engine.state.interaction {
        case .drawingBelt:
            currentBeltPath = []
            appendBeltPoint(at: location)
        case .placingBuilding(let type):
            updateFootprintGhost(origin: GridMath.gridPoint(for: location), footprint: type.footprint)
        case .movingBuilding(let id):
            beginLiveDrag(buildingID: id, at: location)
        default:
            lastPanLocation = location
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let start = touchStartLocation, location.beltDistance(to: start) > 8 {
            hasMovedSignificantly = true
        }

        switch engine.state.interaction {
        case .drawingBelt:
            appendBeltPoint(at: location)
        case .placingBuilding(let type):
            updateFootprintGhost(origin: GridMath.gridPoint(for: location), footprint: type.footprint)
        case .movingBuilding:
            if draggedBuildingID != nil { updateDragFollow(to: location) }
        default:
            if let last = lastPanLocation {
                let dx = last.x - location.x
                let dy = last.y - location.y
                cameraNode.position.x += dx
                cameraNode.position.y += dy
                lastPanLocation = location
            }
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
            if draggedBuildingID != nil { endLiveDrag(at: location) }
        default:
            if !hasMovedSignificantly {
                if let building = engine.state.building(at: gridPoint) {
                    engine.selectBuilding(id: building.id)
                } else if let belt = engine.state.belt(at: gridPoint) {
                    engine.selectBelt(id: belt.id)
                } else {
                    engine.deselect()
                }
            }
        }
        lastPanLocation = nil
        touchStartLocation = nil
    }

    // MARK: - Drag-and-drop moving

    private func beginLiveDrag(buildingID: UUID, at location: CGPoint) {
        guard draggedBuildingID == nil, let building = engine.state.building(id: buildingID) else { return }
        if !building.isBeingMoved {
            engine.beginMovingBuilding(id: buildingID)
        }
        draggedBuildingID = buildingID
        if let node = buildingNodes[buildingID] {
            dragOriginalScenePosition = node.position
            node.beginDragVisual()
        }
        Haptics.impact(.light)
        updateDragFollow(to: location)
    }

    private func updateDragFollow(to location: CGPoint) {
        guard let id = draggedBuildingID, let node = buildingNodes[id], let building = engine.state.building(id: id) else { return }
        node.updateDragVisual(to: location)
        let origin = GridMath.gridPoint(for: location)
        updateFootprintGhost(origin: origin, footprint: building.type.footprint, ignoring: id)
    }

    private func endLiveDrag(at location: CGPoint) {
        guard let id = draggedBuildingID else { return }
        let point = GridMath.gridPoint(for: location)
        let success = engine.commitMove(buildingID: id, to: point)
        if let node = buildingNodes[id] {
            let finalPosition = success
                ? GridMath.centerScenePosition(origin: point, footprint: node.footprint)
                : (dragOriginalScenePosition ?? node.position)
            node.endDragVisual(success: success, finalPosition: finalPosition)
        }
        Haptics.impact(success ? .medium : .light)
        if !success { Haptics.notify(.error) }
        finishDrag()
    }

    private func cancelLiveDrag() {
        guard let id = draggedBuildingID else { return }
        engine.cancelMovingBuilding(id: id)
        if let node = buildingNodes[id] {
            node.endDragVisual(success: false, finalPosition: dragOriginalScenePosition ?? node.position)
        }
        finishDrag()
    }

    private func finishDrag() {
        draggedBuildingID = nil
        dragOriginalScenePosition = nil
        clearFootprintGhost()
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

    func playBeltUpgradeFlash(lineID: UUID) {
        beltNodes[lineID]?.playUpgradeFlash()
    }

    // MARK: - External gesture hooks (called by GameSceneContainer)

    func handlePinch(incrementalScale: CGFloat) {
        let newScale = cameraNode.xScale / incrementalScale
        cameraNode.setScale(max(0.6, min(2.5, newScale)))
    }

    func handleLongPressBegan(at location: CGPoint) {
        let point = GridMath.gridPoint(for: location)
        if let building = engine.state.building(at: point) {
            beginLiveDrag(buildingID: building.id, at: location)
        } else if engine.state.grid.isBuildable(at: point) {
            onRequestBuildMenu?(point)
        }
    }

    func handleLongPressChanged(at location: CGPoint) {
        guard draggedBuildingID != nil else { return }
        updateDragFollow(to: location)
    }

    func handleLongPressEnded(at location: CGPoint) {
        guard draggedBuildingID != nil else { return }
        endLiveDrag(at: location)
    }

    func handleLongPressCancelled() {
        cancelLiveDrag()
    }
}

private extension CGPoint {
    func beltDistance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
