import Foundation

/// The TV shows people read about most on English Wikipedia over the past 12 months that aired in that year
/// (`rules/popular-shows.json`, built by `scripts/build-popular-shows.py`; D-66). Search's Popular, New seasons and
/// each service's "Popular on" row read it, so a well-known show between seasons is there too, not only what airs
/// this week. Each entry carries TVmaze's record of the show (poster URLs only, loaded at runtime, rule 9).
struct PopularShows: Decodable, Sendable {
    struct Entry: Decodable, Sendable {
        /// Page views of the show's article over the 12 months, plus its season articles': the order.
        let views: Int
        /// The last day an episode aired, `yyyy-MM-dd`.
        let lastAired: String?
        /// The latest season that has begun, and its first day, `yyyy-MM-dd`.
        let season: Int?
        let seasonStart: String?
        let show: TVmazeShow
    }

    let updated: String
    /// Most viewed first.
    let shows: [Entry]

    static let empty = PopularShows(updated: "", shows: [])

    /// The app's bundled list, decoded once.
    static let bundled = loadBundled()

    /// The bundled list; empty if it's missing or unreadable, so Search still shows what's airing.
    static func loadBundled(from bundle: Bundle = .main) -> PopularShows {
        guard let url = bundle.url(forResource: "popular-shows", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode(PopularShows.self, from: data) else { return .empty }
        return list
    }
}
