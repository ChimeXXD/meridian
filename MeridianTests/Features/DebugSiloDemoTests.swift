import Foundation
import Testing
@testable import Meridian

/// Debug › Silo demo, for the case study's recordings: Silo's listed return (S4E1, a date-only placeholder in 2027)
/// moved to a chosen time, with the wording its Apple TV rule really gives it, so every widget and Live Activity
/// state can be filmed with Silo's art.
@MainActor
@Suite("Silo demo")
struct DebugSiloDemoTests {
    static let now = Date(iso: "2026-11-03T18:00:00Z")

    /// Silo as Upcoming lists it today: TVmaze's guessed 2027 date, so date only (O-10).
    static let listedSilo = Drop(id: "tvmaze:38052:3330000", showID: DebugSiloDemo.showID, showName: "Silo", season: 4,
                                 number: 1, episodeTitle: "Episode 1", date: Date(iso: "2027-07-09T12:00:00Z"),
                                 airdate: "2027-07-09", confidence: .dateOnly, source: .dateOnly,
                                 provider: ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false),
                                 previousDate: nil)

    static let tonight = Drop(id: "tvmaze:94:1", showID: "94", showName: "House of the Dragon", season: 3, number: 1,
                              episodeTitle: nil, date: now + 5 * 3_600, airdate: nil, confidence: .exact,
                              source: .broadcast(network: "HBO"),
                              provider: ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: false),
                              previousDate: nil)

    @Test("the demo's show ID is Silo's in TVmaze's own recorded data")
    func siloID() throws {
        let show = try JSONDecoder().decode(TVmazeShow.self, from: Fixture.data("tvmaze/show-silo-embed.json"))
        #expect(show.name == "Silo")
        #expect(String(show.id) == DebugSiloDemo.showID)
    }

    @Test("moves Silo to the chosen time with its Apple TV rule's wording")
    func silo() throws {
        let rules = try Fixture.bundledRules()
        let drop = try #require(DebugSiloDemo.drop(minutes: 3, from: Self.listedSilo, rules: rules, now: Self.now))
        let rule = try #require(rules.platform(matching: ["Apple TV"]))
        #expect(drop.date == Self.now + 180)
        #expect(drop.confidence == .estimated)
        #expect(drop.source == .platformRule(rule.label))
        #expect(ReleaseWording.verb(drop, past: false) == "Expected")
        #expect(DebugFakeDrop.isFake(drop))
        #expect(drop.showID == DebugSiloDemo.showID && drop.showName == "Silo" && drop.episodeLabel == "S4E1")
        #expect(drop.provider == Self.listedSilo.provider)
        #expect(drop.previousDate == nil)
    }

    @Test("no platform rule means no demo, rather than a made-up exact time")
    func noRule() throws {
        var listed = Self.listedSilo
        listed.provider = ProviderLabel(name: "Nowhere TV", countryCode: nil, noOfficialStream: false)
        #expect(DebugSiloDemo.drop(minutes: 3, from: listed, rules: try Fixture.bundledRules(), now: Self.now) == nil)
    }

    @Test("4 days out reads 4d 4h for half an hour, not 4d 3h a second later")
    func fourDays() {
        let drop = Self.now + DebugSiloDemo.fourDaysMinutes * 60
        let still = { (elapsed: TimeInterval) in
            CountdownFormatter.text(CountdownFormatter.stillParts(from: Self.now + elapsed, to: drop))
        }
        #expect(still(0) == "4d 4h" && still(1_799) == "4d 4h" && still(1_801) == "4d 3h")
    }

    @Test("the same-night pair is one Live Activity, Silo first")
    func sameNight() throws {
        let silo = try #require(DebugSiloDemo.drop(minutes: 3, from: Self.listedSilo, rules: try Fixture.bundledRules(),
                                                    now: Self.now))
        let pair = DebugSiloDemo.sameNight(silo: silo, with: Self.tonight)
        #expect(pair.count == 2 && pair.allSatisfy(DebugFakeDrop.isFake))
        #expect(Set(pair.map(\.id)).count == 2)
        #expect(pair[1].showName == "House of the Dragon" && pair[1].date == silo.date + 3_600)
        let nights = ActivityPlanner.nights(pair.sorted { $0.date < $1.date })
        #expect(nights.count == 1 && nights[0].first?.showName == "Silo")
    }

    @Test("fakes stand in for their shows' real drops, so a row never shows a show twice")
    func replacesReal() throws {
        let silo = try #require(DebugSiloDemo.drop(minutes: 3, from: Self.listedSilo, rules: try Fixture.bundledRules(),
                                                    now: Self.now))
        let stale = DebugFakeDrop.make(minutes: 10, now: Self.now)
        let result = UpcomingLoader.Result(drops: [Self.tonight, Self.listedSilo, stale])
        let merged = try #require(DebugFakeDrop.merging([silo], into: result))
        #expect(merged.drops.map(\.id) == [silo.id, Self.tonight.id])
    }

    @Test("with no fakes, stale ones go and real drops stay")
    func noFakes() {
        let stale = DebugFakeDrop.make(minutes: 10, now: Self.now)
        let result = UpcomingLoader.Result(drops: [Self.listedSilo, stale])
        #expect(DebugFakeDrop.merging([], into: result)?.drops == [Self.listedSilo])
        #expect(DebugFakeDrop.merging([], into: nil) == nil)
    }

    @Test("a new demo ends earlier demo activities and leaves real ones running")
    func endsEarlierFakes() async {
        let requester = FakeActivityRequester()
        let state = DropActivityAttributes.ContentState(phase: .upcoming, dropDate: Self.now + 180, delayedFrom: nil)
        requester.activities = [
            RunningActivity(id: "demo", dropIDs: ["\(DebugFakeDrop.idPrefix)38052:1"], state: state, windowStart: nil),
            RunningActivity(id: "real", dropIDs: [Self.tonight.id], state: state, windowStart: nil),
        ]
        let ended = await ActivityScheduler(requester: requester).endFakes()
        #expect(ended == 1)
        #expect(requester.ended == ["demo"])
        #expect(requester.activities.map(\.id) == ["real"])
    }
}
