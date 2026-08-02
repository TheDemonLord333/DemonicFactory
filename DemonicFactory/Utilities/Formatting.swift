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

    private static let germanFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    /// German-grouped integer, e.g. 12500 -> "12.500".
    static func german(_ value: Int) -> String {
        germanFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Compact German form for very large numbers, e.g. 2_100_000 -> "2,1 Mio.".
    static func germanCompact(_ value: Int) -> String {
        let n = Double(value)
        switch abs(value) {
        case 1_000_000_000...:
            return String(format: "%.1f", n / 1_000_000_000).replacingOccurrences(of: ".", with: ",") + " Mrd."
        case 1_000_000...:
            return String(format: "%.1f", n / 1_000_000).replacingOccurrences(of: ".", with: ",") + " Mio."
        default:
            return german(value)
        }
    }

    /// "2 Min." / "3 Min. 30 Sek." for a whole number of seconds.
    static func minutesSeconds(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if seconds == 0 { return "\(minutes) Min." }
        return "\(minutes) Min. \(seconds) Sek."
    }
}
