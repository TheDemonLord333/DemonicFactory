//
//  Formatting.swift
//  DemonicFactory
//

import Foundation

enum NumberFormat {
    /// Compact "1.2K" / "3.4M" style formatting for currency and resource counters.
    static func compact(_ value: Int) -> String {
        let n = Double(value)
        switch abs(value) {
        case 1_000_000...:
            return String(format: "%.1fM", n / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", n / 1_000)
        default:
            return "\(value)"
        }
    }

    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours) Std. \(minutes) Min."
        }
        return "\(minutes) Min."
    }
}
