import Foundation

/// Where a poster on the Search tab leads: the show, and its next episode when the grid already knows it (the airing
/// grid does; a search result doesn't, so the page asks).
struct ShowRoute: Hashable, Sendable {
    let result: SearchResult
    let knownDrop: Drop?
}

/// The show page's one network question: when is the next episode? Timed exactly as Upcoming times it (TimeResolver
/// with the bundled rules for TV, the Japanese broadcast for anime, plus a followed show's own `offsetMinutes`), so the
/// two screens never disagree. Nil when nothing is scheduled or the request fails: the page then leaves the line out
/// rather than guess.
enum ShowPreview {
    static func nextDrop(catalog: Catalog, id: Int, client: TVmazeClient, anilist: AniListClient, rules: RulesFile,
                         offsetMinutes: Int = 0, now: Date = .now) async -> Drop? {
        switch catalog {
        case .tvmaze:
            guard let show = try? await client.show(id: id), let next = show.embedded?.nextepisode else { return nil }
            let resolution = TimeResolver.resolve(next.listing(show: show), rules: rules,
                                                  offsetMinutes: offsetMinutes, now: now)
            return AiringItem(pick: AiringSoon.Pick(show: show, episode: next, resolution: resolution)).drop
        case .anilist:
            guard let media = try? await anilist.media(id: id) else { return nil }
            return AiringItem(media: media, offsetMinutes: offsetMinutes)?.drop
        }
    }
}
