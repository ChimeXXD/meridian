import Foundation
import Testing
@testable import Meridian

@Suite("Source chip content")
struct SourceChipContentTests {
    @Test("every source gets the SPEC wording and a fixed status kind", arguments: [
        (ReleaseSource.broadcast(network: "HBO"), Confidence.exact, "Broadcast", SourceKind.exact),
        (.platformRule("Netflix rule"), .estimated, "Netflix rule", .estimated),
        (.override(note: "Marvel 18:00 PT"), .exact, "Confirmed", .exact),
        (.override(note: "Reported by fans"), .estimated, "Adjusted", .adjusted),
        (.adjusted(base: .anilist, offsetMinutes: 60), .estimated, "Adjusted", .adjusted),
        (.anilist, .exact, "JP broadcast", .exact),
        (.dateOnly, .dateOnly, "Date only", .dateOnly),
    ])
    func wording(source: ReleaseSource, confidence: Confidence, label: String, kind: SourceKind) {
        let content = SourceChipContent(source: source, confidence: confidence)
        #expect(content.label == label)
        #expect(content.kind == kind)
    }

    @Test("every kind has a glyph, so colour is never the only signal")
    func glyphs() {
        let glyphs = SourceKind.allCases.map(\.glyph)
        #expect(glyphs.allSatisfy { !$0.isEmpty })
        #expect(Set(glyphs).count == glyphs.count)
    }

    @Test("section counts read as a phrase", arguments: [(0, "No shows"), (1, "1 show"), (3, "3 shows")])
    @MainActor
    func sectionCount(count: Int, text: String) {
        #expect(SectionHeader.countText(count) == text)
    }

    @Test("episode labels follow SPEC (S2E5), and missing numbers are dropped", arguments: [
        (Optional(2), Optional(5), Optional("S2E5")),
        (nil, 5, "E5"),
        (2, nil, nil),
        (nil, nil, nil),
    ])
    func episodeLabel(season: Int?, number: Int?, expected: String?) {
        let drop = Drop(id: "tvmaze:1:2", showID: "1", showName: "Silo", season: season, number: number, episodeTitle: nil,
                        date: .now, airdate: nil, confidence: .exact, source: .broadcast(network: "Apple TV"),
                        provider: nil, previousDate: nil)
        #expect(drop.episodeLabel == expected)
    }
}
