import Foundation
import Testing
@testable import Meridian

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

    /// Both recorded schedules of Fri 30 Oct 2026, resolved with the bundled rules and seen from Lagos.
    static func pool(at now: String) throws -> [AiringSoon.Pick] {
        AiringSoon.pool(from: try items("schedule-web-2026-10-30") + items("schedule-us-2026-10-30"),
                        rules: try Fixture.bundledRules(), now: try Date(now, strategy: .iso8601),
                        formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
    }

    static func pick(_ name: String, at now: String) throws -> AiringSoon.Pick? {
        try pool(at: now).first { $0.show.name == name }
    }

    @Test("schedule items keep the episode: season, number, airdate and airtime")
    func decodesEpisode() throws {
        let item = try #require(try Self.items("schedule-web-2026-10-30").first { $0.show?.name == "Dark Matter" })
        #expect(item.episode.season == 2)
        #expect(item.episode.number == 10)
        #expect(item.episode.airdate == "2026-10-30")
        #expect(item.episode.airtime == "")
    }

    @Test("picks popular drama and animation, once each, most popular first, uncapped until filtered")
    func picks() throws {
        let shows = try Self.pool(at: "2026-10-30T00:00:00Z").map(\.show)
        #expect(shows.count > AiringSoon.limit)
        #expect(Set(shows.map(\.id)).count == shows.count)
        #expect(shows.allSatisfy { ["Scripted", "Animation"].contains($0.type ?? "") })
        #expect(shows.map { $0.weight ?? 0 } == shows.map { $0.weight ?? 0 }.sorted(by: >))
        #expect(shows.map(\.name).contains("Dark Matter"))
        #expect(!shows.map(\.name).contains("Late Night with Seth Meyers"))
    }

    @Test("English shows, and Japanese only for anime")
    func languages() throws {
        let shows = try Self.pool(at: "2026-10-30T00:00:00Z").map(\.show)
        #expect(shows.allSatisfy { $0.language == "English" || ($0.language == "Japanese" && $0.type == "Animation") })
    }

    @Test("a placeholder airstamp is resolved by the platform rule, never trusted (rule 2)")
    func placeholderResolved() throws {
        // Dark Matter S2E10: airtime "" and a fake 12:00Z; the Apple TV rule says 21:00 New York the evening before.
        let pick = try #require(try Self.pick("Dark Matter", at: "2026-10-30T00:00:00Z"))
        #expect(pick.resolution.confidence == .estimated)
        #expect(pick.resolution.date == (try Date("2026-10-30T01:00:00Z", strategy: .iso8601)))
    }

    @Test("an episode already out by its real time is gone, though its placeholder is still ahead")
    func upcomingByResolvedTime() throws {
        // 06:00Z: after the real 01:00Z release, before the fake 12:00Z airstamp.
        #expect(try Self.pick("Dark Matter", at: "2026-10-30T06:00:00Z") == nil)
    }

    @Test("a real broadcast airtime is exact")
    func broadcastExact() throws {
        let pick = try #require(try Self.pick("Fire Country", at: "2026-10-30T06:00:00Z"))
        #expect(pick.resolution.confidence == .exact)
        #expect(pick.resolution.date == (try Date("2026-10-31T01:00:00Z", strategy: .iso8601)))
    }

    @Test("episodes dropped at the same time keep the lowest one: a new season keeps episode 1")
    func sameTimeDropKeepsLowestEpisode() throws {
        // Netflix drops the whole season (E1–E3); Paramount+ drops E10–E13 of Avatar: Seven Havens together.
        let season = try #require(try Self.pick("How to Ruin Diwali: Meet the Parents", at: "2026-10-30T00:00:00Z"))
        #expect(season.episode.season == 1)
        #expect(season.episode.number == 1)
        let batch = try #require(try Self.pick("Avatar: Seven Havens", at: "2026-10-30T00:00:00Z"))
        #expect(batch.episode.number == 10)
    }

    @Test("the lowest episode wins whatever order the schedule lists them in")
    func tieBreakIgnoresListOrder() throws {
        // The recording lists each batch in ascending order, so feed it reversed to prove the tie-break, not the order.
        let items = try (Self.items("schedule-web-2026-10-30") + Self.items("schedule-us-2026-10-30")).reversed()
        let pool = AiringSoon.pool(from: Array(items), rules: try Fixture.bundledRules(),
                                   now: Date(iso: "2026-10-30T00:00:00Z"),
                                   formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
        #expect(pool.first { $0.show.name == "How to Ruin Diwali: Meet the Parents" }?.episode.number == 1)
        #expect(pool.first { $0.show.name == "Avatar: Seven Havens" }?.episode.number == 10)
    }

    @Test("asks for the viewer's yesterday too: a US evening lands on the next day east of the US")
    func loadsYesterday() async throws {
        let network = TVmazeClientTests.FakeNetwork(Array(repeating: (200, [:], Data("[]".utf8)), count: 8))
        // 16:00 on Sat 31 Oct in Auckland, where Friday's 21:00 ET episodes land on Saturday afternoon.
        _ = await AiringSoon.load(client: TVmazeClientTests.client(network), rules: try Fixture.bundledRules(),
                                  now: try Date("2026-10-31T03:00:00Z", strategy: .iso8601),
                                  formatter: DropFormatter(zoneIdentifier: "Pacific/Auckland"))
        let dates = await network.requests.compactMap { url in
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "date" }?.value
        }
        #expect(Set(dates) == ["2026-10-30", "2026-10-31", "2026-11-01", "2026-11-02"])
        #expect(dates.count == 8)
    }

    @Test("offline (every schedule call fails) is nil, not an empty week, so Search can say the schedule is missing")
    func allCallsFail() async throws {
        let network = TVmazeClientTests.FakeNetwork([(503, [:], Data())])
        let picks = await AiringSoon.load(client: TVmazeClientTests.client(network), rules: try Fixture.bundledRules(),
                                          now: Date(iso: "2026-10-30T00:00:00Z"),
                                          formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
        #expect(picks == nil)
        // One answered call is enough for a list, even an empty one.
        let partial = TVmazeClientTests.FakeNetwork([(503, [:], Data()), (200, [:], Data("[]".utf8))])
        let some = await AiringSoon.load(client: TVmazeClientTests.client(partial), rules: try Fixture.bundledRules(),
                                         now: Date(iso: "2026-10-30T00:00:00Z"),
                                         formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
        #expect(some?.isEmpty == true)
    }

    @Test("a date-only episode stays through its day in the viewer's zone, then goes")
    func dateOnlyByDay() throws {
        // Days of Our Lives on Peacock: no airtime and no Peacock rule, so date only.
        let today = try #require(try Self.pick("Days of Our Lives", at: "2026-10-30T20:00:00Z"))
        #expect(today.resolution.confidence == .dateOnly)
        #expect(try Self.pick("Days of Our Lives", at: "2026-10-30T23:30:00Z") == nil) // 00:30 on the 31st in Lagos
    }

    @Test("keeps only the viewer's today and the next two days, judged in the viewer's zone")
    func windowEndsOnTheThirdDay() throws {
        // From Wed 28 Oct in Lagos the window ends on Fri 30 Oct. Fire Country airs 21:00 ET Fri = 02:00 Sat in Lagos.
        let at = "2026-10-28T00:00:00Z"
        #expect(try Self.pick("Fire Country", at: at) == nil)
        #expect(try Self.pick("Dark Matter", at: at) != nil)       // 02:00 Fri in Lagos
        #expect(try Self.pick("Days of Our Lives", at: at) != nil) // date only, Fri 30 Oct
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
