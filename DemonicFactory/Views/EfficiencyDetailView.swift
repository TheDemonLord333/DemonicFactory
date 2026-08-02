//
//  EfficiencyDetailView.swift
//  DemonicFactory
//

import SwiftUI

struct EfficiencyDetailView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(NumberFormat.percent(viewModel.efficiency))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(efficiencyColor)

                if viewModel.efficiencyIssues.isEmpty {
                    ContentUnavailableView(
                        "Alles läuft rund",
                        systemImage: "checkmark.circle.fill",
                        description: Text("Keine Probleme in deiner Produktionskette gefunden.")
                    )
                    .foregroundStyle(.white)
                } else {
                    List(viewModel.efficiencyIssues, id: \.self) { issue in
                        Label(issue, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Palette.demonRed)
                            .listRowBackground(Palette.anthracite)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.top, 24)
            .background(Palette.voidBlack.ignoresSafeArea())
            .navigationTitle("Fabrikeffizienz")
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

    private var efficiencyColor: Color {
        switch viewModel.efficiency {
        case 80...: return Palette.soulGreen
        case 50..<80: return Palette.gold
        default: return Palette.demonRed
        }
    }
}
