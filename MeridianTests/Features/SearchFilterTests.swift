import Foundation
import Testing
@testable import Meridian

/// Search before you type, one filter at a time (D-43), with each filter's meaning from Chime, 6 Nov 2026 (D-66):
/// Popular is the past year's popular shows, Today is today only, New seasons is the past 3 months plus this week's
/// premieres, and a service shows "Popular on" over "Airing on". TV's schedule comes from the recorded TVmaze
/// schedules of 30 Oct 2026, anime from AniList's popular and premiere pages. Nothing here asks the network.
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
        return media.filter { $0.nextAiringEpisode != nil }.compactMap { AiringItem(media: $0) }
    }

    /// A popular-list entry as `scripts/build-popular-shows.py` writes it.
    static func popular(_ id: Int, _ name: String, network: String = "Netflix", views: Int, lastAired: String,
                        season: Int? = 2, seasonStart: String? = "2025-06-01") throws -> PopularItem {
        let json = """
        {"views":\(views),"lastAired":"\(lastAired)","season":\(season.map(String.init) ?? "null"),
         "seasonStart":\(seasonStart.map { "\"\($0)\"" } ?? "null"),
         "show":{"id":\(id),"name":"\(name)","type":"Scripted","language":"English","webChannel":{"id":1,"name":"\(network)"}}}
        """
        return PopularItem(entry: try JSONDecoder().decode(PopularShows.Entry.self, from: Data(json.utf8)))
    }

    static func shelves(_ filter: SearchFilter, kind: SearchView.Kind = .tv, upcoming: [AiringItem],
                        popular: [PopularItem] = [], at now: String, zone: String = "Africa/Lagos") -> [SearchShelf] {
        AiringFilter.shelves(filter, kind: kind, catalogue: SearchCatalogue(upcoming: upcoming, popular: popular, seasons: popular),
                             now: Date(iso: now), formatter: DropFormatter(zoneIdentifier: zone))
    }

    static func titles(_ shelf: SearchShelf?) -> [String] { shelf?.entries.map(\.result.title) ?? [] }

    @Test("Popular is the past year's popular shows, most viewed first, whether or not an episode is coming")
    func popularPastYear() throws {
        let now = "2026-10-30T00:00:00Z"
        let list = [
            try Self.popular(1, "Big Hit", views: 9_000_000, lastAired: "2025-12-31"),
            try Self.popular(61315, "Dark Matter", network: "Apple TV", views: 5_000_000, lastAired: "2026-10-23"),
            // 30 Oct 2025 is 365 days before 30 Oct 2026, so it's kept; the day before isn't.
            try Self.popular(3, "Last Aired 366 Days Ago", views: 8_000_000, lastAired: "2025-10-29"),
            try Self.popular(4, "Last Aired 365 Days Ago", views: 7_000_000, lastAired: "2025-10-30"),
        ]
        let shelves = Self.shelves(.popular, upcoming: try Self.tv(at: now), popular: list, at: now)
        #expect(shelves.map(\.header) == ["Popular in the past year"])
        #expect(Self.titles(shelves.first) == ["Big Hit", "Last Aired 365 Days Ago", "Dark Matter"])
        // A popular show that also airs this week says when; one between seasons says when its season began.
        #expect(shelves.first?.entries.first { $0.id == 61315 }?.drop != nil)
        #expect(shelves.first?.entries.first { $0.id == 1 }?.drop == nil)
    }

    @Test("Popular shows 15 at most")
    func popularLimit() throws {
        let list = try (1...20).map { try Self.popular($0, "Show \($0)", views: 100 - $0, lastAired: "2026-10-01") }
        let shelves = Self.shelves(.popular, upcoming: [], popular: list, at: "2026-10-30T00:00:00Z")
        #expect(shelves.first?.entries.count == AiringSoon.limit)
    }

    @Test("an episode that came out since the grid loaded is no longer offered as still to come")
    func dropsWhatIsOut() throws {
        // Loaded at midnight; looked at again at 06:00Z, after Dark Matter's real 01:00Z release.
        let items = try Self.tv(at: "2026-10-30T00:00:00Z")
        #expect(items.contains { $0.result.title == "Dark Matter" })
        let later = Self.shelves(.today, upcoming: items, at: "2026-10-30T06:00:00Z")
        #expect(!Self.titles(later.first).contains("Dark Matter"))
    }

    @Test("Today is the viewer's calendar day, wherever they are, and nothing later", arguments: [
        // 20:00Z: CBS's 21:00 ET Fire Country is 02:00 tomorrow in Lagos, 21:00 today in New York, 14:00 tomorrow
        // in Auckland (where it's already the 31st, so 'today' there is the 31st and it counts).
        ("Africa/Lagos", false), ("America/New_York", true), ("Pacific/Auckland", true),
    ])
    func today(zone: String, firesToday: Bool) throws {
        let now = "2026-10-30T20:00:00Z"
        let shelf = try #require(Self.shelves(.today, upcoming: try Self.tv(at: now, zone: zone), at: now, zone: zone).first)
        #expect(shelf.header == "Airing today")
        #expect(Self.titles(shelf).contains("Fire Country") == firesToday)
        let formatter = DropFormatter(zoneIdentifier: zone)
        let today = formatter.localDay(Date(iso: now))
        #expect(shelf.entries.allSatisfy { entry in
            guard let drop = entry.drop else { return false }
            return drop.confidence == .dateOnly ? drop.airdate == today : formatter.localDay(drop.date) == today
        })
    }

    @Test("Today counts a date-only episode on its listed day")
    func todayDateOnly() throws {
        let now = "2026-10-30T15:00:00Z"
        let shelf = Self.shelves(.today, upcoming: try Self.tv(at: now), at: now).first
        #expect(shelf?.entries.contains { $0.result.title == "Days of Our Lives" && $0.drop?.confidence == .dateOnly } == true)
    }

    @Test("New seasons: a season begun in the past 90 days, or a premiere this week; never older or not yet begun")
    func newSeasons() throws {
        let now = "2026-10-30T00:00:00Z"
        let list = [
            try Self.popular(1, "Began 89 Days Ago", views: 10, lastAired: "2026-10-20", season: 3, seasonStart: "2026-08-02"),
            try Self.popular(2, "Began 91 Days Ago", views: 90, lastAired: "2026-10-20", season: 2, seasonStart: "2026-07-31"),
            try Self.popular(3, "Begins Tomorrow", views: 80, lastAired: "2025-12-01", season: 4, seasonStart: "2026-10-31"),
            try Self.popular(4, "Began Today", views: 50, lastAired: "2026-10-30", season: 1, seasonStart: "2026-10-30"),
        ]
        let shelf = try #require(Self.shelves(.newSeasons, upcoming: try Self.tv(at: now), popular: list, at: now).first)
        #expect(shelf.header == "New seasons")
        let titles = Self.titles(shelf)
        // Most popular first, then this week's premieres of shows on no popular list, in the airing order.
        #expect(Array(titles.prefix(2)) == ["Began Today", "Began 89 Days Ago"])
        #expect(!titles.contains("Began 91 Days Ago") && !titles.contains("Begins Tomorrow"))
        #expect(titles.contains("How to Ruin Diwali: Meet the Parents"))
        #expect(shelf.entries.allSatisfy { $0.drop == nil || $0.drop?.number == 1 })
    }

    @Test("a service shows 'Popular on' over 'Airing on', each with only that service's shows")
    func service() throws {
        let now = "2026-10-30T00:00:00Z"
        let list = [try Self.popular(1, "Tracker", network: "CBS", views: 9, lastAired: "2026-05-01"),
                    try Self.popular(2, "Wednesday", network: "Netflix", views: 99, lastAired: "2026-09-03")]
        let shelves = Self.shelves(.service("CBS"), upcoming: try Self.tv(at: now), popular: list, at: now)
        #expect(shelves.map(\.header) == ["Popular on CBS", "Airing on CBS in the next few days"])
        #expect(Self.titles(shelves.first) == ["Tracker"])
        #expect(!(shelves.last?.entries.isEmpty ?? true))
        #expect(shelves.last?.entries.allSatisfy { $0.result.network == "CBS" } == true)
    }

    @Test("service chips come from the 12 major platforms, most subscribers first, never YouTube or BBC iPlayer")
    func popularServicesOnly() throws {
        #expect(AiringFilter.services == ["Netflix", "Prime Video", "HBO Max", "Disney+", "Paramount+", "Hulu",
                                          "Peacock", "Apple TV", "CBS", "NBC", "ABC", "FOX"])
        #expect(!AiringFilter.services.contains("YouTube") && !AiringFilter.services.contains("BBC iPlayer"))
        let shelves = Self.shelves(.service("Disney+"), upcoming: try Self.tv(at: "2026-10-30T00:00:00Z"),
                                   at: "2026-10-30T00:00:00Z")
        #expect(shelves.allSatisfy { $0.entries.isEmpty })
    }

    @Test("a platform with nothing to show gets no chip; one with only popular shows or only airing ones keeps it")
    func emptyPlatformsHidden() throws {
        let now = "2026-10-30T00:00:00Z"
        // Disney+ has nothing in the recorded schedule; Wednesday puts Netflix on the popular list; CBS only airs.
        let catalogue = SearchCatalogue(upcoming: try Self.tv(at: now),
                                        popular: [try Self.popular(2, "Wednesday", network: "Netflix", views: 9,
                                                                   lastAired: "2026-09-03")], seasons: [])
        let options = AiringFilter.options(for: .tv, catalogue: catalogue, now: Date(iso: now),
                                           formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
        #expect(options.contains(.service("Netflix")) && options.contains(.service("CBS")))
        #expect(!options.contains(.service("Disney+")))
        // The chips that stay keep the platforms' order.
        let labels = options.compactMap { if case .service(let label) = $0 { label } else { nil } }
        #expect(labels == AiringFilter.services.filter(labels.contains))
    }

    @Test("every major platform has a logo in the bundled list")
    func everyServiceHasLogo() {
        let logos = NetworkLogos.loadBundled()
        #expect(PopularServices.all.allSatisfy { $0.names.contains { logos.image(for: $0) != nil } })
    }

    @Test("the HBO Max chip also holds shows on HBO's own channel, so there's one HBO chip")
    func hboOneChip() throws {
        // The recording has no English HBO shows, so two small listings: one on HBO's channel, one on HBO Max.
        func listing(_ id: Int, _ name: String, channel: String) -> String {
            """
            {"id":\(id),"season":1,"number":2,"airdate":"2026-10-31","airtime":"21:00",
             "airstamp":"2026-11-01T01:00:00+00:00","show":{"id":\(id),"name":"\(name)","type":"Scripted",
             "language":"English","weight":90,"network":{"id":\(id),"name":"\(channel)"}}}
            """
        }
        let json = "[\(listing(1, "On HBO", channel: "HBO")),\(listing(2, "On HBO Max", channel: "HBO Max"))]"
        let schedule = try JSONDecoder().decode([TVmazeScheduleItem].self, from: Data(json.utf8))
        let items = AiringSoon.pool(from: schedule, rules: try Fixture.bundledRules(), now: Date(iso: "2026-10-31T00:00:00Z"),
                                    formatter: DropFormatter(zoneIdentifier: "Africa/Lagos")).map(AiringItem.init(pick:))
        #expect(!AiringFilter.services.contains("HBO"))
        let shelves = Self.shelves(.service("HBO Max"), upcoming: items, at: "2026-10-31T00:00:00Z")
        #expect(Set(Self.titles(shelves.last)) == ["On HBO", "On HBO Max"])
    }

    @Test("TV offers Popular, Today, New seasons and the platforms with shows, with no Exact time; anime no platforms")
    func options() throws {
        let catalogue = SearchCatalogue(upcoming: try Self.tv(at: "2026-10-30T00:00:00Z"), popular: [], seasons: [])
        func options(_ kind: SearchView.Kind) -> [SearchFilter] {
            AiringFilter.options(for: kind, catalogue: catalogue, now: Date(iso: "2026-10-30T00:00:00Z"),
                                 formatter: DropFormatter(zoneIdentifier: "Africa/Lagos"))
        }
        #expect(Array(options(.tv).prefix(3)) == [.popular, .today, .newSeasons])
        #expect(!options(.tv).dropFirst(3).isEmpty)
        #expect(options(.anime) == [.popular, .today, .newSeasons])
    }

    @Test("anime: New seasons finds this week's premieres; Today uses the Japanese broadcast time")
    func anime() throws {
        let items = try Self.anime()
        let now = "2026-10-31T23:00:00Z"
        let premieres = Self.shelves(.newSeasons, kind: .anime, upcoming: items, at: now).first?.entries ?? []
        #expect(Set(premieres.map(\.id)) == [178972, 203275, 214536])
        let today = Self.shelves(.today, kind: .anime, upcoming: items, at: now).first?.entries ?? []
        #expect(!today.isEmpty)
        let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos")
        #expect(today.allSatisfy { $0.drop.map(\.date).map(formatter.localDay) == formatter.localDay(Date(iso: now)) })
    }

    @Test("each cell says when, in the app's words (rule 3), or when its season began")
    func cellLine() throws {
        let now = Date(iso: "2026-10-30T00:00:00Z")
        let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos", locale: Locale(identifier: "en_GB"))
        let items = try Self.tv(at: "2026-10-30T00:00:00Z")
        let dark = try #require(items.first { $0.result.title == "Dark Matter" })
        #expect(SearchShelf.Entry(result: dark.result, drop: dark.drop).line(now: now, formatter: formatter)
            == "Expected today at 02:00")
        let anime = try #require(try Self.anime().first { $0.result.id == 178972 })
        #expect(SearchShelf.Entry(result: anime.result, drop: anime.drop).line(now: now, formatter: formatter)?
            .hasPrefix("Airs in Japan") == true)
        let between = SearchShelf.Entry(result: dark.result, drop: nil, season: 3, seasonStart: "2026-09-12")
        #expect(between.line(now: now, formatter: formatter) == "Season 3 began Sat 12 Sep")
        let first = SearchShelf.Entry(result: dark.result, drop: nil, season: 1, seasonStart: "2025-11-26")
        #expect(first.line(now: now, formatter: formatter) == "Began Wed 26 Nov 2025")
        // A soap whose TVmaze seasons are years (General Hospital, season 2026) never reads "Season 2026 began".
        let soap = SearchShelf.Entry(result: dark.result, drop: nil, season: 2026, seasonStart: "2026-01-02")
        #expect(soap.line(now: now, formatter: formatter) == "Began Fri 2 Jan")
    }

    @Test("a filter with nothing to show says so in plain words")
    func noMatchCopy() {
        #expect(AiringFilter.noMatch(.today) == "Nothing left to air today.")
        #expect(AiringFilter.noMatch(.newSeasons) == "No new seasons in the past 3 months.")
        #expect(AiringFilter.noMatch(.service("Netflix")) == "Nothing on Netflix from the past year or the next few days.")
    }
}
