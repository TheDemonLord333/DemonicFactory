//
//  CreaturesPanel.swift
//  DemonicFactory
//

import SwiftUI

struct CreaturesPanel: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.creatures.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Kreaturen",
                        systemImage: "tornado",
                        description: Text("Baue ein Beschwörungsportal und liefere ihm Dämonenkerne.")
                    )
                    .foregroundStyle(.white)
                } else {
                    List(viewModel.creatures) { creature in
                        HStack(spacing: 12) {
                            Circle()
                                .stroke(creature.rarity.frameColor, lineWidth: 2.5)
                                .background(Circle().fill(Palette.anthracite))
                                .frame(width: 40, height: 40)
                                .overlay(Image(systemName: creature.type.iconSystemName).foregroundStyle(creature.rarity.frameColor))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(creature.name).font(.subheadline.bold()).foregroundStyle(.white)
                                Text("\(creature.type.displayName) · \(creature.rarity.displayName) · \(creature.role.displayName)")
                                    .font(.caption2)
                                    .foregroundStyle(creature.rarity.frameColor)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Label("\(creature.hp)", systemImage: "heart.fill").font(.caption2).foregroundStyle(Palette.demonRed)
                                Label("\(creature.attack)", systemImage: "bolt.fill").font(.caption2).foregroundStyle(Palette.lavaOrange)
                            }
                        }
                        .listRowBackground(Palette.anthracite)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Palette.voidBlack.ignoresSafeArea())
            .navigationTitle("Kreaturen")
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
