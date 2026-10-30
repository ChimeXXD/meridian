import Foundation
import Testing
@testable import Airstamp

/// SPEC: Out now (drop ≤ now < drop + 1 h), Next 24 hours (now < drop ≤ now + 24 h), This week (up to now + 7 days),
/// Later, Date only, Nothing scheduled. Checked with a fixed clock and a drop on each side of every boundary.
@Suite("Upcoming sections")
struct UpcomingSectionsTests {
    static let now = Date(iso: "2026-11-01T12:00:00Z")
    static let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))

    static func drop(_ name: String, in seconds: TimeInterval, dateOnly: Bool = false, airdate: String? = nil) -> Drop {
        Drop(id: "tvmaze:\(name)", showID: name, showName: name, season: 1, number: 1, episodeTitle: nil,
             date: now.addingTimeInterval(seconds), airdate: airdate, confidence: dateOnly ? .dateOnly : .exact,
             source: dateOnly ? .dateOnly : .broadcast(network: "HBO"), provider: nil, previousDate: nil)
    }

    static let hour: TimeInterval = 3_600, day: TimeInterval = 86_400

    /// Seconds from now: an hour ago, a day, a week, and one second either side.
    static let boundaryCases: [(TimeInterval, UpcomingSections.Bucket)] = [
        (-3_600, .gone), (-3_599, .outNow), (0, .outNow), (1, .next24Hours),
        (86_400, .next24Hours), (86_401, .thisWeek), (604_800, .thisWeek), (604_801, .later),
    ]

    @Test("each side of every boundary lands in the right section", arguments: boundaryCases)
    func boundaries(offset: TimeInterval, expected: UpcomingSections.Bucket) {
        #expect(UpcomingSections.bucket(Self.drop("x", in: offset), now: Self.now) == expected)
    }

    @Test("a date-only drop is always Date only, whatever its sort key")
    func dateOnly() {
        #expect(UpcomingSections.bucket(Self.drop("x", in: 3_600, dateOnly: true), now: Self.now) == .dateOnly)
    }

    @Test("the hero is the soonest drop that isn't gone, and leaves its section")
    func hero() {
        let drops = [Self.drop("Later", in: 9 * Self.day), Self.drop("Soon", in: 2 * Self.hour),
                     Self.drop("Gone", in: -2 * Self.hour), Self.drop("Week", in: 3 * Self.day)]
        let sections = UpcomingSections.make(drops: drops, nothingScheduled: ["Quiet"], now: Self.now)
        #expect(sections.hero?.showName == "Soon")
        #expect(sections.sections.map(\.title) == ["This week", "Later", "Nothing scheduled"])
        #expect(sections.sections.flatMap(\.drops).map(\.showName) == ["Week", "Later"])
        #expect(sections.sections.last?.shows == ["Quiet"])
    }

    @Test("with no timed drop, the headline names the next real date")
    func emptyNamesDate() {
        let silo = Self.drop("Silo", in: 250 * Self.day, dateOnly: true, airdate: "2027-07-09")
        let sections = UpcomingSections.make(drops: [silo], nothingScheduled: [], now: Self.now)
        #expect(sections.hero == nil)
        #expect(sections.emptyHeadline(formatter: Self.lagos) == "Silo returns Fri 9 Jul")
    }

    @Test("with nothing at all, it says so and promises no refresh interval (D-27)")
    func emptyNothing() {
        let sections = UpcomingSections.make(drops: [], nothingScheduled: ["Quiet"], now: Self.now)
        #expect(sections.emptyHeadline(formatter: Self.lagos)
                == "Nothing scheduled for your shows yet. Airstamp checks again each time you open it.")
    }
}
