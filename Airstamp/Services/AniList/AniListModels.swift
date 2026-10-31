import Foundation

// AniList GraphQL response shapes (https://docs.anilist.co). Only the fields Airstamp uses.

struct AniListMedia: Codable, Hashable, Sendable {
    struct Title: Codable, Hashable, Sendable {
        let romaji: String?
        let english: String?
    }

    struct FuzzyDate: Codable, Hashable, Sendable {
        let year: Int?
    }

    struct Cover: Codable, Hashable, Sendable {
        let large: URL?
        let extraLarge: URL?
    }

    struct NextEpisode: Codable, Hashable, Sendable {
        /// Unix seconds: the Japanese broadcast.
        let airingAt: Int
        let episode: Int
    }

    struct Link: Codable, Hashable, Sendable {
        let site: String
        let type: String?
    }

    let id: Int
    let isAdult: Bool
    let title: Title
    var startDate: FuzzyDate? = nil
    /// FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED, HIATUS.
    var status: String? = nil
    var format: String? = nil
    var popularity: Int? = nil
    var countryOfOrigin: String? = nil
    var coverImage: Cover? = nil
    var bannerImage: URL? = nil
    var nextAiringEpisode: NextEpisode? = nil
    var externalLinks: [Link]? = nil

    /// The English title when AniList has one, otherwise the romaji.
    var displayTitle: String { title.english ?? title.romaji ?? "Untitled" }

    /// The first official streaming site, e.g. "Crunchyroll".
    var streamingSite: String? { externalLinks?.first { $0.type == "STREAMING" }?.site }

    /// "Finished", "Airing", "Not yet aired".
    var statusText: String? {
        switch status {
        case "FINISHED": "Finished"
        case "RELEASING": "Airing"
        case "NOT_YET_RELEASED": "Not yet aired"
        case "CANCELLED": "Cancelled"
        case "HIATUS": "On hiatus"
        default: nil
        }
    }
}

struct AniListAiring: Codable, Hashable, Sendable {
    let airingAt: Int
    let episode: Int
    let media: AniListMedia
}

/// `{ data: { Page: { media | airingSchedules } } }`
struct AniListPage: Decodable, Sendable {
    struct Page: Decodable, Sendable {
        struct Info: Decodable, Sendable { let hasNextPage: Bool? }
        let pageInfo: Info?
        let media: [AniListMedia]?
        let airingSchedules: [AniListAiring]?
    }

    struct Body: Decodable, Sendable {
        let Page: Page
    }

    let data: Body
}

/// `{ data: { Media } }`
struct AniListSingle: Decodable, Sendable {
    struct Body: Decodable, Sendable {
        let Media: AniListMedia?
    }

    let data: Body
}
