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

    static func quiet(_ name: String) -> UpcomingLoader.Quiet {
        UpcomingLoader.Quiet(showID: name, name: name, status: "Ended", lastAired: "2025-03-29")
    }

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
        let sections = UpcomingSections.make(drops: drops, nothingScheduled: [Self.quiet("Quiet")], now: Self.now)
        #expect(sections.hero?.showName == "Soon")
        #expect(sections.sections.map(\.title) == ["This week", "Later", "Nothing scheduled"])
        #expect(sections.sections.flatMap(\.drops).map(\.showName) == ["Week", "Later"])
        #expect(sections.sections.last?.shows.map(\.name) == ["Quiet"])
    }

    @Test("with no timed drop, the headline names the next real date")
    func emptyNamesDate() {
        let silo = Self.drop("Silo", in: 250 * Self.day, dateOnly: true, airdate: "2027-07-09")
        let sections = UpcomingSections.make(drops: [silo], nothingScheduled: [], now: Self.now)
        #expect(sections.hero == nil)
        #expect(sections.emptyHeadline(formatter: Self.lagos, now: Self.now) == "Silo returns Fri 9 Jul 2027")
    }

    @Test("with nothing at all, it says so and promises no refresh interval (D-27)")
    func emptyNothing() {
        let sections = UpcomingSections.make(drops: [], nothingScheduled: [Self.quiet("Quiet")], now: Self.now)
        #expect(sections.emptyHeadline(formatter: Self.lagos, now: Self.now)
                == "Nothing scheduled for your shows yet. Airstamp checks again each time you open it.")
    }

    @Test("with no countdown, the top of the screen spotlights a show instead of going blank")
    func spotlight() {
        let silo = Self.drop("Silo", in: 250 * Self.day, dateOnly: true, airdate: "2027-07-09")
        let withDate = UpcomingSections.make(drops: [silo], nothingScheduled: [Self.quiet("Solo Leveling")], now: Self.now)
        #expect(withDate.spotlight == .dateOnly(silo))
        #expect(withDate.sections.flatMap(\.drops).isEmpty)
        #expect(withDate.sections.map(\.title) == ["Nothing scheduled"])
        let quietOnly = UpcomingSections.make(drops: [], nothingScheduled: [Self.quiet("Solo Leveling")], now: Self.now)
        #expect(quietOnly.spotlight == .quiet(Self.quiet("Solo Leveling")))
        // Like the hero, the spotlighted show leaves its section rather than appearing twice.
        #expect(quietOnly.sections.isEmpty)
        let twoQuiet = UpcomingSections.make(drops: [], nothingScheduled: [Self.quiet("Solo Leveling"), Self.quiet("Arcane")],
                                             now: Self.now)
        #expect(twoQuiet.sections.flatMap(\.shows).map(\.name) == ["Arcane"])
        let timed = UpcomingSections.make(drops: [Self.drop("Soon", in: Self.hour)], nothingScheduled: [], now: Self.now)
        #expect(timed.spotlight == nil)
        // Nothing left to feature (the only drop has gone): no spotlight, so the view falls back to SPEC's sentence.
        let gone = UpcomingSections.make(drops: [Self.drop("Gone", in: -2 * Self.hour)], nothingScheduled: [], now: Self.now)
        #expect(gone.hero == nil && gone.spotlight == nil)
    }
}
