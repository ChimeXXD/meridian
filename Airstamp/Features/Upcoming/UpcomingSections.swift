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
        /// Names of followed shows with no next episode, for "Nothing scheduled".
        var shows: [String] = []
    }

    var hero: Drop?
    var sections: [Section]
    /// The soonest date-only drop, named by the empty headline when there's no hero.
    var nextDateOnly: Drop?

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

    static func make(drops: [Drop], nothingScheduled: [String], now: Date) -> UpcomingSections {
        let sorted = drops.sorted { $0.date < $1.date }
        let timed = sorted.filter { [.outNow, .next24Hours, .thisWeek, .later].contains(bucket($0, now: now)) }
        let hero = timed.first
        let rest = sorted.filter { $0.id != hero?.id }
        let titled: [(String, Bucket)] = [("Out now", .outNow), ("Next 24 hours", .next24Hours), ("This week", .thisWeek),
                                          ("Later", .later), ("Date only", .dateOnly)]
        var sections = titled.compactMap { title, kind -> Section? in
            let matching = rest.filter { bucket($0, now: now) == kind }
            return matching.isEmpty ? nil : Section(title: title, drops: matching)
        }
        if !nothingScheduled.isEmpty { sections.append(Section(title: "Nothing scheduled", shows: nothingScheduled)) }
        return UpcomingSections(hero: hero, sections: sections,
                                nextDateOnly: sorted.first { $0.confidence == .dateOnly })
    }

    /// What the top of Upcoming says when no show has a time yet. Names the next real date when there is one;
    /// never promises a refresh interval (D-27).
    func emptyHeadline(formatter: DropFormatter, now: Date) -> String {
        if let next = nextDateOnly, let day = next.airdate.flatMap({ formatter.airdate($0, now: now) }) {
            return "\(next.showName) returns \(day)"
        }
        return "Nothing scheduled for your shows yet. Airstamp checks again each time you open it."
    }
}
