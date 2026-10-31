import Foundation

// TVmaze API response shapes (https://www.tvmaze.com/api). Only the fields Airstamp uses.

struct TVmazeCountry: Codable, Hashable, Sendable {
    let name: String?
    let code: String?
    let timezone: String?
}

struct TVmazeChannel: Codable, Hashable, Sendable {
    let id: Int
    let name: String
    let country: TVmazeCountry?
}

struct TVmazeEpisode: Codable, Hashable, Sendable {
    let id: Int
    let name: String?
    let season: Int?
    let number: Int?
    let type: String?
    let airdate: String?
    let airtime: String?
    let airstamp: String?
    let runtime: Int?
}

struct TVmazeShow: Codable, Hashable, Sendable {
    struct Embedded: Codable, Hashable, Sendable {
        let nextepisode: TVmazeEpisode?
        let previousepisode: TVmazeEpisode?
    }

    let id: Int
    let name: String
    let type: String?
    let language: String?
    let status: String?
    let premiered: String?
    let network: TVmazeChannel?
    let webChannel: TVmazeChannel?
    /// TVmaze's popularity score, 0–100.
    let weight: Int?
    /// The main poster: "medium" is 210 × 295, "original" full size. Nil when TVmaze has none.
    let image: TVmazeShowImage?
    let embedded: Embedded?

    enum CodingKeys: String, CodingKey {
        case id, name, type, language, status, premiered, network, webChannel, weight, image
        case embedded = "_embedded"
    }
}

/// One episode on a TVmaze schedule. The broadcast schedule puts the show inline; the streaming schedule embeds it.
struct TVmazeScheduleItem: Decodable, Sendable {
    /// The episode's own fields (season, number, airdate, airtime, airstamp) sit at the top level of the item.
    let episode: TVmazeEpisode
    let show: TVmazeShow?

    private struct Embedded: Decodable { let show: TVmazeShow? }
    private enum CodingKeys: String, CodingKey {
        case show
        case embedded = "_embedded"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        episode = try TVmazeEpisode(from: decoder)
        show = try container.decodeIfPresent(TVmazeShow.self, forKey: .show)
            ?? container.decodeIfPresent(Embedded.self, forKey: .embedded)?.show
    }
}

struct TVmazeShowImage: Codable, Hashable, Sendable {
    let medium: URL?
    let original: URL?
}

struct TVmazeSearchResult: Codable, Hashable, Sendable {
    let score: Double
    let show: TVmazeShow
}

extension TVmazeEpisode {
    /// The catalog-neutral listing `TimeResolver` works on.
    func listing(show: TVmazeShow) -> EpisodeListing {
        EpisodeListing(
            episodeID: "tvmaze:\(id)",
            showID: "tvmaze:\(show.id)",
            airdate: airdate.flatMap { $0.isEmpty ? nil : $0 },
            airtime: airtime ?? "",
            airstamp: airstamp.flatMap(Self.parseAirstamp),
            channelNames: [show.webChannel?.name, show.network?.name].compactMap { $0 },
            broadcastNetwork: show.network?.name ?? show.webChannel?.name)
    }

    /// TVmaze airstamps carry an offset, e.g. "2025-11-14T12:00:00+00:00".
    static func parseAirstamp(_ text: String) -> Date? {
        try? Date(text, strategy: .iso8601)
    }
}

/// One entry of `/shows/:id/images`. Only URLs are used; the images themselves are fetched at runtime (D-37).
struct TVmazeImage: Codable, Hashable, Sendable {
    struct Resolution: Codable, Hashable, Sendable {
        let url: URL
        let width: Int?
        let height: Int?
    }

    let type: String?
    let main: Bool
    let resolutions: [String: Resolution]
}
