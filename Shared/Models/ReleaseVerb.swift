import Foundation

/// How sure a release time is, in one word (D-40): "Out" for a published time, "Expected" for an estimate, "Airs in
/// Japan" for an anime's Japanese TV time. The raw values are the words, so the Live Activity payload carries the
/// same strings it always has (CLAUDE.md rule 7).
enum ReleaseVerb: String, Codable, Hashable, Sendable {
    case out = "Out"
    case expected = "Expected"
    case airsInJapan = "Airs in Japan"

    /// The verb for a drop: an AniList time airs in Japan, an exact time is out, anything else is expected.
    init(_ drop: Drop) {
        if case .anilist = drop.source {
            self = .airsInJapan
        } else {
            self = drop.confidence == .exact ? .out : .expected
        }
    }

    /// The word on screen. After the time only a sure time says "Released" and an anime "Aired in Japan"; an estimate
    /// keeps "Expected", as it's never sure.
    func word(past: Bool) -> String {
        guard past else { return rawValue }
        return switch self {
        case .out: "Released"
        case .expected: rawValue
        case .airsInJapan: "Aired in Japan"
        }
    }

    /// The words VoiceOver says for the time left, mid-sentence: "in 2 hours", "expected in 2 hours", "airs in Japan
    /// in 2 hours" for a spoken countdown (`left`, without its "in"), or "out now", "expected now", "just aired in
    /// Japan" when `left` is nil. The widgets and the Live Activity both build their phrase on it.
    func spoken(left: String?) -> String {
        guard let left else {
            return switch self {
            case .out: "out now"
            case .expected: "expected now"
            case .airsInJapan: "just aired in Japan"
            }
        }
        return switch self {
        case .out: "in \(left)"
        case .expected: "expected in \(left)"
        case .airsInJapan: "airs in Japan in \(left)"
        }
    }
}
