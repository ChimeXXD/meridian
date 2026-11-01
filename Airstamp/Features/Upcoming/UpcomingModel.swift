import Foundation
import Observation

/// Loads Upcoming for the followed shows: drops through `UpcomingLoader`, then each show's artwork (D-37). Refreshes
/// when the app becomes active, when the followed list changes and on pull-to-refresh; it never promises an interval
/// (D-27). Each refresh also hands the widgets a fresh snapshot and their small art (D-05, D4-1).
@MainActor
@Observable
final class UpcomingModel {
    private(set) var result: UpcomingLoader.Result?
    private(set) var artwork: [String: ShowArtwork] = [:]

    private let client: TVmazeClient
    private let anilist: AniListClient
    private let loader: UpcomingLoader
    private let snapshots: WidgetSnapshotWriter
    /// Bumped by each refresh, so a slower, older refresh (a launch and a foreground at once, or a follow change
    /// mid-load) can't overwrite a newer result.
    private var generation = 0

    /// The rules Upcoming resolves times with, shared with Search so both say the same time for an episode.
    var rules: RulesFile { loader.rules }
    init(client: TVmazeClient, anilist: AniListClient, rules: RulesFile, viewerCountry: String?,
         snapshots: WidgetSnapshotWriter = .appGroup) {
        self.client = client
        self.anilist = anilist
        self.snapshots = snapshots
        loader = UpcomingLoader(client: client, anilist: anilist, rules: rules, viewerCountry: viewerCountry)
    }

    func refresh(_ shows: [FollowedShow], now: Date = .now) async {
        let requests = shows.map {
            UpcomingLoader.Request(catalog: $0.catalog, id: $0.catalogID, name: $0.name, offsetMinutes: $0.animeOffsetMinutes)
        }
        generation += 1
        let current = generation
        let loaded = await loader.load(requests, now: now)
        guard current == generation else { return }
        result = loaded.keepingLastKnown(from: result)
        // The widgets get the times at once; their art follows once it's loaded.
        let snapshot = snapshots.write(result?.drops ?? [], now: now)
        let ids = (result?.drops ?? []).map(\.showID) + (result?.nothingScheduled ?? []).map(\.showID)
        let missing = Set(ids).filter { artwork[$0] == nil }
        await withTaskGroup(of: (String, ShowArtwork?).self) { group in
            for id in missing {
                let key = Drop.key(showID: id)
                group.addTask { [client, anilist] in
                    switch key.catalog {
                    case .tvmaze: (id, try? ShowArtwork(images: await client.images(showID: key.id)))
                    case .anilist: (id, try? await anilist.media(id: key.id).map(ShowArtwork.init(media:)))
                    }
                }
            }
            for await (id, art) in group {
                if let art { artwork[id] = art }
            }
        }
        // A newer refresh writes its own art; this one mustn't delete what that one needs.
        guard current == generation, let snapshot else { return }
        await snapshots.saveArt(for: snapshot, artwork: artwork)
    }

    /// The last three aired episodes, newest first, for Show detail.
    func pastEpisodes(showID: String, now: Date = .now) async -> [PastEpisode] {
        // TVmaze shows only: AniList has no episode list in this query ("anilist:<id>" isn't an Int).
        guard let id = Int(showID), let episodes = try? await client.episodes(showID: id) else { return [] }
        let today = DropFormatter(timeZone: .gmt).localDay(now)
        // Numbered episodes only, before taking three, so specials don't use up the slots.
        let aired = episodes.compactMap { episode -> PastEpisode? in
            guard let airdate = episode.airdate, let number = episode.number, Self.hasAired(episode, today: today, now: now)
            else { return nil }
            let label = episode.season.map { "S\($0)E\(number)" } ?? "E\(number)"
            return PastEpisode(label: label, title: episode.name ?? label, airdate: airdate)
        }
        return Array(aired.suffix(3).reversed())
    }

    /// An empty airtime means TVmaze's airstamp is a fake noon placeholder (CLAUDE.md rule 2, D-25), so only the
    /// listed date counts, and only once that day is over.
    private static func hasAired(_ episode: TVmazeEpisode, today: String, now: Date) -> Bool {
        if let airtime = episode.airtime, !airtime.isEmpty,
           let stamp = episode.airstamp.flatMap(TVmazeEpisode.parseAirstamp) {
            return stamp <= now
        }
        return episode.airdate.map { $0 < today } ?? false
    }
}
