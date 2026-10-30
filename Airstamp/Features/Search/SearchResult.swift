import Foundation

/// One search result as Search shows it: the title, and a meta line that tells same-name shows apart ("2019 · HBO ·
/// US · Ended" against "2012 · HOT3 · IL · Ended"). Search never picks a result for you (SPEC §1).
struct SearchResult: Hashable, Identifiable, Sendable {
    let id: Int
    let catalog: Catalog
    let title: String
    let year: Int?
    let network: String?
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
        let provider = channel.map { [$0.name, show.network?.country?.code].compactMap(\.self).joined(separator: " · ") }
        meta = [year.map(String.init), provider, show.status.map(Self.sentenceCase)]
            .compactMap(\.self).joined(separator: " · ")
    }

    var followShow: FollowStore.Show {
        FollowStore.Show(catalog: catalog, id: id, name: title, year: year, network: network)
    }

    /// TVmaze's "To Be Determined" reads as "To be determined" (sentence case, D-39).
    private static func sentenceCase(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst().lowercased()
    }
}
