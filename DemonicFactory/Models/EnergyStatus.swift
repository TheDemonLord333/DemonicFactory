//
//  EnergyStatus.swift
//  DemonicFactory
//

import Foundation

struct EnergyStatus {
    var production: Double = 0
    var consumption: Double = 0
    var capacity: Double = 150
    var stored: Double = 40

    var isDeficit: Bool { consumption > production && stored <= 0.01 }
    var fillRatio: Double { capacity > 0 ? min(1, max(0, stored / capacity)) : 0 }
}
