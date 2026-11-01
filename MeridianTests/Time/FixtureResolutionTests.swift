import Foundation
import Testing
@testable import Meridian

/// Real TVmaze data against independently confirmed release times (SPEC §3, D1-2).
@Suite("Real episodes resolve to their confirmed release time")
struct FixtureResolutionTests {
    /// The accuracy definition in SPEC: within 5 minutes of the confirmed release.
    static let tolerance: TimeInterval = 5 * 60

    @Test("every recorded episode matches its confirmed time and confidence")
    func everyFixtureMatches() throws {
        let rules = try Fixture.bundledRules()
        let cases = try Fixture.ruleCases()
        #expect(cases.count >= 17)

        for item in cases {
            let listing = item.episode.listing(show: item.show)
            let result = TimeResolver.resolve(listing, rules: rules)
            #expect(result.confidence == item.expected.confidence, "\(item.slug): confidence")
            if let instant = item.expected.instant {
                let gap = abs(result.date.timeIntervalSince(instant))
                #expect(gap <= Self.tolerance, "\(item.slug): off by \(Int(gap / 60)) min (\(item.expected.note))")
            } else {
                #expect(result.airdate == item.episode.airdate, "\(item.slug): date-only keeps the listed airdate")
            }
        }
    }

    /// The rows of SPEC §3.3, listed here so a rule deleted from the JSON can't drop out of the check.
    static let specRows: [(name: String, matches: @Sendable (Resolution) -> Bool)] = [
        ("Netflix rule", { $0.source == .platformRule("Netflix rule") }),
        ("Prime Video rule", { $0.source == .platformRule("Prime Video rule") }),
        ("Apple TV rule", { $0.source == .platformRule("Apple TV rule") }),
        ("Paramount+ rule", { $0.source == .platformRule("Paramount+ rule") }),
        ("HBO broadcast", { $0.source == .broadcast(network: "HBO") }),
        ("date only (Disney+, Peacock, Hulu)", { $0.confidence == .dateOnly }),
        ("overrides", { if case .override = $0.source { true } else { false } }),
    ]

    @Test("every SPEC §3.3 row is backed by at least two real episodes")
    func everyRuleHasTwoFixtures() throws {
        let rules = try Fixture.bundledRules()
        let results = try Fixture.ruleCases().map { TimeResolver.resolve($0.episode.listing(show: $0.show), rules: rules) }
        for row in Self.specRows {
            let backing = results.filter(row.matches).count
            #expect(backing >= 2, "\(row.name) has \(backing) fixture(s)")
        }
        let labels = Set(rules.platforms.map(\.label))
        #expect(labels == ["Netflix rule", "Prime Video rule", "Apple TV rule", "Paramount+ rule"])
    }
}
