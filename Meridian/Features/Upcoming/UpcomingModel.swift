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
    /// The last refresh that reached every followed show, kept across launches for Upcoming's "Updated 14:05" (D6-2).
    private(set) var lastUpdated: Date?

    private let client: TVmazeClient
    private let anilist: AniListClient
    private var loader: UpcomingLoader
    /// Fetches the rules file from GitHub at most once a day (D-34); nil keeps the bundled rules.
    private let rulesStore: RulesStore?
    private let snapshots: WidgetSnapshotWriter
    /// Bumped by each refresh, so a slower, older refresh (a launch and a foreground at once, or a follow change
    /// mid-load) can't overwrite a newer result.
    private var generation = 0
    private let defaults: UserDefaults
    static let lastUpdatedKey = "lastUpdated"

    /// The rules Upcoming resolves times with, shared with Search so both say the same time for an episode.
    var rules: RulesFile { loader.rules }
    init(client: TVmazeClient, anilist: AniListClient, rules: RulesFile, viewerCountry: String?,
         snapshots: WidgetSnapshotWriter = .appGroup, defaults: UserDefaults = .standard,
         rulesStore: RulesStore? = nil) {
        self.rulesStore = rulesStore
        self.defaults = defaults
        lastUpdated = defaults.object(forKey: Self.lastUpdatedKey) as? Date
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
        // The newest valid rules first, so a fixed time reaches the phone without an app update.
        if let rulesStore {
            let latest = await rulesStore.current()
            if latest != loader.rules {
                loader = UpcomingLoader(client: loader.client, anilist: loader.anilist, rules: latest,
                                        viewerCountry: loader.viewerCountry)
            }
        }
        var loaded = await loader.load(requests, now: now)
        guard current == generation else { return }
        // An empty follow list reached nothing, so it doesn't count as an update.
        if loaded.failed.isEmpty, !requests.isEmpty {
            lastUpdated = now
            defaults.set(now, forKey: Self.lastUpdatedKey)
        }
        // On a cold launch the last snapshot is the last known result, so an offline start doesn't empty the widgets
        // (and delete their art) for shows that merely failed to load.
        let previous = result ?? snapshots.lastWritten().map {
            UpcomingLoader.Result(drops: $0.drops, nothingScheduled: $0.nothingScheduled)
        }
        // A published time that moved later keeps its first listed time, for "Delayed from 21:00" (D-58).
        loaded.drops = DelayDetection.carry(from: previous?.drops ?? [], into: loaded.drops)
        result = loaded.keepingLastKnown(from: previous, followOrder: requests.map(\.showID))
        #if DEBUG
        // Debug → "Fake drop in N minutes" (SPEC §7): the fake show goes to Upcoming and the widgets like a real one.
        result = DebugFakeDrop.adding(to: result)
        #endif
        // The widgets get the times at once; their art follows once it's loaded.
        let snapshot = snapshots.write(result?.drops ?? [], nothingScheduled: result?.nothingScheduled ?? [], now: now)
        let ids = (result?.drops ?? []).map(\.showID) + (result?.nothingScheduled ?? []).map(\.showID)
        var missing = Set(ids).filter { artwork[$0] == nil }
        #if DEBUG
        // The fake show has no art; "debug" would ask TVmaze for show 0 on every refresh.
        missing.remove(DebugFakeDrop.showID)
        #endif
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
