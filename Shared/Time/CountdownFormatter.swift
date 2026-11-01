import Foundation

/// Turns the time until a drop into what a countdown should show. Pure, so views and widgets agree.
enum CountdownFormatter {
    /// "Out now" lasts this long after the drop (SPEC: drop ≤ now < drop + 1 h).
    static let outNowWindow: TimeInterval = 3_600
    /// Within this window the countdown is a plain timer; beyond it, whole days and then a timer (`daySplit`). Both
    /// tick live.
    static let tickingWindow: TimeInterval = 86_400

    static func state(drop: Date, confidence: Confidence, now: Date) -> CountdownState {
        if confidence == .dateOnly { return .dateOnly }
        let remaining = drop.timeIntervalSince(now)
        if remaining <= -outNowWindow { return .released }
        if remaining <= 0 { return .outNow }
        if remaining <= tickingWindow { return .ticking }
        return .coarse(parts(from: now, to: drop, maxUnits: 2))
    }

    /// How a live countdown more than a day away is drawn: whole days, then a timer ticking down to the next day edge
    /// ("2d" + "4:10:22"). Under a day, 0 days and the edge is the drop. Each edge needs a redraw (widgets have an
    /// hourly entry on it, `WidgetTimeline`), so the day count steps down.
    static func daySplit(drop: Date, now: Date) -> (days: Int, edge: Date) {
        // Rounded up, less one: exactly on an edge (widget entries land on whole hours) the clock starts at 24:00:00
        // and ticks, instead of sitting paused at 0:00 until the next entry.
        let days = max(0, Int((drop.timeIntervalSince(now) / 86_400).rounded(.up)) - 1)
        return (days, drop.addingTimeInterval(-Double(days) * 86_400))
    }

    /// The widest the live countdown can be from now on, with zeros for digits: "0:00:00", "00:00", "2d 00:00:00".
    /// Views size the timer from it, because a ticking `Text(timerInterval:)` otherwise takes all the width a widget
    /// offers and pushes everything else out.
    static func clockTemplate(drop: Date, now: Date) -> String {
        let split = daySplit(drop: drop, now: now)
        // With days left the clock runs back up to 23:59:59 at each edge, so it keeps two hour digits.
        let seconds = split.days > 0 ? 86_399 : max(0, Int(split.edge.timeIntervalSince(now)))
        let clock = switch seconds {
        case 36_000...: "00:00:00"
        case 3_600...: "0:00:00"
        case 600...: "00:00"
        default: "0:00"
        }
        return split.days > 0 ? "\(split.days)d \(clock)" : clock
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

    /// "2d 4h", plain text for `parts` (tests and accessibility fallbacks); the views draw the live timer instead.
    static func text(_ parts: [CountdownPart]) -> String {
        parts.map { "\($0.value)\($0.unit.rawValue)" }.joined(separator: " ")
    }

    /// "2 days 4 hours", the spoken form of `text(_:)` for accessibility labels.
    static func spokenText(_ parts: [CountdownPart]) -> String {
        parts.map { $0.unit.spoken($0.value) }.joined(separator: " ")
    }
}
