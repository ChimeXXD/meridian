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

    /// Every fake drop's ID starts with this, the copies of real drops too.
    static let idPrefix = "debug:fake:"

    static private(set) var current: Drop?

    static func isFake(_ drop: Drop) -> Bool { drop.id.hasPrefix(idPrefix) }

    /// Sets the fake drop `minutes` from `now`, replacing any earlier one, and returns it.
    @discardableResult
    static func set(minutes: Double, now: Date = .now) -> Drop {
        let date = now.addingTimeInterval(minutes * 60)
        let drop = Drop(id: "\(idPrefix)\(Int(date.timeIntervalSince1970))", showID: showID, showName: "Debug Show",
                        season: 1, number: 1, episodeTitle: "Fake episode", date: date, airdate: nil,
                        confidence: .exact, source: .broadcast(network: "Debug TV"),
                        provider: ProviderLabel(name: "Debug TV", countryCode: nil, noOfficialStream: false),
                        previousDate: nil)
        current = drop
        return drop
    }

    /// A fake copy of a real drop, `minutes` from `now`: its show, episode, network and art, for a release-night
    /// Live Activity that looks like the real thing on camera (the case study's demo video). The real drop stays too.
    @discardableResult
    static func set(minutes: Double, like real: Drop, now: Date = .now) -> Drop {
        var drop = real
        drop.date = now.addingTimeInterval(minutes * 60)
        drop.id = "\(idPrefix)\(Int(drop.date.timeIntervalSince1970))"
        drop.previousDate = nil
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

    /// `result` with the fake drop in date order, replacing any earlier fake one; without one, only stale fakes go.
    static func adding(to result: UpcomingLoader.Result?) -> UpcomingLoader.Result? {
        // A copy of a real drop carries a real show's name, so an offline relaunch can bring it back from the last
        // snapshot as that show's last known drop; it goes here even when there's no fake drop now.
        guard let current else {
            guard var result else { return nil }
            result.drops.removeAll(where: isFake)
            return result
        }
        var merged = result ?? UpcomingLoader.Result()
        merged.drops.removeAll(where: isFake)
        merged.drops.append(current)
        merged.drops.sort { ($0.date, $0.id) < ($1.date, $1.id) }
        return merged
    }
}
#endif
