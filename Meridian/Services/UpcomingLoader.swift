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

        var show: ShowID { ShowID(catalog: catalog, id: id) }

        /// Same form as `Drop.showID` and `QuietShow.showID`: "38052" or "anilist:154587".
        var showID: String { show.description }
    }

    /// A followed show with no next episode, shared with the widgets through the snapshot.
    typealias Quiet = QuietShow

    struct Result: Equatable, Sendable {
        var drops: [Drop] = []
        /// Followed shows with no next episode listed, in follow order.
        var nothingScheduled: [Quiet] = []
        /// The names of followed shows that couldn't be loaded this time, for Upcoming's status line.
        var failed: [String] = []
        /// The same shows by ID ("38052", "anilist:154587"), which is what their last known drops are matched on:
        /// two followed shows can share a name (The Office US and UK).
        var failedShowIDs: [String] = []

        /// Keeps the last known drop for each show that failed this time (offline, a TVmaze hiccup), so Upcoming
        /// doesn't go empty; the show stays in `failed` so the screen can say so. Shows no longer followed don't
        /// come back, because only failed show IDs are carried over. A kept show with nothing scheduled goes back to its
        /// place in `followOrder` (followed show IDs, which survive a rename), so the widgets' rows don't reshuffle when a load fails.
        func keepingLastKnown(from previous: Result?, followOrder: [String] = []) -> Result {
            let failedIDs = Set(failedShowIDs)
            guard let previous, !failedIDs.isEmpty else { return self }
            var merged = self
            merged.drops += previous.drops.filter { failedIDs.contains($0.showID) }
            merged.nothingScheduled += previous.nothingScheduled.filter { failedIDs.contains($0.showID) }
            merged.drops.sort { $0.date < $1.date }
            let place = Dictionary(followOrder.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
            merged.nothingScheduled.sort { (place[$0.showID] ?? .max) < (place[$1.showID] ?? .max) }
            return merged
        }
    }

    private enum Outcome: Sendable {
        case drop(Drop), nothing(Quiet), failed(Request)
    }

    /// How old a cached next episode may be when Upcoming refreshes: 15 minutes, so a delay shows soon after it's
    /// announced and "Updated 14:05" is true to within it (D-59). Search and artwork keep the 6-hour cache.
    static let freshness: TimeInterval = 15 * 60
    /// Shows asked for at once. TVmaze allows about 20 calls per 10 seconds, and a long follow list fired all at once
    /// would spend that on the first refresh; Upcoming's artwork follows the same limit.
    static let maxInFlight = 6

    let client: TVmazeClient
    /// Anime come from AniList (D-19); nil leaves followed anime out.
    var anilist: AniListClient? = nil
    let rules: RulesFile
    /// ISO country code, for "No official stream in your country" (CLAUDE.md rule 11).
    let viewerCountry: String?

    func load(_ requests: [Request], now: Date) async -> Result {
        let outcomes = await withTaskGroup(of: (Int, Outcome).self) { group in
            var waiting = requests.enumerated().filter { $0.element.catalog == .tvmaze || anilist != nil }.makeIterator()
            // At most `maxInFlight` at once: each finished show starts the next.
            func startNext() -> Bool {
                guard let (index, request) = waiting.next() else { return false }
                group.addTask { (index, await load(request, now: now)) }
                return true
            }
            for _ in 0..<Self.maxInFlight { guard startNext() else { break } }
            var collected: [(Int, Outcome)] = []
            for await outcome in group {
                collected.append(outcome)
                _ = startNext()
            }
            return collected.sorted { $0.0 < $1.0 }.map(\.1)
        }
        var result = Result()
        for outcome in outcomes {
            switch outcome {
            case .drop(let drop): result.drops.append(drop)
            case .nothing(let quiet): result.nothingScheduled.append(quiet)
            case .failed(let request):
                result.failed.append(request.name)
                result.failedShowIDs.append(request.showID)
            }
        }
        result.drops.sort { $0.date < $1.date }
        return result
    }

    private func load(_ request: Request, now: Date) async -> Outcome {
        if request.catalog == .anilist { return await loadAnime(request, now: now) }
        guard let show = try? await client.show(id: request.id, maxAge: Self.freshness)
        else { return .failed(request) }
        let id = ShowID(catalog: .tvmaze, id: show.id)
        guard let next = show.embedded?.nextepisode else {
            return .nothing(Quiet(showID: id.description, name: show.name, status: show.status,
                                  lastAired: show.embedded?.previousepisode?.airdate))
        }
        let resolution = TimeResolver.resolve(next.listing(show: show), rules: rules, offsetMinutes: request.offsetMinutes,
                                              now: now)
        let channel = show.network ?? show.webChannel
        let provider = channel.map {
            ProviderLabel(name: $0.name, countryCode: show.network?.country?.code, viewerCountry: viewerCountry, rules: rules)
        }
        return .drop(Drop(id: id.dropID(episode: next.id), showID: id.description, showName: show.name,
                          season: next.season, number: next.number, episodeTitle: next.name, date: resolution.date,
                          airdate: resolution.airdate, confidence: resolution.confidence, source: resolution.source,
                          provider: provider, previousDate: nil, broadcastZone: show.network?.country?.timezone))
    }

    /// An anime's next episode is its Japanese broadcast (AniList `airingAt`), shifted by the show's offset.
    private func loadAnime(_ request: Request, now: Date) async -> Outcome {
        guard let anilist, let media = try? await anilist.media(id: request.id, maxAge: Self.freshness)
        else { return .failed(request) }
        let id = ShowID(catalog: .anilist, id: media.id)
        guard let next = media.nextAiringEpisode else {
            return .nothing(Quiet(showID: id.description, name: media.displayTitle, status: media.status,
                                  lastAired: nil))
        }
        let resolution = TimeResolver.resolveAniList(airingAt: Date(timeIntervalSince1970: TimeInterval(next.airingAt)),
                                                     offsetMinutes: request.offsetMinutes)
        let provider = media.streamingSite.map {
            ProviderLabel(name: $0, countryCode: nil, viewerCountry: viewerCountry, rules: rules)
        }
        return .drop(Drop(id: id.dropID(episode: next.episode), showID: id.description,
                          showName: media.displayTitle, season: nil, number: next.episode, episodeTitle: nil,
                          date: resolution.date, airdate: resolution.airdate, confidence: resolution.confidence,
                          source: resolution.source, provider: provider, previousDate: nil))
    }
}
