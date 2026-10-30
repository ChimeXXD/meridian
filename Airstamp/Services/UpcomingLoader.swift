import Foundation

/// Turns followed shows into drops: TVmaze's next episode for each, resolved by `TimeResolver` against the rules
/// file, with a provider label for the viewer's country. A show TVmaze can't serve is reported, never dropped
/// silently. AniList shows are added with the AniList client.
struct UpcomingLoader: Sendable {
    struct Request: Hashable, Sendable {
        var catalog: Catalog
        var id: Int
        var name: String
        var offsetMinutes: Int
    }

    struct Result: Equatable, Sendable {
        var drops: [Drop] = []
        /// Followed shows with no next episode listed, in follow order.
        var nothingScheduled: [String] = []
        /// Followed shows that couldn't be loaded this time.
        var failed: [String] = []

        /// Keeps the last known drop for each show that failed this time (offline, a TVmaze hiccup), so Upcoming
        /// doesn't go empty; the show stays in `failed` so the screen can say so. Shows no longer followed don't
        /// come back, because only failed names are carried over.
        func keepingLastKnown(from previous: Result?) -> Result {
            guard let previous, !failed.isEmpty else { return self }
            var merged = self
            merged.drops += previous.drops.filter { failed.contains($0.showName) }
            merged.drops.sort { $0.date < $1.date }
            return merged
        }
    }

    private enum Outcome: Sendable {
        case drop(Drop), nothing(String), failed(String)
    }

    let client: TVmazeClient
    /// Anime come from AniList (D-19); nil leaves followed anime out.
    var anilist: AniListClient? = nil
    let rules: RulesFile
    /// ISO country code, for "No official stream in your country" (CLAUDE.md rule 11).
    let viewerCountry: String?

    func load(_ requests: [Request], now: Date) async -> Result {
        let outcomes = await withTaskGroup(of: (Int, Outcome).self) { group in
            for (index, request) in requests.enumerated() {
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
            case .nothing(let name): result.nothingScheduled.append(name)
            case .failed(let name): result.failed.append(name)
            }
        }
        result.drops.sort { $0.date < $1.date }
        return result
    }

    private func load(_ request: Request, now: Date) async -> Outcome {
        if request.catalog == .anilist { return await loadAnime(request, now: now) }
        guard let show = try? await client.show(id: request.id) else { return .failed(request.name) }
        guard let next = show.embedded?.nextepisode else { return .nothing(show.name) }
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
        guard let anilist, let media = try? await anilist.media(id: request.id) else { return .failed(request.name) }
        guard let next = media.nextAiringEpisode else { return .nothing(media.displayTitle) }
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
