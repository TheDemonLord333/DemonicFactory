//
//  FactoryGrid.swift
//  DemonicFactory
//

import Foundation

enum TerrainType: String, Codable {
    case normal
    case blocked
    case lava
    case crack

    var isBuildable: Bool { self == .normal }
}

struct FactoryGrid: Codable {
    private(set) var width: Int
    private(set) var height: Int
    private var terrain: [TerrainType]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.terrain = Array(repeating: .normal, count: width * height)
    }

    private func index(of point: GridPoint) -> Int? {
        guard contains(point) else { return nil }
        return point.y * width + point.x
    }

    func contains(_ point: GridPoint) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < width && point.y < height
    }

    func terrain(at point: GridPoint) -> TerrainType {
        guard let idx = index(of: point) else { return .blocked }
        return terrain[idx]
    }

    mutating func setTerrain(_ type: TerrainType, at point: GridPoint) {
        guard let idx = index(of: point) else { return }
        terrain[idx] = type
    }

    func isBuildable(at point: GridPoint) -> Bool {
        contains(point) && terrain(at: point).isBuildable
    }

    var allPoints: [GridPoint] {
        var points: [GridPoint] = []
        points.reserveCapacity(width * height)
        for y in 0..<height {
            for x in 0..<width {
                points.append(GridPoint(x: x, y: y))
            }
        }
        return points
    }

    /// Scatters a handful of lava fields and cracks so the starting field doesn't
    /// look like a sterile grid, per the "Lavafelder / Risse im Boden" requirement.
    static func startingGrid(width: Int, height: Int) -> FactoryGrid {
        var grid = FactoryGrid(width: width, height: height)
        let lavaSpots = [GridPoint(x: width - 2, y: 1), GridPoint(x: width - 2, y: 2)]
        let crackSpots = [GridPoint(x: 1, y: height - 2)]
        lavaSpots.forEach { grid.setTerrain(.lava, at: $0) }
        crackSpots.forEach { grid.setTerrain(.crack, at: $0) }
        return grid
    }
}
