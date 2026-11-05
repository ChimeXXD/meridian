import Foundation

/// Upcoming's layout from a list of drops (SPEC §1 and its section criterion): the hero is the soonest drop that is
/// out now or still to come; everything else goes into Out now, Next 24 hours, This week, Later, Date only and
/// Nothing scheduled, in that order. Pure, so the boundaries are tested with a fixed clock.
struct UpcomingSections: Equatable {
    enum Bucket: Equatable {
        /// More than an hour past its drop: no longer shown.
        case gone
        case outNow, next24Hours, thisWeek, later, dateOnly
    }

    struct Section: Equatable {
        var title: String
        var drops: [Drop] = []
        /// Followed shows with no next episode, for "Nothing scheduled".
        var shows: [UpcomingLoader.Quiet] = []
    }

    var hero: Drop?
    var sections: [Section]
    /// The soonest date-only drop, named by the empty headline when there's no hero.
    var nextDateOnly: Drop?
    /// With no countdown, the show the top of the screen features instead of going blank (Chime: "too bland").
    var spotlight: Spotlight?

    /// With no countdown, the show the top of the screen features instead of going blank (Chime: "too bland").
    enum Spotlight: Equatable {
        case dateOnly(Drop), quiet(UpcomingLoader.Quiet)
    }

    /// The spotlighted show's ID, for its art.
    var spotlightShowID: String? {
        switch spotlight {
        case .dateOnly(let drop): drop.showID
        case .quiet(let show): show.showID
        case nil: nil
        }
    }

    static func bucket(_ drop: Drop, now: Date) -> Bucket {
        if drop.confidence == .dateOnly { return .dateOnly }
        let seconds = drop.date.timeIntervalSince(now)
        switch seconds {
        case ...(-3_600): return .gone
        case ...0: return .outNow
        case ...86_400: return .next24Hours
        case ...(7 * 86_400): return .thisWeek
        default: return .later
        }
    }

    /// The instants a timed drop changes section (`bucket`): into This week, Next 24 hours and Out now, and gone an
    /// hour after its drop. Each takes effect at that instant, so Upcoming's page redraws there (`UpcomingSchedule`).
    static func changes(drops: [Drop]) -> [Date] {
        drops.filter { $0.confidence != .dateOnly }
            .flatMap { [$0.date - 7 * 86_400, $0.date - 86_400, $0.date, $0.date + 3_600] }
            .sorted()
    }

    static func make(drops: [Drop], nothingScheduled: [UpcomingLoader.Quiet], now: Date) -> UpcomingSections {
        let sorted = drops.sorted { $0.date < $1.date }
        let timed = sorted.filter { [.outNow, .next24Hours, .thisWeek, .later].contains(bucket($0, now: now)) }
        let hero = timed.first
        // With no countdown, the soonest date-only show (or else the first quiet one) is spotlighted at the top.
        // Like the hero, whatever leads the screen leaves its section, so nothing appears twice.
        let nextDateOnly = sorted.first { $0.confidence == .dateOnly }
        let lead = hero ?? nextDateOnly
        let rest = sorted.filter { $0.id != lead?.id }
        let titled: [(String, Bucket)] = [("Out now", .outNow), ("Next 24 hours", .next24Hours), ("This week", .thisWeek),
                                          ("Later", .later), ("Date only", .dateOnly)]
        var sections = titled.compactMap { title, kind -> Section? in
            let matching = rest.filter { bucket($0, now: now) == kind }
            return matching.isEmpty ? nil : Section(title: title, drops: matching)
        }
        let quiet = lead == nil ? Array(nothingScheduled.dropFirst()) : nothingScheduled
        if !quiet.isEmpty { sections.append(Section(title: "Nothing scheduled", shows: quiet)) }
        let spotlight: Spotlight? = if hero != nil { nil } else if let nextDateOnly { .dateOnly(nextDateOnly) }
            else { nothingScheduled.first.map(Spotlight.quiet) }
        return UpcomingSections(hero: hero, sections: sections, nextDateOnly: nextDateOnly, spotlight: spotlight)
    }

    /// What the top of Upcoming says when no show has a time yet. Names the next real date when there is one;
    /// never promises a refresh interval (D-27).
    func emptyHeadline(formatter: DropFormatter, now: Date) -> String {
        if let next = nextDateOnly, let day = next.airdate.flatMap({ formatter.airdate($0, now: now) }) {
            return "\(next.showName) returns \(day)"
        }
        return "Nothing scheduled for your shows yet. Meridian checks again each time you open it."
    }
}
