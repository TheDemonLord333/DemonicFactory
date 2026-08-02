//
//  SaveGameManager.swift
//  DemonicFactory
//

import Foundation
import SwiftData

@MainActor
final class SaveGameManager {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(engine: GameEngine) {
        let snapshot = engine.makeSnapshot()
        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        do {
            let existing = try context.fetch(FetchDescriptor<GameSaveRecord>())
            if let record = existing.first {
                record.snapshotData = data
                record.savedAt = .now
            } else {
                context.insert(GameSaveRecord(snapshotData: data))
            }
            try context.save()
            engine.state.lastSavedAt = .now
        } catch {
            // Autosave failing once shouldn't interrupt play; the next tick tries again.
        }
    }

    /// Returns the last saved snapshot plus how long the player was away, or
    /// nil on a fresh install.
    func load() -> (snapshot: GameSnapshot, offlineDuration: TimeInterval)? {
        guard let record = try? context.fetch(FetchDescriptor<GameSaveRecord>()).first,
              let snapshot = try? JSONDecoder().decode(GameSnapshot.self, from: record.snapshotData)
        else { return nil }
        let offlineDuration = Date.now.timeIntervalSince(record.savedAt)
        return (snapshot, max(0, offlineDuration))
    }
}
