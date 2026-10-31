import Foundation

/// One search result as Search shows it: the title, and a meta line that tells same-name shows apart ("2019 · HBO ·
/// US · Ended" against "2012 · HOT3 · IL · Ended"). Search never picks a result for you (SPEC §1).
/// The poster grid prints `gridMeta` over `status`; VoiceOver reads them as one `meta` line.
struct SearchResult: Hashable, Identifiable, Sendable {
    let id: Int
    let catalog: Catalog
    let title: String
    let year: Int?
    let network: String?
    let status: String?
    /// The year and network with its country, short enough for a three-across grid cell, which puts the status on a
    /// line of its own: "2019 · HBO · US". The country stays, because it is what tells same-name shows apart.
    let gridMeta: String
    let meta: String
    /// TVmaze's 210 × 295 poster, loaded at runtime and cached on the phone (D-37).
    let poster: URL?

    init(show: TVmazeShow) {
        id = show.id
        catalog = .tvmaze
        title = show.name
        poster = show.image?.medium
        year = show.premiered.flatMap { Int($0.prefix(4)) }
        let channel = show.network ?? show.webChannel
        network = channel?.name
        status = show.status.map(Self.sentenceCase)
        let provider = channel.map { [$0.name, show.network?.country?.code].compactMap(\.self).joined(separator: " · ") }
        gridMeta = Self.line(year.map(String.init), provider)
        meta = Self.line(gridMeta.isEmpty ? nil : gridMeta, status)
    }

    /// An anime from AniList, worded like a TV result: "2023 · Crunchyroll · Finished".
    init(media: AniListMedia) {
        id = media.id
        catalog = .anilist
        title = media.displayTitle
        poster = media.coverImage?.large
        year = media.startDate?.year
        network = media.streamingSite
        status = media.statusText
        gridMeta = Self.line(year.map(String.init), network)
        meta = Self.line(gridMeta.isEmpty ? nil : gridMeta, status)
    }

    var followShow: FollowStore.Show {
        FollowStore.Show(catalog: catalog, id: id, name: title, year: year, network: network)
    }

    private static func line(_ parts: String?...) -> String {
        parts.compactMap(\.self).joined(separator: " · ")
    }

    /// TVmaze's "To Be Determined" reads as "To be determined" (sentence case, D-39).
    private static func sentenceCase(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst().lowercased()
    }
}
