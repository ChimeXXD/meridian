import Foundation

/// Search's suggestions before you type (Chime: the app felt empty): shows with episodes in the next few days, from
/// TVmaze's streaming and US schedules. Drama and animation in English, plus Japanese anime; never news or talk shows.
/// Most popular first, by TVmaze's weight.
enum AiringSoon {
    static let limit = 15
    /// Today and the next two days: enough to fill the list, within TVmaze's rate limit (6 calls, cached for 6 h).
    static let days = 3

    static func shows(from items: [TVmazeScheduleItem]) -> [TVmazeShow] {
        var seen = Set<Int>()
        let shows = items.compactMap(\.show).filter { show in
            guard seen.insert(show.id).inserted, let type = show.type else { return false }
            return (type == "Scripted" || type == "Animation")
                && (show.language == "English" || (show.language == "Japanese" && type == "Animation"))
        }
        return Array(shows.sorted { ($0.weight ?? 0, $1.name) > ($1.weight ?? 0, $0.name) }.prefix(limit))
    }

    /// Loads the schedules for the coming days (in the viewer's zone) at once and picks from them. Calls that fail are
    /// skipped. Returns nil when the task was cancelled, so a half-loaded list is never kept.
    static func load(client: TVmazeClient, now: Date = .now) async -> [TVmazeShow]? {
        let formatter = DropFormatter()
        let dates = (0..<days).map { formatter.localDay(now.addingTimeInterval(Double($0) * 86_400)) }
        // Indexed so the merged order (and so the weight tie-break) doesn't depend on which call answers first.
        // Two calls per day: the streaming schedule (even index) and the US broadcast schedule (odd index).
        let calls = dates.flatMap { [($0, true), ($0, false)] }
        let parts = await withTaskGroup(of: (Int, [TVmazeScheduleItem]).self) { group in
            for (index, call) in calls.enumerated() {
                group.addTask {
                    let items = call.1 ? try? await client.webSchedule(date: call.0)
                                       : try? await client.schedule(country: "US", date: call.0)
                    return (index, items ?? [])
                }
            }
            var parts = [[TVmazeScheduleItem]](repeating: [], count: calls.count)
            for await (index, items) in group { parts[index] = items }
            return parts
        }
        guard !Task.isCancelled else { return nil }
        // "Airing in the next few days" promises what's coming, so episodes already out today don't count.
        let upcoming = parts.flatMap(\.self).filter { item in
            item.airstamp.flatMap(TVmazeEpisode.parseAirstamp).map { $0 > now } ?? false
        }
        return shows(from: upcoming)
    }
}
