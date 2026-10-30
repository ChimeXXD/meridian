import Foundation
import Testing
@testable import Airstamp

/// Search's suggestions before you type: shows with episodes in the next few days, from TVmaze's schedules, so the app
/// isn't empty when you don't know what to look for. Drama and animation in English, plus anime; no news or talk shows.
@Suite("Airing soon")
struct AiringSoonTests {
    static func items(_ fixture: String) throws -> [TVmazeScheduleItem] {
        try JSONDecoder().decode([TVmazeScheduleItem].self, from: Fixture.data("tvmaze/\(fixture).json"))
    }

    @Test("both schedule shapes decode: the show inline (broadcast) and embedded (streaming)")
    func decodesBothShapes() throws {
        #expect(try Self.items("schedule-us-2026-10-30").allSatisfy { $0.show != nil })
        #expect(try Self.items("schedule-web-2026-10-30").allSatisfy { $0.show != nil })
    }

    @Test("picks popular drama and animation, once each, most popular first")
    func picks() throws {
        let shows = AiringSoon.shows(from: try Self.items("schedule-web-2026-10-30") + Self.items("schedule-us-2026-10-30"))
        #expect(shows.count == AiringSoon.limit)
        #expect(Set(shows.map(\.id)).count == shows.count)
        #expect(shows.allSatisfy { ["Scripted", "Animation"].contains($0.type ?? "") })
        #expect(shows.map { $0.weight ?? 0 } == shows.map { $0.weight ?? 0 }.sorted(by: >))
        #expect(shows.map(\.name).contains("Dark Matter"))
        #expect(!shows.map(\.name).contains("Late Night with Seth Meyers"))
    }

    @Test("English shows, and Japanese only for anime")
    func languages() throws {
        let shows = AiringSoon.shows(from: try Self.items("schedule-web-2026-10-30") + Self.items("schedule-us-2026-10-30"))
        #expect(shows.allSatisfy { $0.language == "English" || ($0.language == "Japanese" && $0.type == "Animation") })
    }

    @Test("asks TVmaze for the streaming schedule and the US schedule of a day")
    func requests() async throws {
        let network = TVmazeClientTests.FakeNetwork([(200, [:], Data("[]".utf8)), (200, [:], Data("[]".utf8))])
        let client = TVmazeClientTests.client(network)
        _ = try await client.webSchedule(date: "2026-10-30")
        _ = try await client.schedule(country: "US", date: "2026-10-30")
        let urls = await network.requests.map(\.absoluteString)
        #expect(urls == ["https://api.tvmaze.com/schedule/web?date=2026-10-30",
                         "https://api.tvmaze.com/schedule?country=US&date=2026-10-30"])
    }
}
