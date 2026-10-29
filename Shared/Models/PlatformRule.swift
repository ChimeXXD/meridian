import Foundation

/// A platform's usual release time, used when TVmaze has no airtime.
struct PlatformRule: Codable, Hashable, Sendable {
    /// TVmaze web channel or network names this rule covers.
    var match: [String]
    /// IANA zone ID, never a fixed offset.
    var zone: String
    /// "HH:mm" in `zone`.
    var time: String
    /// Days relative to the listed airdate (Apple TV is -1).
    var dayOffset: Int
    /// Source chip text, e.g. "Netflix rule".
    var label: String
    /// At least 2 real examples.
    var sources: [String]
}
