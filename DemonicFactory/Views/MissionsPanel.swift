//
//  MissionsPanel.swift
//  DemonicFactory
//

import SwiftUI

struct MissionsPanel: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(viewModel.missions) { mission in
                VStack(alignment: .leading, spacing: 8) {
                    Text(mission.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)

                    ProgressView(value: mission.progressFraction)
                        .tint(mission.isCompleted ? Palette.gold : Palette.soulGreen)

                    HStack {
                        Text("\(min(mission.progress, mission.targetAmount))/\(mission.targetAmount)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        rewardLabel(mission)
                        if mission.isCompleted && !mission.isClaimed {
                            Button("Abholen") { viewModel.claimMission(mission) }
                                .buttonStyle(.borderedProminent)
                                .tint(Palette.violet)
                        } else if mission.isClaimed {
                            Label("Abgeholt", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Palette.soulGreen)
                        }
                    }
                }
                .padding(.vertical, 4)
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

    private func rewardLabel(_ mission: Mission) -> some View {
        HStack(spacing: 6) {
            Label("\(mission.rewardHellCoin)", systemImage: "dollarsign.circle.fill")
                .foregroundStyle(Palette.gold)
            if mission.rewardBloodCrystal > 0 {
                Label("\(mission.rewardBloodCrystal)", systemImage: "diamond.fill")
                    .foregroundStyle(Palette.demonRed)
            }
        }
        .font(.caption2.bold())
    }
}
