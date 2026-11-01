import Foundation

/// Reads shows and episodes from TVmaze (CC BY-SA; credited on the Credits screen).
/// TVmaze allows about 20 calls per 10 seconds per IP and answers HTTP 429 beyond that,
/// so the client honours `Retry-After`, backs off, and caches responses for 6 hours.
actor TVmazeClient {
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    typealias Sleep = @Sendable (Duration) async throws -> Void

    static let baseURL = URL(string: "https://api.tvmaze.com")!
    static let maxRetries = 3
    /// Longest `Retry-After` the client will wait; beyond this it reports `.rateLimited` instead of hanging.
    static let maxRetryDelay = 30

    private let cache: ResponseCache
    private let transport: Transport
    private let sleep: Sleep

    init(cache: ResponseCache = .standard(name: "TVmaze"),
         transport: @escaping Transport = TVmazeClient.urlSession,
         sleep: @escaping Sleep = { try await Task.sleep(for: $0) }) {
        self.cache = cache
        self.transport = transport
        self.sleep = sleep
    }

    func search(_ query: String) async throws -> [TVmazeShow] {
        let results: [TVmazeSearchResult] = try await get("/search/shows", [URLQueryItem(name: "q", value: query)])
        return results.map(\.show)
    }

    /// The show with its next and previous episodes embedded. `nextepisode` is absent when none is scheduled.
    func show(id: Int) async throws -> TVmazeShow {
        try await get("/shows/\(id)", [URLQueryItem(name: "embed[]", value: "nextepisode"),
                                       URLQueryItem(name: "embed[]", value: "previousepisode")])
    }

    /// Posters, backgrounds and banners for a show, as URLs (D-37).
    func images(showID: Int) async throws -> [TVmazeImage] {
        try await get("/shows/\(showID)/images", [])
    }

    /// Every streaming episode released on `date` ("yyyy-MM-dd"), worldwide.
    func webSchedule(date: String) async throws -> [TVmazeScheduleItem] {
        try await get("/schedule/web", [URLQueryItem(name: "date", value: date)])
    }

    /// Every broadcast episode airing on `date` in one country.
    func schedule(country: String, date: String) async throws -> [TVmazeScheduleItem] {
        try await get("/schedule", [URLQueryItem(name: "country", value: country), URLQueryItem(name: "date", value: date)])
    }

    func episodes(showID: Int) async throws -> [TVmazeEpisode] {
        try await get("/shows/\(showID)/episodes", [])
    }

    private func get<T: Decodable>(_ path: String, _ query: [URLQueryItem]) async throws -> T {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        // Encoded by hand: URLComponents leaves "&", "+" and "[]" unencoded inside values.
        if !query.isEmpty {
            components.percentEncodedQuery = query
                .map { "\(Self.encode($0.name))=\(Self.encode($0.value ?? ""))" }
                .joined(separator: "&")
        }
        guard let url = components.url else { throw TVmazeError.invalidResponse }

        // A cached body that no longer decodes (e.g. after a model change) falls through to the network.
        if let cached = await cache.body(for: url), let decoded = try? JSONDecoder().decode(T.self, from: cached) {
            return decoded
        }
        let body = try await fetch(url)
        let decoded = try JSONDecoder().decode(T.self, from: body)
        await cache.store(body, for: url)
        return decoded
    }

    private func fetch(_ url: URL) async throws -> Data {
        var attempt = 0
        while true {
            let (body, response) = try await transport(URLRequest(url: url))
            switch response.statusCode {
            case 200..<300:
                return body
            case 429 where attempt < Self.maxRetries:
                let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                let delay = max(0, retryAfter ?? 1 << attempt)
                guard delay <= Self.maxRetryDelay else { throw TVmazeError.rateLimited }
                try await sleep(.seconds(delay))
                attempt += 1
            case 429:
                throw TVmazeError.rateLimited
            default:
                throw TVmazeError.http(status: response.statusCode)
            }
        }
    }

    /// Percent-encodes a query name or value, including the characters URLComponents keeps.
    private static func encode(_ text: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+[]?#")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }

    static let urlSession: Transport = { request in
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TVmazeError.invalidResponse }
        return (data, http)
    }
}
