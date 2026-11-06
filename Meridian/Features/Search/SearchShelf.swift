import Foundation

/// What Search has loaded for one catalog before you type: shows with an episode in the next few days, the popular
/// shows of the past year, and the shows whose season began recently (D-66). TV's two lists are the same bundled
/// `PopularShows`; anime's come from AniList.
struct SearchCatalogue: Sendable {
    var upcoming: [AiringItem]
    var popular: [PopularItem]
    var seasons: [PopularItem]
}

/// One titled grid on Search before you type: "Popular in the past year", or a service's "Popular on Netflix" over
/// "Airing on Netflix in the next few days" (D-66). An empty one isn't shown. Its `id` names the header
/// (`search-<id>-header`) and the cells (`<id>-1`, `<id>-2`, …) for the screen checks.
struct SearchShelf: Identifiable, Hashable, Sendable {
    /// A cell: the show, its next episode when one is still to come, and when its latest season began.
    struct Entry: Hashable, Identifiable, Sendable {
        let result: SearchResult
        let drop: Drop?
        var season: Int? = nil
        var seasonStart: String? = nil

        var id: Int { result.id }

        /// "Out today at 21:00" for a show with an episode coming (rule 3, D-40); otherwise when its latest season
        /// began, "Season 3 began Sat 12 Sep" ("Began Fri 3 Oct" for an anime or a show's first season).
        func line(now: Date, formatter: DropFormatter) -> String? {
            if let drop { return ReleaseWording.outLine(drop, now: now, formatter: formatter) }
            guard let seasonStart, let day = formatter.airdate(seasonStart, now: now) else { return nil }
            // TVmaze numbers a daily soap's seasons by year (2026): "Season 2026 began" would read as nonsense.
            if let season, (2...999).contains(season) { return "Season \(season) began \(day)" }
            return "Began \(day)"
        }
    }

    let id: String
    let header: String
    let entries: [Entry]
}
