import Foundation

/// Where a show's schedule comes from.
enum Catalog: String, Codable, Sendable {
    case tvmaze, anilist
}
