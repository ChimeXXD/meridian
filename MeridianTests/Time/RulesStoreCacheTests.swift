import Foundation
import Testing
@testable import Meridian

/// PLAN Day 7 (Day 1 review item 6): before the remote rules fetch is switched on, the store keeps its last good copy
/// and its next attempt time in Caches, so a cold or offline launch serves the newest valid rules and doesn't fetch
/// again early. A copy older than the bundled file (an app update shipped newer rules) is ignored.
@Suite("Rules store cache")
struct RulesStoreCacheTests {
    static let url = URL(string: "https://rules.example/r.json")!

    static func cacheFile() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("rules-cache-\(UUID().uuidString).json")
    }

    /// The bundled rules file's bytes with a different `updated` date, so the two copies can be told apart.
    static func rules(updated: String) throws -> Data {
        let text = try #require(String(data: try RulesStoreTests.bundledData(), encoding: .utf8))
        let bundled = try Fixture.bundledRules().updated
        return Data(text.replacingOccurrences(of: "\"updated\": \"\(bundled)\"", with: "\"updated\": \"\(updated)\"").utf8)
    }

    @Test("a fetched copy survives a relaunch, and the next attempt time is kept too")
    func survivesRelaunch() async throws {
        let cache = Self.cacheFile()
        let clock = TestClock(now: Date(iso: "2026-11-05T09:00:00Z"))
        let newer = try Self.rules(updated: "2099-01-01")
        let first = RulesStore(bundled: try Fixture.bundledRules(), remoteURL: Self.url, cacheURL: cache,
                               now: { clock.now }) { _ in newer }
        #expect(await first.current().updated == "2099-01-01")

        // Relaunched offline an hour later: the cached copy, and no fetch before its day is up.
        clock.now = Date(iso: "2026-11-05T10:00:00Z")
        let relaunched = RulesStore(bundled: try Fixture.bundledRules(), remoteURL: Self.url, cacheURL: cache,
                                    now: { clock.now }) { _ in
            Issue.record("fetched again before the day was up")
            throw URLError(.notConnectedToInternet)
        }
        #expect(await relaunched.current().updated == "2099-01-01")
    }

    @Test("a cached copy older than the bundled file is ignored: an app update's rules win")
    func newerBundleWins() async throws {
        let cache = Self.cacheFile()
        let clock = TestClock(now: Date(iso: "2026-11-05T09:00:00Z"))
        let older = try Self.rules(updated: "2000-01-01")
        let store = RulesStore(bundled: try Fixture.bundledRules(), remoteURL: Self.url, cacheURL: cache,
                               now: { clock.now }) { _ in older }
        let bundled = try Fixture.bundledRules()
        #expect(await store.current().updated == bundled.updated)

        let relaunched = RulesStore(bundled: bundled, remoteURL: Self.url, cacheURL: cache, now: { clock.now }) { _ in
            throw URLError(.notConnectedToInternet)
        }
        #expect(await relaunched.current().updated == bundled.updated)
    }

    @Test("a damaged cache file is ignored, never trusted")
    func damagedCache() async throws {
        let cache = Self.cacheFile()
        try Data("not json".utf8).write(to: cache)
        let bundled = try Fixture.bundledRules()
        let store = RulesStore(bundled: bundled, remoteURL: Self.url, cacheURL: cache,
                               now: { Date(iso: "2026-11-05T09:00:00Z") }) { _ in throw URLError(.timedOut) }
        #expect(await store.current().updated == bundled.updated)
    }
}
