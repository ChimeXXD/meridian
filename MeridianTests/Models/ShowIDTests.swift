import Foundation
import Testing
@testable import Meridian

/// A show's identity as one value (catalog and ID), written in the strings the snapshot (D-05) and the Live Activity
/// payload (rule 7) have always carried, so neither changes.
@Suite("Show ID")
struct ShowIDTests {
    @Test("reads and writes the snapshot's form: a TVmaze show by its number, an AniList one with its catalog",
          arguments: [("38052", ShowID(catalog: .tvmaze, id: 38052)),
                      ("anilist:154587", ShowID(catalog: .anilist, id: 154587))])
    func stringForm(string: String, show: ShowID) {
        #expect(ShowID(string) == show)
        #expect(show.description == string)
    }

    @Test("anything else isn't a show ID, rather than show 0",
          arguments: ["", "debug", "from", "anilist:", "anilist:x", "tvmaze:38052", "-5", "+5", "38052 ", "0x10"])
    func rejects(string: String) {
        #expect(ShowID(string) == nil)
    }

    @Test("the catalog-qualified key and a drop's ID")
    func keys() {
        let silo = ShowID(catalog: .tvmaze, id: 38052), frieren = ShowID(catalog: .anilist, id: 154587)
        #expect(silo.key == "tvmaze:38052")
        #expect(frieren.key == "anilist:154587")
        #expect(silo.dropID(episode: 3314580) == "tvmaze:38052:3314580")
        #expect(frieren.dropID(episode: 12) == "anilist:154587:12")
    }

    @Test("encodes as the plain string, so the JSON doesn't change, and reads it back")
    func coding() throws {
        let shows = [ShowID(catalog: .tvmaze, id: 38052), ShowID(catalog: .anilist, id: 154587)]
        let json = try JSONEncoder().encode(shows)
        #expect(String(decoding: json, as: UTF8.self) == #"["38052","anilist:154587"]"#)
        #expect(try JSONDecoder().decode([ShowID].self, from: json) == shows)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode([ShowID].self, from: Data(#"["debug"]"#.utf8)) }
    }

    @Test("a drop's show is nil for an ID that isn't one, never show 0")
    func dropShow() {
        let drop = Drop(id: "debug-1", showID: "debug", showName: "Debug Show", season: nil, number: nil,
                        episodeTitle: nil, date: .now, airdate: nil, confidence: .exact, source: .dateOnly,
                        provider: nil, previousDate: nil)
        #expect(drop.show == nil)
        var anime = drop
        anime.showID = "anilist:154587"
        #expect(anime.show == ShowID(catalog: .anilist, id: 154587))
    }
}
