import Foundation

/// Countries where a provider has no official stream, so the label can say so honestly.
struct ProviderRule: Codable, Hashable, Sendable {
    var match: [String]
    /// ISO country codes, e.g. "NG".
    var noOfficialStreamIn: [String]
    var source: String
}
