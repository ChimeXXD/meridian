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
