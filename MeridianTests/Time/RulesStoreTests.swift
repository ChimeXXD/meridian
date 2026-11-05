import Foundation
import Testing
@testable import Meridian

@Suite("Rules file and RulesStore")
struct RulesStoreTests {
    actor CallCounter {
        private(set) var count = 0
        func hit() { count += 1 }
    }

    static func bundledData() throws -> Data {
        let url = try #require(Bundle.main.url(forResource: "platform-rules", withExtension: "json"))
        return try Data(contentsOf: url)
    }

    @Test("the bundled rules file passes schema validation")
    func bundledIsValid() throws {
        let rules = try Fixture.bundledRules()
        #expect(rules.schemaVersion == 1)
        #expect(rules.platforms.count >= 4)
        try rules.validate()
    }

    @Test("validation rejects a rule with one source, a bad zone or a bad time")
    func validationCatchesBadRules() throws {
        let good = try Fixture.bundledRules()
        var oneSource = good
        oneSource.platforms[0].sources = ["https://only.example"]
        #expect(throws: RulesValidationError.self) { try oneSource.validate() }

        var badZone = good
        badZone.platforms[0].zone = "Mars/Olympus"
        #expect(throws: RulesValidationError.self) { try badZone.validate() }

        var badTime = good
        badTime.platforms[0].time = "25:99"
        #expect(throws: RulesValidationError.self) { try badTime.validate() }

        for fixedOffset in ["UTC+1", "EST", "GMT+01:00"] {
            var offsetZone = good
            offsetZone.platforms[0].zone = fixedOffset
            #expect(throws: RulesValidationError.self, "\(fixedOffset) is not an IANA ID") { try offsetZone.validate() }
        }
    }

    @Test("a show override must be a wall-clock time, never a fixed instant")
    func showOverrideWithInstantIsRejected() throws {
        var rules = try Fixture.bundledRules()
        rules.overrides.append(ReleaseOverride(episode: nil, show: "tvmaze:1", instant: Date(iso: "2026-11-01T00:00:00Z"),
                                               zone: nil, time: nil, dayOffset: nil, confirmed: true, note: "Pinned",
                                               source: "https://g.example"))
        #expect(throws: RulesValidationError.invalidOverride("tvmaze:1")) { try rules.validate() }
    }

    @Test("an episode override can't give both an instant and a wall-clock time")
    func ambiguousEpisodeOverrideIsRejected() throws {
        var rules = try Fixture.bundledRules()
        rules.overrides.append(ReleaseOverride(episode: "tvmaze:2", show: nil, instant: Date(iso: "2026-11-01T00:00:00Z"),
                                               zone: "America/New_York", time: "21:00", dayOffset: 0, confirmed: true,
                                               note: "Both", source: "https://h.example"))
        #expect(throws: RulesValidationError.invalidOverride("tvmaze:2")) { try rules.validate() }
    }

    /// The store serves whichever copy is newer by comparing `updated` as text, which only orders zero-padded
    /// yyyy-MM-dd dates: "9" or "2026-12-1" would beat the bundled file.
    @Test("the updated date must be a real, zero-padded yyyy-MM-dd", arguments: [
        "", "9", "2026-12-1", "2026-1-05", "26-11-03", "2026/11/03", "2026-11-03T00:00", "2026-02-30", "20261-01-01",
    ])
    func badUpdatedIsRejected(_ updated: String) throws {
        var rules = try Fixture.bundledRules()
        rules.updated = updated
        #expect(throws: RulesValidationError.invalidUpdated(updated)) { try rules.validate() }
    }

    @Test("a remote copy with a bad updated date isn't served, however new it claims to be")
    func remoteWithBadUpdatedFallsBack() async throws {
        let bundled = try Fixture.bundledRules()
        var remote = bundled
        remote.updated = "9999"
        remote.platforms[0].time = "23:59"
        let remoteData = try JSONEncoder.rules.encode(remote)
        let store = RulesStore(bundled: bundled, remoteURL: URL(string: "https://rules.example/r.json")) { _ in remoteData }
        #expect(await store.current() == bundled)
    }

    @Test("a channel name can belong to only one platform rule")
    func duplicateMatchIsRejected() throws {
        var rules = try Fixture.bundledRules()
        rules.platforms[1].match.append("netflix")
        #expect(throws: RulesValidationError.invalidPlatform(rules.platforms[1].label)) { try rules.validate() }
    }

    @Test("with remote updates off, the store never touches the network")
    func remoteOffMakesNoCall() async throws {
        let counter = CallCounter()
        let bundled = try Fixture.bundledRules()
        let store = RulesStore(bundled: bundled, remoteURL: nil) { _ in
            await counter.hit()
            return Data()
        }
        let rules = await store.current()
        #expect(rules == bundled)
        #expect(await counter.count == 0)
    }

    @Test("a valid remote copy is used, at most once a day")
    func remoteValidIsUsedDaily() async throws {
        let counter = CallCounter()
        var remote = try Fixture.bundledRules()
        remote.updated = "2099-01-01"  // newer than the bundled file, which the store would otherwise serve
        let remoteData = try JSONEncoder.rules.encode(remote)
        let clock = TestClock(now: Date(iso: "2026-11-01T09:00:00Z"))
        let store = RulesStore(bundled: try Fixture.bundledRules(), remoteURL: URL(string: "https://rules.example/r.json"),
                               now: { clock.now }) { _ in
            await counter.hit()
            return remoteData
        }
        #expect(await store.current().updated == "2099-01-01")
        clock.now = Date(iso: "2026-11-01T20:00:00Z")
        _ = await store.current()
        #expect(await counter.count == 1)
        clock.now = Date(iso: "2026-11-02T09:30:00Z")
        _ = await store.current()
        #expect(await counter.count == 2)
    }

    @Test("invalid JSON, an invalid schema or a network error fall back to the bundled copy")
    func fallbacks() async throws {
        let bundled = try Fixture.bundledRules()
        var invalid = bundled
        invalid.platforms[0].sources = []
        let invalidData = try JSONEncoder.rules.encode(invalid)

        let serverError = RulesStore.httpFetch { request in
            (Data("<html>Server error</html>".utf8),
             HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!)
        }
        let responses: [@Sendable () async throws -> Data] = [
            { Data("not json".utf8) },
            { invalidData },
            { throw URLError(.notConnectedToInternet) },
            { try await serverError(URL(string: "https://rules.example/r.json")!) },
        ]
        for response in responses {
            let store = RulesStore(bundled: bundled, remoteURL: URL(string: "https://rules.example/r.json")) { _ in try await response() }
            #expect(await store.current() == bundled)
        }
    }
}

extension RulesStoreTests {
    @Test("after a failed fetch the store retries within the hour, not the next day")
    func retriesSoonAfterFailure() async throws {
        let counter = CallCounter()
        let clock = TestClock(now: Date(iso: "2026-11-01T09:00:00Z"))
        let store = RulesStore(bundled: try Fixture.bundledRules(), remoteURL: URL(string: "https://rules.example/r.json"),
                               now: { clock.now }) { _ in
            await counter.hit()
            throw URLError(.timedOut)
        }
        _ = await store.current()
        clock.now = Date(iso: "2026-11-01T09:30:00Z")
        _ = await store.current()
        #expect(await counter.count == 1)
        clock.now = Date(iso: "2026-11-01T10:01:00Z")
        _ = await store.current()
        #expect(await counter.count == 2)
    }
}

/// A settable clock for time-dependent tests.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Date
    init(now: Date) { value = now }
    var now: Date {
        get { lock.withLock { value } }
        set { lock.withLock { value = newValue } }
    }
}
