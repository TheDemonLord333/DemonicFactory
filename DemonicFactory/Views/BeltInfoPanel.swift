//
//  BeltInfoPanel.swift
//  DemonicFactory
//
//  Floating card shown when a conveyor belt is selected — mirrors
//  BuildingInfoPanel but belts only support one action: removal.
//

import SwiftUI

struct BeltInfoPanel: View {
    @ObservedObject var viewModel: GameViewModel
    let info: SelectedBeltInfo

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.right.square.fill")
                .font(.title3)
                .foregroundStyle(Palette.violet)

            VStack(alignment: .leading, spacing: 2) {
                Text("Förderband · \(info.tileCount) Felder")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
            }

            Spacer()

            Button(role: .destructive) {
                viewModel.removeSelectedBelt()
            } label: {
                Label("\(info.removeRefund)", systemImage: "trash.fill")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .tint(Palette.demonRed)

            Button {
                viewModel.deselectBelt()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Palette.anthracite.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.violet.opacity(0.6), lineWidth: 1.5))
        )
    }

    private var statusText: String {
        if !info.isFunctional { return "Nicht verbunden" }
        if info.isJammed { return "Blockiert" }
        return "\(info.itemCount) Objekt(e) unterwegs"
    }

    private var statusColor: Color {
        if !info.isFunctional || info.isJammed { return Palette.demonRed }
        return Palette.soulGreen
    }
}
