import Foundation
import Testing
@testable import Airstamp

@Suite("TimeResolver")
struct TimeResolverTests {
    static let rules = RulesFile(
        schemaVersion: 1, updated: "2026-10-30",
        platforms: [PlatformRule(match: ["Netflix"], zone: "America/Los_Angeles", time: "00:00", dayOffset: 0,
                                 label: "Netflix rule", sources: ["https://a.example", "https://b.example"])],
        overrides: [
            ReleaseOverride(episode: "tvmaze:10", show: nil, instant: Date(iso: "2026-11-27T01:00:00Z"), zone: nil, time: nil,
                            dayOffset: nil, confirmed: true, note: "Event drop", source: "https://c.example"),
            ReleaseOverride(episode: nil, show: "tvmaze:500", instant: nil, zone: "America/Los_Angeles", time: "18:00",
                            dayOffset: 0, confirmed: false, note: "Show at 18:00 PT", source: "https://d.example"),
        ],
        providers: [])

    static func listing(episode: String = "tvmaze:1", show: String = "tvmaze:1", airdate: String? = "2026-11-26",
                        airtime: String = "", airstamp: String? = nil, channel: String = "Netflix") -> EpisodeListing {
        EpisodeListing(episodeID: episode, showID: show, airdate: airdate, airtime: airtime,
                       airstamp: airstamp.map { Date(iso: $0) }, channelNames: [channel], broadcastNetwork: nil)
    }

    @Test("a placeholder airstamp is never exact, whatever its hour", arguments: [
        "2026-11-26T12:00:00Z", "2026-11-26T16:00:00Z", "2026-11-26T17:00:00Z",
    ])
    func placeholderNeverExact(_ stamp: String) {
        let ruled = TimeResolver.resolve(Self.listing(airstamp: stamp), rules: Self.rules)
        #expect(ruled.confidence == .estimated)
        #expect(ruled.source == .platformRule("Netflix rule"))

        let unruled = TimeResolver.resolve(Self.listing(airstamp: stamp, channel: "Peacock"), rules: Self.rules)
        #expect(unruled.confidence == .dateOnly)
        #expect(unruled.source == .dateOnly)
        #expect(unruled.airdate == "2026-11-26")
    }

    @Test("a real airtime is trusted as an exact broadcast")
    func broadcastIsExact() {
        var item = Self.listing(airtime: "21:00", airstamp: "2026-06-22T01:00:00Z", channel: "HBO")
        item.broadcastNetwork = "HBO"
        let result = TimeResolver.resolve(item, rules: Self.rules)
        #expect(result.confidence == .exact)
        #expect(result.source == .broadcast(network: "HBO"))
        #expect(result.date == Date(iso: "2026-06-22T01:00:00Z"))
    }

    @Test("episode override beats show override beats platform rule")
    func overrideBeatsRule() {
        let both = TimeResolver.resolve(Self.listing(episode: "tvmaze:10", show: "tvmaze:500"), rules: Self.rules)
        #expect(both.date == Date(iso: "2026-11-27T01:00:00Z"))
        #expect(both.confidence == .exact)
        #expect(both.source == .override(note: "Event drop"))

        let showOnly = TimeResolver.resolve(Self.listing(show: "tvmaze:500"), rules: Self.rules)
        #expect(showOnly.date == Date(iso: "2026-11-27T02:00:00Z"))  // 18:00 PST on 26 Nov
        #expect(showOnly.confidence == .estimated)

        let ruleOnly = TimeResolver.resolve(Self.listing(), rules: Self.rules)
        #expect(ruleOnly.date == Date(iso: "2026-11-26T08:00:00Z"))  // 00:00 PST on 26 Nov
    }

    @Test("an episode override that can't produce a time falls back to the show override")
    func episodeOverrideWithoutDateFallsBack() {
        let rules = RulesFile(
            schemaVersion: 1, updated: "2026-10-30", platforms: Self.rules.platforms,
            overrides: [
                ReleaseOverride(episode: "tvmaze:11", show: nil, instant: nil, zone: "America/New_York", time: "20:00",
                                dayOffset: 0, confirmed: true, note: "Needs an airdate", source: "https://e.example"),
                ReleaseOverride(episode: nil, show: "tvmaze:600", instant: nil, zone: "America/Los_Angeles", time: "18:00",
                                dayOffset: 0, confirmed: false, note: "Show at 18:00 PT", source: "https://f.example"),
            ],
            providers: [])
        // No airdate: the episode override can't place 20:00, and neither can the show override,
        // so the result is date only rather than a time borrowed from the placeholder.
        let undated = TimeResolver.resolve(Self.listing(episode: "tvmaze:11", show: "tvmaze:600", airdate: nil,
                                                        airstamp: "2026-11-26T12:00:00Z"), rules: rules)
        #expect(undated.confidence == .dateOnly)

        let dated = TimeResolver.resolve(Self.listing(episode: "tvmaze:11", show: "tvmaze:600"), rules: rules)
        #expect(dated.source == .override(note: "Needs an airdate"))
    }

    @Test("no airdate and no airtime means date only with no invented time")
    func missingAirdate() {
        let result = TimeResolver.resolve(Self.listing(airdate: nil, channel: "Peacock"), rules: Self.rules)
        #expect(result.confidence == .dateOnly)
        #expect(result.airdate == nil)
    }

    @Test("an anime's UTC instant doesn't move when US clocks change")
    func animeIgnoresUSDST() throws {
        let before = TimeResolver.resolveAniList(airingAt: Date(iso: "2026-10-30T15:00:00Z"), offsetMinutes: 0)
        let after = TimeResolver.resolveAniList(airingAt: Date(iso: "2026-11-06T15:00:00Z"), offsetMinutes: 0)
        #expect(before.confidence == .exact)
        #expect(before.source == .anilist)

        let lagos = DropFormatter(timeZone: try #require(TimeZone(identifier: "Africa/Lagos")))
        #expect(lagos.localTime(before.date) == "16:00")
        #expect(lagos.localTime(after.date) == "16:00")

        let newYork = DropFormatter(timeZone: try #require(TimeZone(identifier: "America/New_York")))
        #expect(newYork.localTime(before.date) == "11:00")
        #expect(newYork.localTime(after.date) == "10:00")  // only the US clock moved
    }

    @Test("an anime offset shifts the time and marks it adjusted")
    func animeOffsetIsAdjusted() {
        let result = TimeResolver.resolveAniList(airingAt: Date(iso: "2026-10-30T15:00:00Z"), offsetMinutes: 30)
        #expect(result.date == Date(iso: "2026-10-30T15:30:00Z"))
        #expect(result.confidence == .estimated)
        #expect(result.source == .adjusted(base: "JP broadcast", offsetMinutes: 30))
    }

    @Test("an offset never invents a time for a date-only drop")
    func offsetLeavesDateOnlyAlone() {
        let result = TimeResolver.resolve(Self.listing(channel: "Peacock"), rules: Self.rules, offsetMinutes: 30)
        #expect(result.confidence == .dateOnly)
    }
}
