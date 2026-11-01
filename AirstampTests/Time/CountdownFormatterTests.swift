import Foundation
import Testing
@testable import Airstamp

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

    @Test("more than 24 hours away is counted in days (the views tick the rest live, see daySplit)")
    func coarseBeyondADay() {
        let state = CountdownFormatter.state(drop: Self.drop, confidence: .estimated, now: Self.now(minus: 86_401))
        #expect(state == .coarse([CountdownPart(value: 1, unit: .day)]))
    }

    static let day: TimeInterval = 86_400, hour: TimeInterval = 3_600, minute: TimeInterval = 60

    @Test("the live countdown splits off whole days; the clock part ticks down to the next day edge")
    func daySplit() {
        let split = CountdownFormatter.daySplit(drop: Self.drop, now: Self.now(minus: 2 * Self.day + 4 * Self.hour + 600))
        #expect(split.days == 2)
        #expect(split.edge == Self.drop.addingTimeInterval(-2 * Self.day))
        let underADay = CountdownFormatter.daySplit(drop: Self.drop, now: Self.now(minus: 5 * Self.hour))
        #expect(underADay.days == 0)
        #expect(underADay.edge == Self.drop)
        // Exactly on a day edge (widget entries land on whole hours) it reads "3d 24:00:00" and ticks, never a
        // frozen "4d 0:00".
        let onEdge = CountdownFormatter.daySplit(drop: Self.drop, now: Self.now(minus: 4 * Self.day))
        #expect(onEdge.days == 3)
        #expect(onEdge.edge == Self.drop.addingTimeInterval(-3 * Self.day))
        #expect(CountdownFormatter.daySplit(drop: Self.drop, now: Self.now(minus: Self.day)).days == 0)
    }

    @Test("a ticking countdown is sized from a template as wide as its widest value, so widgets can't stretch it")
    func clockTemplate() {
        #expect(CountdownFormatter.clockTemplate(drop: Self.drop, now: Self.now(minus: 5 * Self.hour)) == "0:00:00")
        #expect(CountdownFormatter.clockTemplate(drop: Self.drop, now: Self.now(minus: 15 * Self.hour)) == "00:00:00")
        #expect(CountdownFormatter.clockTemplate(drop: Self.drop, now: Self.now(minus: 40 * Self.minute)) == "00:00")
        #expect(CountdownFormatter.clockTemplate(drop: Self.drop, now: Self.now(minus: 2 * Self.day + Self.hour))
            == "2d 00:00:00")
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
    }
}
