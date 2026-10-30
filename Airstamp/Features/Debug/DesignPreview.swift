#if DEBUG
import SwiftUI

/// The artwork-led screens with real TVmaze artwork and sample times, for Chime's design review before the data
/// layer exists (Day 3). Launch with `-designPreview` (Upcoming) or `-designPreview detail` (Silo's Show detail);
/// add `bottom` to open scrolled to the end.
/// Artwork is fetched at runtime and never stored in the repo (D-37).
struct DesignPreview: View {
    @State private var artwork: [String: ShowArtwork] = [:]
    @State private var path: [Drop] = []
    private let now = Date.now
    private let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos")
    private let anchor: UnitPoint? = ProcessInfo.processInfo.arguments.contains("bottom") ? .bottom : nil

    private let direction = Direction.launched

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

    /// `-designPreview A|B|C` opens that direction (DirectionKit); no letter opens the current artwork-led screens.
    @ViewBuilder private var upcoming: some View {
        let open: (Drop) -> Void = { path.append($0) }
        switch direction {
        case .nightSky:
            NightSkyUpcoming(drops: drops, artwork: artwork, formatter: formatter, scrollAnchor: anchor, onSelect: open)
        case .glass:
            GlassUpcoming(drops: drops, artwork: artwork, formatter: formatter, scrollAnchor: anchor, onSelect: open)
        case .posterColour:
            PosterColourUpcoming(drops: drops, artwork: artwork, formatter: formatter, scrollAnchor: anchor, onSelect: open)
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
        case .glass:
            GlassDetail(drop: drop, artwork: art, episodes: episodes, broadcastZone: zone, formatter: formatter,
                        scrollAnchor: anchor)
        case .posterColour:
            PosterColourDetail(drop: drop, artwork: art, episodes: episodes, broadcastZone: zone, formatter: formatter,
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

    /// Real shows (TVmaze IDs) with sample times relative to now.
    private var drops: [Drop] {
        func drop(_ id: Int, _ name: String, _ season: Int, _ number: Int, in seconds: TimeInterval, _ confidence: Confidence,
                  _ source: ReleaseSource, _ provider: ProviderLabel, airdate: String? = nil, delayedBy: TimeInterval? = nil) -> Drop {
            let date = now.addingTimeInterval(seconds)
            return Drop(id: "tvmaze:\(id):\(season)x\(number)", showID: String(id), showName: name, season: season, number: number,
                        episodeTitle: nil, date: date, airdate: airdate, confidence: confidence, source: source,
                        provider: provider, previousDate: delayedBy.map { date.addingTimeInterval(-$0) })
        }
        let hour: TimeInterval = 3_600, day: TimeInterval = 86_400
        return [
            drop(38052, "Silo", 4, 1, in: 2 * hour + 600, .exact, .broadcast(network: "Apple TV"),
                 ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false)),
            drop(69956, "Frieren: Beyond Journey's End", 2, 8, in: 5 * hour + 1_500, .exact, .anilist,
                 ProviderLabel(name: "Crunchyroll", countryCode: nil, noOfficialStream: false)),
            drop(44778, "House of the Dragon", 3, 4, in: 2 * day + 4 * hour, .exact, .broadcast(network: "HBO"),
                 ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: true)),
            drop(53647, "Wednesday", 3, 1, in: 3 * day + 2 * hour, .estimated, .platformRule("Netflix rule"),
                 ProviderLabel(name: "Netflix", countryCode: nil, noOfficialStream: false), delayedBy: hour),
            drop(46562, "The Last of Us", 3, 1, in: 9 * day, .exact, .broadcast(network: "HBO"),
                 ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: false)),
            drop(44933, "Severance", 3, 1, in: 20 * day, .dateOnly, .dateOnly,
                 ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false), airdate: "2026-11-19"),
        ]
    }
}
#endif
