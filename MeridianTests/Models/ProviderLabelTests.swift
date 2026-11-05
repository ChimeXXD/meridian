import Foundation
import Testing
@testable import Meridian

/// Provider labels name the network and its country ("HBO · US", D-20), and say there's no official stream only
/// when the rules file says so for the viewer's country (CLAUDE.md rule 11).
@Suite("Provider label")
struct ProviderLabelTests {
    static let rules = RulesFile(
        schemaVersion: 1, updated: "2026-10-30", platforms: [], overrides: [],
        providers: [ProviderRule(match: ["Disney+"], noOfficialStreamIn: ["NG"], source: "https://e.example")])

    @Test("a TV network shows its country")
    func networkCountry() {
        let label = ProviderLabel(name: "HBO", countryCode: "US", viewerCountry: "NG", rules: Self.rules)
        #expect(label.display == "HBO · US")
        #expect(!label.noOfficialStream)
    }

    @Test("a global streamer has no country")
    func streamer() {
        #expect(ProviderLabel(name: "Apple TV", countryCode: nil, viewerCountry: "NG", rules: Self.rules).display == "Apple TV")
    }

    @Test("no official stream only where the rules file says so", arguments: [("NG", true), ("GB", false), (nil, false)])
    func noOfficialStream(viewer: String?, expected: Bool) {
        let label = ProviderLabel(name: "Disney+", countryCode: nil, viewerCountry: viewer, rules: Self.rules)
        #expect(label.noOfficialStream == expected)
    }

    @Test("a line that ends with a country splits there, so a tight line shortens the words and keeps ' · US'",
          arguments: [("Paramount+ with Showtime · US", "Paramount+ with Showtime", " · US"),
                      ("S12E104 · Paramount+ with Showtime · US", "S12E104 · Paramount+ with Showtime", " · US"),
                      ("S2E5 · Apple TV", "S2E5 · Apple TV", nil),
                      ("Apple TV", "Apple TV", nil),
                      ("+3 more this week", "+3 more this week", nil)])
    func countrySplit(line: String, lead: String, country: String?) {
        let split = ProviderLabel.splitCountry(line)
        #expect(split.lead == lead)
        #expect(split.country == country)
    }

    /// At the largest text sizes a wrapped meta line left "· US" alone on its last line (BU-10): the country is glued
    /// to its network and each dot to the word before it, while the names' own spaces can still break.
    @Test("a wrapped meta line keeps the country with its network and each dot with the word before it",
          arguments: [("S3E4 · HBO · US", "S3E4\u{00A0}· HBO\u{00A0}·\u{00A0}US"),
                      ("S4E1 · Apple TV", "S4E1\u{00A0}· Apple TV"),
                      ("Paramount+ with Showtime · US", "Paramount+ with Showtime\u{00A0}·\u{00A0}US"),
                      ("Apple TV", "Apple TV")])
    func wrapsWithoutStrandingTheCountry(line: String, expected: String) {
        #expect(ProviderLabel.wrapping(line) == expected)
    }
}
