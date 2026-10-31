import Foundation
import Testing
@testable import Airstamp

@Suite("Formatting")
struct FormattingTests {
    static let instant = Date(iso: "2026-07-15T07:00:00Z")

    @Test("one UTC instant renders correctly in 6 zones", arguments: [
        ("Africa/Lagos", "2026-07-15", "08:00"),
        ("Europe/London", "2026-07-15", "08:00"),
        ("Asia/Kolkata", "2026-07-15", "12:30"),
        ("Asia/Tokyo", "2026-07-15", "16:00"),
        ("America/New_York", "2026-07-15", "03:00"),
        ("Australia/Sydney", "2026-07-15", "17:00"),
    ])
    func sixZones(zone: String, day: String, time: String) throws {
        let formatter = DropFormatter(timeZone: try #require(TimeZone(identifier: zone)))
        #expect(formatter.localDay(Self.instant) == day)
        #expect(formatter.localTime(Self.instant) == time)
    }

    @Test("stepping days counts calendar days across a clock change, not 24-hour blocks", arguments: [
        // New York, 00:30 on Sun 1 Nov 2026 (a 25-hour day): two days on is Tue 3 Nov.
        ("America/New_York", "2026-11-01T04:30:00Z", 2, "2026-11-03"),
        // London, 00:30 on Mon 29 Mar 2027, just after the 23-hour Sunday: one day back is Sun 28 Mar.
        ("Europe/London", "2027-03-28T23:30:00Z", -1, "2027-03-28"),
    ])
    func stepsCalendarDays(zone: String, now: String, days: Int, day: String) throws {
        let formatter = DropFormatter(timeZone: try #require(TimeZone(identifier: zone)))
        #expect(formatter.localDay(Date(iso: now), addingDays: days) == day)
    }

    @Test("a date-only drop shows the same day in every zone", arguments: [
        "Africa/Lagos", "America/New_York", "Pacific/Auckland", "Pacific/Pago_Pago",
    ])
    func dateOnlyNeverShifts(zone: String) throws {
        let formatter = DropFormatter(timeZone: try #require(TimeZone(identifier: zone)), locale: Locale(identifier: "en_GB"))
        #expect(formatter.airdate("2026-04-29") == "Wed 29 Apr")
    }

    @Test("an unreadable airdate yields nothing rather than a wrong day")
    func badAirdate() {
        #expect(DropFormatter(timeZone: .gmt).airdate("2026-13-45") == nil)
        #expect(DropFormatter(timeZone: .gmt).airdate("") == nil)
    }
}
