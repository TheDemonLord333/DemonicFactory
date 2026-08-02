//
//  ContentView.swift
//  DemonicFactory
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        GameRootView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: GameSaveRecord.self, inMemory: true)
}
