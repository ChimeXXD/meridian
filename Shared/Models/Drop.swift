import Foundation

/// One upcoming episode with its resolved release time.
struct Drop: Codable, Hashable, Identifiable, Sendable {
    /// "\(catalog):\(showID):\(episodeID)"
    var id: String
    var showID: String
    var showName: String
    var season: Int?
    var number: Int?
    /// Hidden in widgets (spoiler-safe).
    var episodeTitle: String?
    /// UTC instant. For `dateOnly` drops it is only a sort key; show `airdate` instead.
    var date: Date
    /// "yyyy-MM-dd" as listed. `dateOnly` rows are formatted from this, never from `date` (D-28).
    var airdate: String?
    var confidence: Confidence
    var source: ReleaseSource
    var provider: ProviderLabel?
    /// Set when a refresh moved the time later.
    var previousDate: Date?
    /// The network's own IANA zone, for "That's when HBO airs it in its home zone: Fri 17:00 New York time".
    /// Only a broadcast time has one.
    var broadcastZone: String? = nil

    /// This drop's show as a catalog and ID; nil for a `showID` that isn't one (the debug show's "debug").
    var show: ShowID? { ShowID(showID) }

    /// "S2E5", or "E5" when there's no season; nil without an episode number.
    var episodeLabel: String? {
        guard let number else { return nil }
        return season.map { "S\($0)E\(number)" } ?? "E\(number)"
    }
}
