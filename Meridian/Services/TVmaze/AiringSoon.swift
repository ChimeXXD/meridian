import Foundation

/// Search's suggestions before you type (Chime: the app felt empty): shows with episodes in the next few days, from
/// TVmaze's streaming and US schedules. Drama and animation in English, plus Japanese anime; never news or talk shows.
/// Most popular first, by TVmaze's weight (D-43). Each show keeps its next episode with the time `TimeResolver` gives
/// it, so filters can ask "today?", "a new season?" or "exact?" without trusting a placeholder airstamp (D-25).
enum AiringSoon {
    /// How many shows the grid holds, applied after any filter.
    static let limit = 15
    /// Today and the next two days: enough to fill the list, within TVmaze's rate limit (8 calls with yesterday's,
    /// cached for 6 h).
    static let days = 3

    /// A show in the grid and its soonest episode still to come.
    struct Pick: Hashable, Sendable {
        let show: TVmazeShow
        let episode: TVmazeEpisode
        let resolution: Resolution
    }

    /// Every qualifying show, most popular first, with its soonest episode still to come. An episode is still to come
    /// when its resolved time is after `now`; a date-only one stays through its airdate in `formatter`'s zone. Either
    /// way it must fall on the viewer's today or the next `days - 1` days, so a US Monday evening that lands on the
    /// viewer's Tuesday is left out.
    static func pool(from items: [TVmazeScheduleItem], rules: RulesFile, now: Date,
                     formatter: DropFormatter = DropFormatter()) -> [Pick] {
        let today = formatter.localDay(now)
        let lastDay = formatter.localDay(now, addingDays: days - 1)
        var soonest: [Int: Pick] = [:]
        for item in items {
            guard let show = item.show, qualifies(show) else { continue }
            let resolution = TimeResolver.resolve(item.episode.listing(show: show), rules: rules, now: now)
            let upcoming = resolution.confidence == .dateOnly
                ? (today...lastDay).contains(resolution.airdate ?? "")
                : resolution.date > now && formatter.localDay(resolution.date) <= lastDay
            guard upcoming else { continue }
            let pick = Pick(show: show, episode: item.episode, resolution: resolution)
            if let current = soonest[show.id], !isSooner(pick, than: current) { continue }
            soonest[show.id] = pick
        }
        return soonest.values.sorted { ($0.show.weight ?? 0, $1.show.name) > ($1.show.weight ?? 0, $0.show.name) }
    }

    /// Loads the schedules for the coming days (in the viewer's zone) at once and picks from them. Calls that fail are
    /// skipped. Returns nil when the task was cancelled, so a half-loaded list is never kept, or when every call failed
    /// (offline), so the caller can say the schedule is missing rather than show an empty week.
    static func load(client: TVmazeClient, rules: RulesFile, now: Date = .now,
                     formatter: DropFormatter = DropFormatter()) async -> [Pick]? {
        // From yesterday: TVmaze dates an episode in its own country, so east of the US a Friday 21:00 ET episode
        // lands on the viewer's Saturday (D-17). Its listing is under the viewer's yesterday.
        let dates = (-1..<days).map { formatter.localDay(now, addingDays: $0) }
        // Indexed so the merged order (and so the weight tie-break) doesn't depend on which call answers first.
        // Two calls per day: the streaming schedule (even index) and the US broadcast schedule (odd index).
        let calls = dates.flatMap { [($0, true), ($0, false)] }
        let parts = await withTaskGroup(of: (Int, [TVmazeScheduleItem]?).self) { group in
            for (index, call) in calls.enumerated() {
                group.addTask {
                    let items = call.1 ? try? await client.webSchedule(date: call.0)
                                       : try? await client.schedule(country: "US", date: call.0)
                    return (index, items)
                }
            }
            var parts = [[TVmazeScheduleItem]?](repeating: nil, count: calls.count)
            for await (index, items) in group { parts[index] = items }
            return parts
        }
        guard !Task.isCancelled, parts.contains(where: { $0 != nil }) else { return nil }
        return pool(from: parts.compactMap(\.self).flatMap(\.self), rules: rules, now: now, formatter: formatter)
    }

    private static func qualifies(_ show: TVmazeShow) -> Bool {
        guard let type = show.type else { return false }
        return (type == "Scripted" || type == "Animation")
            && (show.language == "English" || (show.language == "Japanese" && type == "Animation"))
    }

    /// Earlier release first; a season dropped at once keeps its lowest season and episode. A special (no season or
    /// number) sorts after numbered episodes, so it never displaces episode 1 of a new season.
    private static func isSooner(_ a: Pick, than b: Pick) -> Bool {
        (a.resolution.date, a.episode.season ?? .max, a.episode.number ?? .max)
            < (b.resolution.date, b.episode.season ?? .max, b.episode.number ?? .max)
    }
}
