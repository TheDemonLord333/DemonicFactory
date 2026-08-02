//
//  GameSaveRecord.swift
//  DemonicFactory
//
//  SwiftData-backed save slot. The full game state is stored as an encoded
//  GameSnapshot rather than as a sprawling relational SwiftData graph — this
//  keeps saving/loading a single atomic operation and avoids SwiftData
//  relationship pitfalls for what is, structurally, a single save-game blob.
//  `slotID` exists so multiple save slots can be added later without a
//  migration.
//

import Foundation
import SwiftData

@Model
final class GameSaveRecord {
    var slotID: String
    var savedAt: Date
    var snapshotData: Data

    init(slotID: String = "default", savedAt: Date = .now, snapshotData: Data) {
        self.slotID = slotID
        self.savedAt = savedAt
        self.snapshotData = snapshotData
    }
}
