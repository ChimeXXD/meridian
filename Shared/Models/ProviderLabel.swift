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

    /// A line that ends with a country code, split before it: "S2E5 · HBO · US" is ("S2E5 · HBO", " · US"), so a tight
    /// line shortens the words and keeps the country (D-20, CLAUDE.md rule 11). A line without one keeps it all.
    static func splitCountry(_ line: String) -> (lead: String, country: String?) {
        guard let dot = line.range(of: " · ", options: .backwards) else { return (line, nil) }
        let code = line[dot.upperBound...]
        guard code.count == 2, code.allSatisfy({ $0.isASCII && $0.isUppercase }) else { return (line, nil) }
        return (String(line[..<dot.lowerBound]), String(line[dot.lowerBound...]))
    }

    /// The same line for a view that wraps it (BU-10): the country is glued to its network ("HBO\u{A0}·\u{A0}US") and
    /// every other dot to the word before it ("S3E4\u{A0}· HBO"), so a line never starts with a dot or ends on "· US"
    /// alone; the names' own spaces still break. The stored text keeps plain spaces, for the widgets' one-line
    /// shortening (`splitCountry`) and VoiceOver.
    static func wrapping(_ line: String) -> String {
        let (lead, country) = splitCountry(line)
        let glued = lead.replacingOccurrences(of: " · ", with: "\u{00A0}· ")
        return glued + (country.map { $0.replacingOccurrences(of: " · ", with: "\u{00A0}·\u{00A0}") } ?? "")
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
