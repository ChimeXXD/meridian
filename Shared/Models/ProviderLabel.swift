import Foundation

/// The origin network or channel and its country, e.g. "HBO · US" (D-20).
struct ProviderLabel: Codable, Hashable, Sendable {
    var name: String
    var countryCode: String?
    var noOfficialStream: Bool

    var display: String {
        guard let countryCode else { return name }
        return "\(name) · \(countryCode)"
    }
}

extension ProviderLabel {
    /// A label for a network or streamer, flagged when the rules file lists no official stream in the viewer's
    /// country (CLAUDE.md rule 11). `countryCode` is the network's own country; global streamers have none.
    init(name: String, countryCode: String?, viewerCountry: String?, rules: RulesFile) {
        let blocked = viewerCountry.map { viewer in
            rules.providers.contains { $0.match.contains(name) && $0.noOfficialStreamIn.contains(viewer) }
        } ?? false
        self.init(name: name, countryCode: countryCode, noOfficialStream: blocked)
    }
}
