import Foundation

/// What narrows Search's airing grid: one at a time, picked like the TV | Anime switch (Chime, 1 Nov 2026; D-43).
enum SearchFilter: Hashable, Sendable {
    case popular, today, newSeasons, exactTime
    case service(String)

    var label: String {
        switch self {
        case .popular: "Popular"
        case .today: "Today"
        case .newSeasons: "New seasons"
        case .exactTime: "Exact time"
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

/// Filters the airing grid on what's already loaded: no TVmaze or AniList request (D-43). Every filter also drops an
/// episode that has come out since the grid loaded, so a grid left open never lists what's already out.
enum AiringFilter {
    /// Services offered as filters, most shows first.
    static let maxServices = 6

    /// TV: Popular, Today, New seasons, Exact time, then its services. Anime: no exact-time or service filter, because
    /// every anime time is the Japanese broadcast and AniList names no single service.
    static func options(for kind: SearchView.Kind, items: [AiringItem],
                        hasLogo: (String) -> Bool = { _ in false }) -> [SearchFilter] {
        switch kind {
        case .tv: [.popular, .today, .newSeasons, .exactTime]
            + services(in: items, hasLogo: hasLogo).map(SearchFilter.service)
        case .anime: [.popular, .today, .newSeasons]
        }
    }

    /// The services in the whole pool (not the filtered grid, so a chosen one never disappears), named as each cell
    /// names it: the network, else the web channel. The 6 with the most shows (ties A to Z), then those with a logo
    /// first, so logo chips sit together (Chime, D-44).
    static func services(in items: [AiringItem], hasLogo: (String) -> Bool = { _ in false }) -> [String] {
        let counts = Dictionary(grouping: items.compactMap(\.result.network), by: \.self).mapValues(\.count)
        let top = counts.keys.sorted { (counts[$0] ?? 0, $1) > (counts[$1] ?? 0, $0) }.prefix(maxServices)
        return top.filter(hasLogo) + top.filter { !hasLogo($0) }
    }

    /// The items that pass `filter` and are still to come at `now`, in their order, at most `limit`.
    static func apply(_ filter: SearchFilter, to items: [AiringItem], now: Date, formatter: DropFormatter,
                      limit: Int = AiringSoon.limit) -> [AiringItem] {
        let today = formatter.localDay(now)
        func onToday(_ drop: Drop) -> Bool {
            drop.confidence == .dateOnly ? drop.airdate == today : formatter.localDay(drop.date) == today
        }
        let kept = items.filter { item in
            let drop = item.drop
            let ahead = drop.confidence == .dateOnly ? (drop.airdate ?? "") >= today : drop.date > now
            guard ahead else { return false }
            switch filter {
            case .popular: return true
            case .today: return onToday(drop)
            case .newSeasons: return drop.number == 1
            case .exactTime: return drop.confidence == .exact
            case .service(let name): return item.result.network == name
            }
        }
        return Array(kept.prefix(limit))
    }

    /// One plain line when a filter leaves the grid empty.
    static func noMatch(_ filter: SearchFilter, kind: SearchView.Kind) -> String {
        let window = kind == .tv ? "in the next few days" : "this week"
        switch filter {
        case .popular: return "Nothing airing \(window)."
        case .today: return "Nothing left to air today."
        case .newSeasons: return "No new seasons \(window)."
        case .exactTime: return "No confirmed times \(window)."
        case .service(let name): return "Nothing on \(name) \(window)."
        }
    }
}
