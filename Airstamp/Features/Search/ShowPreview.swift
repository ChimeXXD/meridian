import Foundation

/// Where a poster on the Search tab leads: the show, and its next episode when the grid already knows it (the airing
/// grid does; a search result doesn't, so the page asks).
struct ShowRoute: Hashable, Sendable {
    let result: SearchResult
    let knownDrop: Drop?
}

/// What the show page needs from the network: when the next episode is, and the key art for its Night Sky header.
/// The time is worked out exactly as Upcoming does (TimeResolver with the bundled rules for TV, the Japanese broadcast
/// for anime, plus a followed show's own `offsetMinutes`), so the two screens never disagree, and the art is the
/// same TVmaze key art or AniList banner Upcoming shows. A missing time (nothing scheduled, or a failed request) is
/// nil, and the page then leaves the line out rather than guess.
enum ShowPreview {
    struct Loaded: Sendable {
        let drop: Drop?
        let artwork: ShowArtwork?
    }

    static func load(catalog: Catalog, id: Int, knownDrop: Drop?, client: TVmazeClient, anilist: AniListClient,
                     rules: RulesFile, offsetMinutes: Int = 0, now: Date = .now) async -> Loaded {
        switch catalog {
        case .tvmaze:
            var drop = knownDrop
            if drop == nil, let show = try? await client.show(id: id), let next = show.embedded?.nextepisode {
                let resolution = TimeResolver.resolve(next.listing(show: show), rules: rules,
                                                      offsetMinutes: offsetMinutes, now: now)
                drop = AiringItem(pick: AiringSoon.Pick(show: show, episode: next, resolution: resolution)).drop
            }
            let artwork = (try? await client.images(showID: id)).map(ShowArtwork.init(images:))
            return Loaded(drop: drop, artwork: artwork)
        case .anilist:
            // One request gives both the next broadcast and the banner.
            guard let media = try? await anilist.media(id: id) else { return Loaded(drop: knownDrop, artwork: nil) }
            return Loaded(drop: knownDrop ?? AiringItem(media: media, offsetMinutes: offsetMinutes)?.drop,
                          artwork: ShowArtwork(media: media))
        }
    }
}
