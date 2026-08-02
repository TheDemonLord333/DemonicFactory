//
//  BottomBarView.swift
//  DemonicFactory
//

import SwiftUI

struct BottomBarView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(BottomBarTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Palette.anthracite.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.darkViolet, lineWidth: 1))
        )
    }

    private func tabButton(_ tab: BottomBarTab) -> some View {
        let isHighlighted = currentTutorialHighlight == tab
        let isBeltActive = tab == .belts && viewModel.isDrawingBelt

        return Button {
            handleTap(tab)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.iconSystemName)
                    .font(.system(size: 18, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 9, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(isBeltActive ? Palette.voidBlack : .white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isBeltActive ? Palette.soulGreen : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHighlighted ? Palette.gold : .clear, lineWidth: 2)
            )
        }
    }

    private var currentTutorialHighlight: BottomBarTab? {
        guard let index = viewModel.tutorialStepIndex, index < viewModel.tutorialSteps.count else { return nil }
        return viewModel.tutorialSteps[index].highlightTab
    }

    private func handleTap(_ tab: BottomBarTab) {
        switch tab {
        case .belts:
            viewModel.toggleBeltDrawing()
        default:
            viewModel.activeTab = tab
        }
    }
}
