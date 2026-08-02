//
//  TopBarView.swift
//  DemonicFactory
//

import SwiftUI

struct TopBarView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 14) {
            currencyChip(icon: "dollarsign.circle.fill", color: Palette.gold, value: NumberFormat.compact(viewModel.hellCoin))
            currencyChip(icon: "diamond.fill", color: Palette.demonRed, value: NumberFormat.compact(viewModel.bloodCrystal))
            energyChip
            Spacer(minLength: 8)
            efficiencyChip
            levelChip
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Palette.anthracite.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.darkViolet, lineWidth: 1))
        )
    }

    private func currencyChip(icon: String, color: Color, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.footnote.monospacedDigit().bold()).foregroundStyle(.white)
        }
    }

    private var energyChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(viewModel.energy.isDeficit ? Palette.demonRed : Palette.soulGreen)
                .symbolEffect(.pulse, isActive: viewModel.energy.isDeficit)
            Text("\(Int(viewModel.energy.stored))/\(Int(viewModel.energy.capacity))")
                .font(.footnote.monospacedDigit().bold())
                .foregroundStyle(.white)
        }
        .opacity(viewModel.energy.isDeficit ? 1 : 0.9)
    }

    private var efficiencyChip: some View {
        Button {
            viewModel.showEfficiencyDetail = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                Text(NumberFormat.percent(viewModel.efficiency))
                    .font(.footnote.monospacedDigit().bold())
            }
            .foregroundStyle(efficiencyColor)
        }
    }

    private var efficiencyColor: Color {
        switch viewModel.efficiency {
        case 80...: return Palette.soulGreen
        case 50..<80: return Palette.gold
        default: return Palette.demonRed
        }
    }

    private var levelChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill").foregroundStyle(Palette.violet)
            Text("Lv \(viewModel.playerLevel)").font(.footnote.bold()).foregroundStyle(.white)
        }
    }
}
