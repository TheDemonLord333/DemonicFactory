//
//  GridPoint.swift
//  DemonicFactory
//

import Foundation
import CoreGraphics

struct GridPoint: Hashable, Codable {
    var x: Int
    var y: Int

    static let zero = GridPoint(x: 0, y: 0)

    func offset(dx: Int, dy: Int) -> GridPoint {
        GridPoint(x: x + dx, y: y + dy)
    }

    var neighbors: [GridPoint] {
        [offset(dx: 1, dy: 0), offset(dx: -1, dy: 0), offset(dx: 0, dy: 1), offset(dx: 0, dy: -1)]
    }

    func isOrthogonallyAdjacent(to other: GridPoint) -> Bool {
        let dx = abs(x - other.x)
        let dy = abs(y - other.y)
        return (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    }

    func distance(to other: GridPoint) -> Double {
        let dx = Double(x - other.x)
        let dy = Double(y - other.y)
        return (dx * dx + dy * dy).squareRoot()
    }
}

enum BeltDirection: String, Codable, CaseIterable {
    case north, east, south, west

    /// Direction pointing from `from` towards the orthogonally adjacent `to`.
    static func from(_ from: GridPoint, to: GridPoint) -> BeltDirection {
        if to.x > from.x { return .east }
        if to.x < from.x { return .west }
        if to.y > from.y { return .north }
        return .south
    }

    var rotationRadians: CGFloat {
        switch self {
        case .east: return 0
        case .north: return .pi / 2
        case .west: return .pi
        case .south: return -.pi / 2
        }
    }
}
