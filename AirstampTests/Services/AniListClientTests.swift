import Foundation
import Testing
@testable import Airstamp

/// Anime schedules from AniList (D-19): search, one show's next episode, and what airs in Japan this week. Adult
/// titles are never shown, and requests stay under AniList's 30 a minute (CLAUDE.md rule 8).
@Suite("AniList client")
struct AniListClientTests {
    static func ok(_ fixture: String) throws -> (status: Int, headers: [String: String], body: Data) {
        (200, [:], try Fixture.data("anilist/\(fixture).json"))
    }

    static func client(_ network: TVmazeClientTests.FakeNetwork,
                       clock: TestClock = TestClock(now: Date(iso: "2026-10-30T22:00:00Z"))) -> AniListClient {
        AniListClient(cache: ResponseCache(directory: FileManager.default.temporaryDirectory
                                               .appendingPathComponent("anilist-tests-\(UUID().uuidString)"),
                                           ttl: 6 * 3_600, now: { clock.now }),
                      transport: { try await network.send($0) }, sleep: { await network.sleep($0) },
                      now: { clock.now })
    }

    @Test("search posts a GraphQL query to AniList and parses the results")
    func search() async throws {
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("search-frieren")])
        let media = try await Self.client(network).search("Frieren")
        #expect(media.map(\.id).prefix(2) == [154587, 182255])
        #expect(media.first?.displayTitle == "Frieren: Beyond Journey’s End")
        #expect(await network.requests.first?.absoluteString == "https://graphql.anilist.co")
    }

    @Test("adult titles are filtered out of every result (rule 8)")
    func adultFiltered() async throws {
        let body = Data("""
        {"data":{"Page":{"media":[{"id":1,"isAdult":true,"title":{"romaji":"A"}},{"id":2,"isAdult":false,"title":{"romaji":"B"}}]}}}
        """.utf8)
        let media = try await Self.client(TVmazeClientTests.FakeNetwork([(200, [:], body)])).search("x")
        #expect(media.map(\.id) == [2])
    }

    @Test("back-to-back requests are spaced to stay under 30 a minute")
    func rateLimit() async throws {
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("search-frieren")])
        let client = Self.client(network)
        _ = try await client.search("Frieren")
        _ = try await client.search("Frieren 2")
        #expect(await network.sleeps == [.seconds(2)])
    }

    @Test("concurrent requests each take their own slot instead of firing together")
    func rateLimitConcurrent() async throws {
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("search-frieren")])
        let client = Self.client(network)
        async let a = client.search("A")
        async let b = client.search("B")
        async let c = client.search("C")
        _ = try await (a, b, c)
        #expect(await network.sleeps.sorted() == [.seconds(2), .seconds(4)])
    }

    @Test("a repeated search is served from the cache, without a request")
    func cached() async throws {
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("search-frieren")])
        let client = Self.client(network)
        _ = try await client.search("Frieren")
        _ = try await client.search("Frieren")
        #expect(await network.requests.count == 1)
    }

    @Test("airing this week: the most popular airing anime with an episode in the next 7 days, across the whole week")
    func airing() async throws {
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("releasing-2026-10-31")])
        let media = try await Self.client(network).airingSoon(from: Date(iso: "2026-10-31T00:00:00Z"), days: 7)
        let ids = media.map(\.id)
        #expect(ids.prefix(3) == [195516, 195604, 235])  // Apothecary Diaries (in 6 days), Black Clover, Detective Conan
        #expect(!ids.contains(21))  // One Piece's next episode is months away
        #expect(media.allSatisfy { $0.countryOfOrigin == "JP" && !$0.isAdult })
        #expect(media.map { $0.popularity ?? 0 } == media.map { $0.popularity ?? 0 }.sorted(by: >))
    }

    @Test("a search result reads like a TV one: year, where to watch, status, and the cover")
    func searchResult() throws {
        let page = try JSONDecoder().decode(AniListPage.self, from: Fixture.data("anilist/search-frieren.json"))
        let result = SearchResult(media: try #require(page.data.Page.media?.first))
        #expect(result.catalog == .anilist)
        #expect(result.meta == "2023 · Crunchyroll · Finished")
        #expect(result.poster?.absoluteString.hasPrefix("https://") == true)
    }

    @Test("artwork: the banner as the background, the cover as the poster")
    func artwork() throws {
        let page = try JSONDecoder().decode(AniListPage.self, from: Fixture.data("anilist/search-frieren.json"))
        let media = try #require(page.data.Page.media?.first)
        let art = ShowArtwork(media: media)
        #expect(art.background == media.bannerImage)
        #expect(art.poster == media.coverImage?.extraLarge)
    }
}

/// Followed anime become drops worded "Airs in Japan …" (D-40), keyed apart from TVmaze shows.
@Suite("Upcoming loader, anime")
struct UpcomingLoaderAnimeTests {
    @Test("an airing anime becomes a JP broadcast drop with its streaming site")
    func animeDrop() async throws {
        let body = Data("""
        {"data":{"Media":{"id":195604,"isAdult":false,"title":{"romaji":"Black Clover","english":"Black Clover Season 2"},
        "nextAiringEpisode":{"airingAt":1793455200,"episode":5},"externalLinks":[{"site":"Crunchyroll","type":"STREAMING"}]}}}
        """.utf8)
        let anilist = AniListClientTests.client(TVmazeClientTests.FakeNetwork([(200, [:], body)]))
        let loader = UpcomingLoader(client: TVmazeClientTests.client(TVmazeClientTests.FakeNetwork([(500, [:], Data())])),
                                    anilist: anilist, rules: try RulesStore.loadBundled(), viewerCountry: "NG")
        let request = UpcomingLoader.Request(catalog: .anilist, id: 195604, name: "Black Clover", offsetMinutes: 0)
        let drop = try #require(await loader.load([request], now: Date(iso: "2026-10-30T22:00:00Z")).drops.first)
        #expect(drop.source == .anilist)
        #expect(drop.date == Date(timeIntervalSince1970: 1_793_455_200))
        #expect(drop.showID == "anilist:195604")
        #expect(drop.episodeLabel == "E5")
        #expect(drop.provider?.display == "Crunchyroll")
        #expect(drop.showName == "Black Clover Season 2")
    }
}
