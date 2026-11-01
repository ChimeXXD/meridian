import CryptoKit
import Foundation

/// A small on-disk cache of API responses, keyed by URL, valid for `ttl` seconds.
/// The fetch time is stored inside each entry, so no file-timestamp API is needed
/// (which keeps the privacy manifest to UserDefaults only).
actor ResponseCache {
    private struct Entry: Codable {
        let fetchedAt: Date
        let body: Data
    }

    private let directory: URL
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date

    init(directory: URL, ttl: TimeInterval, now: @escaping @Sendable () -> Date = { .now }) {
        self.directory = directory
        self.ttl = ttl
        self.now = now
    }

    /// The app's default cache: `Caches/<name>`, 6 hours (D-12).
    static func standard(name: String) -> ResponseCache {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return ResponseCache(directory: caches.appendingPathComponent(name), ttl: 6 * 60 * 60)
    }

    func body(for url: URL) -> Data? {
        guard let data = try? Data(contentsOf: file(for: url)),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              now().timeIntervalSince(entry.fetchedAt) < ttl else { return nil }
        return entry.body
    }

    func store(_ body: Data, for url: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(Entry(fetchedAt: now(), body: body)) else { return }
        try? data.write(to: file(for: url), options: .atomic)
    }

    private func file(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return directory.appendingPathComponent(digest.map { String(format: "%02x", $0) }.joined() + ".json")
    }
}
