#if DEBUG
import SwiftUI

/// The artwork-led screens with real TVmaze artwork and sample times, for Chime's design review before the data
/// layer exists (Day 3). Launch with `-designPreview` (Upcoming) or `-designPreview detail` (the first show's detail,
/// Silo by default); add `bottom` to open scrolled to the end. `-designPreview A` opens Night Sky (DirectionKit); add a
/// timed show's TVmaze ID (`-designPreview A 44778`) to give it the soonest sample time, so it becomes the hero.
/// Severance is date-only and can't be featured.
/// Artwork is fetched at runtime and never stored in the repo (D-37).
struct DesignPreview: View {
    @State private var artwork: [String: ShowArtwork] = [:]
    @State private var path: [Drop] = []
    /// Built once: `body`, `onAppear` and `loadArtwork` all read it.
    private let drops: [Drop]
    private let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos")
    private let anchor: UnitPoint? = ProcessInfo.processInfo.arguments.contains("bottom") ? .bottom : nil

    private let direction = Direction.launched

    init() {
        drops = Self.sampleDrops(now: .now, featuredID: ProcessInfo.processInfo.arguments.first { Int($0) != nil })
    }

    var body: some View {
        NavigationStack(path: $path) {
            upcoming
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(for: Drop.self) { detail(for: $0) }
        }
        .task { await loadArtwork() }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("detail") { path = [drops[0]] }
        }
    }

    /// `-designPreview A` opens Night Sky; no letter opens the earlier artwork-led screens.
    @ViewBuilder private var upcoming: some View {
        let open: (Drop) -> Void = { path.append($0) }
        switch direction {
        case .nightSky:
            NightSkyUpcoming(drops: drops, artwork: artwork, formatter: formatter, scrollAnchor: anchor, onSelect: open)
        case nil:
            UpcomingArtView(drops: drops, artwork: artwork, formatter: formatter, scrollAnchor: anchor, onSelect: open)
        }
    }

    @ViewBuilder private func detail(for drop: Drop) -> some View {
        let art = artwork[drop.showID]
        let episodes = drop.showID == "38052" ? Self.siloEpisodes : []
        let zone = "America/New_York"
        switch direction {
        case .nightSky:
            NightSkyDetail(drop: drop, artwork: art, episodes: episodes, broadcastZone: zone, formatter: formatter,
                           scrollAnchor: anchor)
        case nil:
            ShowDetailArtView(drop: drop, artwork: art, episodes: episodes, broadcastZone: zone, formatter: formatter,
                              scrollAnchor: anchor)
        }
    }

    private func loadArtwork() async {
        let client = TVmazeClient()
        await withTaskGroup(of: (String, ShowArtwork?).self) { group in
            for id in Set(drops.map(\.showID)) {
                group.addTask { (id, try? ShowArtwork(images: await client.images(showID: Int(id) ?? 0))) }
            }
            for await (id, art) in group {
                if let art { artwork[id] = art }
            }
        }
    }

    /// Silo S3's last three episodes, from the recorded TVmaze fixture.
    static let siloEpisodes: [ShowDetailArtView.PastEpisode] = [
        .init(label: "S3E10", title: "Troy", airdate: "2026-09-04"),
        .init(label: "S3E9", title: "Farewell", airdate: "2026-08-28"),
        .init(label: "S3E8", title: "Gray Goo", airdate: "2026-08-21"),
    ]

    /// Real shows (TVmaze IDs) with sample times relative to now. The featured show, if any, takes the first slot.
    private static func sampleDrops(now: Date, featuredID: String?) -> [Drop] {
        typealias Sample = (id: Int, name: String, season: Int, number: Int, confidence: Confidence, source: ReleaseSource,
                            provider: ProviderLabel, delayed: Bool)
        var timed: [Sample] = [
            (38052, "Silo", 4, 1, .exact, .broadcast(network: "Apple TV"),
             ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false), false),
            (69956, "Frieren: Beyond Journey's End", 2, 8, .exact, .anilist,
             ProviderLabel(name: "Crunchyroll", countryCode: nil, noOfficialStream: false), false),
            (44778, "House of the Dragon", 3, 4, .exact, .broadcast(network: "HBO"),
             ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: true), false),
            (53647, "Wednesday", 3, 1, .estimated, .platformRule("Netflix rule"),
             ProviderLabel(name: "Netflix", countryCode: nil, noOfficialStream: false), true),
            (46562, "The Last of Us", 3, 1, .exact, .broadcast(network: "HBO"),
             ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: false), false),
        ]
        if let featuredID, let index = timed.firstIndex(where: { String($0.id) == featuredID }) {
            timed.insert(timed.remove(at: index), at: 0)
        }
        let hour: TimeInterval = 3_600, day: TimeInterval = 86_400
        let slots = [2 * hour + 600, 5 * hour + 1_500, 2 * day + 4 * hour, 3 * day + 2 * hour, 9 * day]
        assert(slots.count == timed.count, "every timed show needs a slot, or zip drops it")
        let drops = zip(timed, slots).map { show, seconds in
            let date = now.addingTimeInterval(seconds)
            return Drop(id: "tvmaze:\(show.id):\(show.season)x\(show.number)", showID: String(show.id), showName: show.name,
                        season: show.season, number: show.number, episodeTitle: nil, date: date, airdate: nil,
                        confidence: show.confidence, source: show.source, provider: show.provider,
                        previousDate: show.delayed ? date.addingTimeInterval(-hour) : nil)
        }
        let severance = Drop(id: "tvmaze:44933:3x1", showID: "44933", showName: "Severance", season: 3, number: 1,
                             episodeTitle: nil, date: now.addingTimeInterval(20 * day), airdate: "2026-11-19",
                             confidence: .dateOnly, source: .dateOnly,
                             provider: ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false),
                             previousDate: nil)
        return drops + [severance]
    }
}
#endif
