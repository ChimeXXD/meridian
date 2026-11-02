import Foundation

/// Turns the time until a drop into what a countdown should show. Pure, so views and widgets agree.
enum CountdownFormatter {
    /// "Out now" lasts this long after the drop (SPEC: drop ≤ now < drop + 1 h).
    static let outNowWindow: TimeInterval = 3_600
    /// Within this window, 24 hours left included, the countdown is a live timer; beyond it, it stands still in whole
    /// days and hours (`stillParts`). Only the last day ticks (Chime, 2 Nov).
    static let tickingWindow: TimeInterval = 86_400

    static func state(drop: Date, confidence: Confidence, now: Date) -> CountdownState {
        if confidence == .dateOnly { return .dateOnly }
        let remaining = drop.timeIntervalSince(now)
        if remaining <= -outNowWindow { return .released }
        if remaining <= 0 { return .outNow }
        if remaining <= tickingWindow { return .ticking }
        return .coarse(stillParts(from: now, to: drop))
    }

    /// The still count more than a day away: whole days, then whole hours, both rounded down and both always there,
    /// so "4d 4h", "2d 0h", and "1d 0h" from 25 hours down to just over 24 (at 24 it ticks). Widgets step it with
    /// an entry just after each hour (`WidgetTimeline.edgeLag`).
    static func stillParts(from now: Date, to drop: Date) -> [CountdownPart] {
        let hours = max(0, Int((drop.timeIntervalSince(now) / 3_600).rounded(.down)))
        return [CountdownPart(value: hours / 24, unit: .day), CountdownPart(value: hours % 24, unit: .hour)]
    }

    /// The widest the ticking countdown can be from now on, with zeros for digits: "00:00:00", "0:00:00", "00:00".
    /// Views size the timer from it, because a ticking `Text(timerInterval:)` otherwise takes all the width a widget
    /// offers and pushes everything else out.
    static func clockTemplate(drop: Date, now: Date) -> String {
        switch max(0, Int(drop.timeIntervalSince(now))) {
        case 36_000...: "00:00:00"
        case 3_600...: "0:00:00"
        case 600...: "00:00"
        default: "0:00"
        }
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

    /// "2d 4h", "1d 0h": plain text for parts (the inline widget, tests); `CountdownText` styles the units instead.
    static func text(_ parts: [CountdownPart]) -> String {
        parts.map { "\($0.value)\($0.unit.rawValue)" }.joined(separator: " ")
    }

    /// "2 days 4 hours", the spoken form of `text(_:)` for accessibility labels. A zero is left out, so the still
    /// "1d 0h" is said "1 day".
    static func spokenText(_ parts: [CountdownPart]) -> String {
        parts.filter { $0.value > 0 }.map { $0.unit.spoken($0.value) }.joined(separator: " ")
    }
}
