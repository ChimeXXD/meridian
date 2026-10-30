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

    /// Anime airing in Japan from `from` for `days` days: one entry per show, most popular first.
    func airingSoon(from: Date, days: Int) async throws -> [AniListMedia] {
        let query = "query ($from: Int, $to: Int) { Page(perPage: 50) { airingSchedules(airingAt_greater: $from, " +
            "airingAt_lesser: $to, sort: TIME) { airingAt episode media { \(Self.fields) } } } }"
        let start = Int(from.timeIntervalSince1970)
        let page: AniListPage = try await post(query, ["from": .int(start), "to": .int(start + days * 86_400)])
        var seen = Set<Int>()
        return (page.data.Page.airingSchedules ?? []).map(\.media)
            .filter { !$0.isAdult && $0.countryOfOrigin == "JP" && seen.insert($0.id).inserted }
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
        if let lastRequest {
            let wait = Self.spacing - now().timeIntervalSince(lastRequest)
            if wait > 0 { try await sleep(.milliseconds(Int(wait * 1_000))) }
        }
        lastRequest = now()
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
