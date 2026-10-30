import Foundation
import SwiftData

/// A show you follow, stored on the phone with SwiftData (app target only; widgets read the JSON snapshot, D-05).
@Model
final class FollowedShow {
    /// "tvmaze:38052" or "anilist:154587": one entry per show per catalog.
    @Attribute(.unique) var key: String
    var catalogRaw: String
    var catalogID: Int
    var name: String
    /// Premiere year and network, to tell same-name shows apart in lists (SPEC §1, Search).
    var year: Int?
    var network: String?
    /// The release-night Live Activity, on by default.
    var liveActivity: Bool
    /// A per-show stream delay for anime, in minutes (SPEC §3.1, O-1).
    var animeOffsetMinutes: Int
    var followedAt: Date

    var catalog: Catalog { Catalog(rawValue: catalogRaw) ?? .tvmaze }

    init(catalog: Catalog, catalogID: Int, name: String, year: Int?, network: String?, followedAt: Date = .now) {
        key = Self.key(catalog: catalog, id: catalogID)
        catalogRaw = catalog.rawValue
        self.catalogID = catalogID
        self.name = name
        self.year = year
        self.network = network
        liveActivity = true
        animeOffsetMinutes = 0
        self.followedAt = followedAt
    }

    static func key(catalog: Catalog, id: Int) -> String { "\(catalog.rawValue):\(id)" }
}
