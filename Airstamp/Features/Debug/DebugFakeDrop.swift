#if DEBUG
import Foundation

/// The Debug menu's fake drop (D-11, SPEC §7): a clearly fake "Debug Show" episode that Upcoming adds to its result
/// on every refresh, so it reaches Upcoming and the widgets' snapshot like a followed show's drop. Most of Chime's real
/// shows have nothing upcoming, so this is how a countdown, "Out now" and a Live Activity get tested.
///
/// It lives in memory only: a relaunch forgets it (the next refresh then drops it from the snapshot), and the unit
/// tests, which run inside the app, never see one left over from a debugging session.
@MainActor
enum DebugFakeDrop {
    /// Not a TVmaze or AniList ID, so nothing confuses it with a followed show.
    static let showID = "debug"

    static private(set) var current: Drop?

    /// Sets the fake drop `minutes` from `now`, replacing any earlier one, and returns it.
    @discardableResult
    static func set(minutes: Double, now: Date = .now) -> Drop {
        let date = now.addingTimeInterval(minutes * 60)
        let drop = Drop(id: "debug:fake:\(Int(date.timeIntervalSince1970))", showID: showID, showName: "Debug Show",
                        season: 1, number: 1, episodeTitle: "Fake episode", date: date, airdate: nil,
                        confidence: .exact, source: .broadcast(network: "Debug TV"),
                        provider: ProviderLabel(name: "Debug TV", countryCode: nil, noOfficialStream: false),
                        previousDate: nil)
        current = drop
        return drop
    }

    static func clear() { current = nil }

    /// Moves the fake drop later, keeping its old time as `previousDate` ("Simulate delay +1 h").
    static func delay(by interval: TimeInterval) {
        guard var drop = current else { return }
        drop.previousDate = drop.previousDate ?? drop.date
        drop.date = drop.date.addingTimeInterval(interval)
        current = drop
    }

    /// `result` with the fake drop in date order, replacing any earlier fake one; unchanged when there's none.
    static func adding(to result: UpcomingLoader.Result?) -> UpcomingLoader.Result? {
        guard let current else { return result }
        var merged = result ?? UpcomingLoader.Result()
        merged.drops.removeAll { $0.showID == showID }
        merged.drops.append(current)
        merged.drops.sort { ($0.date, $0.id) < ($1.date, $1.id) }
        return merged
    }
}
#endif
