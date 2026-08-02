//
//  TutorialOverlay.swift
//  DemonicFactory
//

import SwiftUI

struct TutorialOverlay: View {
    @ObservedObject var viewModel: GameViewModel
    let step: TutorialStep
    let stepNumber: Int
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Schritt \(stepNumber)/\(totalSteps)")
                    .font(.caption2.bold())
                    .foregroundStyle(Palette.gold)
                Spacer()
                Button("Überspringen") { viewModel.skipTutorial() }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Text(step.title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(step.message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            HStack {
                Spacer()
                Button("Weiter") { viewModel.advanceTutorial() }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.violet)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Palette.anthracite.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.gold.opacity(0.6), lineWidth: 1.5))
        )
    }
}
