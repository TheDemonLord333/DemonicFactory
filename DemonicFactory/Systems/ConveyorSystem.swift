//
//  ConveyorSystem.swift
//  DemonicFactory
//
//  Moves items along each drawn belt line. When the destination buffer is full,
//  items visibly pile up at the end of the line (isJammed) instead of vanishing —
//  this is the player's main signal that a production chain needs attention.
//
//  Connections are recomputed from current adjacency every tick rather than
//  cached once at placement time — a belt endpoint always reflects whatever
//  building (if any) currently sits next to it, so a move, sell-and-rebuild,
//  etc. can never leave a line pointing at a building that isn't there anymore.
//

import Foundation

enum ConveyorSystem {
    private static let minimumSpacing: Double = 0.6

    static func advance(state: GameState, deltaTime: TimeInterval) {
        for line in state.beltLines {
            recomputeConnections(line, state: state)
        }

        advanceItems(state: state, deltaTime: deltaTime)
        advanceStorageOutputs(state: state, deltaTime: deltaTime)
    }

    private static func recomputeConnections(_ line: ConveyorLine, state: GameState) {
        line.sourceBuildingID = line.path.first?.neighbors.compactMap { state.building(at: $0) }.first?.id
        line.destinationBuildingID = line.path.last?.neighbors.compactMap { state.building(at: $0) }.first?.id
    }

    private static func advanceItems(state: GameState, deltaTime: TimeInterval) {
        for line in state.beltLines {
            guard line.isFunctional,
                  let sourceID = line.sourceBuildingID,
                  let destinationID = line.destinationBuildingID,
                  let source = state.building(id: sourceID),
                  let destination = state.building(id: destinationID),
                  !source.isBeingMoved, !destination.isBeingMoved
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

            // Storage sources are paced by their own output timer below, not
            // spawned opportunistically like a machine's output buffer.
            guard source.type != .storage else { continue }

            if let next = pickResourceToSpawn(from: source, destination: destination),
               canSpawn(on: line) {
                source.removeExported(next, amount: 1)
                line.itemsInTransit.append(BeltItem(resource: next, distanceAlongPath: 0))
            }
        }
    }

    /// Storage doesn't push onto every outgoing belt every frame — it pushes
    /// one item at a time, at its level's output interval, cycling through its
    /// outgoing lines round-robin so several downstream machines stay fed
    /// roughly evenly.
    private static func advanceStorageOutputs(state: GameState, deltaTime: TimeInterval) {
        for building in state.buildings where building.type == .storage && !building.isBeingMoved {
            building.outputTimer -= deltaTime
            guard building.outputTimer <= 0 else { continue }
            building.outputTimer = BuildingLevelConfig.storageOutputInterval(level: building.level)

            let outgoing = state.beltLines.filter { $0.sourceBuildingID == building.id }
            guard !outgoing.isEmpty else { continue }

            let startIndex = ((building.nextOutputLineIndex % outgoing.count) + outgoing.count) % outgoing.count
            for offset in 0..<outgoing.count {
                let index = (startIndex + offset) % outgoing.count
                let line = outgoing[index]
                guard let destinationID = line.destinationBuildingID,
                      let destination = state.building(id: destinationID), !destination.isBeingMoved,
                      let resource = pickResourceToSpawn(from: building, destination: destination),
                      canSpawn(on: line)
                else { continue }

                building.removeExported(resource, amount: 1)
                line.itemsInTransit.append(BeltItem(resource: resource, distanceAlongPath: 0))
                building.nextOutputLineIndex = index + 1
                break
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
    /// Works for both machines (stock lives in outputBuffer) and Storage
    /// (stock lives in inputBuffer) via `exportableStock`.
    private static func pickResourceToSpawn(from source: FactoryBuilding, destination: FactoryBuilding) -> ResourceType? {
        let stock = source.exportableStock
        if let recipe = RecipeDatabase.recipe(for: destination.type) {
            for wanted in recipe.inputs.keys where stock[wanted, default: 0] > 0 {
                return wanted
            }
        }
        return ResourceType.allCases.first { stock[$0, default: 0] > 0 }
    }
}
