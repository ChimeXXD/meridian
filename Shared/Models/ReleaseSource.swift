import Foundation

/// Where a displayed time came from. The views say how sure it is in words (`ReleaseWording`), and Show detail
/// explains the source in one sentence (D-40).
enum ReleaseSource: Codable, Hashable, Sendable {
    /// TVmaze airtime in the network's own time zone.
    case broadcast(network: String)
    /// A platform rule from the rules file, e.g. "Netflix rule".
    case platformRule(String)
    /// A per-episode or per-show override from the rules file (D-18).
    case override(note: String)
    /// A user offset applied on top of another source, e.g. an anime stream delay.
    case adjusted(base: String, offsetMinutes: Int)
    /// AniList `airingAt`: the Japanese broadcast time.
    case anilist
    case dateOnly

    /// A short name for the underlying source, used when an offset adjusts it.
    var baseLabel: String {
        switch self {
        case .broadcast(let network): network
        case .platformRule(let label): label
        case .override(let note): note
        case .adjusted(let base, _): base
        case .anilist: "JP broadcast"
        case .dateOnly: "Date only"
        }
    }
}
