//
//  MachinesListView.swift
//  DemonicFactory
//

import SwiftUI

struct MachinesListView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(BuildingType.allCases) { type in
                    let buildings = viewModel.engine.state.buildings.filter { $0.type == type }
                    if !buildings.isEmpty {
                        Section(type.displayName) {
                            ForEach(buildings) { building in
                                Button {
                                    viewModel.engine.selectBuilding(id: building.id)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: type.iconSystemName)
                                            .foregroundStyle(type.themeColor)
                                        VStack(alignment: .leading) {
                                            Text("\(type.displayName) · Lv\(building.level)")
                                                .foregroundStyle(.white)
                                            Text(building.isActive ? "Aktiv" : "Inaktiv")
                                                .font(.caption)
                                                .foregroundStyle(building.isActive ? Palette.soulGreen : Palette.demonRed)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .listRowBackground(Palette.anthracite)
                    }
                }
                if viewModel.engine.state.buildings.isEmpty {
                    Text("Noch keine Maschinen gebaut.")
                        .foregroundStyle(.white.opacity(0.6))
                        .listRowBackground(Palette.anthracite)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.voidBlack.ignoresSafeArea())
            .navigationTitle("Maschinen")
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
