//
//  BuildMenuView.swift
//  DemonicFactory
//

import SwiftUI

struct BuildMenuView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(BuildingType.allCases) { type in
                        Button {
                            viewModel.beginPlacing(type)
                            dismiss()
                        } label: {
                            buildingCard(type)
                        }
                        .disabled(viewModel.hellCoin < type.baseHellCoinCost)
                    }
                }
                .padding(16)
            }
            .background(Palette.voidBlack.ignoresSafeArea())
            .navigationTitle("Bauen")
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

    private func buildingCard(_ type: BuildingType) -> some View {
        let affordable = viewModel.hellCoin >= type.baseHellCoinCost
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.iconSystemName)
                    .font(.title2)
                    .foregroundStyle(type.themeColor)
                Spacer()
            }
            Text(type.displayName)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Text(type.flavorText)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(3)
                .frame(minHeight: 32, alignment: .top)
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill").foregroundStyle(Palette.gold)
                Text("\(type.baseHellCoinCost)")
                    .font(.caption.bold())
                    .foregroundStyle(affordable ? .white : Palette.demonRed)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Palette.anthracite)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(type.themeColor.opacity(0.5), lineWidth: 1))
        )
        .opacity(affordable ? 1 : 0.5)
    }
}
