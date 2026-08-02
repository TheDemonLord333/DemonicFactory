//
//  GameSnapshot.swift
//  DemonicFactory
//
//  Codable mirror of GameState used for saving/loading. Kept separate from the
//  runtime model classes so those stay free to use reference semantics without
//  worrying about Codable synthesis for every field (e.g. transient touch state).
//

import Foundation

struct BuildingSnapshot: Codable {
    var id: UUID
    var type: BuildingType
    var x: Int
    var y: Int
    var level: Int
    var progress: Double
    var inputBuffer: [ResourceType: Int]
    var outputBuffer: [ResourceType: Int]
    var health: Double
}

struct BeltItemSnapshot: Codable {
    var resource: ResourceType
    var distanceAlongPath: Double
}

struct BeltLineSnapshot: Codable {
    var id: UUID
    var path: [GridPoint]
    var sourceBuildingID: UUID?
    var destinationBuildingID: UUID?
    var speed: Double
    var items: [BeltItemSnapshot]
}

struct CreatureSnapshot: Codable {
    var id: UUID
    var type: CreatureType
    var name: String
    var hp: Int
    var x: Int
    var y: Int
}

struct MissionSnapshot: Codable {
    var id: UUID
    var title: String
    var goalType: MissionGoalType
    var targetResource: ResourceType?
    var targetAmount: Int
    var progress: Int
    var rewardHellCoin: Int
    var rewardBloodCrystal: Int
    var isCompleted: Bool
    var isClaimed: Bool
    var continuousSeconds: Double
}

struct GameSnapshot: Codable {
    var gridWidth: Int
    var gridHeight: Int
    var terrain: [TerrainType]
    var buildings: [BuildingSnapshot]
    var beltLines: [BeltLineSnapshot]
    var creatures: [CreatureSnapshot]
    var missions: [MissionSnapshot]
    var resources: [ResourceType: Int]
    var energyStored: Double
    var energyCapacity: Double
    var playerLevel: Int
    var playerXP: Int
    var elapsedPlayTime: TimeInterval
    var lifetimeProduced: [ResourceType: Int]
    var lifetimeBuildingsBuilt: Int
    var lifetimeCreaturesSummoned: Int

    init(state: GameState) {
        gridWidth = state.grid.width
        gridHeight = state.grid.height
        terrain = state.grid.allPoints.map { state.grid.terrain(at: $0) }

        buildings = state.buildings.map {
            BuildingSnapshot(
                id: $0.id, type: $0.type, x: $0.gridPosition.x, y: $0.gridPosition.y,
                level: $0.level, progress: $0.progress,
                inputBuffer: $0.inputBuffer, outputBuffer: $0.outputBuffer, health: $0.health
            )
        }

        beltLines = state.beltLines.map { line in
            BeltLineSnapshot(
                id: line.id, path: line.path,
                sourceBuildingID: line.sourceBuildingID, destinationBuildingID: line.destinationBuildingID,
                speed: line.speed,
                items: line.itemsInTransit.map { BeltItemSnapshot(resource: $0.resource, distanceAlongPath: $0.distanceAlongPath) }
            )
        }

        creatures = state.creatures.map {
            CreatureSnapshot(id: $0.id, type: $0.type, name: $0.name, hp: $0.hp, x: $0.gridPosition.x, y: $0.gridPosition.y)
        }

        missions = state.missions.map {
            MissionSnapshot(
                id: $0.id, title: $0.title, goalType: $0.goalType, targetResource: $0.targetResource,
                targetAmount: $0.targetAmount, progress: $0.progress,
                rewardHellCoin: $0.rewardHellCoin, rewardBloodCrystal: $0.rewardBloodCrystal,
                isCompleted: $0.isCompleted, isClaimed: $0.isClaimed, continuousSeconds: $0.continuousSeconds
            )
        }

        resources = state.resources
        energyStored = state.energy.stored
        energyCapacity = state.energy.capacity
        playerLevel = state.playerLevel
        playerXP = state.playerXP
        elapsedPlayTime = state.elapsedPlayTime
        lifetimeProduced = state.lifetimeProduced
        lifetimeBuildingsBuilt = state.lifetimeBuildingsBuilt
        lifetimeCreaturesSummoned = state.lifetimeCreaturesSummoned
    }

    func apply(to state: GameState) {
        var grid = FactoryGrid(width: gridWidth, height: gridHeight)
        for (index, terrainType) in terrain.enumerated() {
            let point = GridPoint(x: index % gridWidth, y: index / gridWidth)
            grid.setTerrain(terrainType, at: point)
        }
        state.grid = grid

        state.buildings = buildings.map { snapshot in
            let building = FactoryBuilding(
                id: snapshot.id, type: snapshot.type,
                gridPosition: GridPoint(x: snapshot.x, y: snapshot.y), level: snapshot.level
            )
            building.progress = snapshot.progress
            building.inputBuffer = snapshot.inputBuffer
            building.outputBuffer = snapshot.outputBuffer
            building.health = snapshot.health
            return building
        }

        state.beltLines = beltLines.map { snapshot in
            let line = ConveyorLine(
                id: snapshot.id, path: snapshot.path,
                sourceBuildingID: snapshot.sourceBuildingID, destinationBuildingID: snapshot.destinationBuildingID,
                speed: snapshot.speed
            )
            line.itemsInTransit = snapshot.items.map { BeltItem(resource: $0.resource, distanceAlongPath: $0.distanceAlongPath) }
            return line
        }

        state.creatures = creatures.map { snapshot in
            let blueprint = SummoningSystem.blueprints.first { $0.type == snapshot.type } ?? SummoningSystem.blueprints[0]
            let creature = Creature(id: snapshot.id, blueprint: blueprint, name: snapshot.name, gridPosition: GridPoint(x: snapshot.x, y: snapshot.y))
            creature.hp = snapshot.hp
            return creature
        }

        state.missions = missions.map { snapshot in
            let mission = Mission(
                id: snapshot.id, title: snapshot.title, goalType: snapshot.goalType,
                targetResource: snapshot.targetResource, targetAmount: snapshot.targetAmount,
                rewardHellCoin: snapshot.rewardHellCoin, rewardBloodCrystal: snapshot.rewardBloodCrystal
            )
            mission.progress = snapshot.progress
            mission.isCompleted = snapshot.isCompleted
            mission.isClaimed = snapshot.isClaimed
            mission.continuousSeconds = snapshot.continuousSeconds
            return mission
        }

        state.resources = resources
        state.energy.stored = energyStored
        state.energy.capacity = energyCapacity
        state.playerLevel = playerLevel
        state.playerXP = playerXP
        state.elapsedPlayTime = elapsedPlayTime
        state.lifetimeProduced = lifetimeProduced
        state.lifetimeBuildingsBuilt = lifetimeBuildingsBuilt
        state.lifetimeCreaturesSummoned = lifetimeCreaturesSummoned
        state.interaction = .idle
        state.selectedBuildingID = nil
    }
}
