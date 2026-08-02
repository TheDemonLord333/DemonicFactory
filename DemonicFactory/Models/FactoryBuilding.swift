//
//  FactoryBuilding.swift
//  DemonicFactory
//
//  Runtime instance of a placed machine. Reference type so SpriteKit nodes and
//  systems can hold onto the same building without copy-on-write surprises.
//

import Foundation

final class FactoryBuilding: Identifiable {
    let id: UUID
    var type: BuildingType
    var gridPosition: GridPoint
    var level: Int
    var progress: Double
    var inputBuffer: [ResourceType: Int]
    var outputBuffer: [ResourceType: Int]
    var isActive: Bool
    var isBlocked: Bool
    var health: Double
    /// True while being dragged — production/output pause and the building
    /// can't accept or emit resources until it's dropped somewhere valid.
    var isBeingMoved: Bool
    /// Counts down to the next automatic storage output (unused by machines).
    var outputTimer: Double
    /// Round-robin cursor into this building's outgoing belt lines (storage only).
    var nextOutputLineIndex: Int

    init(
        id: UUID = UUID(),
        type: BuildingType,
        gridPosition: GridPoint,
        level: Int = 1
    ) {
        self.id = id
        self.type = type
        self.gridPosition = gridPosition
        self.level = level
        self.progress = 0
        self.inputBuffer = [:]
        self.outputBuffer = [:]
        self.isActive = false
        self.isBlocked = false
        self.health = 1.0
        self.isBeingMoved = false
        self.outputTimer = 0
        self.nextOutputLineIndex = 0
    }

    var bufferCapacity: Int { type.bufferCapacity(level: level) }

    var totalOutputStored: Int { outputBuffer.values.reduce(0, +) }
    var totalInputStored: Int { inputBuffer.values.reduce(0, +) }

    /// Storage keeps its stock in `inputBuffer` (it has no recipe/production
    /// cycle of its own); every other building exports what it produced via
    /// `outputBuffer`. Belt logic reads/writes through this so both cases
    /// share one code path.
    var exportableStock: [ResourceType: Int] {
        type == .storage ? inputBuffer : outputBuffer
    }

    func removeExported(_ resource: ResourceType, amount: Int) {
        if type == .storage {
            inputBuffer[resource, default: 0] -= amount
        } else {
            outputBuffer[resource, default: 0] -= amount
        }
    }

    func canUpgrade() -> Bool { level < type.maxLevel }

    func upgradeCost() -> Int { type.upgradeCost(fromLevel: level) }

    /// All grid tiles this building's footprint covers, `gridPosition` anchoring
    /// the bottom-left corner.
    var occupiedTiles: [GridPoint] {
        let footprint = type.footprint
        var tiles: [GridPoint] = []
        tiles.reserveCapacity(footprint.width * footprint.height)
        for dy in 0..<footprint.height {
            for dx in 0..<footprint.width {
                tiles.append(gridPosition.offset(dx: dx, dy: dy))
            }
        }
        return tiles
    }

    func occupies(_ point: GridPoint) -> Bool { occupiedTiles.contains(point) }
}
