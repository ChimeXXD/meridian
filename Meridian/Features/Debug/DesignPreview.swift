#if DEBUG
import SwiftUI

/// The real Night Sky screens (D-38) with live TVmaze artwork and sample times, for screenshots and design review.
/// Launch with `-designPreview` (Upcoming) or `-designPreview detail` (the first show's detail, Silo by default); add
/// `bottom` to open scrolled to the end, and a timed show's TVmaze ID (`44778`) to give it the soonest sample time, so
/// it becomes the hero. Severance is date-only and can't be featured.
/// Artwork is fetched at runtime and never stored in the repo (D-37).
struct DesignPreview: View {
    @State private var artwork: [String: ShowArtwork] = [:]
    @State private var path: [Drop] = []
    @State private var liveActivity = true
    /// Built once: `body`, `onAppear` and `loadArtwork` all read it.
    private let drops: [Drop]
    private let formatter = DropFormatter(zoneIdentifier: "Africa/Lagos")
    private let anchor: UnitPoint? = ProcessInfo.processInfo.arguments.contains("bottom") ? .bottom : nil
    private static let offline = ProcessInfo.processInfo.arguments.contains("offline")

    /// Today at `hour:minute` in Lagos, the zone the preview formats in, so the "Updated" time reads the same on any Mac.
    private static func lagosToday(hour: Int, minute: Int) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Lagos") ?? .gmt
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: .now)
    }

    init() {
        drops = Self.sampleDrops(now: .now, featuredID: ProcessInfo.processInfo.arguments.first { Int($0) != nil })
    }

    var body: some View {
        NavigationStack(path: $path) {
            // `offline`: two shows didn't refresh and the times are from 14:05, for Upcoming's "Updated" line (D6-2).
            UpcomingView(result: UpcomingLoader.Result(drops: drops, failed: Self.offline ? ["Silo", "Frieren"] : []),
                         artwork: artwork, hasShows: true,
                         lastUpdated: Self.offline ? Self.lagosToday(hour: 14, minute: 5) : nil,
                         formatter: formatter, scrollAnchor: anchor) { path.append($0) }
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(for: Drop.self) { drop in
                    ShowDetailView(drop: drop, artwork: artwork[drop.showID],
                                   episodes: drop.showID == "38052" ? Self.siloEpisodes : [], liveActivity: $liveActivity,
                                   formatter: formatter, scrollAnchor: anchor)
                }
        }
        .task { await loadArtwork() }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("detail") { path = [drops[0]] }
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
    static let siloEpisodes: [PastEpisode] = [
        .init(label: "S3E10", title: "Troy", airdate: "2026-09-04"),
        .init(label: "S3E9", title: "Farewell", airdate: "2026-08-28"),
        .init(label: "S3E8", title: "Gray Goo", airdate: "2026-08-21"),
    ]

    /// Real shows (TVmaze IDs) with sample times relative to now. The featured show, if any, takes the first slot.
    private static func sampleDrops(now: Date, featuredID: String?) -> [Drop] {
        typealias Sample = (id: Int, name: String, season: Int, number: Int, confidence: Confidence, source: ReleaseSource,
                            provider: ProviderLabel, delayed: Bool)
        var timed: [Sample] = [
            // Apple TV is a streamer: TVmaze lists no air time (recorded fixture), so the platform rule sets it.
            (38052, "Silo", 4, 1, .estimated, .platformRule("Apple TV rule"),
             ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false), false),
            (69956, "Frieren: Beyond Journey's End", 2, 8, .exact, .anilist,
             ProviderLabel(name: "Crunchyroll", countryCode: nil, noOfficialStream: false), false),
            // A published time that moved later, so it says "Delayed from" (D-58); an estimate never does.
            (44778, "House of the Dragon", 3, 4, .exact, .broadcast(network: "HBO"),
             ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: false), true),
            (53647, "Wednesday", 3, 1, .estimated, .platformRule("Netflix rule"),
             ProviderLabel(name: "Netflix", countryCode: nil, noOfficialStream: false), false),
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
                        previousDate: show.delayed ? date.addingTimeInterval(-hour) : nil,
                        broadcastZone: show.provider.name == "HBO" ? "America/New_York" : nil)
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
