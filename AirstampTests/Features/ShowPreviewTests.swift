import Foundation
import Testing
@testable import Airstamp

/// The show page opened from any poster on the Search tab: the poster, the title, and the next release date in the
/// app's words, left out entirely when nothing is scheduled (Chime, 1 Nov 2026).
@Suite("Show page from Search")
struct ShowPreviewTests {
    static let now = Date(iso: "2026-11-01T12:00:00Z")
    static let lagos = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))

    static func next(_ catalog: Catalog, id: Int, offsetMinutes: Int = 0,
                     responses: [(status: Int, headers: [String: String], body: Data)]) async throws -> Drop? {
        let network = TVmazeClientTests.FakeNetwork(responses)
        return await ShowPreview.nextDrop(catalog: catalog, id: id, client: TVmazeClientTests.client(network),
                                          anilist: AniListClientTests.client(network),
                                          rules: try Fixture.bundledRules(), offsetMinutes: offsetMinutes,
                                          now: now)
    }

    static func json(_ text: String) -> (status: Int, headers: [String: String], body: Data) {
        (200, [:], Data(text.utf8))
    }

    @Test("a TV show's next episode, timed like everywhere else: Silo's far-off date with no time")
    func tvNext() async throws {
        let drop = try #require(try await Self.next(.tvmaze, id: 44778,
                                                    responses: [(200, [:], Fixture.data("tvmaze/show-silo-embed.json"))]))
        #expect(drop.confidence == .dateOnly)
        #expect(ReleaseWording.outLine(drop, now: Self.now, formatter: Self.lagos)
                == "Out Fri 9 Jul 2027, time not announced")
    }

    @Test("nothing scheduled means no release line at all")
    func tvNothingScheduled() async throws {
        let ended = #"{"id":1,"name":"Ended","type":"Scripted","status":"Ended","_embedded":{"previousepisode":{"id":9,"airdate":"2020-01-01"}}}"#
        #expect(try await Self.next(.tvmaze, id: 1, responses: [Self.json(ended)]) == nil)
    }

    @Test("an anime's next episode is its Japanese broadcast")
    func animeNext() async throws {
        let media = #"{"data":{"Media":{"id":5,"isAdult":false,"title":{"romaji":"A"},"countryOfOrigin":"JP","nextAiringEpisode":{"airingAt":1794200000,"episode":4}}}}"#
        let drop = try #require(try await Self.next(.anilist, id: 5, responses: [Self.json(media)]))
        #expect(drop.number == 4)
        #expect(ReleaseWording.outLine(drop, now: Self.now, formatter: Self.lagos).hasPrefix("Airs in Japan"))
    }

    @Test("a followed anime's own adjustment moves its time, as on Upcoming")
    func animeOffset() async throws {
        let media = #"{"data":{"Media":{"id":5,"isAdult":false,"title":{"romaji":"A"},"countryOfOrigin":"JP","nextAiringEpisode":{"airingAt":1794200000,"episode":4}}}}"#
        let drop = try #require(try await Self.next(.anilist, id: 5, offsetMinutes: 30, responses: [Self.json(media)]))
        #expect(drop.date == Date(timeIntervalSince1970: 1_794_200_000 + 30 * 60))
    }

    @Test("a finished anime has no release line")
    func animeFinished() async throws {
        let media = #"{"data":{"Media":{"id":6,"isAdult":false,"title":{"romaji":"B"},"countryOfOrigin":"JP","nextAiringEpisode":null}}}"#
        #expect(try await Self.next(.anilist, id: 6, responses: [Self.json(media)]) == nil)
    }

    @Test("a failed request leaves the line out rather than guessing")
    func failed() async throws {
        #expect(try await Self.next(.tvmaze, id: 1, responses: [(500, [:], Data())]) == nil)
    }

    @Test("the page uses the larger poster: TVmaze's original, AniList's extra large")
    func largePoster() throws {
        // The recordings carry no image links (rule 9), so a small show with both sizes.
        let json = #"{"id":1,"name":"S","image":{"medium":"https://example.com/m.jpg","original":"https://example.com/o.jpg"}}"#
        let show = try JSONDecoder().decode(TVmazeShow.self, from: Data(json.utf8))
        #expect(SearchResult(show: show).largePoster?.absoluteString == "https://example.com/o.jpg")
        #expect(SearchResult(show: show).poster?.absoluteString == "https://example.com/m.jpg")
    }
}
