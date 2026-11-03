#if DEBUG
import Foundation

/// Debug › Silo demo, for the case study's recordings: Silo returns only in 2027, so its listed episode is moved to a
/// chosen time. Its show, episode, network and art stay real, and its time is worded as its platform rule words it
/// ("Expected", from Apple TV's usual time), so the footage says what Meridian would really say about Silo.
@MainActor
enum DebugSiloDemo {
    /// Silo's TVmaze ID.
    static let showID = "38052"

    /// "4d 4h": four days, four and a half hours away, so the still countdown holds "4d 4h" for half an hour (D-56).
    static let fourDaysMinutes: Double = 4 * 1_440 + 4 * 60 + 30
    /// The last day, ticking.
    static let lastDayMinutes: Double = 3 * 60

    /// Silo's drop in Upcoming: its listed one (a date-only placeholder today), or the demo's copy while one is set,
    /// since the copy stands in for it. Nil until Silo is followed and loaded.
    static func listed(in drops: [Drop]) -> Drop? {
        drops.first { $0.showID == showID }
    }

    /// A fake copy of Silo's `listed` drop `minutes` from `now`, with the confidence and source the resolver gives an
    /// episode on its platform that day. Nil when no platform rule covers it, so the demo never invents an exact time.
    static func drop(minutes: Double, from listed: Drop, rules: RulesFile, now: Date = .now) -> Drop? {
        var drop = DebugFakeDrop.copy(of: listed, minutes: minutes, now: now)
        let day = DropFormatter(timeZone: .gmt).localDay(drop.date)
        let listing = EpisodeListing(episodeID: listed.id, showID: listed.showID, airdate: day, airtime: "",
                                     airstamp: nil, channelNames: [listed.provider?.name].compactMap { $0 },
                                     broadcastNetwork: nil)
        let resolution = TimeResolver.resolve(listing, rules: rules)
        guard resolution.confidence != .dateOnly else { return nil }
        drop.confidence = resolution.confidence
        drop.source = resolution.source
        drop.airdate = day
        return drop
    }

    /// Silo and a copy of `other` an hour later: the same night, so one Live Activity covers both, Silo first.
    static func sameNight(silo: Drop, with other: Drop) -> [Drop] {
        [silo, DebugFakeDrop.copy(of: other, minutes: 60, now: silo.date)]
    }
}
#endif
