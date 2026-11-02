import Foundation

/// An anime's stream can follow its Japanese TV time by a set delay (SPEC §3.1, UI-BRIEF `detail-offset`): Show
/// detail sets it per show, and `TimeResolver` applies it, so the time reads "Expected" once it's adjusted (D-40).
enum AnimeOffset {
    static let range = 0...180
    static let step = 15

    /// "Same time as Japan", "15 min after Japan", "1 h 30 min after Japan".
    static func phrase(_ minutes: Int) -> String {
        guard minutes > 0 else { return "Same time as Japan" }
        let hours = minutes / 60, rest = minutes % 60
        let parts = [hours > 0 ? "\(hours) h" : nil, rest > 0 ? "\(rest) min" : nil].compactMap(\.self)
        return "\(parts.joined(separator: " ")) after Japan"
    }

    /// Anime only: a show from AniList, or one whose time is already adjusted from Japan's.
    static func applies(to drop: Drop, catalog: Catalog) -> Bool {
        if catalog == .anilist { return true }
        switch drop.source {
        case .anilist, .adjusted: return true
        default: return false
        }
    }
}
