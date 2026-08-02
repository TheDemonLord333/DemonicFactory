//
//  BuildingInfoPanel.swift
//  DemonicFactory
//
//  Floating, semi-transparent card shown when a building is selected — it must
//  not cover the factory floor entirely, so it stays compact and anchored to
//  the bottom of the screen above the tab bar.
//

import SwiftUI

struct BuildingInfoPanel: View {
    @ObservedObject var viewModel: GameViewModel
    let info: SelectedBuildingInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if info.storageBreakdown != nil {
                storageSection
            } else {
                recipeSummary
                statsRow
            }
            actionRow
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Palette.anthracite.opacity(0.92))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(info.type.themeColor.opacity(0.6), lineWidth: 1.5))
        )
    }

    private var header: some View {
        HStack {
            Image(systemName: info.type.iconSystemName)
                .font(.title3)
                .foregroundStyle(info.type.themeColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(info.type.displayName) · Lv\(info.level)/\(info.maxLevel)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(info.isActive ? "In Betrieb" : (info.isBlocked ? "Blockiert" : "Wartet"))
                    .font(.caption2)
                    .foregroundStyle(info.isActive ? Palette.soulGreen : Palette.demonRed)
            }
            Spacer()
            Button {
                viewModel.deselectBuilding()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    @ViewBuilder
    private var recipeSummary: some View {
        if !info.recipeInputs.isEmpty || info.recipeOutput != nil {
            HStack(spacing: 6) {
                ForEach(info.recipeInputs) { item in
                    resourceChip(item.resource, amount: item.amount)
                }
                if !info.recipeInputs.isEmpty {
                    Image(systemName: "arrow.right").foregroundStyle(.white.opacity(0.5))
                }
                if let output = info.recipeOutput {
                    resourceChip(output, amount: 1)
                } else {
                    Image(systemName: "tornado").foregroundStyle(Palette.magenta)
                }
            }
            .font(.caption2)
        }
    }

    @ViewBuilder
    private var storageSection: some View {
        if let breakdown = info.storageBreakdown {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Gesamt").font(.caption2).foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text("\(NumberFormat.german(totalStored)) / \(NumberFormat.german(info.bufferCapacity))")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(capacityColor)
                }
                ProgressView(value: capacityRatio).tint(capacityColor)

                if breakdown.isEmpty {
                    Text("Leer").font(.caption2).foregroundStyle(.white.opacity(0.5))
                } else {
                    ForEach(breakdown) { item in
                        HStack(spacing: 4) {
                            Image(systemName: item.resource.iconSystemName).foregroundStyle(item.resource.color)
                            Text(item.resource.displayName).foregroundStyle(.white.opacity(0.85))
                            Spacer()
                            Text(NumberFormat.german(item.amount)).foregroundStyle(.white)
                        }
                        .font(.caption2)
                    }
                }

                if let interval = info.storageOutputInterval {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill").foregroundStyle(Palette.violet)
                        Text(String(format: "Ausgabe: alle %.2fs", interval)).foregroundStyle(.white.opacity(0.7))
                    }
                    .font(.caption2)
                }
            }
        }
    }

    private var totalStored: Int { info.storageBreakdown?.reduce(0) { $0 + $1.amount } ?? 0 }
    private var capacityRatio: Double { info.bufferCapacity > 0 ? Double(totalStored) / Double(info.bufferCapacity) : 0 }
    private var capacityColor: Color {
        switch capacityRatio {
        case ..<0.7: return Palette.blurple
        case 0.7..<0.9: return Palette.lavaOrange
        default: return Palette.demonRed
        }
    }

    private func resourceChip(_ resource: ResourceType, amount: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: resource.iconSystemName).foregroundStyle(resource.color)
            Text("\(amount)").foregroundStyle(.white)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statItem(icon: "timer", value: String(format: "%.1fs", info.processingTime))
            if info.energyDraw > 0 {
                statItem(icon: "bolt.fill", value: String(format: "%.1f/s", info.energyDraw))
            }
            ProgressView(value: info.progress)
                .tint(info.isActive ? Palette.soulGreen : Palette.demonRed)
                .frame(maxWidth: .infinity)
        }
    }

    private func statItem(icon: String, value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.caption2)
            Text(value).font(.caption2.monospacedDigit())
        }
        .foregroundStyle(.white.opacity(0.75))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.beginMovingSelected()
            } label: {
                Label("Verschieben", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .tint(.white)

            if info.canUpgrade {
                Button {
                    viewModel.upgradeSelected()
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
                viewModel.sellSelected()
            } label: {
                Label("\(info.sellRefund)", systemImage: "trash.fill")
                    .font(.caption.bold())
            }
            .buttonStyle(.bordered)
            .tint(Palette.demonRed)
        }
    }
}
