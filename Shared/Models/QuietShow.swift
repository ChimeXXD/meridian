import Foundation

/// A followed show with no next episode: enough to show its poster and say why ("Ended · last episode …"). Upcoming
/// lists these under "Nothing scheduled", and the snapshot hands them to the widgets' spare rows (D-48).
struct QuietShow: Codable, Equatable, Hashable, Sendable {
    /// Same form as `Drop.showID`: "38052" or "anilist:154587".
    var showID: String
    var name: String
    /// TVmaze's or AniList's own status, worded by `ReleaseWording.quietNote`.
    var status: String?
    /// "yyyy-MM-dd" of the last aired episode, when known.
    var lastAired: String?
}
