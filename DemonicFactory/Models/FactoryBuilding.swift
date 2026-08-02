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
    }

    var bufferCapacity: Int { type.bufferCapacity(level: level) }

    var totalOutputStored: Int { outputBuffer.values.reduce(0, +) }
    var totalInputStored: Int { inputBuffer.values.reduce(0, +) }

    func canUpgrade() -> Bool { level < type.maxLevel }

    func upgradeCost() -> Int { type.upgradeCost(fromLevel: level) }
}
