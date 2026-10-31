import Foundation
import Testing
@testable import Airstamp

/// Search never auto-picks: every result says year, network (with country) and status, so the US "Euphoria" can be
/// told from the Israeli one it was based on (SPEC §1, Search).
@Suite("Search results")
struct SearchResultTests {
    static func results() throws -> [SearchResult] {
        let shows = try JSONDecoder().decode([TVmazeSearchResult].self, from: Fixture.data("tvmaze/search-euphoria.json"))
        return shows.map { SearchResult(show: $0.show) }
    }

    @Test("same-name shows read differently")
    func disambiguation() throws {
        let results = try Self.results()
        #expect(results.map(\.title) == ["Euphoria", "Euphoria", "Euphorie", "Eufòria"])
        #expect(results.map(\.meta) == [
            "2019 · HBO · US · Ended",
            "2012 · HOT3 · IL · Ended",
            "2025 · RTL+ · To be determined",
            "2022 · TV3 · ES · To be determined",
        ])
    }

    @Test("a grid cell still tells them apart: year · network · country, then the status on its own line")
    func gridMeta() throws {
        let results = try Self.results()
        #expect(results.map(\.gridMeta) == ["2019 · HBO · US", "2012 · HOT3 · IL", "2025 · RTL+", "2022 · TV3 · ES"])
        #expect(results.map(\.status) == ["Ended", "Ended", "To be determined", "To be determined"])
    }

    @Test("following a result hands the store its id, name, year and network")
    func followPayload() throws {
        let show = try #require(try Self.results().first).followShow
        #expect(show == FollowStore.Show(catalog: .tvmaze, id: 28826, name: "Euphoria", year: 2019, network: "HBO"))
    }
}

/// Search shows each show's poster (Chime's picks: Plex and Apple TV poster rows, Plex's poster grid).
@Suite("Search posters")
struct SearchPosterTests {
    @Test("a result carries TVmaze's medium poster, and none when TVmaze has no image")
    func poster() throws {
        let items = try JSONDecoder().decode([TVmazeScheduleItem].self,
                                             from: Fixture.data("tvmaze/schedule-web-2026-10-30.json"))
        let show = try #require(items.first?.show)
        #expect(SearchResult(show: show).poster?.absoluteString
                == "https://static.tvmaze.com/uploads/images/medium_portrait/644/1611629.jpg")
        let euphoria = try JSONDecoder().decode([TVmazeSearchResult].self, from: Fixture.data("tvmaze/search-euphoria.json"))
        #expect(SearchResult(show: euphoria[0].show).poster == nil)
    }
}
