import Foundation

/// The viewer's country from their time zone (D2-6), for "No official stream in your country" (CLAUDE.md rule 11).
/// The table is the tz database's zone.tab, bundled as `zone-countries.json` (`scripts/make-zone-countries.py`); a zone
/// it doesn't know (UTC, a fixed offset) falls back to the device region.
struct ViewerCountry: Sendable {
    private let table: [String: String]

    init(table: [String: String]) {
        self.table = table
    }

    var count: Int { table.count }

    /// ISO country code, e.g. "NG" for Africa/Lagos.
    func code(zone: String, region: String?) -> String? {
        table[zone] ?? region
    }

    static func loadBundled(from bundle: Bundle = .main) throws -> ViewerCountry {
        guard let url = bundle.url(forResource: "zone-countries", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return ViewerCountry(table: try JSONDecoder().decode([String: String].self, from: Data(contentsOf: url)))
    }
}
