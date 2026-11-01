import Foundation
import Testing
@testable import Airstamp

/// Search's airing grid, narrowed by one filter at a time (D-43): Popular, Today, New seasons, Exact time, or one
/// service. TV comes from the recorded TVmaze schedules of 30 Oct 2026, anime from AniList's popular and premiere
/// pages. The filter runs on what's loaded and never asks the network.
@Suite("Search filters")
struct SearchFilterTests {
    static func tv(at now: String, zone: String = "Africa/Lagos") throws -> [AiringItem] {
        let items = try AiringSoonTests.items("schedule-web-2026-10-30") + AiringSoonTests.items("schedule-us-2026-10-30")
        return AiringSoon.pool(from: items, rules: try Fixture.bundledRules(), now: Date(iso: now),
                               formatter: DropFormatter(zoneIdentifier: zone)).map(AiringItem.init(pick:))
    }

    static func anime() throws -> [AiringItem] {
        let decoder = JSONDecoder()
        let popular = try decoder.decode(AniListPage.self, from: Fixture.data("anilist/releasing-2026-10-31.json"))
        let premieres = try decoder.decode(AniListPage.self, from: Fixture.data("anilist/premieres-2026-11-01.json"))
        let media = (popular.data.Page.media ?? []) + (premieres.data.Page.airingSchedules ?? []).map(\.media)
        return media.filter { $0.nextAiringEpisode != nil }.compactMap(AiringItem.init(media:))
    }

    static func apply(_ filter: SearchFilter, _ items: [AiringItem], at now: String,
                      zone: String = "Africa/Lagos") -> [AiringItem] {
        AiringFilter.apply(filter, to: items, now: Date(iso: now), formatter: DropFormatter(zoneIdentifier: zone))
    }

    @Test("Popular keeps the most popular first and shows 15 at most")
    func popular() throws {
        let shown = Self.apply(.popular, try Self.tv(at: "2026-10-30T00:00:00Z"), at: "2026-10-30T00:00:00Z")
        #expect(shown.count == AiringSoon.limit)
        #expect(shown.map(\.weight) == shown.map(\.weight).sorted(by: >))
    }

