import Foundation

/// Turns followed shows into drops: TVmaze's next episode for each, resolved by `TimeResolver` against the rules
/// file, with a provider label for the viewer's country. A show TVmaze can't serve is reported, never dropped
/// silently. Followed anime come from AniList's next airing episode.
struct UpcomingLoader: Sendable {
    struct Request: Hashable, Sendable {
        var catalog: Catalog
        var id: Int
        var name: String
        var offsetMinutes: Int

        /// Same form as `Drop.showID` and `QuietShow.showID`: "38052" or "anilist:154587".
        var showID: String { catalog == .anilist ? "anilist:\(id)" : String(id) }
    }

    /// A followed show with no next episode, shared with the widgets through the snapshot.
    typealias Quiet = QuietShow

    struct Result: Equatable, Sendable {
        var drops: [Drop] = []
        /// Followed shows with no next episode listed, in follow order.
        var nothingScheduled: [Quiet] = []
        /// Followed shows that couldn't be loaded this time.
        var failed: [String] = []

        /// Keeps the last known drop for each show that failed this time (offline, a TVmaze hiccup), so Upcoming
        /// doesn't go empty; the show stays in `failed` so the screen can say so. Shows no longer followed don't
        /// come back, because only failed names are carried over. A kept show with nothing scheduled goes back to its
        /// place in `followOrder` (followed show IDs, which survive a rename), so the widgets' rows don't reshuffle when a load fails.
        func keepingLastKnown(from previous: Result?, followOrder: [String] = []) -> Result {
            guard let previous, !failed.isEmpty else { return self }
            var merged = self
            merged.drops += previous.drops.filter { failed.contains($0.showName) }
            merged.nothingScheduled += previous.nothingScheduled.filter { failed.contains($0.name) }
            merged.drops.sort { $0.date < $1.date }
            let place = Dictionary(followOrder.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
            merged.nothingScheduled.sort { (place[$0.showID] ?? .max) < (place[$1.showID] ?? .max) }
            return merged
        }
    }

    private enum Outcome: Sendable {
        case drop(Drop), nothing(Quiet), failed(String)
    }

    /// How old a cached next episode may be when Upcoming refreshes: 15 minutes, so a delay shows soon after it's
    /// announced and "Updated 14:05" is true to within it (D-59). Search and artwork keep the 6-hour cache.
    static let freshness: TimeInterval = 15 * 60

    let client: TVmazeClient
    /// Anime come from AniList (D-19); nil leaves followed anime out.
    var anilist: AniListClient? = nil
    let rules: RulesFile
    /// ISO country code, for "No official stream in your country" (CLAUDE.md rule 11).
    let viewerCountry: String?

    func load(_ requests: [Request], now: Date) async -> Result {
        let outcomes = await withTaskGroup(of: (Int, Outcome).self) { group in
            for (index, request) in requests.enumerated() where request.catalog == .tvmaze || anilist != nil {
                group.addTask { (index, await load(request, now: now)) }
            }
            var collected: [(Int, Outcome)] = []
            for await outcome in group { collected.append(outcome) }
            return collected.sorted { $0.0 < $1.0 }.map(\.1)
        }
        var result = Result()
        for outcome in outcomes {
            switch outcome {
            case .drop(let drop): result.drops.append(drop)
            case .nothing(let quiet): result.nothingScheduled.append(quiet)
            case .failed(let name): result.failed.append(name)
            }
        }
        result.drops.sort { $0.date < $1.date }
        return result
    }

    private func load(_ request: Request, now: Date) async -> Outcome {
        if request.catalog == .anilist { return await loadAnime(request, now: now) }
        guard let show = try? await client.show(id: request.id, maxAge: Self.freshness)
        else { return .failed(request.name) }
        guard let next = show.embedded?.nextepisode else {
            return .nothing(Quiet(showID: String(show.id), name: show.name, status: show.status,
                                  lastAired: show.embedded?.previousepisode?.airdate))
        }
        let resolution = TimeResolver.resolve(next.listing(show: show), rules: rules, offsetMinutes: request.offsetMinutes,
                                              now: now)
        let channel = show.network ?? show.webChannel
        let provider = channel.map {
            ProviderLabel(name: $0.name, countryCode: show.network?.country?.code, viewerCountry: viewerCountry, rules: rules)
        }
        return .drop(Drop(id: "tvmaze:\(show.id):\(next.id)", showID: String(show.id), showName: show.name,
                          season: next.season, number: next.number, episodeTitle: next.name, date: resolution.date,
                          airdate: resolution.airdate, confidence: resolution.confidence, source: resolution.source,
                          provider: provider, previousDate: nil, broadcastZone: show.network?.country?.timezone))
    }

    /// An anime's next episode is its Japanese broadcast (AniList `airingAt`), shifted by the show's offset.
    private func loadAnime(_ request: Request, now: Date) async -> Outcome {
        guard let anilist, let media = try? await anilist.media(id: request.id, maxAge: Self.freshness)
        else { return .failed(request.name) }
        guard let next = media.nextAiringEpisode else {
            return .nothing(Quiet(showID: "anilist:\(media.id)", name: media.displayTitle, status: media.status,
                                  lastAired: nil))
        }
        let resolution = TimeResolver.resolveAniList(airingAt: Date(timeIntervalSince1970: TimeInterval(next.airingAt)),
                                                     offsetMinutes: request.offsetMinutes)
        let provider = media.streamingSite.map {
            ProviderLabel(name: $0, countryCode: nil, viewerCountry: viewerCountry, rules: rules)
        }
        return .drop(Drop(id: "anilist:\(media.id):\(next.episode)", showID: "anilist:\(media.id)",
                          showName: media.displayTitle, season: nil, number: next.episode, episodeTitle: nil,
                          date: resolution.date, airdate: resolution.airdate, confidence: resolution.confidence,
                          source: resolution.source, provider: provider, previousDate: nil))
    }
}
