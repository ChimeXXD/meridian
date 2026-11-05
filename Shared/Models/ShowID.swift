import Foundation

/// A show's identity: its catalog and its ID there. Written as the string `Drop.showID` and `QuietShow.showID` carry,
/// "38052" for TVmaze and "anilist:154587" for AniList, so the snapshot (D-05) and the Live Activity payload
/// (CLAUDE.md rule 7) read the same with it.
struct ShowID: Hashable, Sendable, CustomStringConvertible {
    var catalog: Catalog
    var id: Int

    init(catalog: Catalog, id: Int) {
        self.catalog = catalog
        self.id = id
    }

    /// Reads `description`'s form. Nil for anything else, such as the debug show's "debug", rather than show 0.
    init?(_ string: String) {
        let anime = string.hasPrefix(Self.anilistPrefix)
        let digits = anime ? string.dropFirst(Self.anilistPrefix.count) : Substring(string)
        guard !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }), let id = Int(digits) else { return nil }
        self.init(catalog: anime ? .anilist : .tvmaze, id: id)
    }

    /// "38052" for a TVmaze show, "anilist:154587" for an AniList one: the form the snapshot and the views key on.
    var description: String { catalog == .anilist ? "\(Self.anilistPrefix)\(id)" : String(id) }

    /// "tvmaze:38052", "anilist:154587": with its catalog always, as `FollowedShow.key` and the rules file's show
    /// overrides have it.
    var key: String { "\(catalog.rawValue):\(id)" }

    /// A drop's ID, the show's key and the catalog's episode: "tvmaze:38052:3314580" (TVmaze's episode ID),
    /// "anilist:154587:12" (AniList's episode number).
    func dropID(episode: Int) -> String { "\(key):\(episode)" }

    private static let anilistPrefix = "anilist:"
}

extension ShowID: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let show = ShowID(string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a show ID: \(string)")
        }
        self = show
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
