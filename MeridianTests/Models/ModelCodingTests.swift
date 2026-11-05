import Foundation
import Testing
@testable import Meridian

@Suite("Model coding")
struct ModelCodingTests {
    static let sources: [ReleaseSource] = [
        .broadcast(network: "HBO"),
        .platformRule("Netflix rule"),
        .override(note: "Event drop"),
        .adjusted(base: .anilist, offsetMinutes: 30),
        .adjusted(base: .platformRule("Crunchyroll rule"), offsetMinutes: -15),
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

    /// The JSON every source was written with in the widget snapshot (D-05). Each one still reads back as the same
    /// source, and every source but `adjusted` (whose base is now a source, not its label) still writes it.
    static let storedSources: [(json: String, source: ReleaseSource)] = [
        (#"{"broadcast":{"network":"HBO"}}"#, .broadcast(network: "HBO")),
        (#"{"platformRule":{"_0":"Netflix rule"}}"#, .platformRule("Netflix rule")),
        (#"{"override":{"note":"Event drop"}}"#, .override(note: "Event drop")),
        (#"{"anilist":{}}"#, .anilist),
        (#"{"dateOnly":{}}"#, .dateOnly),
    ]

    @Test("a source reads and writes the JSON it always has", arguments: storedSources)
    func storedSource(json: String, source: ReleaseSource) throws {
        #expect(try JSONDecoder().decode(ReleaseSource.self, from: Data(json.utf8)) == source)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(try String(decoding: encoder.encode(source), as: UTF8.self) == json)
    }

    @Test("an adjusted source written with its base's label still decodes", arguments: [
        ("JP broadcast", ReleaseSource.adjusted(base: .anilist, offsetMinutes: 30)),
    ])
    func oldAdjusted(base: String, expected: ReleaseSource) throws {
        let json = #"{"adjusted":{"base":"\#(base)","offsetMinutes":30}}"#
        let source = try JSONDecoder().decode(ReleaseSource.self, from: Data(json.utf8))
        #expect(source == expected)
        #expect(source.baseLabel == base)
    }

    @Test("an adjusted source now writes its base as a source")
    func newAdjusted() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = try encoder.encode(ReleaseSource.adjusted(base: .anilist, offsetMinutes: 30))
        #expect(String(decoding: json, as: UTF8.self) == #"{"adjusted":{"base":{"anilist":{}},"offsetMinutes":30}}"#)
    }
}
