//
//  ConveyorSystem.swift
//  DemonicFactory
//
//  Moves items along each drawn belt line. When the destination buffer is full,
//  items visibly pile up at the end of the line (isJammed) instead of vanishing —
//  this is the player's main signal that a production chain needs attention.
//

import Foundation

enum ConveyorSystem {
    private static let minimumSpacing: Double = 0.6

    static func advance(state: GameState, deltaTime: TimeInterval) {
        for line in state.beltLines {
            guard line.isFunctional,
                  let sourceID = line.sourceBuildingID,
                  let destinationID = line.destinationBuildingID,
                  let source = state.building(id: sourceID),
                  let destination = state.building(id: destinationID)
            else {
                line.isJammed = false
                continue
            }

            for index in line.itemsInTransit.indices {
                if line.itemsInTransit[index].distanceAlongPath < line.length {
                    line.itemsInTransit[index].distanceAlongPath = min(
                        line.length,
                        line.itemsInTransit[index].distanceAlongPath + line.speed * deltaTime
                    )
                }
            }

            var stillJammed = false
            line.itemsInTransit.removeAll { item in
                guard item.distanceAlongPath >= line.length else { return false }
                if deliver(item.resource, to: destination) {
                    return true
                } else {
                    stillJammed = true
                    return false
                }
            }
            line.isJammed = stillJammed

            if let next = pickResourceToSpawn(from: source, destination: destination),
               canSpawn(on: line) {
                source.outputBuffer[next, default: 0] -= 1
                line.itemsInTransit.append(BeltItem(resource: next, distanceAlongPath: 0))
            }
        }
    }

    private static func deliver(_ resource: ResourceType, to destination: FactoryBuilding) -> Bool {
        let current = destination.inputBuffer[resource, default: 0]
        guard current < destination.bufferCapacity else { return false }
        destination.inputBuffer[resource, default: 0] = current + 1
        return true
    }

    private static func canSpawn(on line: ConveyorLine) -> Bool {
        !line.itemsInTransit.contains { $0.distanceAlongPath < minimumSpacing }
    }

    /// Prefers a resource the destination machine actually consumes; falls back
    /// to whatever the source happens to be holding (e.g. feeding a Storage).
    private static func pickResourceToSpawn(from source: FactoryBuilding, destination: FactoryBuilding) -> ResourceType? {
        if let recipe = RecipeDatabase.recipe(for: destination.type) {
            for wanted in recipe.inputs.keys where source.outputBuffer[wanted, default: 0] > 0 {
                return wanted
            }
        }
        return ResourceType.allCases.first { source.outputBuffer[$0, default: 0] > 0 }
    }
}
