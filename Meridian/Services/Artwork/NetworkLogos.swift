import Foundation

/// Logos for Search's service chips (D-44): a hand-checked list of freely licensed Wikimedia Commons files
/// (`rules/network-logos.json`), matched by the exact TVmaze network or web channel name. Only URLs are bundled; the
/// images load at runtime like posters and are never committed (rule 9).
struct NetworkLogos: Decodable, Sendable {
    struct Logo: Decodable, Sendable {
        let names: [String]
        let file: String
        let page: URL
        let license: String
        let attribution: String?
        let image: URL
    }

    let source: String
    let checked: String
    let logos: [Logo]

    /// The logo image for a service named exactly as TVmaze names it ("HBO", "Apple TV"); nil when there's none.
    func image(for name: String) -> URL? {
        logos.first { $0.names.contains(name) }?.image
    }

    /// One line per file whose license asks for credit, for the Credits screen. The credit is Commons' own wording,
    /// which already names the licence: "AMC+ logo: Ardi3005, CC BY-SA 4.0, via Wikimedia Commons".
    var credits: [String] {
        logos.compactMap { logo in logo.attribution.map { "\(logo.names.first ?? logo.file) logo: \($0)" } }
    }

    static let empty = NetworkLogos(source: "", checked: "", logos: [])

    /// The app's bundled list, decoded once and shared by Search and Credits.
    static let bundled = loadBundled()

    /// The bundled list; empty if it's missing or unreadable, so chips simply show names.
    static func loadBundled(from bundle: Bundle = .main) -> NetworkLogos {
        guard let url = bundle.url(forResource: "network-logos", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let logos = try? JSONDecoder().decode(NetworkLogos.self, from: data) else { return .empty }
        return logos
    }
}
