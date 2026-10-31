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

    @Test("premieres this week join the list: a season whose episode 1 airs in the window, most popular first")
    func premieres() async throws {
        // A new season is NOT_YET_RELEASED until episode 1 airs, so the popular-airing page never has it (D3-8b).
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("releasing-2026-10-31"), try Self.ok("premieres-2026-11-01")])
        let media = try await Self.client(network).airingSoon(from: Date(iso: "2026-10-31T23:00:00Z"), days: 7)
        let ids = media.map(\.id)
        #expect(Set([178972, 203275, 214536]).isSubset(of: Set(ids)))  // GROTESQQQUE, Demons' Crest, Cardfight!! Vanguard
        #expect(media.first { $0.id == 178972 }?.nextAiringEpisode?.episode == 1)
        #expect(Set(ids).count == ids.count)
        #expect(media.map { $0.popularity ?? 0 } == media.map { $0.popularity ?? 0 }.sorted(by: >))
        #expect(await network.requests.count == 2)
    }

    @Test("a show on both lists appears once, and a premiere in the window's last hour is asked for")
    func premieresMerged() async throws {
        func body(_ list: String) -> Data {
            Data("""
            {"data":{"Page":{\(list)}}}
            """.utf8)
        }
        let show = """
        {"id":7,"isAdult":false,"title":{"romaji":"S"},"popularity":10,"countryOfOrigin":"JP",
        "nextAiringEpisode":{"airingAt":1793530000,"episode":1}}
        """
        let network = TVmazeClientTests.FakeNetwork([(200, [:], body("\"media\":[\(show)]")),
                                                     (200, [:], body("\"airingSchedules\":[{\"airingAt\":1793530000,\"episode\":1,\"media\":\(show)}]"))])
        let from = Date(iso: "2026-10-31T23:40:00Z")
        let media = try await Self.client(network).airingSoon(from: from, days: 7)
        #expect(media.map(\.id) == [7])
        let sent = await network.bodies.last.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let end = Int(from.timeIntervalSince1970) + 7 * 86_400
        let lesser = sent.firstMatch(of: /airingAt_lesser: (\d+)/).flatMap { Int($0.1) } ?? 0
        #expect(lesser >= end)
    }

    /// A premieres page of episode-1 airings, as AniList sends it.
    static func premierePage(ids: [Int], hasNextPage: Bool) -> (status: Int, headers: [String: String], body: Data) {
        let rows = ids.map { id in
            "{\"airingAt\":1793530000,\"episode\":1,\"media\":{\"id\":\(id),\"isAdult\":false,\"title\":{\"romaji\":\"S\(id)\"}," +
                "\"popularity\":\(id),\"countryOfOrigin\":\"JP\",\"nextAiringEpisode\":{\"airingAt\":1793530000,\"episode\":1}}}"
        }
        let json = "{\"data\":{\"Page\":{\"pageInfo\":{\"hasNextPage\":\(hasNextPage)}," +
            "\"airingSchedules\":[\(rows.joined(separator: ","))]}}}"
        return (200, [:], Data(json.utf8))
    }

    @Test("a season's opening week has more premieres than one page: the next pages are read too")
    func premieresPaged() async throws {
        // 1–8 Oct 2026 had 60 episode-1 airings; page 1 stopped on the Tuesday (checked live, 1 Nov 2026).
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("releasing-2026-10-31"),
                                                     Self.premierePage(ids: [11], hasNextPage: true),
                                                     Self.premierePage(ids: [22], hasNextPage: false)])
        let media = try await Self.client(network).airingSoon(from: Date(iso: "2026-10-31T23:00:00Z"), days: 7)
        #expect(Set([11, 22]).isSubset(of: Set(media.map(\.id))))
        #expect(await network.requests.count == 3)
        let last = await network.bodies.last.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        #expect(last.contains("page: 2"))
    }

    @Test("paging stops after 3 pages, to stay well under AniList's 30 requests a minute")
    func premieresPageLimit() async throws {
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("releasing-2026-10-31"),
                                                     Self.premierePage(ids: [11], hasNextPage: true)])
        _ = try await Self.client(network).airingSoon(from: Date(iso: "2026-10-31T23:00:00Z"), days: 7)
        #expect(await network.requests.count == 4)
    }

    @Test("if the premieres request fails, the popular list still shows")
    func premieresFailing() async throws {
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("releasing-2026-10-31"), (500, [:], Data())])
        let media = try await Self.client(network).airingSoon(from: Date(iso: "2026-10-31T00:00:00Z"), days: 7)
        #expect(media.map(\.id).prefix(3) == [195516, 195604, 235])
    }

    @Test("loads within the same hour ask the same question, so the second comes from the cache")
    func premieresCachedWithinTheHour() async throws {
        let network = TVmazeClientTests.FakeNetwork([try Self.ok("releasing-2026-10-31"), try Self.ok("premieres-2026-11-01")])
        let client = Self.client(network)
        _ = try await client.airingSoon(from: Date(iso: "2026-10-31T23:10:00Z"), days: 7)
        _ = try await client.airingSoon(from: Date(iso: "2026-10-31T23:40:00Z"), days: 7)
        #expect(await network.requests.count == 2)
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
