import Foundation

/// A catalog-neutral view of one listed episode, the input to `TimeResolver`.
struct EpisodeListing: Hashable, Sendable {
    /// "tvmaze:<id>"
    var episodeID: String
    var showID: String
    /// "yyyy-MM-dd", or nil when unannounced.
    var airdate: String?
    /// "HH:mm", or "" when the catalog has no real time.
    var airtime: String
    /// Catalog's UTC instant. A placeholder whenever `airtime` is empty (D-25).
    var airstamp: Date?
    /// Web channel and network names, used to match platform rules.
    var channelNames: [String]
    /// The network whose airtime this is, for the broadcast source chip.
    var broadcastNetwork: String?
}
