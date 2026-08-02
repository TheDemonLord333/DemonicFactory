//
//  ConveyorModels.swift
//  DemonicFactory
//
//  A ConveyorLine is a single drawn belt path connecting a source building's
//  output to a destination building's input. Items animate along the path and
//  visibly queue up (stau) at the end when the destination is full.
//

import Foundation

struct BeltItem: Identifiable {
    let id: UUID = UUID()
    let resource: ResourceType
    /// Distance travelled along the line's path, in tiles.
    var distanceAlongPath: Double
}

final class ConveyorLine: Identifiable {
    let id: UUID
    /// Ordered, orthogonally-connected tiles the belt occupies.
    var path: [GridPoint]
    var sourceBuildingID: UUID?
    var destinationBuildingID: UUID?
    var level: Int
    var itemsInTransit: [BeltItem]
    /// True once an item reaches the end but the destination buffer is full.
    var isJammed: Bool

    init(
        id: UUID = UUID(),
        path: [GridPoint],
        sourceBuildingID: UUID? = nil,
        destinationBuildingID: UUID? = nil,
        level: Int = 1
    ) {
        self.id = id
        self.path = path
        self.sourceBuildingID = sourceBuildingID
        self.destinationBuildingID = destinationBuildingID
        self.level = level
        self.itemsInTransit = []
        self.isJammed = false
    }

    /// Tiles travelled per second — derived from level, never stored
    /// separately, so it can't drift out of sync with an upgrade.
    var speed: Double { BuildingLevelConfig.beltSpeed(level: level) }

    var length: Double { Double(max(path.count - 1, 1)) }
    var isFunctional: Bool { sourceBuildingID != nil && destinationBuildingID != nil }
    var canUpgrade: Bool { level < BuildingLevelConfig.maxBeltLevel }
    func upgradeCost() -> Int { BuildingLevelConfig.beltUpgradeCost(fromLevel: level) }

    func occupies(_ point: GridPoint) -> Bool { path.contains(point) }

    func scenePath() -> [GridPoint] { path }
}
