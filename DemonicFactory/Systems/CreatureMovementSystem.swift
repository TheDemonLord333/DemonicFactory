//
//  CreatureMovementSystem.swift
//  DemonicFactory
//
//  Lightweight wander behaviour so summoned creatures feel alive on the factory
//  floor. A full GameplayKit pathfinding graph (GKGridGraph) is a natural
//  extension point once creatures need to route around dense machine clusters.
//

import CoreGraphics

enum CreatureMovementSystem {
    static func advance(state: GameState, deltaTime: TimeInterval) {
        for creature in state.creatures {
            let targetPosition = GridMath.scenePosition(for: creature.wanderTarget)
            let dx = targetPosition.x - creature.position.x
            let dy = targetPosition.y - creature.position.y
            let distance = (dx * dx + dy * dy).squareRoot()
            let step = CGFloat(creature.speed * deltaTime) * GridMath.tileSize

            if distance <= max(step, 1) {
                creature.position = targetPosition
                creature.gridPosition = creature.wanderTarget
                creature.wanderTarget = randomWanderTarget(from: creature.gridPosition, in: state.grid)
            } else {
                creature.position.x += dx / distance * step
                creature.position.y += dy / distance * step
            }
        }
    }

    private static func randomWanderTarget(from origin: GridPoint, in grid: FactoryGrid) -> GridPoint {
        for _ in 0..<8 {
            let dx = Int.random(in: -3...3)
            let dy = Int.random(in: -3...3)
            let candidate = origin.offset(dx: dx, dy: dy)
            if grid.isBuildable(at: candidate) { return candidate }
        }
        return origin
    }
}
