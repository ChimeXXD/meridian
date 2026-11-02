import Foundation
import Testing
@testable import Meridian

/// The art behind Welcome (Chime's picks, 2 Nov: Mindvalley's staggered rows, Nike's mixed sizes, HBO's TV-and-anime
/// collage). TV and anime alternate, each URL appears once, and too little art leaves the plain night.
@Suite("Welcome wall")
struct WelcomeWallTests {
    static func tile(_ name: String, _ shape: WelcomeWall.Tile.Shape = .poster) -> WelcomeWall.Tile {
        WelcomeWall.Tile(url: URL(string: "https://example.com/\(name).jpg")!, shape: shape)
    }

    @Test("TV and anime alternate, then deal across the rows in turn")
    func interleaves() {
        let tv = (1...6).map { Self.tile("t\($0)") }
        let anime = (1...3).map { Self.tile("a\($0)", .wide) }
        let rows = WelcomeWall.arrange(tv: tv, anime: anime)
        let names = rows.map { $0.map { $0.url.deletingPathExtension().lastPathComponent } }
        #expect(names == [["t1", "a2", "t4"], ["a1", "t3", "t5"], ["t2", "a3", "t6"]])
    }

    @Test("a picture already on the wall isn't added again")
    func dedupes() {
        let tv = (1...9).map { Self.tile("t\($0)") }
        let rows = WelcomeWall.arrange(tv: tv, anime: [Self.tile("t1"), Self.tile("t2")])
        #expect(rows.flatMap(\.self).count == 9)
    }

    @Test("too little art leaves the plain night")
    func tooFew() {
        let rows = WelcomeWall.arrange(tv: (1...5).map { Self.tile("t\($0)") }, anime: [Self.tile("a1")])
        #expect(rows.isEmpty)
    }

    @Test("the rows never hold more than the screen needs")
    func capped() {
        let rows = WelcomeWall.arrange(tv: (1...40).map { Self.tile("t\($0)") }, anime: [])
        #expect(rows.allSatisfy { $0.count <= WelcomeWall.perRow })
    }

    @Test("recorded schedules fill the wall with TV posters, anime covers and a few anime banners")
    func fromFixtures() throws {
        let rules = try Fixture.bundledRules()
        let items = try AiringSoonTests.items("schedule-web-2026-10-30") + AiringSoonTests.items("schedule-us-2026-10-30")
        let picks = AiringSoon.pool(from: items, rules: rules, now: Date(iso: "2026-10-30T12:00:00Z"),
                                    formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
        let page = try JSONDecoder().decode(AniListPage.self, from: Fixture.data("anilist/releasing-2026-10-31.json"))
        let tv = WelcomeWall.tvTiles(picks)
        let anime = WelcomeWall.animeTiles(page.data.Page.media ?? [])
        #expect(!tv.isEmpty && tv.allSatisfy { $0.shape == .poster })
        #expect(anime.contains { $0.shape == .wide } && anime.contains { $0.shape == .poster })
        let rows = WelcomeWall.arrange(tv: tv, anime: anime)
        #expect(rows.count == WelcomeWall.rowCount)
        #expect(rows.allSatisfy { row in row.contains { anime.contains($0) } })
    }
}
