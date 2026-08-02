//
//  BeltInfoPanel.swift
//  DemonicFactory
//
//  Floating card shown when a conveyor belt is selected — mirrors
//  BuildingInfoPanel's layout, scaled down to what a belt actually has:
//  level/speed, connection status, upgrade, and removal.
//

import SwiftUI

struct BeltInfoPanel: View {
    @ObservedObject var viewModel: GameViewModel
    let info: SelectedBeltInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            statusRow
            actionRow
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Palette.anthracite.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.violet.opacity(0.6), lineWidth: 1.5))
        )
    }

    private var header: some View {
        HStack {
            Image(systemName: "arrow.right.square.fill")
                .font(.title3)
                .foregroundStyle(Palette.violet)
            VStack(alignment: .leading, spacing: 2) {
                Text("Förderband · Lv\(info.level)/\(info.maxLevel)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
            }
            Spacer()
            Button {
                viewModel.deselectBelt()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 3) {
                Image(systemName: "gauge.with.dots.needle.67percent").font(.caption2)
                Text(String(format: "%.2f Felder/s", info.speed)).font(.caption2.monospacedDigit())
            }
            HStack(spacing: 3) {
                Image(systemName: "square.grid.3x3.fill").font(.caption2)
                Text("\(info.tileCount) Felder").font(.caption2.monospacedDigit())
            }
        }
        .foregroundStyle(.white.opacity(0.75))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            if info.canUpgrade {
                Button {
                    viewModel.upgradeSelectedBelt()
                } label: {
                    Label("\(info.upgradeCost)", systemImage: "arrow.up.circle.fill")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(Palette.violet)
                .disabled(viewModel.hellCoin < info.upgradeCost)
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
        }
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
