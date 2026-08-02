//
//  InteractionBannerView.swift
//  DemonicFactory
//
//  Small banner shown while the player is mid-action (placing a building,
//  drawing a belt, moving a machine) with an explicit way to cancel.
//

import SwiftUI

struct InteractionBannerView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        if let text = bannerText {
            HStack {
                Text(text)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    viewModel.cancelInteraction()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Palette.violet.opacity(0.85))
            )
        }
    }

    private var bannerText: String? {
        switch viewModel.interaction {
        case .placingBuilding(let type):
            return "Tippe auf ein freies Feld, um \(type.displayName) zu bauen"
        case .drawingBelt:
            return "Ziehe ein Förderband über die Felder"
        case .movingBuilding:
            return "Tippe auf ein freies Feld, um die Maschine zu verschieben"
        default:
            return nil
        }
    }
}
