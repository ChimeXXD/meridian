import Foundation

/// Reads anime schedules from AniList's GraphQL API (credited on the Credits screen, D-19). Adult titles are always
/// filtered out, requests are spaced at least 2 seconds apart to stay under AniList's 30 a minute, and responses are
/// cached like TVmaze's (CLAUDE.md rule 8).
actor AniListClient {
    typealias Transport = TVmazeClient.Transport
    typealias Sleep = TVmazeClient.Sleep

    static let endpoint = URL(string: "https://graphql.anilist.co")!
    /// 30 requests a minute (AniList's degraded limit).
    static let spacing: TimeInterval = 2
    /// Pages of this week's premieres read at most: 150 episode 1s, 4 requests a load with the popular list.
    static let premierePages = 3

    private let cache: ResponseCache
    private let transport: Transport
    private let sleep: Sleep
    private let now: @Sendable () -> Date
    private var lastRequest: Date?

    init(cache: ResponseCache = .standard(name: "AniList"),
         transport: @escaping Transport = TVmazeClient.urlSession,
         sleep: @escaping Sleep = { try await Task.sleep(for: $0) },
         now: @escaping @Sendable () -> Date = { .now }) {
        self.cache = cache
        self.transport = transport
        self.sleep = sleep
        self.now = now
    }

    private static let fields = """
        id isAdult title { romaji english } startDate { year } status format popularity countryOfOrigin
        coverImage { large extraLarge } bannerImage nextAiringEpisode { airingAt episode } externalLinks { site type }
        """

    func search(_ text: String) async throws -> [AniListMedia] {
        let query = "query ($search: String) { Page(perPage: 20) { media(search: $search, type: ANIME, " +
            "isAdult: false, sort: POPULARITY_DESC) { \(Self.fields) } } }"
        let page: AniListPage = try await post(query, ["search": .string(text)])
        return (page.data.Page.media ?? []).filter { !$0.isAdult }
    }

    func media(id: Int) async throws -> AniListMedia? {
        let query = "query ($id: Int) { Media(id: $id, type: ANIME) { \(Self.fields) } }"
        let single: AniListSingle = try await post(query, ["id": .int(id)])
        return single.data.Media.flatMap { $0.isAdult ? nil : $0 }
    }

    /// The most popular anime airing in Japan with an episode in the next `days` days, most popular first. Asks for
    /// popular airing shows and keeps those whose next episode falls in the window, so the list covers the whole
    /// week (a time-sorted schedule page only reaches about a day). A new season is `NOT_YET_RELEASED` until its
    /// episode 1 airs, so premieres come from a second request for this week's episode 1s (D3-8b). Widening the
    /// first to that status fills it with hyped shows months away and finds none (checked 1 Nov 2026).
    func airingSoon(from: Date, days: Int) async throws -> [AniListMedia] {
        let query = "query { Page(perPage: 50) { media(type: ANIME, status: RELEASING, countryOfOrigin: \"JP\", " +
            "isAdult: false, sort: POPULARITY_DESC) { \(Self.fields) } } }"
        let page: AniListPage = try await post(query, [:])
        let start = from.timeIntervalSince1970, end = start + Double(days) * 86_400
        // Whole hours around the window, so loads within the same hour send the same request and hit the cache. The
        // end is rounded up, or a premiere in the window's last hour would be missed.
        let hour = Int(start) / 3_600 * 3_600, last = hour + days * 86_400 + 3_600
        // A season's opening week has more episode 1s than a page holds (60 in 1–8 Oct 2026), so read on, at most
        // 3 pages. Premieres are extra: a failed page keeps what came before, and the popular list still shows.
        var premieres: [AniListAiring] = []
        for number in 1...Self.premierePages {
            let premiereQuery = "query { Page(page: \(number), perPage: 50) { pageInfo { hasNextPage } " +
                "airingSchedules(airingAt_greater: \(hour), airingAt_lesser: \(last), episode: 1, sort: TIME) " +
                "{ airingAt episode media { \(Self.fields) } } } }"
            guard let result: AniListPage = try? await post(premiereQuery, [:]) else { break }
            premieres += result.data.Page.airingSchedules ?? []
            guard result.data.Page.pageInfo?.hasNextPage == true else { break }
        }
        try Task.checkCancellation()  // A cancelled load must fail, not return a list missing its premieres.
        var seen = Set<Int>()
        let all = (page.data.Page.media ?? []) + premieres.map(\.media)
        return all.filter { media in
            guard !media.isAdult, media.countryOfOrigin == "JP", let next = media.nextAiringEpisode,
                  seen.insert(media.id).inserted else { return false }
            return Double(next.airingAt) >= start && Double(next.airingAt) <= end
        }
        .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
    }

    // MARK: Transport

    enum Variable: Encodable, Sendable {
        case string(String), int(Int)

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value): try container.encode(value)
            case .int(let value): try container.encode(value)
            }
        }
    }

    private struct Request: Encodable {
        let query: String
        let variables: [String: Variable]
    }

    private func post<T: Decodable>(_ query: String, _ variables: [String: Variable]) async throws -> T {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let body = try encoder.encode(Request(query: query, variables: variables))
        // POSTs have no URL to key on, so the cache keys on the request body itself.
        let cacheKey = URL(string: "anilist:\(body.base64EncodedString())") ?? Self.endpoint
        if let cached = await cache.body(for: cacheKey), let decoded = try? JSONDecoder().decode(T.self, from: cached) {
            return decoded
        }
        let data = try await send(body)
        let decoded = try JSONDecoder().decode(T.self, from: data)
        await cache.store(data, for: cacheKey)
        return decoded
    }

    private func send(_ body: Data) async throws -> Data {
        // Reserve this request's slot before sleeping: the actor is reentrant, so concurrent callers (Upcoming loads
        // every followed anime at once) would otherwise all read the same `lastRequest` and fire together.
        let current = now()
        let slot = lastRequest.map { max(current, $0.addingTimeInterval(Self.spacing)) } ?? current
        lastRequest = slot
        let wait = slot.timeIntervalSince(current)
        if wait > 0 { try await sleep(.milliseconds(Int(wait * 1_000))) }
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await transport(request)
        switch response.statusCode {
        case 200..<300: return data
        case 429: throw TVmazeError.rateLimited
        default: throw TVmazeError.http(status: response.statusCode)
        }
    }
}
