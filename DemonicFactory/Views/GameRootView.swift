//
//  GameRootView.swift
//  DemonicFactory
//
//  Top-level layout: the SpriteKit factory floor fills the screen, thin
//  translucent SwiftUI panels float over the top/bottom edges so the field
//  stays mostly visible, per the "UI darf das Spielfeld nicht zu stark
//  verdecken" requirement.
//

import SwiftUI
import SwiftData

struct GameRootView: View {
    @StateObject private var viewModel = GameViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            GameSceneContainer(scene: viewModel.scene)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                TopBarView(viewModel: viewModel)

                Spacer(minLength: 0)

                InteractionBannerView(viewModel: viewModel)

                if let info = viewModel.selectedBuilding {
                    BuildingInfoPanel(viewModel: viewModel, info: info)
                }

                if let beltInfo = viewModel.selectedBelt {
                    BeltInfoPanel(viewModel: viewModel, info: beltInfo)
                }

                if let index = viewModel.tutorialStepIndex, index < viewModel.tutorialSteps.count {
                    TutorialOverlay(
                        viewModel: viewModel,
                        step: viewModel.tutorialSteps[index],
                        stepNumber: index + 1,
                        totalSteps: viewModel.tutorialSteps.count
                    )
                }

                BottomBarView(viewModel: viewModel)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if let report = viewModel.offlineReport {
                Color.black.opacity(0.6).ignoresSafeArea()
                OfflineProgressPopup(report: report) {
                    viewModel.offlineReport = nil
                }
            }
        }
        .background(Palette.voidBlack.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(item: $viewModel.activeTab) { tab in
            switch tab {
            case .build: BuildMenuView(viewModel: viewModel)
            case .machines: MachinesListView(viewModel: viewModel)
            case .belts: EmptyView()
            case .defense: DefensePlaceholderView()
            case .creatures: CreaturesPanel(viewModel: viewModel)
            case .missions: MissionsPanel(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showEfficiencyDetail) {
            EfficiencyDetailView(viewModel: viewModel)
        }
        .task {
            viewModel.attachPersistence(modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                viewModel.saveNow()
            }
        }
    }
}
