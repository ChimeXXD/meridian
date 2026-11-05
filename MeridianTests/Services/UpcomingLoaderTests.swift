import Foundation
import Testing
@testable import Meridian

/// Followed shows become drops: TVmaze's next episode, resolved by the time engine, with a provider label.
@Suite("Upcoming loader")
struct UpcomingLoaderTests {
    static let silo = UpcomingLoader.Request(catalog: .tvmaze, id: 38052, name: "Silo", offsetMinutes: 0)

    static func loader(_ network: TVmazeClientTests.FakeNetwork) throws -> UpcomingLoader {
        UpcomingLoader(client: TVmazeClientTests.client(network), rules: try RulesStore.loadBundled(), viewerCountry: "NG")
    }

    @Test("Silo's far-off placeholder date (2027-07-09, no airtime) is a date-only drop (O-10)")
    func siloIsDateOnly() async throws {
        let network = TVmazeClientTests.FakeNetwork([try TVmazeClientTests.ok("show-silo-embed")])
        let result = try await Self.loader(network).load([Self.silo], now: Date(iso: "2026-10-30T17:00:00Z"))
        let drop = try #require(result.drops.first)
        #expect(drop.showName == "Silo")
        #expect(drop.episodeLabel == "S4E1")
        #expect(drop.confidence == .dateOnly)
        #expect(drop.airdate == "2027-07-09")
        #expect(drop.provider?.display == "Apple TV")
        #expect(drop.showID == "38052")
    }

    @Test("closer to the date, the Apple TV rule sets the time: 21:00 New York the evening before")
    func siloNearUsesRule() async throws {
        let network = TVmazeClientTests.FakeNetwork([try TVmazeClientTests.ok("show-silo-embed")])
        let result = try await Self.loader(network).load([Self.silo], now: Date(iso: "2027-06-01T12:00:00Z"))
        let drop = try #require(result.drops.first)
        #expect(drop.source == .platformRule("Apple TV rule"))
        #expect(drop.date == Date(iso: "2027-07-09T01:00:00Z"))
    }

    @Test("a show with no next episode is listed as nothing scheduled")
    func nothingScheduled() async throws {
        var json = try #require(try JSONSerialization.jsonObject(with: Fixture.data("tvmaze/show-silo-embed.json"))
                                as? [String: Any])
        var embedded = try #require(json["_embedded"] as? [String: Any])
        embedded["nextepisode"] = nil
        json["_embedded"] = embedded
        let body = try JSONSerialization.data(withJSONObject: json)
        let result = try await Self.loader(TVmazeClientTests.FakeNetwork([(200, [:], body)]))
            .load([Self.silo], now: Date(iso: "2026-10-30T17:00:00Z"))
        #expect(result.drops.isEmpty)
        let quiet = try #require(result.nothingScheduled.first)
        #expect(quiet.name == "Silo")
        #expect(quiet.showID == "38052")
        #expect(quiet.status == "Running")
        #expect(quiet.lastAired == "2026-09-04")
    }

    @Test("a show TVmaze can't serve is reported, not dropped silently")
    func failure() async throws {
        let network = TVmazeClientTests.FakeNetwork([(500, [:], Data())])
        let result = try await Self.loader(network).load([Self.silo], now: Date(iso: "2026-10-30T17:00:00Z"))
        #expect(result.failed == ["Silo"])
        #expect(result.failedShowIDs == ["38052"])
    }
}

/// Offline or a TVmaze hiccup keeps the last known times (UI-BRIEF §5.2, offline state) instead of emptying Upcoming.
@Suite("Upcoming last known times")
struct UpcomingLastKnownTests {
    static func drop(_ name: String, showID: String? = nil) -> Drop {
        Drop(id: "tvmaze:\(showID ?? name)", showID: showID ?? name, showName: name, season: 1, number: 1, episodeTitle: nil,
             date: Date(iso: "2026-11-01T20:00:00Z"), airdate: nil, confidence: .exact, source: .broadcast(network: "HBO"),
             provider: nil, previousDate: nil)
    }

    @Test("a show that failed this time keeps its last known drop and is still named as failed")
    func keepsLastKnown() {
        let previous = UpcomingLoader.Result(drops: [Self.drop("Silo"), Self.drop("Severance")])
        let loaded = UpcomingLoader.Result(drops: [Self.drop("Severance")], failed: ["Silo"], failedShowIDs: ["Silo"])
        let merged = loaded.keepingLastKnown(from: previous)
        #expect(Set(merged.drops.map(\.showName)) == ["Silo", "Severance"])
        #expect(merged.failed == ["Silo"])
    }

    @Test("a kept show with nothing scheduled goes back to its place in follow order, which the widgets' rows use")
    func quietKeepsFollowOrder() {
        let quiet = { (name: String) in QuietShow(showID: name, name: name, status: "Running", lastAired: nil) }
        let previous = UpcomingLoader.Result(nothingScheduled: [quiet("From"), quiet("Solo Leveling")])
        let loaded = UpcomingLoader.Result(nothingScheduled: [quiet("Solo Leveling")], failed: ["From"],
                                            failedShowIDs: ["From"])
        let merged = loaded.keepingLastKnown(from: previous, followOrder: ["From", "Silo", "Solo Leveling"])
        #expect(merged.nothingScheduled.map(\.name) == ["From", "Solo Leveling"])
    }

    @Test("a show that loaded fine replaces its old drop, and an unfollowed show doesn't come back")
    func replacesAndForgets() {
        let previous = UpcomingLoader.Result(drops: [Self.drop("Silo"), Self.drop("Old")])
        let loaded = UpcomingLoader.Result(drops: [Self.drop("Silo")])
        #expect(loaded.keepingLastKnown(from: previous).drops.map(\.showName) == ["Silo"])
    }

    @Test("two followed shows with the same name: only the one that failed keeps its last known drop")
    func sameNameMatchedByShowID() async throws {
        let network = TVmazeClientTests.FakeNetwork(routes: [
            ("/shows/38052", try TVmazeClientTests.ok("show-silo-embed")),
            ("/shows/2?", (500, [:], Data())),
        ])
        let office = { (id: Int) in UpcomingLoader.Request(catalog: .tvmaze, id: id, name: "The Office", offsetMinutes: 0) }
        let loaded = try await UpcomingLoaderTests.loader(network)
            .load([office(38052), office(2)], now: Date(iso: "2026-10-30T17:00:00Z"))
        let previous = UpcomingLoader.Result(drops: [Self.drop("The Office", showID: "38052"),
                                                     Self.drop("The Office", showID: "2")])
        let merged = loaded.keepingLastKnown(from: previous)
        #expect(merged.drops.map(\.showID).sorted() == ["2", "38052"])
        #expect(merged.failed == ["The Office"])
    }
}
