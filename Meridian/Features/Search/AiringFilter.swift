import Foundation

/// What Search shows before you type: one filter at a time, picked like the TV | Anime switch (Chime, 1 Nov 2026;
/// D-43). Exact time was dropped on 6 Nov (D-66).
enum SearchFilter: Hashable, Sendable {
    case popular, today, newSeasons
    case service(String)

    var label: String {
        switch self {
        case .popular: "Popular"
        case .today: "Today"
        case .newSeasons: "New seasons"
        case .service(let name): name
        }
    }

    /// A stable accessibility ID: "search-filter-today", "search-filter-service-netflix".
    var identifier: String {
        switch self {
        case .service(let name):
            "search-filter-service-" + name.lowercased().map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
        default: "search-filter-" + label.lowercased().replacingOccurrences(of: " ", with: "-")
        }
    }
}

/// Builds Search's grids from what's already loaded: no TVmaze or AniList request (D-43). What each filter means
/// (Chime, 6 Nov 2026; D-66):
/// - Popular: the popular shows that aired in the past year, whether or not anything airs this week.
/// - Today: episodes out on the viewer's calendar day, and nothing later.
/// - New seasons: seasons that began in the past 90 days (about three months), plus premieres in the next few days.
/// - A service: "Popular on Netflix" first, then "Airing on Netflix in the next few days".
/// An episode that came out since the grid loaded is never offered as still to come.
enum AiringFilter {
    /// How far back New seasons looks: about three months.
    static let newSeasonDays = 90
    /// How far back Popular looks for a show's last episode.
    static let popularDays = 365

    /// TV: Popular, Today, New seasons, then the major platforms that have something to show. Anime: no service
    /// filter, because AniList names no single service. The `picked` platform keeps its chip even once it has
    /// nothing left (its only episode came out while it was picked), so the selection never vanishes under the
    /// viewer's thumb; its grid says so and offers "Show popular", and the chip goes once another is picked.
    static func options(for kind: SearchView.Kind, catalogue: SearchCatalogue, now: Date,
                        formatter: DropFormatter, picked: SearchFilter? = nil) -> [SearchFilter] {
        guard kind == .tv else { return [.popular, .today, .newSeasons] }
        // The networks with a popular show or an episode still to come, worked out once for all 12 chips.
        let networks = Set((pastYear(catalogue.popular, now: now, formatter: formatter).map(\.result)
            + stillToCome(catalogue.upcoming, now: now, formatter: formatter).map(\.result)).compactMap(\.network))
        return [.popular, .today, .newSeasons] + services.filter { label in
            picked == .service(label) || !networks.isDisjoint(with: PopularServices.service(label)?.names ?? [label])
        }.map(SearchFilter.service)
    }

    /// The major platforms (`PopularServices`, most subscribers first), always in this order. A platform with no
    /// popular show and nothing coming gets no chip at all (Chime, 6 Nov 2026: "There's no point showing something
    /// that's empty"; D-66, superseding D-45's always-shown chips).
    static var services: [String] { PopularServices.all.map(\.label) }

    /// The grids for `filter`, each at most `limit` shows, most popular first.
    static func shelves(_ filter: SearchFilter, kind: SearchView.Kind, catalogue: SearchCatalogue, now: Date,
                        formatter: DropFormatter, limit: Int = AiringSoon.limit) -> [SearchShelf] {
        let today = formatter.localDay(now)
        let upcoming = stillToCome(catalogue.upcoming, now: now, formatter: formatter)
        // Each show's soonest episode still to come, to word a popular show's cell when it has one.
        let next = Dictionary(upcoming.map { ($0.id, $0.drop) }, uniquingKeysWith: { first, _ in first })
        func entry(_ item: PopularItem) -> SearchShelf.Entry {
            SearchShelf.Entry(result: item.result, drop: next[item.id], season: item.season, seasonStart: item.seasonStart)
        }
        func entry(_ item: AiringItem) -> SearchShelf.Entry { SearchShelf.Entry(result: item.result, drop: item.drop) }
        // Most popular first whatever order the list came in (both sources send it sorted; this keeps it a promise).
        let popular = pastYear(catalogue.popular, now: now, formatter: formatter).enumerated()
            .sorted { ($0.element.weight, $1.offset) > ($1.element.weight, $0.offset) }.map(\.element)
        let window = kind == .tv ? "in the next few days" : "this week"

        switch filter {
        case .popular:
            return [SearchShelf(id: "popular", header: "Popular in the past year",
                                entries: popular.prefix(limit).map(entry))]
        case .today:
            let shown = upcoming.filter { item in
                let drop = item.drop
                return drop.confidence == .dateOnly ? drop.airdate == today : formatter.localDay(drop.date) == today
            }
            return [SearchShelf(id: "today", header: "Airing today", entries: shown.prefix(limit).map(entry))]
        case .newSeasons:
            let since = formatter.localDay(now, addingDays: -newSeasonDays)
            let begun = catalogue.seasons.filter { item in
                guard let start = item.seasonStart else { return false }
                return start >= since && start <= today
            }
            // A premiere this week ranks by the show's popularity when it's on a popular list; one that isn't
            // follows them, in the airing order.
            let weights = Dictionary((catalogue.popular + catalogue.seasons).map { ($0.id, $0.weight) },
                                     uniquingKeysWith: max)
            let begunIDs = Set(begun.map(\.id))
            let premieres = upcoming.filter { $0.drop.number == 1 && !begunIDs.contains($0.id) }
            let ranked = (begun.map { (entry($0), $0.weight) }
                + premieres.compactMap { item in weights[item.id].map { (entry(item), $0) } })
                .enumerated()
                .sorted { ($0.element.1, $1.offset) > ($1.element.1, $0.offset) }
                .map(\.element.0)
            let rest = premieres.filter { weights[$0.id] == nil }.map(entry)
            return [SearchShelf(id: "new-seasons", header: "New seasons", entries: Array((ranked + rest).prefix(limit)))]
        case .service(let label):
            let names = Set(PopularServices.service(label)?.names ?? [label])
            let onService = { (result: SearchResult) in result.network.map(names.contains) ?? false }
            return [
                SearchShelf(id: "service-popular", header: "Popular on \(label)",
                            entries: popular.filter { onService($0.result) }.prefix(limit).map(entry)),
                SearchShelf(id: "airing", header: "Airing on \(label) \(window)",
                            entries: upcoming.filter { onService($0.result) }.prefix(limit).map(entry)),
            ]
        }
    }

    /// The episodes not yet out at `now`: one that came out since the list loaded is never offered as still to come.
    private static func stillToCome(_ items: [AiringItem], now: Date, formatter: DropFormatter) -> [AiringItem] {
        let today = formatter.localDay(now)
        return items.filter { item in
            item.drop.confidence == .dateOnly ? (item.drop.airdate ?? "") >= today : item.drop.date > now
        }
    }

    /// The popular shows whose last episode aired in the past year (an anime, with no `lastAired`, always counts).
    private static func pastYear(_ items: [PopularItem], now: Date, formatter: DropFormatter) -> [PopularItem] {
        let yearAgo = formatter.localDay(now, addingDays: -popularDays)
        return items.filter { ($0.lastAired ?? formatter.localDay(now)) >= yearAgo }
    }

    /// One plain line when every grid of a filter is empty; an empty grid beside a full one is just left out.
    static func noMatch(_ filter: SearchFilter) -> String {
        switch filter {
        case .popular: "No popular shows to show."
        case .today: "Nothing left to air today."
        case .newSeasons: "No new seasons in the past 3 months."
        case .service(let name): "Nothing on \(name) from the past year or the next few days."
        }
    }
}
