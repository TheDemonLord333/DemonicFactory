//
//  GridMath.swift
//  DemonicFactory
//
//  Conversions between grid coordinates (GridPoint) and SpriteKit scene points.
//

import CoreGraphics

enum GridMath {
    static let tileSize: CGFloat = 64

    /// Scene-space position of a tile's center. Grid origin (0,0) sits bottom-left.
    static func scenePosition(for point: GridPoint) -> CGPoint {
        CGPoint(
            x: (CGFloat(point.x) + 0.5) * tileSize,
            y: (CGFloat(point.y) + 0.5) * tileSize
        )
    }

    static func gridPoint(for scenePosition: CGPoint) -> GridPoint {
        GridPoint(
            x: Int(floor(scenePosition.x / tileSize)),
            y: Int(floor(scenePosition.y / tileSize))
        )
    }

    static func gridSize(for grid: FactoryGrid) -> CGSize {
        CGSize(width: CGFloat(grid.width) * tileSize, height: CGFloat(grid.height) * tileSize)
    }
}
