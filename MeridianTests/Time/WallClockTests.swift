import Foundation
import Testing
@testable import Meridian

/// Pins how a listed date and a wall-clock time become an instant at the awkward edges: a time that doesn't exist
/// (spring forward), a time that happens twice (fall back), and month, year and leap-day ends. Expected instants are
/// worked out by hand from each zone's clock change.
@Suite("WallClock")
struct WallClockTests {
    struct Case: CustomTestStringConvertible, Sendable {
        let airdate: String
        let time: String
        let zone: String
        let dayOffset: Int
        let expected: String
        let why: String
        var testDescription: String { why }
    }

    static let cases: [Case] = [
        // A time in the gap moves forward by the gap: 02:30 New York on 8 Mar 2026 is 03:30 EDT.
        Case(airdate: "2026-03-08", time: "02:30", zone: "America/New_York", dayOffset: 0,
             expected: "2026-03-08T07:30:00Z", why: "spring gap, New York"),
        Case(airdate: "2026-03-29", time: "01:30", zone: "Europe/London", dayOffset: 0,
             expected: "2026-03-29T01:30:00Z", why: "spring gap, London"),
        // A time that happens twice is the first of the two, still on summer time.
        Case(airdate: "2026-11-01", time: "01:30", zone: "America/New_York", dayOffset: 0,
             expected: "2026-11-01T05:30:00Z", why: "fall overlap, New York"),
        Case(airdate: "2026-10-25", time: "01:30", zone: "Europe/London", dayOffset: 0,
             expected: "2026-10-25T00:30:00Z", why: "fall overlap, London"),
        // America/Santiago springs forward at 00:00 on 6 Sep 2026, so local midnight doesn't exist.
        Case(airdate: "2026-09-06", time: "00:30", zone: "America/Santiago", dayOffset: 0,
             expected: "2026-09-06T04:30:00Z", why: "midnight gap, Santiago"),
        Case(airdate: "2026-09-07", time: "21:00", zone: "America/Santiago", dayOffset: -1,
             expected: "2026-09-07T00:00:00Z", why: "day before a midnight gap, Santiago"),
        Case(airdate: "2026-01-31", time: "21:00", zone: "Africa/Lagos", dayOffset: 1,
             expected: "2026-02-01T20:00:00Z", why: "month end, a day later"),
        Case(airdate: "2026-12-31", time: "00:30", zone: "Africa/Lagos", dayOffset: 1,
             expected: "2026-12-31T23:30:00Z", why: "year end, a day later"),
        Case(airdate: "2027-01-01", time: "21:00", zone: "America/Los_Angeles", dayOffset: -1,
             expected: "2027-01-01T05:00:00Z", why: "new year, the evening before (Apple TV's -1)"),
        Case(airdate: "2028-02-28", time: "00:00", zone: "Asia/Tokyo", dayOffset: 1,
             expected: "2028-02-28T15:00:00Z", why: "into a leap day"),
        Case(airdate: "2027-03-01", time: "12:00", zone: "GMT", dayOffset: -1,
             expected: "2027-02-28T12:00:00Z", why: "back over the end of February, not a leap year"),
    ]

    @Test("an instant at a clock change or a calendar end", arguments: cases)
    func instant(_ item: Case) {
        #expect(WallClock.instant(airdate: item.airdate, time: item.time, zone: item.zone, dayOffset: item.dayOffset)
                == Date(iso: item.expected))
    }

    @Test("an unknown zone gives no instant")
    func unknownZone() {
        #expect(WallClock.instant(airdate: "2026-11-05", time: "21:00", zone: "Mars/Olympus", dayOffset: 0) == nil)
    }

    @Test("dates that don't exist or aren't dates are rejected", arguments: [
        "2026-02-30", "2027-02-29", "2026-11-31", "2026-13-01", "2026-00-10", "2026-11-00",
        "", "2026-11", "2026/11/05", "2026-11-05T00:00", "05-11-2026x",
        "2026-xx-11-05", "2026-11-05-", "2026--11-05", "2026-11-05-junk", "2026-+11-05", "2026-11- 5",
    ])
    func rejectsDate(_ text: String) {
        #expect(WallClock.parseDate(text) == nil)
    }

    /// Lenient on purpose: a hand-written rules entry without zero padding still reads.
    @Test("dates without zero padding are accepted")
    func lenientDates() throws {
        let unpadded = try #require(WallClock.parseDate("2026-1-5"))
        #expect((unpadded.year, unpadded.month, unpadded.day) == (2026, 1, 5))
        let leap = try #require(WallClock.parseDate("2028-02-29"))
        #expect((leap.year, leap.month, leap.day) == (2028, 2, 29))
    }

    @Test("times off a 24-hour clock or not times are rejected", arguments: [
        "24:00", "12:60", "-1:00", "9", "", "21:00:00", "21h00", "21:xx:00", "21::00", "21:00:", "-0:30", "+9:05", "21:+5",
    ])
    func rejectsTime(_ text: String) {
        #expect(WallClock.parseTime(text) == nil)
    }

    @Test("times without zero padding are accepted")
    func lenientTimes() throws {
        let midnight = try #require(WallClock.parseTime("00:00"))
        #expect((midnight.hour, midnight.minute) == (0, 0))
        let last = try #require(WallClock.parseTime("23:59"))
        #expect((last.hour, last.minute) == (23, 59))
        let unpadded = try #require(WallClock.parseTime("9:5"))
        #expect((unpadded.hour, unpadded.minute) == (9, 5))
    }
}
