import Foundation

/// Turns the time until a drop into what a countdown should show. Pure, so views and widgets agree.
enum CountdownFormatter {
    /// "Out now" lasts this long after the drop (SPEC: drop ≤ now < drop + 1 h).
    static let outNowWindow: TimeInterval = 3_600
    /// Within this window the countdown ticks; beyond it, it shows days and hours.
    static let tickingWindow: TimeInterval = 86_400

    static func state(drop: Date, confidence: Confidence, now: Date) -> CountdownState {
        if confidence == .dateOnly { return .dateOnly }
        let remaining = drop.timeIntervalSince(now)
        if remaining <= -outNowWindow { return .released }
        if remaining <= 0 { return .outNow }
        if remaining <= tickingWindow { return .ticking }
        return .coarse(parts(from: now, to: drop, maxUnits: 2))
    }

    /// The largest non-zero unit and up to `maxUnits - 1` after it, rounded down.
    /// Anything under a minute but still ahead reads "1m", so it never shows "0m" before the drop.
    static func parts(from now: Date, to drop: Date, maxUnits: Int) -> [CountdownPart] {
        let seconds = Int(drop.timeIntervalSince(now).rounded(.down))
        guard seconds > 0, maxUnits > 0 else { return [] }
        let minutes = max(1, seconds / 60)
        let units: [(Int, CountdownPart.Unit)] = [(minutes / 1_440, .day), (minutes % 1_440 / 60, .hour), (minutes % 60, .minute)]
        guard let first = units.firstIndex(where: { $0.0 > 0 }) else { return [] }
        return units[first..<min(first + maxUnits, units.count)]
            .filter { $0.0 > 0 }
            .map { CountdownPart(value: $0.0, unit: $0.1) }
    }

    /// "2d 4h", for places that can't style the units (inline widget, accessibility fallbacks).
    static func text(_ parts: [CountdownPart]) -> String {
        parts.map { "\($0.value)\($0.unit.rawValue)" }.joined(separator: " ")
    }

    /// "2 days 4 hours", the spoken form of `text(_:)` for accessibility labels.
    static func spokenText(_ parts: [CountdownPart]) -> String {
        parts.map { $0.unit.spoken($0.value) }.joined(separator: " ")
    }
}
