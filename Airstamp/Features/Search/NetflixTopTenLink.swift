import Foundation

/// A link to Netflix's own weekly Top 10 for the viewer's country (D-43). Netflix's terms forbid copying or
/// redistributing the chart (O-13), so Search opens Netflix's page instead of listing it.
struct NetflixTopTenLink: Hashable, Sendable {
    let label: String
    let url: URL

    /// Countries whose Netflix page isn't named by the current English name ("Czechia", "Türkiye").
    private static let slugOverrides = ["CZ": "czech-republic", "TR": "turkey"]

    /// From the viewer's country code (`ViewerCountry`, "NG"); nil when it's unknown. Netflix names its country pages
    /// by the English country name: "nigeria", "united-kingdom", "trinidad-and-tobago".
    init?(country: String?) {
        // Only two-letter countries: "ZZ" (unknown) would read "Unknown Region", and "001" (a UN area) "world".
        guard let country, country.count == 2, country.allSatisfy({ $0.isASCII && $0.isUppercase }), country != "ZZ",
              Locale.Region.isoRegions.contains(Locale.Region(country)),
              let name = Locale(identifier: "en_US").localizedString(forRegionCode: country) else { return nil }
        let slug = Self.slugOverrides[country] ?? Self.slug(name)
        guard let url = URL(string: "https://www.netflix.com/tudum/top10/\(slug)/tv") else { return nil }
        label = "Top 10 on Netflix in \(name)"
        self.url = url
    }

    /// "Trinidad & Tobago" → "trinidad-and-tobago", "Réunion" → "reunion": letters and digits, one hyphen between words.
    private static func slug(_ name: String) -> String {
        name.replacingOccurrences(of: "&", with: "and")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
            .lowercased()
            .split(whereSeparator: { !($0.isLetter || $0.isNumber) })
            .joined(separator: "-")
    }
}
