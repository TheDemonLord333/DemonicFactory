//
//  GridHighlightState.swift
//  DemonicFactory
//
//  The one visual state a grid tile can be in during build/move mode. Both
//  FactoryScene (which computes it from GameState each frame) and TileNode
//  (which renders it) share this single enum, so the highlighted grid always
//  agrees with the same placement logic GameEngine uses to validate a drop —
//  there's no separate, potentially-contradictory "display" copy of the grid.
//
//  `validPlacement`/`invalidPlacement`/`selected` are reserved for the
//  footprint preview ghost and selection ring, which are dedicated overlay
//  nodes rather than per-tile fills — kept here anyway so every state the
//  spec calls for has one canonical name, even if TileNode itself only
//  renders a subset of them directly.
//

import Foundation

enum GridHighlightState: Equatable {
    case hidden
    case available
    case occupied
    case validPlacement
    case invalidPlacement
    case originalPosition
    case selected
}
