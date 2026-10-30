import Foundation
import Testing
@testable import Airstamp

@Suite("Relative day")
struct RelativeDayTests {
    static let lagos = DropFormatter(timeZone: TimeZone(identifier: "Africa/Lagos")!, locale: Locale(identifier: "en_GB"))
    /// Fri 30 Oct 2026, 22:30 in Lagos.
    static let now = Date(iso: "2026-10-30T21:30:00Z")

    @Test("days are counted in the viewer's zone, not UTC", arguments: [
        ("2026-10-30T22:00:00Z", "Today"),      // 23:00 Fri in Lagos
        ("2026-10-30T23:30:00Z", "Tomorrow"),   // 00:30 Sat in Lagos, still Fri in UTC
        ("2026-10-29T23:30:00Z", "Today"),      // 00:30 Fri in Lagos, still Thu in UTC
        ("2026-10-29T20:00:00Z", "Yesterday"),  // 21:00 Thu in Lagos
        ("2026-11-01T10:00:00Z", "Sun"),
        ("2026-11-05T10:00:00Z", "Thu"),
        ("2026-11-06T10:00:00Z", "Fri 6 Nov"),
        ("2027-07-09T10:00:00Z", "Fri 9 Jul 2027"),  // another year says so (O-10: Silo returns 9 Jul 2027)
    ])
    func relativeDay(iso: String, expected: String) {
        #expect(Self.lagos.relativeDay(Date(iso: iso), now: Self.now) == expected)
    }

    @Test("broadcast zones read as their US abbreviations on both sides of the clock change", arguments: [
        ("2026-10-30T01:00:00Z", "EDT"), ("2026-11-06T01:00:00Z", "EST"),
    ])
    func zoneAbbreviation(iso: String, expected: String) {
        let newYork = DropFormatter(zoneIdentifier: "America/New_York", locale: Locale(identifier: "en_GB"))
        #expect(newYork.zoneAbbreviation(Date(iso: iso)) == expected)
    }

    @Test("weekday and time for widgets and rows")
    func weekdayTime() {
        #expect(Self.lagos.weekdayTime(Date(iso: "2026-11-04T01:00:00Z")) == "Wed 02:00")
    }

    @Test("the same instant is a different day in Lagos and Los Angeles")
    func zoneChangesDay() throws {
        let la = DropFormatter(timeZone: try #require(TimeZone(identifier: "America/Los_Angeles")), locale: Locale(identifier: "en_GB"))
        let drop = Date(iso: "2026-10-31T06:00:00Z")  // 07:00 Sat in Lagos, 23:00 Fri in LA
        #expect(Self.lagos.relativeDay(drop, now: Self.now) == "Tomorrow")
        #expect(la.relativeDay(drop, now: Self.now) == "Today")
    }
}
