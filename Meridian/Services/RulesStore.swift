import Foundation

/// Serves the current rules file. Uses the bundled copy unless a remote URL is set,
/// in which case it fetches at most once a day and keeps a copy only if it validates (D-18, D-34).
/// The last good copy and the next attempt time are kept in Caches, so a cold or offline launch serves the newest
/// valid rules without fetching early; a copy older than the bundled file (an app update) is never served.
actor RulesStore {
    typealias Fetch = @Sendable (URL) async throws -> Data

    /// The rules file on `main`, fetched once a day now that the repo is public (D-34, Day 7).
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/ChimeXXD/meridian/main/rules/platform-rules.json")
    /// Where the last good copy and the next attempt time are kept between launches.
    static var cacheURL: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("platform-rules-cache.json")
    }

    /// What's kept between launches: the fetched file's exact bytes, never re-encoded, and when to try again.
    private struct Cached: Codable {
        var nextAttempt: Date
        var rules: Data?
    }

    private let bundled: RulesFile
    private let remoteURL: URL?
    private let cacheURL: URL?
    private let now: @Sendable () -> Date
    private let fetch: Fetch
    private var fetched: RulesFile?
    private var nextAttempt: Date?

    /// A good copy is kept a day; after a failed fetch, try again in an hour.
    static let refreshInterval: TimeInterval = 24 * 60 * 60
    static let retryInterval: TimeInterval = 60 * 60

    init(bundled: RulesFile, remoteURL: URL?, cacheURL: URL? = nil, now: @escaping @Sendable () -> Date = { .now },
         fetch: @escaping Fetch) {
        self.bundled = bundled
        self.remoteURL = remoteURL
        self.cacheURL = cacheURL
        self.now = now
        self.fetch = fetch
        // A damaged or invalid cache is ignored, never trusted.
        if let cacheURL, let data = try? Data(contentsOf: cacheURL),
           let cached = try? JSONDecoder().decode(Cached.self, from: data) {
            nextAttempt = cached.nextAttempt
            if let bytes = cached.rules, let rules = try? RulesFile.decode(bytes), (try? rules.validate()) != nil {
                fetched = rules
                fetchedBytes = bytes
            }
        }
    }

    /// The newest valid rules: the fetched copy unless the bundled one is newer.
    private var newest: RulesFile {
        guard let fetched, fetched.updated >= bundled.updated else { return bundled }
        return fetched
    }
    private var fetchedBytes: Data?

    func current() async -> RulesFile {
        guard let remoteURL else { return bundled }
        if let nextAttempt, now() < nextAttempt {
            return newest
        }
        // Set before awaiting, so concurrent callers don't start a second fetch.
        nextAttempt = now().addingTimeInterval(Self.refreshInterval)
        do {
            let bytes = try await fetch(remoteURL)
            let candidate = try RulesFile.decode(bytes)
            try candidate.validate()
            fetched = candidate
            fetchedBytes = bytes
        } catch {
            // Keep the last good copy; the bundled file is always valid.
            nextAttempt = now().addingTimeInterval(Self.retryInterval)
        }
        save()
        return newest
    }

    private func save() {
        guard let cacheURL, let nextAttempt,
              let data = try? JSONEncoder().encode(Cached(nextAttempt: nextAttempt, rules: fetchedBytes)) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }

    /// A fetch over HTTP that fails on any non-2xx status, so an error page is never parsed as rules.
    static func httpFetch(transport: @escaping TVmazeClient.Transport = TVmazeClient.urlSession) -> Fetch {
        { url in
            let (data, response) = try await transport(URLRequest(url: url))
            guard (200..<300).contains(response.statusCode) else { throw URLError(.badServerResponse) }
            return data
        }
    }

    static func loadBundled(from bundle: Bundle = .main) throws -> RulesFile {
        guard let url = bundle.url(forResource: "platform-rules", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let rules = try RulesFile.decode(Data(contentsOf: url))
        try rules.validate()
        return rules
    }
}
