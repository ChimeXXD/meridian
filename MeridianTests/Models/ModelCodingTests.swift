import Foundation
import Testing
@testable import Meridian

@Suite("Model coding")
struct ModelCodingTests {
    static let sources: [ReleaseSource] = [
        .broadcast(network: "HBO"),
        .platformRule("Netflix rule"),
        .override(note: "Event drop"),
        .adjusted(base: "JP broadcast", offsetMinutes: 30),
        .anilist,
        .dateOnly,
    ]

    @Test("a Drop round-trips through JSON with every source", arguments: sources)
    func dropRoundTrip(_ source: ReleaseSource) throws {
        let drop = Drop(id: "tvmaze:86175:3314580", showID: "tvmaze:86175", showName: "Pluribus", season: 1, number: 3,
                        episodeTitle: "Grenade", date: Date(iso: "2025-11-14T02:00:00Z"), airdate: "2025-11-14",
                        confidence: .estimated, source: source,
                        provider: ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false),
                        previousDate: Date(iso: "2025-11-14T01:00:00Z"))
        let data = try JSONEncoder().encode(drop)
        #expect(try JSONDecoder().decode(Drop.self, from: data) == drop)
    }

    @Test("confidence and catalog values round-trip", arguments: [Confidence.exact, .estimated, .dateOnly])
    func enumsRoundTrip(_ confidence: Confidence) throws {
        let data = try JSONEncoder().encode([confidence])
        #expect(try JSONDecoder().decode([Confidence].self, from: data) == [confidence])
        let catalogs: [Catalog] = [.tvmaze, .anilist]
        #expect(try JSONDecoder().decode([Catalog].self, from: JSONEncoder().encode(catalogs)) == catalogs)
    }

    @Test("a DropSnapshot round-trips through JSON")
    func snapshotRoundTrip() throws {
        let drop = Drop(id: "tvmaze:1:2", showID: "tvmaze:1", showName: "Silo", season: 4, number: 1, episodeTitle: nil,
                        date: Date(iso: "2027-07-09T12:00:00Z"), airdate: "2027-07-09", confidence: .dateOnly,
                        source: .dateOnly, provider: nil, previousDate: nil)
        let snapshot = DropSnapshot(generatedAt: Date(iso: "2026-10-30T09:00:00Z"), drops: [drop], nextReturn: drop)
        let data = try JSONEncoder().encode(snapshot)
        #expect(try JSONDecoder().decode(DropSnapshot.self, from: data) == snapshot)
    }
}
