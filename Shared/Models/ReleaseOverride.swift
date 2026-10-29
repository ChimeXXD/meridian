import Foundation

/// An exception to a platform rule, for one episode (`episode`) or a whole show (`show`).
/// Episode overrides give an `instant`; show overrides give a wall-clock `zone` and `time`.
struct ReleaseOverride: Codable, Hashable, Sendable {
    var episode: String?
    var show: String?
    var instant: Date?
    var zone: String?
    var time: String?
    var dayOffset: Int?
    /// Confirmed overrides are `exact`; others are `estimated`.
    var confirmed: Bool
    var note: String
    var source: String

    /// The release instant for an episode listed on `airdate`.
    func date(airdate: String?) -> Date? {
        if let instant { return instant }
        guard let airdate, let zone, let time else { return nil }
        return WallClock.instant(airdate: airdate, time: time, zone: zone, dayOffset: dayOffset ?? 0)
    }
}
