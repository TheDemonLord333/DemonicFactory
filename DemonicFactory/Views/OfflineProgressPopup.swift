//
//  OfflineProgressPopup.swift
//  DemonicFactory
//

import SwiftUI

struct OfflineProgressPopup: View {
    let report: OfflineReport
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.largeTitle)
                .foregroundStyle(Palette.violet)

            Text("Deine Fabrik war \(NumberFormat.duration(report.duration)) aktiv")
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if report.gains.isEmpty {
                Text("Ohne Förderbandverbindungen wurde nichts produziert.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                VStack(spacing: 6) {
                    ForEach(sortedGains, id: \.resource) { gain in
                        HStack {
                            Image(systemName: gain.resource.iconSystemName).foregroundStyle(gain.resource.color)
                            Text(gain.resource.displayName).foregroundStyle(.white)
                            Spacer()
                            Text("+\(gain.amount)").foregroundStyle(.white).bold()
                        }
                        .font(.subheadline)
                    }
                }
            }

            Button("Weiter", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .tint(Palette.violet)
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Palette.anthracite)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.violet.opacity(0.6), lineWidth: 1.5))
        )
    }

    private var sortedGains: [ResourceAmount] {
        report.gains
            .map { ResourceAmount(resource: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
}