    @Test("an episode that came out since the grid loaded drops out, whatever the filter")
    func dropsWhatIsOut() throws {
        // Loaded at midnight; looked at again at 06:00Z, after Dark Matter's real 01:00Z release.
        let items = try Self.tv(at: "2026-10-30T00:00:00Z")
        #expect(items.contains { $0.result.title == "Dark Matter" })
        let later = AiringFilter.apply(.popular, to: items, now: Date(iso: "2026-10-30T06:00:00Z"),
                                       formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"), limit: .max)
        #expect(!later.contains { $0.result.title == "Dark Matter" })
    }

    @Test("Today is the viewer's calendar day, wherever they are", arguments: [
        // 20:00Z: CBS's 21:00 ET Fire Country is 02:00 tomorrow in Lagos, 21:00 today in New York, 14:00 tomorrow
        // in Auckland (where it's already the 31st, so 'today' there is the 31st and it counts).
        ("Africa/Lagos", false), ("America/New_York", true), ("Pacific/Auckland", true),
    ])
    func today(zone: String, firesToday: Bool) throws {
        let now = "2026-10-30T20:00:00Z"
        let shown = Self.apply(.today, try Self.tv(at: now, zone: zone), at: now, zone: zone)
        #expect(shown.contains { $0.result.title == "Fire Country" } == firesToday)
        let formatter = DropFormatter(zoneIdentifier: zone)
        let today = formatter.localDay(Date(iso: now))
        #expect(shown.allSatisfy { item in
            item.drop.confidence == .dateOnly ? item.drop.airdate == today : formatter.localDay(item.drop.date) == today
        })
    }

    @Test("Today counts a date-only episode on its listed day")
    func todayDateOnly() throws {
        let now = "2026-10-30T15:00:00Z"
        let shown = Self.apply(.today, try Self.tv(at: now), at: now)
        #expect(shown.contains { $0.result.title == "Days of Our Lives" && $0.drop.confidence == .dateOnly })
    }

    @Test("New seasons keeps episode 1s, brand-new shows included")
    func newSeasons() throws {
        let shown = Self.apply(.newSeasons, try Self.tv(at: "2026-10-30T00:00:00Z"), at: "2026-10-30T00:00:00Z")
        #expect(!shown.isEmpty)
        #expect(shown.allSatisfy { $0.drop.number == 1 })
        #expect(shown.contains { $0.result.title == "How to Ruin Diwali: Meet the Parents" })
    }

    @Test("Exact time keeps only times that would say 'Out', never an estimate or a date only")
    func exactTime() throws {
        let shown = Self.apply(.exactTime, try Self.tv(at: "2026-10-30T06:00:00Z"), at: "2026-10-30T06:00:00Z")
        #expect(!shown.isEmpty)
        #expect(shown.allSatisfy { $0.drop.confidence == .exact })
        #expect(shown.contains { $0.result.title == "Fire Country" })
        #expect(!shown.contains { $0.result.title == "Days of Our Lives" })
    }

    @Test("a service shows only its shows, named as the cell names them")
    func service() throws {
        let items = try Self.tv(at: "2026-10-30T00:00:00Z")
        let services = AiringFilter.services(in: items)
        #expect(services.count <= AiringFilter.maxServices)
        #expect(services.contains("CBS"))
        let shown = Self.apply(.service("CBS"), items, at: "2026-10-30T00:00:00Z")
        #expect(!shown.isEmpty)
        #expect(shown.allSatisfy { $0.result.network == "CBS" })
    }

    @Test("services are listed most shows first, ties A to Z")
    func serviceOrder() throws {
        let items = try Self.tv(at: "2026-10-30T00:00:00Z")
        let counts = Dictionary(grouping: items.compactMap(\.result.network), by: \.self).mapValues(\.count)
        let services = AiringFilter.services(in: items)
        #expect(services == services.sorted { (counts[$0] ?? 0, $1) > (counts[$1] ?? 0, $0) })
    }

    @Test("services with a logo come first, so logo chips sit together; the 6 kept are still those with the most shows")
    func logosGrouped() throws {
        let items = try Self.tv(at: "2026-10-30T00:00:00Z")
        let plain = AiringFilter.services(in: items)
        let withLogo: Set<String> = [plain[1], plain[4]]  // two from the middle, so grouping must move them
        let grouped = AiringFilter.services(in: items, hasLogo: withLogo.contains)
        #expect(Set(grouped) == Set(plain))
        #expect(Array(grouped.prefix(2)) == [plain[1], plain[4]])
        #expect(Array(grouped.dropFirst(2)) == plain.filter { !withLogo.contains($0) })
    }

    @Test("TV offers every filter; anime offers Popular, Today and New seasons")
    func options() throws {
        let tv = AiringFilter.options(for: .tv, items: try Self.tv(at: "2026-10-30T00:00:00Z"))
        #expect(Array(tv.prefix(4)) == [.popular, .today, .newSeasons, .exactTime])
        #expect(tv.dropFirst(4).allSatisfy { if case .service = $0 { true } else { false } })
        #expect(AiringFilter.options(for: .anime, items: try Self.anime()) == [.popular, .today, .newSeasons])
    }

    @Test("anime: New seasons finds this week's premieres; Today uses the Japanese broadcast time")
    func anime() throws {
        let items = try Self.anime()
        let now = "2026-10-31T23:00:00Z"
        let premieres = Self.apply(.newSeasons, items, at: now)
        #expect(Set(premieres.map(\.result.id)) == [178972, 203275, 214536])
        #expect(premieres.first?.result.id == 178972)  // most popular first
        let today = Self.apply(.today, items, at: now)
        #expect(!today.isEmpty)
        let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos")
        #expect(today.allSatisfy { formatter.localDay($0.drop.date) == formatter.localDay(Date(iso: now)) })
    }

    @Test("each cell says when, in the app's words (rule 3)")
    func releaseLine() throws {
        let now = Date(iso: "2026-10-30T00:00:00Z")
        let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
        let items = try Self.tv(at: "2026-10-30T00:00:00Z")
        let dark = try #require(items.first { $0.result.title == "Dark Matter" })
        #expect(dark.releaseLine(now: now, formatter: formatter) == "Expected today at 02:00")
        let anime = try #require(try Self.anime().first { $0.result.id == 178972 })
        #expect(anime.releaseLine(now: now, formatter: formatter).hasPrefix("Airs in Japan"))
    }

    @Test("a filter with no matches says so in plain words")
    func noMatchCopy() {
        #expect(AiringFilter.noMatch(.today, kind: .tv) == "Nothing left to air today.")
        #expect(AiringFilter.noMatch(.newSeasons, kind: .anime) == "No new seasons this week.")
        #expect(AiringFilter.noMatch(.service("Netflix"), kind: .tv) == "Nothing on Netflix in the next few days.")
    }
}
