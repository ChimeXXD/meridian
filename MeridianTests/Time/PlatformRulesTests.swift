import Foundation
import Testing
@testable import Meridian

/// Each rule × 6 zones × US summer and winter, plus the clock-change weeks (SPEC §3, D1-4).
/// Expected local times are worked out by hand, not by the code under test.
@Suite("Platform rules across zones and clock changes")
struct PlatformRulesTests {
    struct Case: CustomTestStringConvertible, Sendable {
        let channel: String
        let airdate: String
        let zone: String
        let day: String
        let time: String
        var testDescription: String { "\(channel) \(airdate) in \(zone) → \(day) \(time)" }
    }

    static let zones = ["Africa/Lagos", "Europe/London", "Asia/Kolkata", "Asia/Tokyo", "America/New_York", "Australia/Sydney"]

    /// Netflix, Prime Video (00:00 PT) and Paramount+ (03:00 ET) agree except on the
    /// US changeover days, which are covered separately below.
    static let midnightPacific: [(airdate: String, local: [String])] = [
        ("2026-07-15", ["2026-07-15 08:00", "2026-07-15 08:00", "2026-07-15 12:30", "2026-07-15 16:00", "2026-07-15 03:00", "2026-07-15 17:00"]),
        ("2026-01-14", ["2026-01-14 09:00", "2026-01-14 08:00", "2026-01-14 13:30", "2026-01-14 17:00", "2026-01-14 03:00", "2026-01-14 19:00"]),
    ]

    /// Apple TV lands at 21:00 ET the evening before the listed date.
    static let appleTV: [(airdate: String, local: [String])] = [
        ("2026-07-15", ["2026-07-15 02:00", "2026-07-15 02:00", "2026-07-15 06:30", "2026-07-15 10:00", "2026-07-14 21:00", "2026-07-15 11:00"]),
        ("2026-01-14", ["2026-01-14 03:00", "2026-01-14 02:00", "2026-01-14 07:30", "2026-01-14 11:00", "2026-01-13 21:00", "2026-01-14 13:00"]),
    ]

    static var matrix: [Case] {
        var cases: [Case] = []
        for channel in ["Netflix", "Prime Video", "Paramount+"] {
            for row in midnightPacific { cases += expand(channel, row) }
        }
        for row in appleTV { cases += expand("Apple TV", row) }
        return cases
    }

    static func expand(_ channel: String, _ row: (airdate: String, local: [String])) -> [Case] {
        zip(zones, row.local).map { zone, local in
            let parts = local.split(separator: " ").map(String.init)
            return Case(channel: channel, airdate: row.airdate, zone: zone, day: parts[0], time: parts[1])
        }
    }

    static let changeovers: [Case] = [
        // US clocks go back on Sun 1 Nov 2026 at 02:00 local.
        Case(channel: "Netflix", airdate: "2026-10-31", zone: "Africa/Lagos", day: "2026-10-31", time: "08:00"),
        Case(channel: "Netflix", airdate: "2026-11-01", zone: "Africa/Lagos", day: "2026-11-01", time: "08:00"),
        Case(channel: "Netflix", airdate: "2026-11-02", zone: "Africa/Lagos", day: "2026-11-02", time: "09:00"),
        Case(channel: "Apple TV", airdate: "2026-11-01", zone: "Africa/Lagos", day: "2026-11-01", time: "02:00"),
        Case(channel: "Apple TV", airdate: "2026-11-02", zone: "Africa/Lagos", day: "2026-11-02", time: "03:00"),
        // US clocks go forward on Sun 8 Mar 2026 and Sun 14 Mar 2027.
        Case(channel: "Netflix", airdate: "2026-03-08", zone: "Africa/Lagos", day: "2026-03-08", time: "09:00"),
        Case(channel: "Netflix", airdate: "2026-03-09", zone: "Africa/Lagos", day: "2026-03-09", time: "08:00"),
        Case(channel: "Apple TV", airdate: "2026-03-08", zone: "Africa/Lagos", day: "2026-03-08", time: "03:00"),
        Case(channel: "Apple TV", airdate: "2026-03-09", zone: "Africa/Lagos", day: "2026-03-09", time: "02:00"),
        Case(channel: "Netflix", airdate: "2027-03-14", zone: "Africa/Lagos", day: "2027-03-14", time: "09:00"),
        Case(channel: "Netflix", airdate: "2027-03-15", zone: "Africa/Lagos", day: "2027-03-15", time: "08:00"),
        // Paramount+ is 03:00 ET, which isn't 00:00 PT on changeover days: on 8 Mar 03:00 is
        // already summer time in New York, and on 1 Nov 03:00 is already winter time.
        Case(channel: "Paramount+", airdate: "2026-03-08", zone: "Africa/Lagos", day: "2026-03-08", time: "08:00"),
        Case(channel: "Paramount+", airdate: "2026-11-01", zone: "Africa/Lagos", day: "2026-11-01", time: "09:00"),
        // EU clocks change on 25 Oct 2026 and 28 Mar 2027: London is 7 h ahead of LA, not 8, that week.
        Case(channel: "Netflix", airdate: "2026-10-21", zone: "Europe/London", day: "2026-10-21", time: "08:00"),
        Case(channel: "Netflix", airdate: "2026-10-28", zone: "Europe/London", day: "2026-10-28", time: "07:00"),
        Case(channel: "Netflix", airdate: "2027-03-24", zone: "Europe/London", day: "2027-03-24", time: "07:00"),
        Case(channel: "Netflix", airdate: "2027-03-31", zone: "Europe/London", day: "2027-03-31", time: "08:00"),
        // Sydney clocks go forward on 4 Oct 2026 and back on 4 Apr 2027.
        Case(channel: "Netflix", airdate: "2026-10-03", zone: "Australia/Sydney", day: "2026-10-03", time: "17:00"),
        Case(channel: "Netflix", airdate: "2026-10-05", zone: "Australia/Sydney", day: "2026-10-05", time: "18:00"),
        Case(channel: "Netflix", airdate: "2027-04-03", zone: "Australia/Sydney", day: "2027-04-03", time: "18:00"),
        Case(channel: "Netflix", airdate: "2027-04-05", zone: "Australia/Sydney", day: "2027-04-05", time: "17:00"),
    ]

    @Test("each rule in 6 zones, US summer and winter", arguments: matrix)
    func zoneMatrix(_ item: Case) throws {
        try check(item)
    }

    @Test("clock-change weeks: US, EU and Sydney", arguments: changeovers)
    func dstChangeover(_ item: Case) throws {
        try check(item)
    }

    private func check(_ item: Case) throws {
        let rules = try Fixture.bundledRules()
        let listing = EpisodeListing(episodeID: "tvmaze:1", showID: "tvmaze:1", airdate: item.airdate, airtime: "",
                                     airstamp: nil, channelNames: [item.channel], broadcastNetwork: nil)
        let result = TimeResolver.resolve(listing, rules: rules)
        #expect(result.confidence == .estimated)
        let formatter = DropFormatter(timeZone: try #require(TimeZone(identifier: item.zone)))
        #expect(formatter.localDay(result.date) == item.day)
        #expect(formatter.localTime(result.date) == item.time)
    }
}
