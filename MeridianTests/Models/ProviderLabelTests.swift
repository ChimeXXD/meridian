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
}
