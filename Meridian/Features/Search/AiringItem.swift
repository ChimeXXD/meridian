import Foundation

/// One cell of Search's airing grid: the show as a search result, and its next episode as a `Drop`, so filters and
/// the cell's "when" line work the same for TV (TVmaze) and anime (AniList).
struct AiringItem: Hashable, Identifiable, Sendable {
    let result: SearchResult
    let drop: Drop
    /// TVmaze weight or AniList popularity: the grid's order, most popular first (D-43).
    let weight: Int

    var id: Int { result.id }

    /// A TVmaze show and its next episode, timed by `TimeResolver` (D3-8).
    init(pick: AiringSoon.Pick) {
        result = SearchResult(show: pick.show)
        weight = pick.show.weight ?? 0
        let episode = pick.episode, show = ShowID(catalog: .tvmaze, id: pick.show.id)
        drop = Drop(id: show.dropID(episode: episode.id), showID: show.description, showName: pick.show.name,
                    season: episode.season, number: episode.number, episodeTitle: nil, date: pick.resolution.date,
                    airdate: pick.resolution.airdate, confidence: pick.resolution.confidence,
                    source: pick.resolution.source, provider: nil, previousDate: nil)
    }

    /// An anime and its next Japanese broadcast; nil when AniList has no next episode.
    init?(media: AniListMedia, offsetMinutes: Int = 0) {
        guard let next = media.nextAiringEpisode else { return nil }
        result = SearchResult(media: media)
        weight = media.popularity ?? 0
        let resolution = TimeResolver.resolveAniList(airingAt: Date(timeIntervalSince1970: TimeInterval(next.airingAt)),
                                                     offsetMinutes: offsetMinutes)
        let show = ShowID(catalog: .anilist, id: media.id)
        drop = Drop(id: show.dropID(episode: next.episode), showID: show.description,
                    showName: media.displayTitle, season: nil, number: next.episode, episodeTitle: nil,
                    date: resolution.date, airdate: resolution.airdate, confidence: resolution.confidence, source: resolution.source,
                    provider: nil, previousDate: nil)
    }

    /// "Out today at 21:00", "Expected Mon at 09:00", "Airs in Japan tomorrow at 01:24" (rule 3, D-40).
    func releaseLine(now: Date, formatter: DropFormatter) -> String {
        ReleaseWording.outLine(drop, now: now, formatter: formatter)
    }
}
