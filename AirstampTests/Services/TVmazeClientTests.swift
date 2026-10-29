import Foundation
import Testing
@testable import Airstamp

@Suite("TVmazeClient")
struct TVmazeClientTests {
    /// Replays canned responses and records every request and every requested sleep.
    actor FakeNetwork {
        private var responses: [(status: Int, headers: [String: String], body: Data)]
        private(set) var requests: [URL] = []
        private(set) var sleeps: [Duration] = []

        init(_ responses: [(status: Int, headers: [String: String], body: Data)]) {
            self.responses = responses
        }

        func send(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
            let url = try #require(request.url)
            requests.append(url)
            let next = responses.count > 1 ? responses.removeFirst() : responses[0]
            let response = HTTPURLResponse(url: url, statusCode: next.status, httpVersion: nil, headerFields: next.headers)!
            return (next.body, response)
        }

        func sleep(_ duration: Duration) { sleeps.append(duration) }
    }

    static func client(_ network: FakeNetwork, clock: TestClock = TestClock(now: Date(iso: "2026-10-30T09:00:00Z")),
                       cacheDirectory: URL = FileManager.default.temporaryDirectory
                           .appendingPathComponent("tvmaze-tests-\(UUID().uuidString)")) -> TVmazeClient {
        TVmazeClient(cache: ResponseCache(directory: cacheDirectory, ttl: 6 * 60 * 60, now: { clock.now }),
                     transport: { try await network.send($0) },
                     sleep: { await network.sleep($0) })
    }

    static func ok(_ fixture: String) throws -> (status: Int, headers: [String: String], body: Data) {
        (200, [:], try Fixture.data("tvmaze/\(fixture).json"))
    }

    @Test("search parses real results and keeps same-name shows apart")
    func searchEuphoria() async throws {
        let network = FakeNetwork([try Self.ok("search-euphoria")])
        let results = try await Self.client(network).search("Euphoria")
        #expect(results.count == 4)
        let hbo = try #require(results.first { $0.network?.name == "HBO" })
        #expect(hbo.premiered == "2019-06-16")
        #expect(results.contains { $0.network?.name == "HOT3" })
        let url = try #require(await network.requests.first)
        #expect(url.absoluteString == "https://api.tvmaze.com/search/shows?q=Euphoria")
    }

    @Test("a query with spaces and symbols is encoded")
    func searchEncoding() async throws {
        let network = FakeNetwork([(200, [:], Data("[]".utf8))])
        _ = try await Self.client(network).search("Daredevil: Born Again & more")
        let url = try #require(await network.requests.first)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        #expect(items == [URLQueryItem(name: "q", value: "Daredevil: Born Again & more")])
        #expect(url.absoluteString.contains("%26"))
    }

    @Test("show(id:) asks for the next and previous episodes and parses them")
    func showWithEmbeds() async throws {
        let network = FakeNetwork([try Self.ok("show-silo-embed")])
        let show = try await Self.client(network).show(id: 44933 /* any id; the fixture is Silo */)
        #expect(show.name == "Silo")
        #expect(show.webChannel?.name == "Apple TV")
        #expect(show.embedded?.nextepisode?.airdate == "2027-07-09")
        #expect(show.embedded?.previousepisode?.season == 3)
        let url = try #require(await network.requests.first)
        #expect(url.absoluteString == "https://api.tvmaze.com/shows/44933?embed%5B%5D=nextepisode&embed%5B%5D=previousepisode")
    }

    @Test("episodes(showID:) parses the full list")
    func episodes() async throws {
        let network = FakeNetwork([try Self.ok("episodes-silo")])
        let list = try await Self.client(network).episodes(showID: 1)
        #expect(list.count == 31)
        #expect(list.allSatisfy { $0.season != nil && $0.number != nil })
    }

    @Test("a 429 waits for Retry-After, then succeeds")
    func retryAfterIsHonoured() async throws {
        let network = FakeNetwork([(429, ["Retry-After": "2"], Data()), try Self.ok("search-silo")])
        let results = try await Self.client(network).search("Silo")
        #expect(!results.isEmpty)
        #expect(await network.requests.count == 2)
        #expect(await network.sleeps == [.seconds(2)])
    }

    @Test("a 429 without Retry-After backs off exponentially")
    func exponentialBackoff() async throws {
        let network = FakeNetwork([(429, [:], Data()), (429, [:], Data()), try Self.ok("search-silo")])
        _ = try await Self.client(network).search("Silo")
        #expect(await network.sleeps == [.seconds(1), .seconds(2)])
    }

    @Test("persistent 429s give up with a rate-limited error")
    func givesUp() async throws {
        let network = FakeNetwork([(429, [:], Data())])
        await #expect(throws: TVmazeError.rateLimited) {
            _ = try await Self.client(network).search("Silo")
        }
        #expect(await network.requests.count == 4)  // 1 try + 3 retries
    }

    @Test("a Retry-After longer than the cap gives up instead of hanging")
    func longRetryAfterGivesUp() async throws {
        let network = FakeNetwork([(429, ["Retry-After": "3600"], Data()), try Self.ok("search-silo")])
        await #expect(throws: TVmazeError.rateLimited) {
            _ = try await Self.client(network).search("Silo")
        }
        #expect(await network.sleeps.isEmpty)
    }

    @Test("other HTTP errors are reported, not retried")
    func httpError() async throws {
        let network = FakeNetwork([(404, [:], Data())])
        await #expect(throws: TVmazeError.http(status: 404)) {
            _ = try await Self.client(network).show(id: 1)
        }
        #expect(await network.requests.count == 1)
    }

    @Test("responses are cached on disk for 6 hours")
    func sixHourCache() async throws {
        let network = FakeNetwork([try Self.ok("search-silo")])
        let clock = TestClock(now: Date(iso: "2026-10-30T09:00:00Z"))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("tvmaze-cache-\(UUID().uuidString)")

        _ = try await Self.client(network, clock: clock, cacheDirectory: directory).search("Silo")
        clock.now = Date(iso: "2026-10-30T14:59:00Z")
        // A fresh client on the same directory still hits the disk cache.
        _ = try await Self.client(network, clock: clock, cacheDirectory: directory).search("Silo")
        #expect(await network.requests.count == 1)

        clock.now = Date(iso: "2026-10-30T15:01:00Z")
        _ = try await Self.client(network, clock: clock, cacheDirectory: directory).search("Silo")
        #expect(await network.requests.count == 2)
    }
}
