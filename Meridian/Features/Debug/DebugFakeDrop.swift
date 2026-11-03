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

    /// The fake drops now set: one, or two for the Silo demo's same-night pair.
    static private(set) var drops: [Drop] = []

    static func isFake(_ drop: Drop) -> Bool { isFake(id: drop.id) }

    static func isFake(id: String) -> Bool { id.hasPrefix(idPrefix) }

    /// A "Debug Show" episode `minutes` from `now`, not yet set.
    static func make(minutes: Double, now: Date = .now) -> Drop {
        let date = now.addingTimeInterval(minutes * 60)
        return Drop(id: "\(idPrefix)\(Int(date.timeIntervalSince1970))", showID: showID, showName: "Debug Show",
                    season: 1, number: 1, episodeTitle: "Fake episode", date: date, airdate: nil,
                    confidence: .exact, source: .broadcast(network: "Debug TV"),
                    provider: ProviderLabel(name: "Debug TV", countryCode: nil, noOfficialStream: false),
                    previousDate: nil)
    }

    /// Sets the fake drop `minutes` from `now`, replacing any earlier one, and returns it.
    @discardableResult
    static func set(minutes: Double, now: Date = .now) -> Drop {
        let drop = make(minutes: minutes, now: now)
        drops = [drop]
        return drop
    }

    /// A fake copy of a real drop, `minutes` from `now`: its show, episode, network and art, for a release-night
    /// Live Activity that looks like the real thing on camera (the case study's demo video).
    static func copy(of real: Drop, minutes: Double, now: Date = .now) -> Drop {
        var drop = real
        drop.date = now.addingTimeInterval(minutes * 60)
        drop.id = "\(idPrefix)\(real.showID):\(Int(drop.date.timeIntervalSince1970))"
        drop.previousDate = nil
        return drop
    }

    /// Sets a fake copy of a real drop, replacing any earlier fake, and returns it.
    @discardableResult
    static func set(minutes: Double, like real: Drop, now: Date = .now) -> Drop {
        let drop = copy(of: real, minutes: minutes, now: now)
        drops = [drop]
        return drop
    }

    /// Sets these fake drops, replacing any earlier ones.
    static func set(_ fakes: [Drop]) { drops = fakes }

    static func clear() { drops = [] }

    /// Moves the fake drops later, keeping their old times as `previousDate` ("Simulate delay +1 h").
    static func delay(by interval: TimeInterval) {
        drops = drops.map { drop in
            var drop = drop
            drop.previousDate = drop.previousDate ?? drop.date
            drop.date = drop.date.addingTimeInterval(interval)
            return drop
        }
    }

    /// `result` with the fake drops set now.
    static func adding(to result: UpcomingLoader.Result?) -> UpcomingLoader.Result? {
        merging(drops, into: result)
    }

    /// `result` with `fakes` in date order. Stale fakes go, and so do the real drops of a show a fake copies, so a
    /// row never shows the show twice (Silo's listed 2027 return beside its demo). With no fakes, only stale fakes go.
    static func merging(_ fakes: [Drop], into result: UpcomingLoader.Result?) -> UpcomingLoader.Result? {
        // A copy of a real drop carries a real show's name, so an offline relaunch can bring it back from the last
        // snapshot as that show's last known drop; it goes here even when there's no fake drop now.
        guard !fakes.isEmpty else {
            guard var result else { return nil }
            result.drops.removeAll(where: isFake)
            return result
        }
        let copied = Set(fakes.map(\.showID))
        var merged = result ?? UpcomingLoader.Result()
        merged.drops.removeAll { isFake($0) || copied.contains($0.showID) }
        merged.nothingScheduled.removeAll { copied.contains($0.showID) }
        merged.drops += fakes
        merged.drops.sort { ($0.date, $0.id) < ($1.date, $1.id) }
        return merged
    }
}
#endif
