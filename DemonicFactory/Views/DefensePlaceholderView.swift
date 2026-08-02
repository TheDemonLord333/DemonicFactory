//
//  DefensePlaceholderView.swift
//  DemonicFactory
//
//  Attack waves and defense buildings are out of scope for the first playable
//  version (see project notes); this honestly communicates that instead of
//  silently omitting the "Verteidigung" tab the spec's UI layout calls for.
//

import SwiftUI

struct DefensePlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Verteidigung",
                systemImage: "shield.slash.fill",
                description: Text("Angriffswellen und Verteidigungsanlagen schalten sich ab Spielerlevel 8 frei. Konzentriere dich zunächst auf deine Produktionsketten.")
            )
            .foregroundStyle(.white)
            .background(Palette.voidBlack.ignoresSafeArea())
            .navigationTitle("Verteidigung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.anthracite, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
