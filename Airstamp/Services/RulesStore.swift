import Foundation

/// Serves the current rules file. Uses the bundled copy unless a remote URL is set,
/// in which case it fetches at most once a day and keeps a copy only if it validates (D-18, D-34).
actor RulesStore {
    typealias Fetch = @Sendable (URL) async throws -> Data

    /// Off while the repo is private (D-34). Set to the raw GitHub URL on Day 7.
    static let remoteURL: URL? = nil

    private let bundled: RulesFile
    private let remoteURL: URL?
    private let now: @Sendable () -> Date
    private let fetch: Fetch
    private var fetched: RulesFile?
    private var nextAttempt: Date?

    /// A good copy is kept a day; after a failed fetch, try again in an hour.
    static let refreshInterval: TimeInterval = 24 * 60 * 60
    static let retryInterval: TimeInterval = 60 * 60

    init(bundled: RulesFile, remoteURL: URL?, now: @escaping @Sendable () -> Date = { .now }, fetch: @escaping Fetch) {
        self.bundled = bundled
        self.remoteURL = remoteURL
        self.now = now
        self.fetch = fetch
    }

    func current() async -> RulesFile {
        guard let remoteURL else { return bundled }
        if let nextAttempt, now() < nextAttempt {
            return fetched ?? bundled
        }
        // Set before awaiting, so concurrent callers don't start a second fetch.
        nextAttempt = now().addingTimeInterval(Self.refreshInterval)
        do {
            let candidate = try RulesFile.decode(try await fetch(remoteURL))
            try candidate.validate()
            fetched = candidate
        } catch {
            // Keep the last good copy; the bundled file is always valid.
            nextAttempt = now().addingTimeInterval(Self.retryInterval)
        }
        return fetched ?? bundled
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
