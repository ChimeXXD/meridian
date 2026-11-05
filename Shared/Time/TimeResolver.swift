import Foundation

/// Decides when an episode really releases (SPEC §3.1). In order:
/// override → real broadcast airtime → platform rule → date only.
/// A TVmaze airstamp with an empty airtime is a placeholder and is never trusted (D-25).
enum TimeResolver {
    /// A listing with no airtime more than this far from `now` is a guessed date, so no rule is applied (O-10).
    static let placeholderHorizon: TimeInterval = 180 * 86_400

    static func resolve(_ listing: EpisodeListing, rules: RulesFile, offsetMinutes: Int = 0, now: Date? = nil) -> Resolution {
        applyingOffset(offsetMinutes, to: base(listing, rules: rules, now: now))
    }

    /// AniList `airingAt` is the Japanese broadcast; an offset models a later stream.
    static func resolveAniList(airingAt: Date, offsetMinutes: Int) -> Resolution {
        applyingOffset(offsetMinutes, to: Resolution(date: airingAt, confidence: .exact, source: .anilist, airdate: nil))
    }

    private static func base(_ listing: EpisodeListing, rules: RulesFile, now: Date?) -> Resolution {
        let candidates = [rules.override(forEpisode: listing.episodeID), rules.override(forShow: listing.showID)]
        if let (override, date) = candidates.lazy.compactMap({ item in
            item.flatMap { o in o.date(airdate: listing.airdate).map { (o, $0) } }
        }).first {
            return Resolution(date: date, confidence: override.confirmed ? .exact : .estimated,
                              source: .override(note: override.note), airdate: listing.airdate)
        }
        if !listing.airtime.isEmpty, let airstamp = listing.airstamp {
            let network = listing.broadcastNetwork ?? listing.channelNames.first ?? "Broadcast"
            return Resolution(date: airstamp, confidence: .exact, source: .broadcast(network: network), airdate: listing.airdate)
        }
        // TVmaze parks far-off returns on a guessed date (Silo S4E1: 2027-07-09); a rule would dress that up (O-10).
        if let now, let airdate = listing.airdate,
           let day = WallClock.instant(airdate: airdate, time: "12:00", zone: "GMT", dayOffset: 0),
           day.timeIntervalSince(now) > placeholderHorizon {
            return dateOnly(listing)
        }
        if let airdate = listing.airdate, let rule = rules.platform(matching: listing.channelNames),
           let date = WallClock.instant(airdate: airdate, time: rule.time, zone: rule.zone, dayOffset: rule.dayOffset) {
            return Resolution(date: date, confidence: .estimated, source: .platformRule(rule.label), airdate: airdate)
        }
        return dateOnly(listing)
    }

    private static func dateOnly(_ listing: EpisodeListing) -> Resolution {
        let sortKey = listing.airdate.flatMap { WallClock.instant(airdate: $0, time: "12:00", zone: "GMT", dayOffset: 0) }
        return Resolution(date: sortKey ?? .distantFuture, confidence: .dateOnly, source: .dateOnly, airdate: listing.airdate)
    }

    private static func applyingOffset(_ minutes: Int, to resolution: Resolution) -> Resolution {
        guard minutes != 0, resolution.confidence != .dateOnly else { return resolution }
        return Resolution(date: resolution.date.addingTimeInterval(TimeInterval(minutes * 60)), confidence: .estimated,
                          source: .adjusted(base: resolution.source, offsetMinutes: minutes),
                          airdate: resolution.airdate)
    }
}
