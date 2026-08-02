//
//  MissionsPanel.swift
//  DemonicFactory
//
//  All leveling/rank/reward math lives in MissionScaling + MissionSystem —
//  this view only ever reads mission.title/level/rank/progress/rewards and
//  calls viewModel.claimMission(_:), never computes a target or reward itself.
//

import SwiftUI

struct MissionsPanel: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(viewModel.missions) { mission in
                MissionRowView(viewModel: viewModel, mission: mission)
                    .listRowBackground(Palette.anthracite)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.voidBlack.ignoresSafeArea())
            .navigationTitle("Missionen")
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

private struct MissionRowView: View {
    @ObservedObject var viewModel: GameViewModel
    let mission: Mission

    @State private var isClaiming = false
    @State private var flash: ClaimFlash?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            ProgressView(value: mission.progressFraction)
                .tint(progressTint)
                .animation(.easeInOut(duration: 0.3), value: mission.progressFraction)
            footer
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(flash != nil ? Palette.gold.opacity(0.12) : Color.clear)
        )
        .overlay(alignment: .topTrailing) {
            if let flash {
                ClaimFlashView(flash: flash)
                    .offset(y: -6)
            }
        }
        .animation(.easeOut(duration: 0.3), value: flash != nil)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(mission.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Text("Level \(mission.level)")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    Text(mission.rank.displayName)
                        .font(.caption2.bold())
                        .foregroundStyle(mission.rank.color)
                        .shadow(color: mission.rank.glowColor ?? .clear, radius: 4)
                }
            }
            Spacer()
            if mission.isCompleted && !mission.isClaimed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Palette.soulGreen)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(progressText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            rewardLabel
            if mission.isCompleted && !mission.isClaimed {
                Button("Abholen") { claim() }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.gold)
                    .disabled(isClaiming)
            } else if isClaiming {
                ProgressView().controlSize(.small)
            }
        }
    }

    private var progressTint: Color {
        if mission.isCompleted { return Palette.gold }
        if mission.progress == 0 { return .gray }
        return Palette.soulGreen
    }

    private var progressText: String {
        let current = min(mission.progress, mission.targetAmount)
        if mission.goalType == .keepEfficiencyAbove {
            return "\(NumberFormat.minutesSeconds(current)) / \(NumberFormat.minutesSeconds(mission.targetAmount))"
        }
        return "\(NumberFormat.german(current))/\(NumberFormat.german(mission.targetAmount))"
    }

    private var rewardLabel: some View {
        HStack(spacing: 6) {
            Label(NumberFormat.germanCompact(mission.rewardHellCoin), systemImage: "dollarsign.circle.fill")
                .foregroundStyle(Palette.gold)
            if mission.rewardBloodCrystal > 0 {
                Label(NumberFormat.germanCompact(mission.rewardBloodCrystal), systemImage: "diamond.fill")
                    .foregroundStyle(Palette.demonRed)
            }
        }
        .font(.caption2.bold())
    }

    /// Runs the ~0.5-0.9s claim flourish, then applies the actual level-up
    /// (via MissionSystem.claimReward, through the engine) partway through so
    /// the new title/target animate in at the end rather than snapping instantly.
    private func claim() {
        guard !isClaiming, mission.isCompleted, !mission.isClaimed else { return }
        isClaiming = true
        let payoutGold = mission.rewardHellCoin
        let payoutCrystal = mission.rewardBloodCrystal
        let rankBefore = mission.rank

        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            viewModel.claimMission(mission)
            let rankedUp = mission.rank.tier != rankBefore.tier

            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                flash = ClaimFlash(gold: payoutGold, bloodCrystal: payoutCrystal, rankedUp: rankedUp, rankName: mission.rank.displayName)
            }
            if rankedUp {
                Haptics.notify(.success)
            } else {
                Haptics.impact(.light)
            }

            try? await Task.sleep(nanoseconds: 550_000_000)
            withAnimation { flash = nil }
            isClaiming = false
        }
    }
}

private struct ClaimFlash {
    let gold: Int
    let bloodCrystal: Int
    let rankedUp: Bool
    let rankName: String
}

private struct ClaimFlashView: View {
    let flash: ClaimFlash

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if flash.rankedUp {
                Text("Rangaufstieg!")
                    .font(.caption2.bold())
                    .foregroundStyle(Palette.violet)
                Text(flash.rankName)
                    .font(.caption.bold())
                    .foregroundStyle(Palette.gold)
            }
            Text("+\(NumberFormat.germanCompact(flash.gold)) Gold")
                .font(.caption2.bold())
                .foregroundStyle(Palette.gold)
            if flash.bloodCrystal > 0 {
                Text("+\(NumberFormat.germanCompact(flash.bloodCrystal)) Seelensteine")
                    .font(.caption2.bold())
                    .foregroundStyle(Palette.demonRed)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Palette.voidBlack.opacity(0.85)))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
