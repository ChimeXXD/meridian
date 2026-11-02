import Foundation
import Testing
@testable import Meridian

@Suite("Countdown")
struct CountdownFormatterTests {
    static let drop = Date(iso: "2026-11-04T01:00:00Z")

    static func now(minus seconds: TimeInterval) -> Date { drop.addingTimeInterval(-seconds) }

    @Test("a date-only drop never ticks, whatever the clock says")
    func dateOnly() {
        #expect(CountdownFormatter.state(drop: Self.drop, confidence: .dateOnly, now: Self.now(minus: 60)) == .dateOnly)
        #expect(CountdownFormatter.state(drop: Self.drop, confidence: .dateOnly, now: Self.drop) == .dateOnly)
    }

    @Test("boundaries match SPEC: Out now for an hour from the drop, ticking within 24 hours", arguments: [
        (-3_600.0, CountdownState.released),
        (-3_599.0, .outNow),
        (0.0, .outNow),
        (1.0, .ticking),
        (86_400.0, .ticking),
    ])
    func boundaries(secondsBefore: TimeInterval, expected: CountdownState) {
        #expect(CountdownFormatter.state(drop: Self.drop, confidence: .exact, now: Self.now(minus: secondsBefore)) == expected)
    }

    static let day: TimeInterval = 86_400, hour: TimeInterval = 3_600, minute: TimeInterval = 60

    /// Seconds before the drop, and the still count shown then.
    static let stillCases: [(TimeInterval, String)] = [
        (day + 1, "1d 0h"),  // just over a day: whole hours, rounded down, so "1d 0h", not "1d" or "24:00:01"
        (25 * hour - 1, "1d 0h"),
        (25 * hour, "1d 1h"),
        (4 * day + 4 * hour, "4d 4h"),
        (4 * day + 4 * hour - 1, "4d 3h"),
        (2 * day + 59 * minute, "2d 0h"),
        (13 * day + 23 * hour + 59 * minute, "13d 23h"),
    ]

    @Test("more than 24 hours away it stands still in whole days and hours, rounded down (Chime, 2 Nov)",
          arguments: stillCases)
    func stillBeyondADay(secondsBefore: TimeInterval, text: String) {
        let state = CountdownFormatter.state(drop: Self.drop, confidence: .estimated, now: Self.now(minus: secondsBefore))
        guard case .coarse(let parts) = state else {
            Issue.record("\(secondsBefore) s before should stand still, got \(state)")
            return
        }
        #expect(CountdownFormatter.text(parts) == text)
    }

    @Test("a day away exactly it already ticks, so a widget entry on that edge starts the clock")
    func ticksFromADay() {
        #expect(CountdownFormatter.state(drop: Self.drop, confidence: .exact, now: Self.now(minus: Self.day)) == .ticking)
        #expect(CountdownFormatter.state(drop: Self.drop, confidence: .exact, now: Self.now(minus: Self.day + 1))
            == .coarse([CountdownPart(value: 1, unit: .day), CountdownPart(value: 0, unit: .hour)]))
    }

    @Test("a ticking countdown is sized from a template as wide as its widest value, so widgets can't stretch it")
    func clockTemplate() {
        #expect(CountdownFormatter.clockTemplate(drop: Self.drop, now: Self.now(minus: 5 * Self.hour)) == "0:00:00")
        #expect(CountdownFormatter.clockTemplate(drop: Self.drop, now: Self.now(minus: 15 * Self.hour)) == "00:00:00")
        #expect(CountdownFormatter.clockTemplate(drop: Self.drop, now: Self.now(minus: 40 * Self.minute)) == "00:00")
        #expect(CountdownFormatter.clockTemplate(drop: Self.drop, now: Self.now(minus: Self.day)) == "00:00:00")
    }

    static let partCases: [(TimeInterval, Int, String)] = [
        (2 * day + 4 * hour + 30 * minute, 2, "2d 4h"),
        (2 * day, 2, "2d"),
        (2 * day + 59, 2, "2d"),
        (4 * hour + 38 * minute, 2, "4h 38m"),
        (4 * hour + 38 * minute, 1, "4h"),
        (38 * minute + 20, 2, "38m"),
        (30, 2, "1m"),
        (day + 5 * minute, 2, "1d"),
    ]

    @Test("parts keep the two largest units and round down", arguments: partCases)
    func parts(seconds: TimeInterval, maxUnits: Int, text: String) {
        let parts = CountdownFormatter.parts(from: Self.now(minus: seconds), to: Self.drop, maxUnits: maxUnits)
        #expect(CountdownFormatter.text(parts) == text)
    }

    @Test("a drop in the past has no parts")
    func pastHasNoParts() {
        #expect(CountdownFormatter.parts(from: Self.drop.addingTimeInterval(1), to: Self.drop, maxUnits: 2).isEmpty)
    }

    @Test("the spoken form spells out units for VoiceOver")
    func spoken() {
        #expect(CountdownFormatter.spokenText([CountdownPart(value: 2, unit: .day), CountdownPart(value: 1, unit: .hour)]) == "2 days 1 hour")
        #expect(CountdownFormatter.spokenText([CountdownPart(value: 1, unit: .minute)]) == "1 minute")
        // The still "1d 0h" is said "1 day", never "1 day 0 hours".
        #expect(CountdownFormatter.spokenText([CountdownPart(value: 1, unit: .day), CountdownPart(value: 0, unit: .hour)]) == "1 day")
    }
}
