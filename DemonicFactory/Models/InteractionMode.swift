//
//  InteractionMode.swift
//  DemonicFactory
//
//  What the next tap on the factory scene should do. Shared between the
//  SwiftUI bottom bar (which sets it) and FactoryScene (which reads it).
//

import Foundation

enum InteractionMode: Equatable {
    case idle
    case placingBuilding(BuildingType)
    case drawingBelt
    case movingBuilding(UUID)
    case selected(UUID)

    static func == (lhs: InteractionMode, rhs: InteractionMode) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.drawingBelt, .drawingBelt): return true
        case let (.placingBuilding(a), .placingBuilding(b)): return a == b
        case let (.movingBuilding(a), .movingBuilding(b)): return a == b
        case let (.selected(a), .selected(b)): return a == b
        default: return false
        }
    }
}
