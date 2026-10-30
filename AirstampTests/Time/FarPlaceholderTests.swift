import Foundation
import Testing
@testable import Airstamp

/// O-10: TVmaze lists far-off returns on a guessed date with no airtime (Silo S4E1: 2027-07-09). A platform rule
/// would turn that guess into a confident-looking estimate, so beyond 180 days such a listing stays date only.
@Suite("Far placeholder dates")
struct FarPlaceholderTests {
    static let now = Date(iso: "2026-10-30T17:00:00Z")

    @Test("a date more than 180 days out with no airtime is date only, even when a rule matches")
    func farIsDateOnly() {
        let listing = TimeResolverTests.listing(airdate: "2027-07-09", airstamp: "2027-07-09T12:00:00Z")
        let result = TimeResolver.resolve(listing, rules: TimeResolverTests.rules, now: Self.now)
        #expect(result.confidence == .dateOnly)
        #expect(result.source == .dateOnly)
        #expect(result.airdate == "2027-07-09")
    }

    @Test("within 180 days the platform rule still applies")
    func nearUsesRule() {
        let listing = TimeResolverTests.listing(airdate: "2026-11-26", airstamp: "2026-11-26T12:00:00Z")
        let result = TimeResolver.resolve(listing, rules: TimeResolverTests.rules, now: Self.now)
        #expect(result.source == .platformRule("Netflix rule"))
    }

    @Test("a real airtime far away is still an exact broadcast")
    func realAirtimeStaysExact() {
        let listing = TimeResolverTests.listing(airdate: "2027-07-09", airtime: "21:00", airstamp: "2027-07-10T01:00:00Z",
                                                channel: "HBO")
        #expect(TimeResolver.resolve(listing, rules: TimeResolverTests.rules, now: Self.now).confidence == .exact)
    }
}
