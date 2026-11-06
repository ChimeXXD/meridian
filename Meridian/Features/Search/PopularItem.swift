import Foundation

/// A show on Search's popular lists (Popular, New seasons, a service's "Popular on"), whether or not an episode is
/// coming: TV from the bundled `PopularShows` (Wikipedia page views), anime from AniList (D-66).
struct PopularItem: Hashable, Identifiable, Sendable {
    let result: SearchResult
    /// Wikipedia page views over 12 months (TV) or AniList popularity (anime): the order, most popular first.
    let weight: Int
    /// The last day an episode aired, `yyyy-MM-dd` (TV), so a list built days ago still keeps only the past year.
    /// Nil for anime, whose AniList query already keeps only the past year.
    let lastAired: String?
    /// The latest season's number (TV only) and the day it began, `yyyy-MM-dd`. An anime season is its own AniList
    /// entry, so its start is the entry's.
    let season: Int?
    let seasonStart: String?

    var id: Int { result.id }

    init(entry: PopularShows.Entry) {
        result = SearchResult(show: entry.show)
        weight = entry.views
        lastAired = entry.lastAired
        season = entry.season
        seasonStart = entry.seasonStart
    }

    init(media: AniListMedia) {
        result = SearchResult(media: media)
        weight = media.popularity ?? 0
        lastAired = nil
        season = nil
        seasonStart = media.startDate?.day.flatMap { day in
            media.startDate?.month.flatMap { month in
                media.startDate?.year.map { String(format: "%04d-%02d-%02d", $0, month, day) }
            }
        }
    }
}
